const express = require('express');
const crypto = require('crypto');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

/** Helpers */
function genPin4() {
  // 4 số
  const n = Math.floor(Math.random() * 10000);
  return n.toString().padStart(4, '0');
}
function genNonce(len = 16) {
  return crypto.randomBytes(len).toString('hex').slice(0, len);
}

// List tokens (cho GV xem token của buổi mình)
router.get('/', authenticateToken, requireRole('teacher','admin'), async (req, res) => {
  try {
    const { session_id } = req.query;
    const params = [];
    let sql = `
      SELECT sct.*
      FROM session_checkin_tokens sct
      JOIN session_instances si ON si.id = sct.session_id
      JOIN teaching_assignments ta ON ta.section_id = si.section_id
      WHERE ta.teacher_id = ?`;
    params.push(req.user.id);

    if (session_id) { sql += ' AND sct.session_id = ?'; params.push(session_id); }
    sql += ' ORDER BY sct.created_at DESC';

    const [rows] = await db.execute(sql, params);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch session checkin tokens' });
  }
});

/**
 * OPEN check-in: đóng token cũ + tạo token mới (transaction)
 * body: { session_id, duration_seconds?: 180 }
 */
router.post('/open', authenticateToken, requireRole('teacher','admin'), async (req, res) => {
  const conn = await db.getConnection();
  try {
    const { session_id, duration_seconds = 180 } = req.body;
    if (!session_id) return res.status(400).json({ error: 'session_id is required' });

    // Kiểm tra quyền GV với session
    const [chk] = await conn.execute(
      `SELECT si.id
       FROM session_instances si
       JOIN teaching_assignments ta ON ta.section_id = si.section_id
       WHERE si.id = ? AND ta.teacher_id = ?`,
      [session_id, req.user.id]
    );
    if (chk.length === 0) return res.status(403).json({ error: 'Forbidden: not your session' });

    await conn.beginTransaction();

    // đóng các token cũ còn active
    await conn.execute(
      `UPDATE session_checkin_tokens
       SET is_active = 0
       WHERE session_id = ? AND is_active = 1`,
      [session_id]
    );

    // tạo token mới (server gen pin + nonce)
    const pin4 = genPin4();
    const nonce = genNonce(16);
    const [ins] = await conn.execute(
      `INSERT INTO session_checkin_tokens
         (id, session_id, pin_4, nonce, expires_at, is_active, created_by)
       VALUES (UUID(), ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND), 1, ?)`,
      [session_id, pin4, nonce, duration_seconds, req.user.id]
    );

    // trả lại token vừa tạo
    const [tok] = await conn.execute(
      `SELECT * FROM session_checkin_tokens
       WHERE session_id = ? AND is_active = 1
       ORDER BY created_at DESC LIMIT 1`,
      [session_id]
    );

    await conn.commit();
    res.status(201).json({
      message: 'Check-in opened',
      token: tok[0]   // có pin_4, nonce, expires_at; chỉ GV xem màn hình này
    });
  } catch (err) {
    await conn.rollback();
    console.error('Open check-in error:', err);
    res.status(500).json({ error: 'Failed to open check-in' });
  } finally {
    conn.release();
  }
});

/** CLOSE check-in: set is_active=0 for current tokens of session */
router.post('/close', authenticateToken, requireRole('teacher','admin'), async (req, res) => {
  try {
    const { session_id } = req.body;
    if (!session_id) return res.status(400).json({ error: 'session_id is required' });

    const [chk] = await db.execute(
      `SELECT si.id
       FROM session_instances si
       JOIN teaching_assignments ta ON ta.section_id = si.section_id
       WHERE si.id = ? AND ta.teacher_id = ?`,
      [session_id, req.user.id]
    );
    if (chk.length === 0) return res.status(403).json({ error: 'Forbidden: not your session' });

    const [r] = await db.execute(
      `UPDATE session_checkin_tokens
       SET is_active = 0
       WHERE session_id = ? AND is_active = 1`,
      [session_id]
    );
    res.json({ message: 'Check-in closed', affected: r.affectedRows });
  } catch (err) {
    console.error('Close check-in error:', err);
    res.status(500).json({ error: 'Failed to close check-in' });
  }
});

/** (Tuỳ chọn) Extend thời gian hiệu lực token hiện tại */
router.post('/extend', authenticateToken, requireRole('teacher','admin'), async (req, res) => {
  try {
    const { session_id, add_seconds = 120 } = req.body;
    if (!session_id) return res.status(400).json({ error: 'session_id is required' });

    // xác thực quyền như trên
    const [chk] = await db.execute(
      `SELECT si.id
       FROM session_instances si
       JOIN teaching_assignments ta ON ta.section_id = si.section_id
       WHERE si.id = ? AND ta.teacher_id = ?`,
      [session_id, req.user.id]
    );
    if (chk.length === 0) return res.status(403).json({ error: 'Forbidden' });

    const [r] = await db.execute(
      `UPDATE session_checkin_tokens
       SET expires_at = DATE_ADD(expires_at, INTERVAL ? SECOND)
       WHERE session_id = ? AND is_active = 1`,
      [add_seconds, session_id]
    );
    res.json({ message: 'Extended', affected: r.affectedRows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to extend token' });
  }
});

module.exports = router;
