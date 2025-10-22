const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

router.get('/', authenticateToken, async (req, res) => {
  try {
    const { section_id, status } = req.query;

    let query = `
      SELECT
        si.*,
        cs.section_code,
        cs.year,
        cs.semester,
        sub.code AS subject_code,
        sub.name AS subject_name,
        r.code AS room_code,
        r.name AS room_name
      FROM session_instances si
      JOIN class_sections cs ON si.section_id = cs.id
      LEFT JOIN subjects sub ON cs.subject_id = sub.id
      LEFT JOIN rooms r ON si.room_id = r.id
      WHERE 1 = 1
    `;

    const params = [];

    if (section_id) {
      query += ' AND si.section_id = ?';
      params.push(section_id);
    }

    if (status) {
      query += ' AND si.status = ?';
      params.push(status);
    }

    query += ' ORDER BY si.starts_at DESC';

    const [rows] = await db.execute(query, params);
    res.json(rows);
  } catch (error) {
    console.error('Get session instances error:', error);
    res.status(500).json({ error: 'Failed to fetch session instances' });
  }
});

router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await db.execute(
      `
      SELECT
        si.*,
        cs.section_code,
        cs.year,
        cs.semester,
        sub.code AS subject_code,
        sub.name AS subject_name,
        r.code AS room_code,
        r.name AS room_name
      FROM session_instances si
      JOIN class_sections cs ON si.section_id = cs.id
      LEFT JOIN subjects sub ON cs.subject_id = sub.id
      LEFT JOIN rooms r ON si.room_id = r.id
      WHERE si.id = ?
      LIMIT 1
      `,
      [id]
    );

    if (!rows || rows.length === 0) {
      return res.status(404).json({ error: 'Session instance not found' });
    }
    res.json(rows[0]);
  } catch (error) {
    console.error('Get session instance by id error:', error);
    res.status(500).json({ error: 'Failed to fetch session instance by id' });
  }
});


router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const {
      section_id,
      starts_at,
      ends_at,
      status = 'planned',
      room_id = null,
    } = req.body;

    if (!section_id || !starts_at || !ends_at) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const id = uuidv4();
    await db.execute(
      `INSERT INTO session_instances (id, section_id, starts_at, ends_at, status, room_id)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, section_id, starts_at, ends_at, status, room_id]
    );

    res.status(201).json({ message: 'Session instance created successfully', id });
  } catch (error) {
    console.error('Create session instance error:', error);
    res.status(500).json({ error: 'Failed to create session instance' });
  }
});

router.put('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const {
      section_id,
      starts_at,
      ends_at,
      status = 'planned',
      room_id = null,
    } = req.body;

    if (!section_id || !starts_at || !ends_at) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    await db.execute(
      `UPDATE session_instances
       SET section_id = ?, starts_at = ?, ends_at = ?, status = ?, room_id = ?
       WHERE id = ?`,
      [section_id, starts_at, ends_at, status, room_id, id]
    );

    res.json({ message: 'Session instance updated successfully' });
  } catch (error) {
    console.error('Update session instance error:', error);
    res.status(500).json({ error: 'Failed to update session instance' });
  }
});

router.delete('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    await db.execute('DELETE FROM session_instances WHERE id = ?', [id]);
    res.json({ message: 'Session instance deleted successfully' });
  } catch (error) {
    console.error('Delete session instance error:', error);
    res.status(500).json({ error: 'Failed to delete session instance' });
  }
});

module.exports = router;
