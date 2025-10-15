const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get all subjects
router.get('/', authenticateToken, async (req, res) => {
  try {
    const [subjects] = await db.execute(
      'SELECT * FROM subjects ORDER BY name'
    );
    res.json(subjects);
  } catch (error) {
    console.error('Get subjects error:', error);
    res.status(500).json({ error: 'Failed to fetch subjects' });
  }
});

// Create subject
router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { code, name, credits } = req.body;
    const id = uuidv4();
    
    await db.execute(
      'INSERT INTO subjects (id, code, name, credits) VALUES (?, ?, ?, ?)',
      [id, code, name, credits]
    );
    
    res.status(201).json({ message: 'Subject created successfully', id });
  } catch (error) {
    console.error('Create subject error:', error);
    res.status(500).json({ error: 'Failed to create subject' });
  }
});

// Update subject
router.put('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { code, name, credits } = req.body;
    
    await db.execute(
      'UPDATE subjects SET code = ?, name = ?, credits = ? WHERE id = ?',
      [code, name, credits, id]
    );
    
    res.json({ message: 'Subject updated successfully' });
  } catch (error) {
    console.error('Update subject error:', error);
    res.status(500).json({ error: 'Failed to update subject' });
  }
});

// Delete subject
router.delete('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    
    await db.execute('DELETE FROM subjects WHERE id = ?', [id]);
    
    res.json({ message: 'Subject deleted successfully' });
  } catch (error) {
    console.error('Delete subject error:', error);
    res.status(500).json({ error: 'Failed to delete subject' });
  }
});

module.exports = router;