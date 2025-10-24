const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const { sendOtpSms, normalizePhone } = require('../services/esmsService');
const {
  generateNumericOtp,
  hashOtp,
  verifyOtp,
} = require('../services/otpGenerator');
const {
  generateTotpSetup,
  verifyTotpToken,
  encryptSecret,
  decryptSecret,
} = require('../services/totpService');

const router = express.Router();

const OTP_LENGTH = Number.parseInt(process.env.OTP_LENGTH ?? '6', 10);
const OTP_TTL_SECONDS = Number.parseInt(process.env.OTP_TTL_SECONDS ?? '300', 10);
const OTP_RESEND_WINDOW = Number.parseInt(
  process.env.OTP_RESEND_WINDOW ?? '60',
  10
);
const OTP_MAX_ATTEMPTS = Number.parseInt(
  process.env.OTP_MAX_ATTEMPTS ?? '5',
  10
);
const ANDROID_SMS_HASH = process.env.ANDROID_SMS_HASH;

function signJwt(profileId, role) {
  return jwt.sign(
    {
      userId: profileId,
      role,
    },
    process.env.JWT_SECRET,
    { expiresIn: '24h' }
  );
}

async function getAccountByEmail(email, connection = db) {
  const [rows] = await connection.execute(
    `SELECT 
        a.id              AS account_id,
        a.profile_id      AS profile_id,
        a.password_hash   AS password_hash,
        a.is_active       AS account_active,
        a.is_phone_verified AS phone_verified,
        p.full_name       AS full_name,
        p.code            AS profile_code,
        p.phone           AS phone,
        p.is_active       AS profile_active,
        ur.role           AS role,
        a.email           AS email
     FROM accounts a
     JOIN profiles p ON a.profile_id = p.id
     JOIN user_roles ur ON p.id = ur.user_id
     WHERE a.email = ?
     LIMIT 1`,
    [email]
  );

  return rows.length > 0 ? rows[0] : null;
}

async function getTotpRecord(accountId, connection = db) {
  const [rows] = await connection.execute(
    'SELECT secret_encrypted FROM account_totp WHERE account_id = ? LIMIT 1',
    [accountId]
  );
  return rows.length > 0 ? rows[0] : null;
}

// =========================
// Đăng nhập
// =========================
router.post('/login', async (req, res) => {
  try {
    const { email, password, totp } = req.body;

    if (!email || !password) {
      return res
        .status(400)
        .json({ error: 'Vui lòng nhập email và mật khẩu.' });
    }

    const account = await getAccountByEmail(email);
    if (!account || !account.account_active || !account.profile_active) {
      return res.status(401).json({ error: 'Thông tin đăng nhập không hợp lệ.' });
    }

    const isValidPassword = await bcrypt.compare(
      password,
      account.password_hash
    );
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Thông tin đăng nhập không hợp lệ.' });
    }

    // Kiểm tra TOTP nếu đã bật
    const totpRecord = await getTotpRecord(account.account_id);
    if (totpRecord) {
      if (!totp) {
        return res.status(403).json({
          need_totp: true,
          error: 'Tài khoản đã bật xác thực hai lớp. Vui lòng nhập mã TOTP.',
        });
      }

      const secret = decryptSecret(totpRecord.secret_encrypted);
      const isValidTotp = verifyTotpToken(secret, totp);
      if (!isValidTotp) {
        return res
          .status(401)
          .json({ error: 'Mã TOTP không chính xác.', need_totp: true });
      }

      await db.execute(
        'UPDATE account_totp SET last_verified_at = NOW() WHERE account_id = ?',
        [account.account_id]
      );
    }

    await db.execute(
      'UPDATE accounts SET last_login_at = NOW() WHERE id = ?',
      [account.account_id]
    );

    const token = signJwt(account.profile_id, account.role);

    res.json({
      token,
      user: {
        id: account.profile_id,
        email: account.email,
        full_name: account.full_name,
        code: account.profile_code,
        role: account.role,
        phone_verified: !!account.phone_verified,
        totp_enabled: Boolean(totpRecord),
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Đăng nhập thất bại.' });
  }
});

// =========================
// Đăng ký - gửi OTP
// =========================
router.post('/register/request-otp', async (req, res) => {
  const {
    full_name,
    email,
    password,
    phone,
    role = 'student',
    code,
  } = req.body;

  if (!full_name || !email || !password || !phone) {
    return res
      .status(400)
      .json({ error: 'Vui lòng nhập đầy đủ họ tên, email, mật khẩu và số điện thoại.' });
  }

  const normalizedPhone = normalizePhone(phone);
  if (!normalizedPhone) {
    return res.status(400).json({ error: 'Số điện thoại không hợp lệ.' });
  }

  const connection = await db.getConnection();
  try {
    await connection.beginTransaction();

    const existingAccount = await getAccountByEmail(email, connection);
    if (existingAccount && existingAccount.phone_verified) {
      await connection.rollback();
      return res
        .status(409)
        .json({ error: 'Email này đã được sử dụng và xác thực.' });
    }

    let profileId;
    let accountId;

    if (!existingAccount) {
      profileId = uuidv4();
      accountId = uuidv4();

      await connection.execute(
        `INSERT INTO profiles (id, code, full_name, email, phone, is_active)
         VALUES (?, ?, ?, ?, ?, 1)`,
        [profileId, code || null, full_name, email, normalizedPhone]
      );

      const hashedPassword = await bcrypt.hash(password, 10);
      await connection.execute(
        `INSERT INTO accounts (id, profile_id, email, password_hash, is_active, is_phone_verified)
         VALUES (?, ?, ?, ?, 0, 0)`,
        [accountId, profileId, email, hashedPassword]
      );

      await connection.execute(
        `INSERT INTO user_roles (user_id, role)
         VALUES (?, ?)
         ON DUPLICATE KEY UPDATE role = VALUES(role)`,
        [profileId, role]
      );
    } else {
      profileId = existingAccount.profile_id;
      accountId = existingAccount.account_id;

      const hashedPassword = await bcrypt.hash(password, 10);
      await connection.execute(
        `UPDATE accounts SET password_hash = ?, is_active = 0, is_phone_verified = 0
         WHERE id = ?`,
        [hashedPassword, accountId]
      );

      await connection.execute(
        `UPDATE profiles
            SET full_name = ?, phone = ?, code = ?, email = ?
          WHERE id = ?`,
        [full_name, normalizedPhone, code || existingAccount.profile_code, email, profileId]
      );

      await connection.execute(
        `UPDATE user_roles SET role = ? WHERE user_id = ?`,
        [role, profileId]
      );
    }

    const [recentRequests] = await connection.execute(
      `SELECT id, created_at 
         FROM phone_otp_requests
        WHERE phone = ? AND purpose = 'register'
        ORDER BY created_at DESC
        LIMIT 1`,
      [normalizedPhone]
    );

    if (recentRequests.length > 0) {
      const lastRequestAt = new Date(recentRequests[0].created_at).getTime();
      if (Date.now() - lastRequestAt < OTP_RESEND_WINDOW * 1000) {
        await connection.rollback();
        return res.status(429).json({
          error: 'Vui lòng chờ trước khi yêu cầu mã OTP mới.',
          retryIn: OTP_RESEND_WINDOW,
        });
      }
    }

    const otp = generateNumericOtp(OTP_LENGTH);
    const transactionId = uuidv4();
    const otpHash = hashOtp(otp, transactionId);

    await connection.execute(
      `INSERT INTO phone_otp_requests
        (id, profile_id, phone, purpose, code_hash, expires_at, attempts, created_at, updated_at)
       VALUES (?, ?, ?, 'register', ?, DATE_ADD(NOW(), INTERVAL ? SECOND), 0, NOW(), NOW())`,
      [transactionId, profileId, normalizedPhone, otpHash, OTP_TTL_SECONDS]
    );

    const sendResult = await sendOtpSms({
      phone: normalizedPhone,
      otp,
      ttlMinutes: Math.ceil(OTP_TTL_SECONDS / 60),
      appHash: ANDROID_SMS_HASH,
      transactionId,
    });

    // Lưu SMSID vào database để kiểm tra report sau
    if (sendResult.smsId) {
      await connection.execute(
        `UPDATE phone_otp_requests
         SET sms_id = ?
         WHERE id = ?`,
        [sendResult.smsId, transactionId]
      );
    }

    await connection.commit();

    res.json({
      transactionId,
      expiresIn: OTP_TTL_SECONDS,
      message: 'Đã gửi mã OTP tới số điện thoại của bạn.',
    });
  } catch (error) {
    await connection.rollback();
    console.error('Register request OTP error:', error);
    res
      .status(500)
      .json({ error: 'Không thể gửi OTP. Vui lòng thử lại sau.' });
  } finally {
    connection.release();
  }
});

// =========================
// Đăng ký - xác thực OTP
// =========================
router.post('/register/verify-otp', async (req, res) => {
  const { transactionId, otp } = req.body;

  if (!transactionId || !otp) {
    return res
      .status(400)
      .json({ error: 'Thiếu transactionId hoặc mã OTP.' });
  }

  const connection = await db.getConnection();

  try {
    await connection.beginTransaction();

    const [[otpRequest]] = await connection.execute(
      `SELECT *
         FROM phone_otp_requests
        WHERE id = ? AND purpose = 'register'
        FOR UPDATE`,
      [transactionId]
    );

    if (!otpRequest) {
      await connection.rollback();
      return res.status(404).json({ error: 'Không tìm thấy yêu cầu OTP.' });
    }

    if (otpRequest.verified_at) {
      await connection.rollback();
      return res
        .status(400)
        .json({ error: 'Mã OTP này đã được sử dụng trước đó.' });
    }

    if (otpRequest.attempts >= OTP_MAX_ATTEMPTS) {
      await connection.rollback();
      return res
        .status(429)
        .json({ error: 'Bạn đã nhập sai OTP quá số lần cho phép.' });
    }

    if (new Date(otpRequest.expires_at).getTime() < Date.now()) {
      await connection.rollback();
      return res.status(410).json({ error: 'Mã OTP đã hết hạn.' });
    }

    const isValidOtp = verifyOtp(otp, transactionId, otpRequest.code_hash);
    if (!isValidOtp) {
      await connection.execute(
        `UPDATE phone_otp_requests
            SET attempts = attempts + 1, updated_at = NOW()
          WHERE id = ?`,
        [transactionId]
      );
      await connection.commit();
      return res.status(401).json({ error: 'Mã OTP không chính xác.' });
    }

    await connection.execute(
      `UPDATE phone_otp_requests
          SET verified_at = NOW(), attempts = attempts + 1, updated_at = NOW()
        WHERE id = ?`,
      [transactionId]
    );

    const profileId = otpRequest.profile_id;

    const [[account]] = await connection.execute(
      `SELECT 
          a.id AS account_id,
          a.profile_id,
          a.email,
          ur.role,
          p.full_name,
          p.code
       FROM accounts a
       JOIN profiles p ON a.profile_id = p.id
       JOIN user_roles ur ON p.id = ur.user_id
       WHERE a.profile_id = ?
       LIMIT 1`,
      [profileId]
    );

    if (!account) {
      throw new Error('Không tìm thấy tài khoản tương ứng với OTP.');
    }

    await connection.execute(
      `UPDATE accounts
          SET is_active = 1,
              is_phone_verified = 1,
              updated_at = NOW()
        WHERE id = ?`,
      [account.account_id]
    );

    await connection.commit();

    const token = signJwt(account.profile_id, account.role);

    res.json({
      message: 'Xác thực OTP thành công.',
      token,
      user: {
        id: account.profile_id,
        email: account.email,
        full_name: account.full_name,
        code: account.code,
        role: account.role,
        phone_verified: true,
      },
    });
  } catch (error) {
    await connection.rollback();
    console.error('Verify OTP error:', error);
    res.status(500).json({ error: 'Không thể xác thực OTP.' });
  } finally {
    connection.release();
  }
});

// =========================
// Khởi tạo TOTP
// =========================
router.post('/totp/init', authenticateToken, async (req, res) => {
  try {
    const accountId = req.user.account_id;
    const email = req.user.email;

    const totpRecord = await getTotpRecord(accountId);
    if (totpRecord) {
      return res
        .status(400)
        .json({ error: 'Bạn đã bật TOTP. Vui lòng tắt trước khi tạo mới.' });
    }

    const setup = await generateTotpSetup(email);
    res.json(setup);
  } catch (error) {
    console.error('Init TOTP error:', error);
    res.status(500).json({ error: 'Không thể khởi tạo TOTP.' });
  }
});

// =========================
// Bật TOTP
// =========================
router.post('/totp/enable', authenticateToken, async (req, res) => {
  const { secret, token } = req.body;

  if (!secret || !token) {
    return res.status(400).json({ error: 'Thiếu secret hoặc mã TOTP.' });
  }

  const isValid = verifyTotpToken(secret, token);
  if (!isValid) {
    return res.status(401).json({ error: 'Mã TOTP không chính xác.' });
  }

  try {
    const encryptedSecret = encryptSecret(secret);
    await db.execute(
      `INSERT INTO account_totp (account_id, secret_encrypted, enabled_at, last_verified_at)
       VALUES (?, ?, NOW(), NOW())
       ON DUPLICATE KEY UPDATE
         secret_encrypted = VALUES(secret_encrypted),
         enabled_at = NOW(),
         last_verified_at = NOW()`,
      [req.user.account_id, encryptedSecret]
    );

    res.json({ message: 'Đã bật xác thực hai lớp (TOTP).' });
  } catch (error) {
    console.error('Enable TOTP error:', error);
    res.status(500).json({ error: 'Không thể bật TOTP.' });
  }
});

// =========================
// Tắt TOTP
// =========================
router.post('/totp/disable', authenticateToken, async (req, res) => {
  const { token } = req.body;

  const totpRecord = await getTotpRecord(req.user.account_id);
  if (!totpRecord) {
    return res.status(404).json({ error: 'TOTP chưa được bật.' });
  }

  if (!token) {
    return res.status(400).json({ error: 'Vui lòng nhập mã TOTP.' });
  }

  const secret = decryptSecret(totpRecord.secret_encrypted);
  const isValid = verifyTotpToken(secret, token);
  if (!isValid) {
    return res.status(401).json({ error: 'Mã TOTP không chính xác.' });
  }

  try {
    await db.execute('DELETE FROM account_totp WHERE account_id = ?', [
      req.user.account_id,
    ]);
    res.json({ message: 'Đã tắt xác thực hai lớp.' });
  } catch (error) {
    console.error('Disable TOTP error:', error);
    res.status(500).json({ error: 'Không thể tắt TOTP.' });
  }
});

// =========================
// Xác thực TOTP (dùng khi đăng nhập)
// =========================
router.post('/totp/verify', authenticateToken, async (req, res) => {
  const { token } = req.body;

  if (!token) {
    return res.status(400).json({ error: 'Vui lòng nhập mã TOTP.' });
  }

  try {
    const totpRecord = await getTotpRecord(req.user.account_id);
    if (!totpRecord) {
      return res.status(404).json({ error: 'TOTP chưa được bật.' });
    }

    const secret = decryptSecret(totpRecord.secret_encrypted);
    const isValid = verifyTotpToken(secret, token);
    if (!isValid) {
      return res.status(401).json({ error: 'Mã TOTP không chính xác.' });
    }

    // Update last verified time
    await db.execute(
      'UPDATE account_totp SET last_verified_at = NOW() WHERE account_id = ?',
      [req.user.account_id]
    );

    res.json({ message: 'Xác thực TOTP thành công.' });
  } catch (error) {
    console.error('Verify TOTP error:', error);
    res.status(500).json({ error: 'Không thể xác thực TOTP.' });
  }
});

// =========================
// Lấy thông tin người dùng hiện tại
// =========================
router.get('/me', authenticateToken, (req, res) => {
  res.json({
    user: {
      id: req.user.id,
      email: req.user.email,
      full_name: req.user.full_name,
      code: req.user.code,
      role: req.user.role,
      phone: req.user.phone,
      phone_verified: !!req.user.is_phone_verified,
      totp_enabled: !!req.user.totp_enabled,
    },
  });
});

// =========================
// Kiểm tra trạng thái SMS
// =========================
router.post('/sms/check-report', async (req, res) => {
  const { transactionId } = req.body;

  if (!transactionId) {
    return res.status(400).json({ error: 'Thiếu transactionId.' });
  }

  try {
    const [[otpRequest]] = await db.execute(
      `SELECT sms_id FROM phone_otp_requests WHERE id = ?`,
      [transactionId]
    );

    if (!otpRequest || !otpRequest.sms_id) {
      return res.status(404).json({ error: 'Không tìm thấy SMSID.' });
    }

    const { getSmsSendReport } = require('../services/esmsService');
    const report = await getSmsSendReport(otpRequest.sms_id);

    if (!report) {
      return res.status(500).json({ error: 'Không thể lấy report từ eSMS.' });
    }

    res.json({
      smsId: otpRequest.sms_id,
      status: report.Status,
      errorCode: report.ErrorCode,
      errorMessage: report.ErrorMessage,
      receiveTime: report.ReceiveTime,
    });
  } catch (error) {
    console.error('Check SMS report error:', error);
    res.status(500).json({ error: 'Lỗi khi kiểm tra report SMS.' });
  }
});

// =========================
// Test: Kiểm tra report bằng SMSID trực tiếp
// =========================
router.post('/sms/check-report-by-smsid', async (req, res) => {
  const { smsId } = req.body;

  if (!smsId) {
    return res.status(400).json({ error: 'Thiếu smsId.' });
  }

  try {
    const { getSmsSendReport } = require('../services/esmsService');
    const report = await getSmsSendReport(smsId);

    if (!report) {
      return res.status(500).json({ error: 'Không thể lấy report từ eSMS.' });
    }

    res.json({
      smsId,
      status: report.Status,
      errorCode: report.ErrorCode,
      errorMessage: report.ErrorMessage,
      receiveTime: report.ReceiveTime,
    });
  } catch (error) {
    console.error('Check SMS report error:', error);
    res.status(500).json({ error: 'Lỗi khi kiểm tra report SMS.' });
  }
});

// =========================
// Đăng xuất
// =========================
router.post('/logout', authenticateToken, (_req, res) => {
  res.json({ message: 'Đăng xuất thành công.' });
});

module.exports = router;
