const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get all profiles with filters
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { search } = req.query;   
    
    let query = `
      SELECT 
        p.*,
        ur.role
      FROM profiles p
      JOIN user_roles ur ON p.id = ur.user_id
      WHERE 1=1
    `;  
    const params = [];
    
    if (search) {
      query += ' AND (p.full_name LIKE ? OR p.code LIKE ?)';
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm);
    }
    
    query += ' ORDER BY p.full_name';
    
    const [profiles] = await db.execute(query, params);
    res.json(profiles);
  } catch (error) {
    console.error('Get profiles error:', error);
    res.status(500).json({ error: 'Failed to fetch profiles' });
  }
});

module.exports = router;