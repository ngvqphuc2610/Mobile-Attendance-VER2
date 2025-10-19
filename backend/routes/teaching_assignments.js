const express = require('express');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

router.get('/', authenticateToken, async (req, res) => {
  try {
    const { section_id, teacher_id } = req.query;

    let query = `
      SELECT
        ta.section_id,
        ta.teacher_id,
        ta.role,
        cs.section_code,
        cs.year,
        cs.semester,
        sub.code AS subject_code,
        sub.name AS subject_name,
        prof.full_name AS teacher_name,
        prof.code AS teacher_code,
        prof.email AS teacher_email
      FROM teaching_assignments ta
      JOIN class_sections cs ON ta.section_id = cs.id
      LEFT JOIN subjects sub ON cs.subject_id = sub.id
      JOIN profiles prof ON ta.teacher_id = prof.id
      WHERE 1 = 1
    `;

    const params = [];

    if (section_id) {
      query += ' AND ta.section_id = ?';
      params.push(section_id);
    }

    if (teacher_id) {
      query += ' AND ta.teacher_id = ?';
      params.push(teacher_id);
    }

    query += `
      ORDER BY
        cs.year DESC,
        cs.semester DESC,
        sub.name,
        prof.full_name
    `;

    const [rows] = await db.execute(query, params);
    res.json(rows);
  } catch (error) {
    console.error('Get teaching assignments error:', error);
    res.status(500).json({ error: 'Failed to fetch teaching assignments' });
  }
});

router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { section_id, teacher_id, role = 'lecturer' } = req.body;

    if (!section_id || !teacher_id) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    await db.execute(
      `INSERT INTO teaching_assignments (section_id, teacher_id, role)
       VALUES (?, ?, ?)`,
      [section_id, teacher_id, role]
    );

    res.status(201).json({ message: 'Teaching assignment created successfully' });
  } catch (error) {
    console.error('Create teaching assignment error:', error);
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Teaching assignment already exists' });
    }
    res.status(500).json({ error: 'Failed to create teaching assignment' });
  }
});

router.put('/:sectionId/:teacherId', authenticateToken, requireRole(['admin']), async (req, res) => {
  const { sectionId, teacherId } = req.params;
  const {
    section_id: nextSectionId = sectionId,
    teacher_id: nextTeacherId = teacherId,
    role = 'lecturer',
  } = req.body;

  const connection = await db.getConnection();

  try {
    await connection.beginTransaction();

    if (nextSectionId === sectionId && nextTeacherId === teacherId) {
      await connection.execute(
        'UPDATE teaching_assignments SET role = ? WHERE section_id = ? AND teacher_id = ?',
        [role, sectionId, teacherId]
      );
    } else {
      await connection.execute(
        'DELETE FROM teaching_assignments WHERE section_id = ? AND teacher_id = ?',
        [sectionId, teacherId]
      );

      await connection.execute(
        `INSERT INTO teaching_assignments (section_id, teacher_id, role)
         VALUES (?, ?, ?)`,
        [nextSectionId, nextTeacherId, role]
      );
    }

    await connection.commit();
    res.json({ message: 'Teaching assignment updated successfully' });
  } catch (error) {
    await connection.rollback();
    console.error('Update teaching assignment error:', error);
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Teaching assignment already exists' });
    }
    res.status(500).json({ error: 'Failed to update teaching assignment' });
  } finally {
    connection.release();
  }
});

router.delete('/:sectionId/:teacherId', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { sectionId, teacherId } = req.params;
    await db.execute(
      'DELETE FROM teaching_assignments WHERE section_id = ? AND teacher_id = ?',
      [sectionId, teacherId]
    );
    res.json({ message: 'Teaching assignment deleted successfully' });
  } catch (error) {
    console.error('Delete teaching assignment error:', error);
    res.status(500).json({ error: 'Failed to delete teaching assignment' });
  }
});

module.exports = router;
