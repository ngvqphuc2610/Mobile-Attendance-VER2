const express = require('express');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get attendance records
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

// Create attendance record
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { user_id, method, confidence_score, note } = req.body;
    
    await db.execute(
      `INSERT INTO attendance (user_id, method, confidence_score, note) 
       VALUES (?, ?, ?, ?)`,
      [user_id, method, confidence_score, note]
    );
    
    res.status(201).json({ message: 'Attendance recorded successfully' });
  } catch (error) {
    console.error('Create attendance error:', error);
    res.status(500).json({ error: 'Failed to record attendance' });
  }
});

// Get attendance statistics
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