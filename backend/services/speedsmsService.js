const axios = require('axios');

const SPEEDSMS_API_URL = 'https://api.speedsms.vn/index.php';

const config = {
  accessToken: process.env.SPEEDSMS_ACCESS_TOKEN,
  smsType: Number.parseInt(process.env.SPEEDSMS_SMS_TYPE ?? '5', 10), // 5=OTP (no sender needed), 3=CSKH, 2=Brandname
  sender: process.env.SPEEDSMS_SENDER || '',
};

function ensureConfig() {
  if (!config.accessToken) {
    throw new Error('SPEEDSMS_ACCESS_TOKEN chưa được cấu hình');
  }
}

function createBasicAuthHeader() {
  // SpeedSMS uses Basic Auth: base64(ACCESS_TOKEN:x)
  const authString = `${config.accessToken}:x`;
  const authBase64 = Buffer.from(authString).toString('base64');
  return `Basic ${authBase64}`;
}

function normalizePhone(phone) {
  if (!phone) return '';
  let sanitized = String(phone).trim();
  
  if (sanitized.startsWith('+')) {
    sanitized = sanitized.slice(1);
  }
  
  sanitized = sanitized.replace(/[\s\-\.]/g, '');
  
  if (sanitized.startsWith('0')) {
    sanitized = `84${sanitized.slice(1)}`;
  }
  
  console.log(`📱 Normalized phone: ${phone} -> ${sanitized}`);
  return sanitized;
}

function buildOtpMessage(otp, { ttlMinutes = 5, appHash } = {}) {
  // Type 3 (CSKH): 160 chars (no dấu) or 70 chars (có dấu)
  // Không được chứa link
  const lines = [`Ma OTP cua ban la: ${otp}`];
  lines.push(`Het han trong ${ttlMinutes} phut.`);
  
  if (appHash) {
    lines.push(appHash);
  }
  
  const message = lines.join('\n');
  console.log('📝 OTP Message:', message);
  console.log(`📏 Length: ${message.length} chars`);
  
  if (message.length > 160) {
    console.warn('⚠️  Message > 160 chars, will be split into multiple SMS');
  }
  
  return message;
}

async function sendSms({ phone, content, smsType, sender }) {
  ensureConfig();

  if (!phone) {
    throw new Error('Thiếu số điện thoại khi gửi SMS');
  }
  if (!content) {
    throw new Error('Thiếu nội dung SMS');
  }

  const finalSmsType = smsType ?? config.smsType ?? 3;
  const finalSender = sender ?? config.sender ?? '';
  
  // SpeedSMS nhận array phones (có thể gửi nhiều số)
  const phones = [normalizePhone(phone)];
  
  const payload = {
    to: phones,
    content: content,
    sms_type: finalSmsType,
  };

  // Chỉ thêm sender khi type=2 (Brandname)
  if (finalSmsType === 2 && finalSender) {
    payload.sender = finalSender;
  }

  console.log('📤 Sending SMS with params:', {
    to: payload.to,
    contentLength: payload.content.length,
    sms_type: payload.sms_type,
    sender: payload.sender || '(none)',
  });

  try {
    // CRITICAL: POST request với Basic Auth (theo tài liệu chính thức)
    const response = await axios.post(
      SPEEDSMS_API_URL + '/sms/send',
      payload,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': createBasicAuthHeader(),
        },
        timeout: 15000,
      }
    );

    const data = response.data ?? {};
    
    console.log('📥 SpeedSMS Response:', {
      status: data.status,
      code: data.code,
      message: data.message,
    });

    if (data.status !== 'success') {
      const errorMessages = {
        '-1': 'Lỗi hệ thống',
        '-2': 'Access token không đúng',
        '-3': 'Số dư tài khoản không đủ',
        '-4': 'Tham số không hợp lệ',
        '-5': 'Số điện thoại không hợp lệ',
        '-6': 'Brandname chưa được duyệt',
        '-7': 'Nội dung tin nhắn vi phạm (có link nhưng không có brandname)',
        '-8': 'Nội dung chứa từ khóa cấm',
        '-99': 'Lỗi không xác định',
      };

      const errorMsg = errorMessages[data.code] || data.message || 'Unknown error';
      const error = new Error(
        `SpeedSMS error [${data.code}]: ${errorMsg}`
      );
      error.response = data;
      throw error;
    }

    // Response trả về array tranId (vì có thể gửi nhiều số)
    const tranIds = data.data || [];
    const tranId = tranIds.length > 0 ? tranIds[0] : null;

    console.log(`✅ SMS sent successfully. TranId: ${tranId}`);

    return { 
      success: true,
      tranId: tranId,
      tranIds: tranIds,
      message: data.message,
      ...data 
    };
  } catch (error) {
    if (error.response?.data) {
      console.error('❌ SpeedSMS API error:', error.response.data);
    } else if (error.request) {
      console.error('❌ No response from SpeedSMS:', error.message);
    } else {
      console.error('❌ Request setup error:', error.message);
    }
    throw error;
  }
}

async function sendOtpSms({ phone, otp, ttlMinutes = 5, appHash, transactionId, smsType }) {
  const content = buildOtpMessage(otp, { ttlMinutes, appHash });
  
  // Type 5 (OTP) - chuyên dụng cho OTP, KHÔNG cần sender
  const result = await sendSms({ 
    phone, 
    content,
    smsType: smsType ?? 5,  // Changed to 5 (OTP type)
    sender: '',
  });

  if (transactionId) {
    console.log(`📝 Transaction ID: ${transactionId}`);
  }

  return result;
}

async function getSmsStatus(tranId) {
  ensureConfig();

  if (!tranId) {
    throw new Error('Thiếu TranId khi kiểm tra trạng thái SMS');
  }

  console.log(`🔍 Checking status for TranId: ${tranId}`);

  try {
    const response = await axios.get(
      SPEEDSMS_API_URL + '/sms/get',
      {
        params: { tranId },
        headers: {
          'Authorization': createBasicAuthHeader(),
        },
        timeout: 10000,
      }
    );

    const data = response.data ?? {};
    
    if (data.status !== 'success') {
      console.error(`❌ GetStatus error: ${data.message}`);
      return null;
    }

    const smsData = data.data || {};
    
    const statusMessages = {
      '0': 'Chưa gửi',
      '1': 'Đã gửi đến nhà mạng',
      '2': 'Nhà mạng đã nhận',
      '3': 'Gửi thành công (đã đến thuê bao)',
      '-1': 'Gửi thất bại',
      '-2': 'Số điện thoại không tồn tại',
      '-3': 'Thuê bao không hoạt động',
    };

    console.log(`📊 SMS Status for ${tranId}:`, {
      status: `${smsData.status} - ${statusMessages[smsData.status] || 'Unknown'}`,
      phone: smsData.phone,
      sendTime: smsData.sendTime,
    });

    return smsData;
  } catch (error) {
    console.error('❌ GetStatus request error:', error.message);
    return null;
  }
}

async function getBalance() {
  ensureConfig();

  try {
    const response = await axios.get(
      SPEEDSMS_API_URL + '/user/balance',
      {
        headers: {
          'Authorization': createBasicAuthHeader(),
        },
        timeout: 10000,
      }
    );

    const data = response.data ?? {};
    
    if (data.status === 'success') {
      const balanceData = data.data || {};
      const balance = balanceData.balance || 0;
      const smsCount = balanceData.sms || 0;
      console.log(`💰 Balance: ${balance.toLocaleString()} VND (${smsCount} SMS)`);
      return balanceData;
    }
    
    return null;
  } catch (error) {
    console.error('❌ GetBalance error:', error.message);
    if (error.response?.data) {
      console.error('Response:', error.response.data);
    }
    return null;
  }
}

module.exports = {
  sendSms,
  sendOtpSms,
  buildOtpMessage,
  normalizePhone,
  getSmsStatus,
  getBalance,
};