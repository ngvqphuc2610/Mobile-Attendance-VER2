const express = require('express');
const db = require('../config/database'); // mysql2/promise pool
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// ----------------- Helpers -----------------

/** Đóng token hết hạn ngay lập tức */
async function closeExpiredTokensNow() {
  await db.execute(`
    UPDATE session_checkin_tokens
    SET is_active = 0
    WHERE is_active = 1
      AND expires_at <= NOW()
  `);
}

/** Tìm token PIN còn hiệu lực */
async function getTokenByPin(pin4) {
  const [rows] = await db.execute(
    `
      SELECT id, session_id
      FROM session_checkin_tokens
      WHERE pin_4 = ?
        AND is_active = 1
        AND expires_at > NOW()
      LIMIT 1
    `,
    [pin4]
  );
  return rows[0] || null;
}

/** Tìm token QR còn hiệu lực */
async function getQrToken({ tokenId, sessionId, nonce }) {
  const [rows] = await db.execute(
    `
      SELECT id
      FROM session_checkin_tokens
      WHERE id = ?
        AND session_id = ?
        AND nonce = ?
        AND is_active = 1
        AND expires_at > NOW()
      LIMIT 1
    `,
    [tokenId, sessionId, nonce]
  );
  return rows[0] || null;
}

/** Lấy thông tin session */
async function getSessionInfo(sessionId) {
  const [rows] = await db.execute(
    `
      SELECT id, section_id, starts_at, ends_at
      FROM session_instances
      WHERE id = ?
      LIMIT 1
    `,
    [sessionId]
  );
  return rows[0] || null;
}

/** Kiểm tra sinh viên có đăng ký section hay không */
async function studentEnrolled(studentId, sectionId) {
  const [rows] = await db.execute(
    `
      SELECT 1
      FROM enrollments
      WHERE student_id = ? AND section_id = ?
      LIMIT 1
    `,
    [studentId, sectionId]
  );
  return rows.length > 0;
}

/** Ghi (hoặc cập nhật) bản ghi attendance */
async function upsertAttendance({
  studentId,
  sectionId,
  sessionId,
  method,
  latitude,
  longitude,
  accuracy,
  address,
}) {
  await db.execute(
    `
      INSERT INTO attendance
        (user_id,section_id, session_id, method, latitude, longitude, accuracy_m, address, at_time)
      VALUES
        (?,?, ?, ?, ?, ?, ?, ?, NOW())
      ON DUPLICATE KEY UPDATE
        at_time = VALUES(at_time),
        method = VALUES(method),
        latitude = VALUES(latitude),
        longitude = VALUES(longitude),
        accuracy_m = VALUES(accuracy_m),
        address = VALUES(address)
    `,
    [studentId,sectionId, sessionId, method, latitude, longitude, accuracy, address]
  );
}

// ----------------- API: Check-in bằng PIN -----------------
/**
 * POST /checkin/pin
 * Body: { student_id, pin_4, latitude?, longitude?, accuracy_m?, address? }
 */
router.post('/pin', authenticateToken, async (req, res) => {
  try {
    const { student_id, pin_4, latitude, longitude, accuracy_m, address } = req.body || {};

    if (!student_id || !pin_4 || String(pin_4).length !== 4) {
      return res.status(400).json({ error: 'Thiếu student_id hoặc pin_4 không hợp lệ' });
    }

    // 1️⃣ Đóng token hết hạn
    await closeExpiredTokensNow();

    // 2️⃣ Tìm token hợp lệ
    const token = await getTokenByPin(pin_4);
    if (!token) return res.status(400).json({ error: 'Mã PIN không hợp lệ hoặc đã hết hạn' });

    // 3️⃣ Kiểm tra buổi học và enrollment
    const session = await getSessionInfo(token.session_id);
    if (!session) return res.status(404).json({ error: 'Không tìm thấy buổi học' });

    const ok = await studentEnrolled(student_id, session.section_id);
    if (!ok) return res.status(403).json({ error: 'Sinh viên không thuộc lớp học (section) này' });

    // 4️⃣ Ghi attendance
    await upsertAttendance({
      studentId: student_id,
      sectionId: session.section_id,
      sessionId: session.id,
      method: 'pin',
      latitude,
      longitude,
      accuracy: accuracy_m,
      address,
    });

    return res.status(201).json({
      message: 'Điểm danh bằng PIN thành công',
      session_id: session.id,
      token_id: token.id,
    });
  } catch (err) {
    console.error('POST /checkin/pin error:', err);
    return res.status(500).json({ error: 'Lỗi server khi điểm danh bằng PIN' });
  }
});

// ----------------- API: Check-in bằng QR -----------------
/**
 * POST /checkin/qr
 * Body: { student_id, session_id, token_id, nonce, latitude?, longitude?, accuracy_m?, address? }
 */
router.post('/qr', authenticateToken, async (req, res) => {
  try {
    const { student_id, session_id, token_id, nonce, latitude, longitude, accuracy_m, address } =
      req.body || {};

    if (!student_id || !session_id || !token_id || !nonce) {
      return res.status(400).json({ error: 'Thiếu dữ liệu bắt buộc' });
    }

    // 1️⃣ Đóng token hết hạn
    await closeExpiredTokensNow();

    // 2️⃣ Kiểm tra token hợp lệ
    const token = await getQrToken({ tokenId: token_id, sessionId: session_id, nonce });
    if (!token) return res.status(400).json({ error: 'Mã QR không hợp lệ hoặc đã hết hạn' });

    // 3️⃣ Kiểm tra buổi học + enrollment
    const session = await getSessionInfo(session_id);
    if (!session) return res.status(404).json({ error: 'Không tìm thấy buổi học' });

    const ok = await studentEnrolled(student_id, session.section_id);
    if (!ok) return res.status(403).json({ error: 'Sinh viên không thuộc lớp học (section) này' });

    // 4️⃣ Ghi attendance
    await upsertAttendance({
      studentId: student_id,
      sectionId: session.section_id,
      sessionId: session_id,
      method: 'qr',
      latitude,
      longitude,
      accuracy: accuracy_m,
      address,
    });

    return res.status(201).json({ message: 'Điểm danh bằng QR thành công' });
  } catch (err) {
    console.error('POST /checkin/qr error:', err);
    return res.status(500).json({ error: 'Lỗi server khi điểm danh bằng QR' });
  }
});

module.exports = router;
