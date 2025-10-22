const express = require('express');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

/**
 * GET /attendance
 * Lọc theo: user_id, from_date, to_date, method, section_id, session_id
 * Sắp xếp mới nhất trước
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { user_id, from_date, to_date, method, section_id, session_id, limit, offset } = req.query;

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
    if (section_id) {
      query += ' AND a.section_id = ?';
      params.push(section_id);
    }
    if (session_id) {
      query += ' AND a.session_id = ?';
      params.push(session_id);
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

    // Phân trang nhẹ (tùy chọn)
    const lim = Number.isFinite(parseInt(limit, 10)) ? Math.max(parseInt(limit, 10), 1) : null;
    const off = Number.isFinite(parseInt(offset, 10)) ? Math.max(parseInt(offset, 10), 0) : null;
    if (lim !== null) {
      query += ' LIMIT ?';
      params.push(lim);
      if (off !== null) {
        query += ' OFFSET ?';
        params.push(off);
      }
    }

    const [rows] = await db.execute(query, params);
    res.json(rows);
  } catch (error) {
    console.error('Get attendance error:', error);
    res.status(500).json({ error: 'Failed to fetch attendance' });
  }
});

/**
 * POST /attendance
 * Ghi nhận điểm danh.
 * - Nếu body có `at_time` (ISO hoặc 'YYYY-MM-DD HH:mm:ss'), dùng giá trị đó.
 * - Nếu không có, mặc định NOW().
 * - Nếu không truyền user_id, dùng id từ token.
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    const {
      user_id,
      method,
      confidence_score,
      note,
      at_time,           // tùy chọn
      section_id,
      session_id,
      latitude,
      longitude,
      accuracy_m,
      address
    } = req.body;

    const uid = user_id || req.user?.id;
    if (!uid) {
      return res.status(400).json({ error: 'Missing user_id (and token has no id)' });
    }

    // Chuẩn hóa kiểu số (nếu có)
    const conf = (confidence_score !== undefined && confidence_score !== null)
      ? Number(confidence_score) : null;
    const lat = (latitude !== undefined && latitude !== null) ? Number(latitude) : null;
    const lon = (longitude !== undefined && longitude !== null) ? Number(longitude) : null;
    const acc = (accuracy_m !== undefined && accuracy_m !== null) ? Number(accuracy_m) : null;

    // Chuẩn hóa method
    const methodVal = method || 'manual';

    let sql;
    let params;

    if (at_time) {
      // Dùng at_time do client gửi
      sql = `
        INSERT INTO attendance
          (user_id, method, confidence_score, note, at_time, section_id, session_id, latitude, longitude, accuracy_m, address)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      params = [
        uid,
        methodVal,
        conf,
        note ?? null,
        at_time,                  // giá trị client
        section_id ?? null,
        session_id ?? null,
        lat,
        lon,
        acc,
        address ?? null
      ];
    } else {
      // Dùng NOW()
      sql = `
        INSERT INTO attendance
          (user_id, method, confidence_score, note, at_time, section_id, session_id, latitude, longitude, accuracy_m, address)
        VALUES (?, ?, ?, ?, NOW(), ?, ?, ?, ?, ?, ?)
      `;
      params = [
        uid,
        methodVal,
        conf,
        note ?? null,
        section_id ?? null,
        session_id ?? null,
        lat,
        lon,
        acc,
        address ?? null
      ];
    }

    const [result] = await db.execute(sql, params);
    res.status(201).json({
      message: 'Attendance recorded successfully',
      id: result?.insertId
    });
  } catch (error) {
    console.error('Create attendance error:', error);
    res.status(500).json({ error: 'Failed to record attendance' });
  }
});

/**
 * GET /attendance/stats
 * Gọi stored procedure: CALL get_attendance_stats(from_date, to_date)
 */
router.get('/stats', authenticateToken, async (req, res) => {
  try {
    const { from_date, to_date } = req.query;
    const [resultSets] = await db.execute(
      'CALL get_attendance_stats(?, ?)',
      [from_date || null, to_date || null]
    );
    // Với mysql2, resultSets[0] là result set đầu tiên
    res.json(resultSets?.[0] ?? []);
  } catch (error) {
    console.error('Get attendance stats error:', error);
    res.status(500).json({ error: 'Failed to fetch attendance statistics' });
  }
});

/**
 * DELETE /attendance/:id
 * Chỉ admin hoặc teacher được xóa
 */
router.delete('/:id', authenticateToken, requireRole(['admin', 'teacher']), async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await db.execute('DELETE FROM attendance WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Attendance not found' });
    }
    res.json({ message: 'Attendance deleted successfully' });
  } catch (error) {
    console.error('Delete attendance error:', error);
    res.status(500).json({ error: 'Failed to delete attendance' });
  }
});

module.exports = router;
