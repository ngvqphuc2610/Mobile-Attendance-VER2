const axios = require('axios');

const ESMS_SEND_ENDPOINT =
  process.env.ESMS_SEND_ENDPOINT ||
  'https://rest.esms.vn/MainService.svc/json/SendMultipleMessage_V4_post_json/';

const ESMS_REPORT_ENDPOINT =
  process.env.ESMS_REPORT_ENDPOINT ||
  'https://rest.esms.vn/MainService.svc/json/GetReport_V4_post_json/';

const config = {
  apiKey: process.env.ESMS_API_KEY,
  secretKey: process.env.ESMS_API_SECRET_KEY,
  brandName: process.env.ESMS_BRAND_NAME,
  smsType: Number.parseInt(process.env.ESMS_SMS_TYPE ?? '2', 10), // Default = 2 (BrandName)
  sandbox: process.env.ESMS_SANDBOX === '1' ? 1 : 0,
};

function ensureConfig() {
  if (!config.apiKey || !config.secretKey) {
    throw new Error('ESMS_API_KEY hoặc ESMS_SECRET_KEY chưa được cấu hình');
  }

  // Chỉ check BrandName khi SmsType = 2 hoặc 4
  if (!config.brandName && (config.smsType === 2 || config.smsType === 4)) {
    throw new Error(`ESMS_BRAND_NAME bắt buộc khi SmsType = ${config.smsType}`);
  }
}

function normalizePhone(phone) {
  if (!phone) return '';
  let sanitized = String(phone).trim();
  
  // Loại bỏ ký tự +
  if (sanitized.startsWith('+')) {
    sanitized = sanitized.slice(1);
  }
  
  // Loại bỏ khoảng trắng, dấu gạch ngang, dấu chấm
  sanitized = sanitized.replace(/[\s\-\.]/g, '');
  
  // Chuyển 0 đầu thành 84
  if (sanitized.startsWith('0')) {
    sanitized = `84${sanitized.slice(1)}`;
  }
  
  console.log(`📱 Normalized phone: ${phone} -> ${sanitized}`);
  return sanitized;
}

function buildOtpMessage(otp, { ttlMinutes = 5, appHash } = {}) {
  // Không dùng dấu tiếng Việt để tránh lỗi encoding
  const lines = [`Ma OTP cua ban la: ${otp}`];
  lines.push(`Het han trong ${ttlMinutes} phut.`);
  
  if (appHash) {
    // Theo format SMS Retriever API: thêm mã hash ở cuối
    lines.push(appHash);
  }
  
  const message = lines.join('\n');
  console.log('📝 OTP Message:', message);
  return message;
}

async function sendSms({ phone, content, smsType, isUnicode = false }) {
  ensureConfig();

  if (!phone) {
    throw new Error('Thiếu số điện thoại khi gửi SMS');
  }
  if (!content) {
    throw new Error('Thiếu nội dung SMS');
  }

  const finalSmsType = smsType ?? config.smsType ?? 8;
  const params = {
    ApiKey: config.apiKey,
    SecretKey: config.secretKey,
    Phone: normalizePhone(phone),
    Content: content,
    SmsType: finalSmsType,
    IsUnicode: isUnicode ? 1 : 0,
  };

  // Chỉ thêm BrandName khi SmsType = 2 hoặc 4
  if ((finalSmsType === 2 || finalSmsType === 4) && config.brandName) {
    params.BrandName = config.brandName;
  }

  // Sandbox mode
  if (config.sandbox === 1) {
    params.Sandbox = 1;
  }

  console.log('📤 Sending SMS with params:', {
    Phone: params.Phone,
    ContentLength: params.Content.length,
    SmsType: params.SmsType,
    BrandName: params.BrandName || '(none)',
    IsUnicode: params.IsUnicode,
    Sandbox: params.Sandbox || 0
  });

  try {
    const response = await axios.post(ESMS_SEND_ENDPOINT, params, {
      timeout: 15000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = response.data ?? {};
    console.log('📥 eSMS Response:', {
      CodeResult: data.CodeResult,
      CountRegenerate: data.CountRegenerate,
      SMSID: data.SMSID,
      ErrorMessage: data.ErrorMessage
    });

    if (`${data.CodeResult}` !== '100') {
      const errorMessages = {
        '101': 'Thiếu ApiKey hoặc SecretKey',
        '102': 'ApiKey hoặc SecretKey không đúng',
        '103': 'Tài khoản không đủ tiền',
        '104': 'BrandName không tồn tại hoặc chưa được duyệt',
        '118': 'Số điện thoại không hợp lệ',
        '119': 'Loại tin nhắn (SmsType) không hợp lệ',
        '131': 'Tin nhắn chứa nội dung vi phạm',
      };

      const errorMsg = errorMessages[data.CodeResult] || data.ErrorMessage || 'Unknown error';
      const error = new Error(
        `eSMS error [${data.CodeResult}]: ${errorMsg}`
      );
      error.response = data;
      throw error;
    }

    const smsId = data.SMSID || data.RefId;
    console.log(`✅ SMS sent successfully. SMSID: ${smsId}`);

    return { ...data, smsId };
  } catch (error) {
    if (error.response?.data) {
      console.error('❌ eSMS API error:', error.response.data);
    } else if (error.request) {
      console.error('❌ No response from eSMS:', error.message);
    } else {
      console.error('❌ Request setup error:', error.message);
    }
    throw error;
  }
}

async function sendOtpSms({ phone, otp, ttlMinutes = 5, appHash, transactionId }) {
  const content = buildOtpMessage(otp, { ttlMinutes, appHash });
  
  // Force SmsType = 8 cho OTP
  const result = await sendSms({ 
    phone, 
    content,
    smsType: 8,
    isUnicode: false
  });

  if (transactionId) {
    console.log(`📝 Transaction ID: ${transactionId}`);
  }

  // KHÔNG auto check report vì có thể gây lỗi 404
  // User có thể gọi getSmsSendReport() riêng nếu cần
  
  return result;
}

async function getSmsSendReport(smsId) {
  ensureConfig();

  if (!smsId) {
    throw new Error('Thiếu SMSID khi kiểm tra report');
  }

  // Clean SMSID - loại bỏ ký tự thừa nếu có
  const cleanSmsId = String(smsId).trim();

  const params = {
    ApiKey: config.apiKey,
    SecretKey: config.secretKey,
    SMSID: cleanSmsId,
  };

  console.log(`🔍 Checking report for SMSID: ${cleanSmsId}`);

  try {
    const response = await axios.post(ESMS_REPORT_ENDPOINT, params, {
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = response.data ?? {};
    
    console.log('📥 GetReport Raw Response:', data);
    
    if (`${data.CodeResult}` !== '100') {
      console.error(`❌ GetReport error: CodeResult=${data.CodeResult}, Message=${data.ErrorMessage}`);
      return null;
    }

    // Parse report data
    const report = data.Data?.[0] ?? {};
    
    const statusMessages = {
      '0': 'Chưa gửi',
      '1': 'Đã gửi thành công',
      '2': 'Gửi thất bại',
      '3': 'Đang gửi',
    };

    console.log(`📊 SMS Report for ${cleanSmsId}:`, {
      Status: `${report.Status} - ${statusMessages[report.Status] || 'Unknown'}`,
      ErrorCode: report.ErrorCode || 'N/A',
      ErrorMessage: report.ErrorMessage || 'N/A',
      ReceiveTime: report.ReceiveTime || 'N/A',
      SentTime: report.SentTime || 'N/A',
    });

    return report;
  } catch (error) {
    if (error.response?.status === 404) {
      console.error('❌ GetReport 404: Endpoint không tồn tại hoặc SMSID chưa có trong hệ thống. Thử lại sau 30-60s.');
    } else if (error.response?.data) {
      console.error('❌ GetReport error response:', error.response.data);
    } else {
      console.error('❌ GetReport request error:', error.message);
    }
    return null;
  }
}

module.exports = {
  sendSms,
  sendOtpSms,
  buildOtpMessage,
  normalizePhone,
  getSmsSendReport,
};