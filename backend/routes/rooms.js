const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get all rooms
router.get('/', authenticateToken, async (req, res) => {
  try {
    const [rooms] = await db.execute(
      'SELECT * FROM rooms ORDER BY name'
    );
    res.json(rooms);
  } catch (error) {
    console.error('Get rooms error:', error);
    res.status(500).json({ error: 'Failed to fetch rooms' });
  }
});

// Create room
router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { code, name, capacity, location } = req.body;
    const id = uuidv4();
    
    await db.execute(
      'INSERT INTO rooms (id, code, name, capacity, location) VALUES (?, ?, ?, ?, ?)',
      [id, code, name, capacity, location]
    );
    
    res.status(201).json({ message: 'Room created successfully', id });
  } catch (error) {
    console.error('Create room error:', error);
    res.status(500).json({ error: 'Failed to create room' });
  }
});

// Update room
router.put('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { code, name, capacity, location } = req.body;
    
    await db.execute(
      'UPDATE rooms SET code = ?, name = ?, capacity = ?, location = ? WHERE id = ?',
      [code, name, capacity, location, id]
    );
    
    res.json({ message: 'Room updated successfully' });
  } catch (error) {
    console.error('Update room error:', error);
    res.status(500).json({ error: 'Failed to update room' });
  }
});

// Delete room
router.delete('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    
    await db.execute('DELETE FROM rooms WHERE id = ?', [id]);
    
    res.json({ message: 'Room deleted successfully' });
  } catch (error) {
    console.error('Delete room error:', error);
    res.status(500).json({ error: 'Failed to delete room' });
  }
});

module.exports = router;