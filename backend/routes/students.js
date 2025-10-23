const express = require('express');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

// Get all students with filters
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { faculty_id, class_id, search } = req.query;

    let query = `
      SELECT 
        s.*,
        p.code, p.full_name, p.email, p.phone, p.is_active,
        c.name as class_name, c.code as class_code,
        f.name as faculty_name, f.code as faculty_code,
        co.year as cohort_year
      FROM students s
      JOIN profiles p ON s.profile_id = p.id
      LEFT JOIN classes c ON s.class_id = c.id
      LEFT JOIN faculties f ON c.faculty_id = f.id
      LEFT JOIN cohorts co ON c.cohort_id = co.id
      WHERE 1=1
    `;

    const params = [];

    if (faculty_id) {
      query += ' AND c.faculty_id = ?';
      params.push(faculty_id);
    }

    if (class_id) {
      query += ' AND s.class_id = ?';
      params.push(class_id);
    }

    if (search) {
      query += ' AND (p.full_name LIKE ? OR p.code LIKE ? OR s.mssv LIKE ?)';
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    query += ' ORDER BY p.full_name';

    const [students] = await db.execute(query, params);
    res.json(students);
  } catch (error) {
    console.error('Get students error:', error);
    res.status(500).json({ error: 'Failed to fetch students' });
  }
});

router.get('/:id/schedules', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { from, to, semester, year } = req.query;

    let query = `
      SELECT
        si.id,
        si.section_id,
        si.starts_at,
        si.ends_at,
        si.status,
        si.room_id,
        cs.section_code,
        cs.year,
        cs.semester,
        sub.code AS subject_code,
        sub.name AS subject_name,
        sub.credits AS subject_credits,
        r.code AS room_code,
        r.name AS room_name
      FROM enrollments e
      JOIN session_instances si ON si.section_id = e.section_id
      JOIN class_sections cs    ON cs.id = si.section_id
      LEFT JOIN subjects sub    ON sub.id = cs.subject_id
      LEFT JOIN rooms r         ON r.id = si.room_id
      WHERE e.student_id = ?
    `;

    const params = [id];

    if (from) {
      query += ' AND si.starts_at >= ?';
      params.push(from);
    }

    if (to) {
      query += ' AND si.starts_at <= ?';
      params.push(to);
    }

    if (semester) {
      query += ' AND cs.semester = ?';
      params.push(Number(semester));
    }

    if (year) {
      query += ' AND cs.year = ?';
      params.push(Number(year));
    }

    query += ' ORDER BY si.starts_at ASC';

    const [rows] = await db.execute(query, params);
    res.json(rows);
  } catch (error) {
    console.error('Get student schedules error:', error);
    res.status(500).json({ error: 'Failed to fetch student schedules' });
  }
});

// Create student
router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  const connection = await db.getConnection();

  try {
    await connection.beginTransaction();

    const {
      code, full_name, email, phone, class_id, mssv,
      password = '123456' // Default password
    } = req.body;

    const profileId = uuidv4();
    const accountId = uuidv4();
    const hashedPassword = await bcrypt.hash(password, 10);

    // Parse MSSV info
    let mssvInfo = null;
    if (mssv && mssv.length === 10) {
      const cohort = 2000 + parseInt(mssv.substring(0, 2));
      const trackCode = mssv.substring(2, 6);
      const serial = parseInt(mssv.substring(6, 10));
      mssvInfo = { cohort, trackCode, serial };
    }

    // Create profile
    await connection.execute(
      `INSERT INTO profiles (id, code, full_name, class_id, email, phone, is_active) 
       VALUES (?, ?, ?, ?, ?, ?, 1)`,
      [profileId, code, full_name, class_id, email, phone]
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
      [profileId, 'student']
    );

    // Create student record
    await connection.execute(
      `INSERT INTO students (profile_id, class_id, mssv, mssv_cohort, mssv_track_code, mssv_serial) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        profileId, class_id, mssv,
        mssvInfo?.cohort, mssvInfo?.trackCode, mssvInfo?.serial
      ]
    );

    await connection.commit();
    res.status(201).json({ message: 'Student created successfully', id: profileId });
  } catch (error) {
    await connection.rollback();
    console.error('Create student error:', error);
    res.status(500).json({ error: 'Failed to create student' });
  } finally {
    connection.release();
  }
});

// Update student
router.put('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  const connection = await db.getConnection();

  try {
    await connection.beginTransaction();

    const { id } = req.params;
    const { code, full_name, email, phone, class_id, mssv } = req.body;

    // Parse MSSV info
    let mssvInfo = null;
    if (mssv && mssv.length === 10) {
      const cohort = 2000 + parseInt(mssv.substring(0, 2));
      const trackCode = mssv.substring(2, 6);
      const serial = parseInt(mssv.substring(6, 10));
      mssvInfo = { cohort, trackCode, serial };
    }

    // Update profile
    await connection.execute(
      `UPDATE profiles 
       SET code = ?, full_name = ?, email = ?, phone = ?, class_id = ? 
       WHERE id = ?`,
      [code, full_name, email, phone, class_id, id]
    );

    // Update account email
    await connection.execute(
      'UPDATE accounts SET email = ? WHERE profile_id = ?',
      [email, id]
    );

    // Update student record
    await connection.execute(
      `UPDATE students 
       SET class_id = ?, mssv = ?, mssv_cohort = ?, mssv_track_code = ?, mssv_serial = ? 
       WHERE profile_id = ?`,
      [class_id, mssv, mssvInfo?.cohort, mssvInfo?.trackCode, mssvInfo?.serial, id]
    );

    await connection.commit();
    res.json({ message: 'Student updated successfully' });
  } catch (error) {
    await connection.rollback();
    console.error('Update student error:', error);
    res.status(500).json({ error: 'Failed to update student' });
  } finally {
    connection.release();
  }
});

// Delete student
router.delete('/:id', authenticateToken, requireRole(['admin']), async (req, res) => {
  const connection = await db.getConnection();

  try {
    await connection.beginTransaction();

    const { id } = req.params;

    // Delete in order due to foreign key constraints
    await connection.execute('DELETE FROM students WHERE profile_id = ?', [id]);
    await connection.execute('DELETE FROM user_roles WHERE user_id = ?', [id]);
    await connection.execute('DELETE FROM accounts WHERE profile_id = ?', [id]);
    await connection.execute('DELETE FROM profiles WHERE id = ?', [id]);

    await connection.commit();
    res.json({ message: 'Student deleted successfully' });
  } catch (error) {
    await connection.rollback();
    console.error('Delete student error:', error);
    res.status(500).json({ error: 'Failed to delete student' });
  } finally {
    connection.release();
  }
});

module.exports = router;
