const crypto = require('crypto');

const DEFAULT_LENGTH = 6;

function generateNumericOtp(length = DEFAULT_LENGTH) {
  if (length < 4 || length > 10) {
    throw new Error('Độ dài OTP phải từ 4 đến 10 ký tự');
  }

  const max = 10 ** length;
  const otp = crypto.randomInt(0, max).toString().padStart(length, '0');
  return otp;
}

function hashOtp(otp, salt) {
  if (!otp || !salt) {
    throw new Error('Thiếu OTP hoặc salt để hash');
  }

  return crypto.createHash('sha256').update(`${otp}:${salt}`).digest('hex');
}

function verifyOtp(otp, salt, hashed) {
  if (!hashed) return false;
  try {
    const candidate = hashOtp(otp, salt);
    const bufCandidate = Buffer.from(candidate, 'hex');
    const bufStored = Buffer.from(hashed, 'hex');
    if (bufCandidate.length !== bufStored.length) {
      return false;
    }
    return crypto.timingSafeEqual(bufCandidate, bufStored);
  } catch (error) {
    return false;
  }
}

module.exports = {
  generateNumericOtp,
  hashOtp,
  verifyOtp,
};
