const express = require('express');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get all teachers with filters
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { faculty_id, search } = req.query;
    
    let query = `
      SELECT 
        t.*,
        p.code, p.full_name, p.email, p.phone, p.is_active,
        f.name as faculty_name, f.code as faculty_code
      FROM teachers t
      JOIN profiles p ON t.profile_id = p.id
      LEFT JOIN faculties f ON t.faculty_id = f.id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (faculty_id) {
      query += ' AND t.faculty_id = ?';
      params.push(faculty_id);
    }
    
    if (search) {
      query += ' AND (p.full_name LIKE ? OR p.code LIKE ? OR p.email LIKE ?)';
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }
    
    query += ' ORDER BY p.full_name';
    
    const [teachers] = await db.execute(query, params);
    res.json(teachers);
  } catch (error) {
    console.error('Get teachers error:', error);
    res.status(500).json({ error: 'Failed to fetch teachers' });
  }
});

// Create teacher
router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const {
      code, full_name, email, phone, faculty_id, title, office,
      password = '123456'
    } = req.body;
    
    const profileId = uuidv4();
    const accountId = uuidv4();
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Create profile
    await connection.execute(
      `INSERT INTO profiles (id, code, full_name, email, phone, is_active) 
       VALUES (?, ?, ?, ?, ?, 1)`,
      [profileId, code, full_name, email, phone]
    );
    
    // Create account
    await connection.execute(
      `INSERT INTO accounts (id, profile_id, email, password_hash, is_active) 
       VALUES (?, ?, ?, ?, 1)`,
      [accountId, profileId, email, hashedPassword]
    );
    
    // Create user role
    await connection.execute(
      'INSERT INTO user_roles (user_id, role) VALUES (?, ?)',
      [profileId, 'teacher']
    );
    
    // Create teacher record
    await connection.execute(
      `INSERT INTO teachers (profile_id, faculty_id, title, office) 
       VALUES (?, ?, ?, ?)`,
      [profileId, faculty_id, title, office]
    );
    
    await connection.commit();
    res.status(201).json({ message: 'Teacher created successfully', id: profileId });
  } catch (error) {
    await connection.rollback();
    console.error('Create teacher error:', error);
    res.status(500).json({ error: 'Failed to create teacher' });
  } finally {
    connection.release();
  }
});

// Update teacher
router.put('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { id } = req.params;
    const { code, full_name, email, phone, faculty_id, title, office } = req.body;
    
    // Update profile
    await connection.execute(
      `UPDATE profiles 
       SET code = ?, full_name = ?, email = ?, phone = ? 
       WHERE id = ?`,
      [code, full_name, email, phone, id]
    );
    
    // Update account email
    await connection.execute(
      'UPDATE accounts SET email = ? WHERE profile_id = ?',
      [email, id]
    );
    
    // Update teacher record
    await connection.execute(
      `UPDATE teachers 
       SET faculty_id = ?, title = ?, office = ? 
       WHERE profile_id = ?`,
      [faculty_id, title, office, id]
    );
    
    await connection.commit();
    res.json({ message: 'Teacher updated successfully' });
  } catch (error) {
    await connection.rollback();
    console.error('Update teacher error:', error);
    res.status(500).json({ error: 'Failed to update teacher' });
  } finally {
    connection.release();
  }
});

// Delete teacher
router.delete('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { id } = req.params;
    
    // Delete in order due to foreign key constraints
    await connection.execute('DELETE FROM teachers WHERE profile_id = ?', [id]);
    await connection.execute('DELETE FROM user_roles WHERE user_id = ?', [id]);
    await connection.execute('DELETE FROM accounts WHERE profile_id = ?', [id]);
    await connection.execute('DELETE FROM profiles WHERE id = ?', [id]);
    
    await connection.commit();
    res.json({ message: 'Teacher deleted successfully' });
  } catch (error) {
    await connection.rollback();
    console.error('Delete teacher error:', error);
    res.status(500).json({ error: 'Failed to delete teacher' });
  } finally {
    connection.release();
  }
});

module.exports = router;