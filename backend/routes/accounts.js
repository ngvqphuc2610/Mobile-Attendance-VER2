const express = require('express');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get all accounts with filters
router.get('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { role, search } = req.query;
    
    let query = `
      SELECT 
        a.id, a.email, a.is_active, a.is_email_verified, a.last_login_at, a.created_at,
        p.id as profile_id, p.code, p.full_name, p.phone,
        ur.role
      FROM accounts a
      JOIN profiles p ON a.profile_id = p.id
      JOIN user_roles ur ON p.id = ur.user_id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (role) {
      query += ' AND ur.role = ?';
      params.push(role);
    }
    
    if (search) {
      query += ' AND (p.full_name LIKE ? OR p.code LIKE ? OR a.email LIKE ?)';
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }
    
    query += ' ORDER BY p.full_name';
    
    let [accounts] = await db.execute(query, params);
    accounts = accounts.map((row) => ({
      ...row,
      is_active: !!row.is_active,
      is_email_verified: !!row.is_email_verified,
    }));
    res.json(accounts);
  } catch (error) {
    console.error('Get accounts error:', error);
    res.status(500).json({ error: 'Failed to fetch accounts' });
  }
});

// Create account
router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const {
      email, password, full_name, code, role, phone,
      // Student specific
      class_id, mssv,
      // Teacher specific
      faculty_id, title, office
    } = req.body;
    
    const profileId = uuidv4();
    const accountId = uuidv4();
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Create profile
    await connection.execute(
      `INSERT INTO profiles (id, code, full_name, email, phone, class_id, is_active) 
       VALUES (?, ?, ?, ?, ?, ?, 1)`,
      [profileId, code, full_name, email, phone, class_id]
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
      [profileId, role]
    );
    
    // Create role-specific record
    if (role === 'student') {
      // Parse MSSV info
      let mssvInfo = null;
      if (mssv && mssv.length === 10) {
        const cohort = 2000 + parseInt(mssv.substring(0, 2));
        const trackCode = mssv.substring(2, 6);
        const serial = parseInt(mssv.substring(6, 10));
        mssvInfo = { cohort, trackCode, serial };
      }
      
      await connection.execute(
        `INSERT INTO students (profile_id, class_id, mssv, mssv_cohort, mssv_track_code, mssv_serial) 
         VALUES (?, ?, ?, ?, ?, ?)`,
        [profileId, class_id, mssv, mssvInfo?.cohort, mssvInfo?.trackCode, mssvInfo?.serial]
      );
    } else if (role === 'teacher') {
      await connection.execute(
        `INSERT INTO teachers (profile_id, faculty_id, title, office) 
         VALUES (?, ?, ?, ?)`,
        [profileId, faculty_id, title, office]
      );
    }
    
    await connection.commit();
    res.status(201).json({ message: 'Account created successfully', id: profileId });
  } catch (error) {
    await connection.rollback();
    console.error('Create account error:', error);
    res.status(500).json({ error: 'Failed to create account' });
  } finally {
    connection.release();
  }
});

// Toggle account status
router.patch('/:id/toggle', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    
    const [result] = await db.execute(
      'UPDATE accounts SET is_active = NOT is_active WHERE profile_id = ?',
      [id]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Account not found' });
    }

    const [[updatedAccount]] = await db.execute(
      'SELECT is_active FROM accounts WHERE profile_id = ?',
      [id]
    );

    res.json({
      message: 'Account status updated successfully',
      is_active: !!updatedAccount?.is_active,
    });
  } catch (error) {
    console.error('Toggle account error:', error);
    res.status(500).json({ error: 'Failed to update account status' });
  }
});

// Reset password
router.patch('/:id/reset-password', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { id } = req.params;
    const { password = '123456' } = req.body;
    
    const hashedPassword = await bcrypt.hash(password, 10);
    
    await db.execute(
      'UPDATE accounts SET password_hash = ? WHERE profile_id = ?',
      [hashedPassword, id]
    );
    
    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ error: 'Failed to reset password' });
  }
});

// Delete account
router.delete('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  const connection = await db.getConnection();
  
  try {
    await connection.beginTransaction();
    
    const { id } = req.params;
    
    // Get role to determine which table to clean up
    const [roles] = await connection.execute(
      'SELECT role FROM user_roles WHERE user_id = ?',
      [id]
    );
    
    if (roles.length > 0) {
      const role = roles[0].role;
      
      // Delete role-specific records
      if (role === 'student') {
        await connection.execute('DELETE FROM students WHERE profile_id = ?', [id]);
      } else if (role === 'teacher') {
        await connection.execute('DELETE FROM teachers WHERE profile_id = ?', [id]);
      }
    }
    
    // Delete in order due to foreign key constraints
    await connection.execute('DELETE FROM user_roles WHERE user_id = ?', [id]);
    await connection.execute('DELETE FROM accounts WHERE profile_id = ?', [id]);
    await connection.execute('DELETE FROM profiles WHERE id = ?', [id]);
    
    await connection.commit();
    res.json({ message: 'Account deleted successfully' });
  } catch (error) {
    await connection.rollback();
    console.error('Delete account error:', error);
    res.status(500).json({ error: 'Failed to delete account' });
  } finally {
    connection.release();
  }
});

module.exports = router;
