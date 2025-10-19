const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

router.get('/', authenticateToken, async (req, res) => {
  try {
    const { section_id } = req.query;

    let query = `
      SELECT
        ss.*,
        cs.section_code,
        cs.year,
        cs.semester,
        sub.code AS subject_code,
        sub.name AS subject_name,
        r.code AS room_code,
        r.name AS room_name
      FROM section_schedules ss
      JOIN class_sections cs ON ss.section_id = cs.id
      LEFT JOIN subjects sub ON cs.subject_id = sub.id
      LEFT JOIN rooms r ON ss.room_id = r.id
      WHERE 1 = 1
    `;
    const params = [];

    if (section_id) {
      query += ' AND ss.section_id = ?';
      params.push(section_id);
    }

    query += `
      ORDER BY
        cs.year DESC,
        cs.semester DESC,
        sub.name,
        ss.day_of_week,
        ss.start_time
    `;

    const [rows] = await db.execute(query, params);
    res.json(rows);
  } catch (error) {
    console.error('Get section schedules error:', error);
    res.status(500).json({ error: 'Failed to fetch section schedules' });
  }
});

router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const {
      section_id,
      day_of_week,
      start_time,
      end_time,
      room_id = null,
    } = req.body;

    if (!section_id || !day_of_week || !start_time || !end_time) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const id = uuidv4();
    await db.execute(
      `INSERT INTO section_schedules (id, section_id, day_of_week, start_time, end_time, room_id)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, section_id, day_of_week, start_time, end_time, room_id]
    );

    res.status(201).json({ message: 'Section schedule created successfully', id });
  } catch (error) {
    console.error('Create section schedule error:', error);
    res.status(500).json({ error: 'Failed to create section schedule' });
  }
});

router.put('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const {
      section_id,
      day_of_week,
      start_time,
      end_time,
      room_id = null,
    } = req.body;

    if (!section_id || !day_of_week || !start_time || !end_time) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    await db.execute(
      `UPDATE section_schedules
       SET section_id = ?, day_of_week = ?, start_time = ?, end_time = ?, room_id = ?
       WHERE id = ?`,
      [section_id, day_of_week, start_time, end_time, room_id, id]
    );

    res.json({ message: 'Section schedule updated successfully' });
  } catch (error) {
    console.error('Update section schedule error:', error);
    res.status(500).json({ error: 'Failed to update section schedule' });
  }
});

router.delete('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    await db.execute('DELETE FROM section_schedules WHERE id = ?', [id]);
    res.json({ message: 'Section schedule deleted successfully' });
  } catch (error) {
    console.error('Delete section schedule error:', error);
    res.status(500).json({ error: 'Failed to delete section schedule' });
  }
});

module.exports = router;
