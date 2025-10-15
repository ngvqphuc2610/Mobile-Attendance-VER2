const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get all faculties
router.get('/', authenticateToken, async (req, res) => {
  try {
    const [faculties] = await db.execute(
      'SELECT * FROM faculties ORDER BY name'
    );
    res.json(faculties);
  } catch (error) {
    console.error('Get faculties error:', error);
    res.status(500).json({ error: 'Failed to fetch faculties' });
  }
});

// Create faculty
router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { code, name } = req.body;
    const id = uuidv4();
    
    await db.execute(
      'INSERT INTO faculties (id, code, name) VALUES (?, ?, ?)',
      [id, code, name]
    );
    
    res.status(201).json({ message: 'Faculty created successfully', id });
  } catch (error) {
    console.error('Create faculty error:', error);
    res.status(500).json({ error: 'Failed to create faculty' });
  }
});

// Update faculty
router.put('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { code, name } = req.body;
    
    await db.execute(
      'UPDATE faculties SET code = ?, name = ? WHERE id = ?',
      [code, name, id]
    );
    
    res.json({ message: 'Faculty updated successfully' });
  } catch (error) {
    console.error('Update faculty error:', error);
    res.status(500).json({ error: 'Failed to update faculty' });
  }
});

// Delete faculty
router.delete('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    
    await db.execute('DELETE FROM faculties WHERE id = ?', [id]);
    
    res.json({ message: 'Faculty deleted successfully' });
  } catch (error) {
    console.error('Delete faculty error:', error);
    res.status(500).json({ error: 'Failed to delete faculty' });
  }
});

module.exports = router;