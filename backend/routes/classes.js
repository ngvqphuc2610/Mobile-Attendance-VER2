const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get all classes with filters
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { faculty_id } = req.query;
    
    let query = `
      SELECT 
        c.*,
        f.name as faculty_name, f.code as faculty_code,
        co.year as cohort_year
      FROM classes c
      LEFT JOIN faculties f ON c.faculty_id = f.id
      LEFT JOIN cohorts co ON c.cohort_id = co.id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (faculty_id) {
      query += ' AND c.faculty_id = ?';
      params.push(faculty_id);
    }
    
    query += ' ORDER BY c.name';
    
    const [classes] = await db.execute(query, params);
    res.json(classes);
  } catch (error) {
    console.error('Get classes error:', error);
    res.status(500).json({ error: 'Failed to fetch classes' });
  }
});

// Create class
router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { code, name, faculty_id, cohort_id } = req.body;
    const id = uuidv4();
    
    await db.execute(
      'INSERT INTO classes (id, code, name, faculty_id, cohort_id) VALUES (?, ?, ?, ?, ?)',
      [id, code, name, faculty_id, cohort_id]
    );
    
    res.status(201).json({ message: 'Class created successfully', id });
  } catch (error) {
    console.error('Create class error:', error);
    res.status(500).json({ error: 'Failed to create class' });
  }
});

// Update class
router.put('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { code, name, faculty_id, cohort_id } = req.body;
    
    await db.execute(
      'UPDATE classes SET code = ?, name = ?, faculty_id = ?, cohort_id = ? WHERE id = ?',
      [code, name, faculty_id, cohort_id, id]
    );
    
    res.json({ message: 'Class updated successfully' });
  } catch (error) {
    console.error('Update class error:', error);
    res.status(500).json({ error: 'Failed to update class' });
  }
});

// Delete class
router.delete('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    
    await db.execute('DELETE FROM classes WHERE id = ?', [id]);
    
    res.json({ message: 'Class deleted successfully' });
  } catch (error) {
    console.error('Delete class error:', error);
    res.status(500).json({ error: 'Failed to delete class' });
  }
});

module.exports = router;