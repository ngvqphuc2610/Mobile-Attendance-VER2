
const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get all class sections with filters
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { class_id, search } = req.query;

    let query = `
      SELECT
        cs.*,
        sub.code AS subject_code,
        sub.name AS subject_name,
        sub.credits AS subject_credits
      FROM class_sections cs
      JOIN subjects sub ON cs.subject_id = sub.id
      WHERE 1 = 1
    `;
    const params = [];

    if (class_id) {
      query += ' AND cs.class_id = ?';
      params.push(class_id);
    }

    if (search) {
      query += ' AND (cs.section_code LIKE ? OR sub.code LIKE ? OR sub.name LIKE ?)';
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    query += ' ORDER BY cs.year DESC, cs.semester DESC, cs.section_code';

    const [rows] = await db.execute(query, params);
    res.json(rows);
  } catch (error) {
    console.error('Get class sections error:', error);
    res.status(500).json({ error: 'Failed to fetch class sections' });
  }
});

// Create a new class section
router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { subject_id, semester, year, section_code, capacity } = req.body;

    if (!subject_id || !semester || !year || !section_code) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const id = uuidv4();
    await db.execute(
      `INSERT INTO class_sections (id, subject_id, semester, year, section_code, capacity)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, subject_id, semester, year, section_code, capacity]
    );

    res.status(201).json({ message: 'Class section created successfully', id });
  } catch (error) {
    console.error('Create class section error:', error);
    res.status(500).json({ error: 'Failed to create class section' });
  }
});

// Update a class section
router.put('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { subject_id, semester, year, section_code, capacity } = req.body;

    if (!subject_id || !semester || !year || !section_code) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    await db.execute(
      `UPDATE class_sections
       SET subject_id = ?, semester = ?, year = ?, section_code = ?, capacity = ?
       WHERE id = ?`,
      [subject_id, semester, year, section_code, capacity, id]
    );

    res.json({ message: 'Class section updated successfully' });
  } catch (error) {
    console.error('Update class section error:', error);
    res.status(500).json({ error: 'Failed to update class section' });
  }
});

// Delete a class section
router.delete('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    await db.execute('DELETE FROM class_sections WHERE id = ?', [id]);
    res.json({ message: 'Class section deleted successfully' });
  } catch (error) {
    console.error('Delete class section error:', error);
    res.status(500).json({ error: 'Failed to delete class section' });
  }
});

module.exports = router;