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
  smsType: Number.parseInt(process.env.ESMS_SMS_TYPE ?? '1', 10),
  sandbox: process.env.ESMS_SANDBOX,
};

function ensureConfig() {
  if (!config.apiKey || !config.secretKey) {
    throw new Error('ESMS_API_KEY hoặc ESMS_SECRET_KEY chưa được cấu hình');
  }

  if (!config.brandName && config.smsType === 2) {
    throw new Error('ESMS_BRAND_NAME bắt buộc khi SmsType = 2 (BrandName)');
  }
}

function normalizePhone(phone) {
  if (!phone) return '';
  let sanitized = String(phone).trim();
  if (sanitized.startsWith('+')) {
    sanitized = sanitized.slice(1);
  }
  sanitized = sanitized.replace(/\s+/g, '');
  if (sanitized.startsWith('0')) {
    sanitized = `84${sanitized.slice(1)}`;
  }
  return sanitized;
}

function buildOtpMessage(otp, { ttlMinutes = 5, appHash } = {}) {
  const lines = [` Ma OTP cua ban la ${otp}`];
  lines.push(`Het han trong ${ttlMinutes} phut.`);
  if (appHash) {
    // Theo format SMS Retriever API: thêm mã hash ở cuối cùng một dòng riêng
    lines.push(appHash);
  }
  return lines.join('\n');
}

async function sendSms({ phone, content, smsType, isUnicode = false }) {
  ensureConfig();

  if (!phone) {
    throw new Error('Thiếu số điện thoại khi gửi SMS');
  }
  if (!content) {
    throw new Error('Thiếu nội dung SMS');
  }

  const params = {
    ApiKey: config.apiKey,
    SecretKey: config.secretKey,
    Phone: normalizePhone(phone),
    Content: content,
    SmsType: smsType ?? config.smsType ?? 2,
    IsUnicode: isUnicode ? 1 : 0,
  };

  if (params.SmsType === 2 && config.brandName) {
    params.BrandName = config.brandName;
  }

  if (config.sandbox !== undefined) {
    params.Sandbox = config.sandbox;
  }

  try {
    const response = await axios.post(ESMS_SEND_ENDPOINT, params, {
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = response.data ?? {};
    if (`${data.CodeResult}` !== '100') {
      const error = new Error(
        `eSMS trả về lỗi CodeResult=${data.CodeResult || 'unknown'}`
      );
      error.response = data;
      throw error;
    }

    // Lấy SMSID từ response
    const smsId = data.SMSID || data.RefId;
    console.log(`✅ SMS sent successfully. SMSID: ${smsId}`);

    return { ...data, smsId };
  } catch (error) {
    if (error.response) {
      console.error('eSMS error response:', error.response);
    } else {
      console.error('eSMS request error:', error.message);
    }
    throw error;
  }
}

async function sendOtpSms({ phone, otp, ttlMinutes = 5, appHash, transactionId }) {
  const content = buildOtpMessage(otp, { ttlMinutes, appHash });
  const result = sendSms({ phone, content });

  if (transactionId) {
    console.log(`📝 Transaction ID: ${transactionId}`);
  }

  return result;
}

async function getSmsSendReport(smsId) {
  ensureConfig();

  if (!smsId) {
    throw new Error('Thiếu SMSID khi kiểm tra report');
  }

  const params = {
    ApiKey: config.apiKey,
    SecretKey: config.secretKey,
    SMSID: smsId,
  };

  try {
    const response = await axios.post(ESMS_REPORT_ENDPOINT, params, {
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = response.data ?? {};
    if (`${data.CodeResult}` !== '100') {
      console.error(`GetReport error: CodeResult=${data.CodeResult}`);
      return null;
    }

    // Parse report data
    const report = data.Data?.[0] ?? {};
    console.log(`📊 SMS Report for ${smsId}:`, {
      Status: report.Status,
      ErrorCode: report.ErrorCode,
      ErrorMessage: report.ErrorMessage,
      ReceiveTime: report.ReceiveTime,
    });

    return report;
  } catch (error) {
    console.error('GetReport request error:', error.message);
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
