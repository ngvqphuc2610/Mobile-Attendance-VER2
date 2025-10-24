const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    // Get user with role
    const [users] = await db.execute(
      `SELECT a.*, p.*, ur.role 
       FROM accounts a 
       JOIN profiles p ON a.profile_id = p.id 
       JOIN user_roles ur ON p.id = ur.user_id 
       WHERE a.email = ? AND a.is_active = 1 AND p.is_active = 1`,
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = users[0];
    const isValidPassword = await bcrypt.compare(password, user.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Update last login
    await db.execute(
      'UPDATE accounts SET last_login_at = NOW() WHERE id = ?',
      [user.id]
    );

    // Generate JWT
    const token = jwt.sign(
      { userId: user.profile_id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: user.profile_id,
        email: user.email,
        full_name: user.full_name,
        code: user.code,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Register
router.post('/register', async (req, res) => {
  try {
    const {
      full_name, email, password, code, role, phone
    } = req.body;

    if (!full_name || !email || !password) {
      return res.status(400).json({ error: 'Full name, email, and password required' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const profileId = uuidv4();
    const accountId = uuidv4();

    await db.execute(
      `INSERT INTO profiles (id, code, full_name, email, phone, is_active) 
       VALUES (?, ?, ?, ?, ?, 1)`,
      [profileId, code, full_name, email, phone]
    );

    await db.execute(
      `INSERT INTO accounts (id, profile_id, email, password_hash, is_active) 
       VALUES (?, ?, ?, ?, 1)`,
      [accountId, profileId, email, hashedPassword]
    );

    await db.execute(
      'INSERT INTO user_roles (user_id, role) VALUES (?, ?)',
      [profileId, role]
    );

    res.status(201).json({ message: 'Account created successfully' });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// Get current user
router.get('/me', authenticateToken, (req, res) => {
  res.json({
    user: {
      id: req.user.id,
      email: req.user.email,
      full_name: req.user.full_name,
      code: req.user.code,
      role: req.user.role
    }
  });
});

// Logout (client-side token removal)
router.post('/logout', authenticateToken, (req, res) => {
  res.json({ message: 'Logged out successfully' });
});

module.exports = router;