const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get face embeddings
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { user_id } = req.query;
    
    let query = 'SELECT * FROM face_embeddings WHERE 1=1';
    const params = [];
    
    if (user_id) {
      query += ' AND user_id = ?';
      params.push(user_id);
    }
    
    const [embeddings] = await db.execute(query, params);
    res.json(embeddings);
  } catch (error) {
    console.error('Get face embeddings error:', error);
    res.status(500).json({ error: 'Failed to fetch face embeddings' });
  }
});

// Create or update face embeddings
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { user_id, vectors } = req.body;  
    
    await db.execute(
      'INSERT INTO face_embeddings (user_id, vectors) VALUES (?, ?) ON CONFLICT (user_id) DO UPDATE SET vectors = ?',
      [user_id, vectors, vectors]
    );
    
    res.status(201).json({ message: 'Face embeddings created/updated successfully' });
  } catch (error) {
    console.error('Create/update face embeddings error:', error);
    res.status(500).json({ error: 'Failed to create/update face embeddings' });
  }
});

module.exports = router;