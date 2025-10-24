const jwt = require('jsonwebtoken');
const db = require('../config/database');

const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get user info from database
    const [users] = await db.execute(
      `SELECT 
         p.*,
         ur.role,
         a.id AS account_id,
         a.email,
         a.is_phone_verified,
         a.is_active AS account_active,
         (SELECT COUNT(1) FROM account_totp atp WHERE atp.account_id = a.id) AS totp_enabled
       FROM profiles p
       JOIN user_roles ur ON p.id = ur.user_id
       JOIN accounts a ON p.id = a.profile_id
       WHERE p.id = ? AND p.is_active = 1`,
      [decoded.userId]
    );

    if (users.length === 0) {
      return res.status(401).json({ error: 'User not found or inactive' });
    }

    const user = users[0];
    if (!user.account_active) {
      return res.status(401).json({ error: 'Account is inactive' });
    }

    req.user = {
      ...user,
      totp_enabled: Boolean(user.totp_enabled),
    };
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid token' });
  }
};

const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    next();
  };
};

module.exports = { authenticateToken, requireRole };
