const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Lấy danh sách attendance
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { user_id, from_date, to_date, method } = req.query;

    let query = `
      SELECT 
        a.*,
        p.full_name, p.code
      FROM attendance a
      JOIN profiles p ON a.user_id = p.id
      WHERE 1=1
    `;

    const params = [];

    if (user_id) {
      query += ' AND a.user_id = ?';
      params.push(user_id);
    }

    if (from_date) {
      query += ' AND a.at_time >= ?';
      params.push(from_date);
    }

    if (to_date) {
      query += ' AND a.at_time <= ?';
      params.push(to_date);
    }

    if (method) {
      query += ' AND a.method = ?';
      params.push(method);
    }

    query += ' ORDER BY a.at_time DESC';

    const [attendance] = await db.execute(query, params);
    res.json(attendance);
  } catch (error) {
    console.error('Get attendance error:', error);
    res.status(500).json({ error: 'Failed to fetch attendance' });
  }
});

// ✅ Ghi nhận điểm danh (có vị trí)
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { user_id, method, confidence_score, note,
            latitude, longitude, accuracy_m, address } = req.body;

    // Nếu không gửi user_id từ client, mặc định lấy từ token
    const uid = user_id || req.user?.id;

    await db.execute(
      `INSERT INTO attendance 
        (user_id, method, confidence_score, note, at_time, latitude, longitude, accuracy_m, address)
       VALUES (?, ?, ?, ?, NOW(), ?, ?, ?, ?)`,
      [uid, method || 'manual', confidence_score || null, note || null,
       latitude || null, longitude || null, accuracy_m || null, address || null]
    );

    res.status(201).json({ message: 'Attendance recorded successfully' });
  } catch (error) {
    console.error('Create attendance error:', error);
    res.status(500).json({ error: 'Failed to record attendance' });
  }
});

// Thống kê điểm danh
router.get('/stats', authenticateToken, async (req, res) => {
  try {
    const { from_date, to_date } = req.query;
    const [stats] = await db.execute(
      'CALL get_attendance_stats(?, ?)',
      [from_date || null, to_date || null]
    );
    res.json(stats[0]);
  } catch (error) {
    console.error('Get attendance stats error:', error);
    res.status(500).json({ error: 'Failed to fetch attendance statistics' });
  }
});

module.exports = router;
