const express = require('express');
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

const buildEnrollmentId = (sectionId, studentId) =>
  `${sectionId}:${studentId}`;

const parseCompositeId = (value) => {
  if (!value || typeof value !== 'string' || !value.includes(':')) {
    throw new Error('INVALID_ID');
  }
  const [sectionId, studentId] = value.split(':');
  if (!sectionId || !studentId) {
    throw new Error('INVALID_ID');
  }
  return { sectionId, studentId };
};

router.get('/', authenticateToken, async (req, res) => {
  try {
    const { section_id: sectionId, student_id: studentId } = req.query;

    let query = `
      SELECT
        e.section_id,
        e.student_id,
        CONCAT(e.section_id, ':', e.student_id) AS id,
        cs.section_code,
        cs.semester,
        cs.year,
        cs.subject_id,
        sub.name AS subject_name,
        sub.code AS subject_code,
        pr.full_name AS student_name,
        pr.code AS student_code
      FROM enrollments e
      JOIN class_sections cs ON cs.id = e.section_id
      JOIN subjects sub ON sub.id = cs.subject_id
      JOIN profiles pr ON pr.id = e.student_id
      WHERE 1 = 1
    `;

    const params = [];

    if (sectionId) {
      query += ' AND e.section_id = ?';
      params.push(sectionId);
    }

    if (studentId) {
      query += ' AND e.student_id = ?';
      params.push(studentId);
    }

    query += ' ORDER BY cs.year DESC, cs.semester DESC, sub.code, cs.section_code, pr.full_name';

    const [rows] = await db.execute(query, params);
    res.json(rows);
  } catch (error) {
    console.error('Get enrollments error:', error);
    res.status(500).json({ error: 'Failed to fetch enrollments' });
  }
});

router.post('/', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { section_id: sectionId, student_id: studentId } = req.body;

    if (!sectionId || !studentId) {
      return res.status(400).json({ error: 'section_id and student_id are required' });
    }

    await db.execute(
      'INSERT INTO enrollments (section_id, student_id) VALUES (?, ?)',
      [sectionId, studentId],
    );

    res.status(201).json({
      message: 'Enrollment created successfully',
      id: buildEnrollmentId(sectionId, studentId),
      section_id: sectionId,
      student_id: studentId,
    });
  } catch (error) {
    console.error('Create enrollment error:', error);

    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Enrollment already exists' });
    }

    if (error.code === 'ER_NO_REFERENCED_ROW_2') {
      return res.status(400).json({ error: 'Invalid section_id or student_id' });
    }

    res.status(500).json({ error: 'Failed to create enrollment' });
  }
});

router.put('/:compositeId', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { compositeId } = req.params;
    const { sectionId, studentId } = parseCompositeId(decodeURIComponent(compositeId));
    const {
      section_id: newSectionId = sectionId,
      student_id: newStudentId = studentId,
    } = req.body;

    const [result] = await db.execute(
      'UPDATE enrollments SET section_id = ?, student_id = ? WHERE section_id = ? AND student_id = ?',
      [newSectionId, newStudentId, sectionId, studentId],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Enrollment not found' });
    }

    res.json({
      message: 'Enrollment updated successfully',
      id: buildEnrollmentId(newSectionId, newStudentId),
      section_id: newSectionId,
      student_id: newStudentId,
    });
  } catch (error) {
    if (error.message === 'INVALID_ID') {
      return res.status(400).json({ error: 'Invalid enrollment identifier' });
    }

    console.error('Update enrollment error:', error);

    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Target enrollment already exists' });
    }

    if (error.code === 'ER_NO_REFERENCED_ROW_2') {
      return res.status(400).json({ error: 'Invalid section_id or student_id' });
    }

    res.status(500).json({ error: 'Failed to update enrollment' });
  }
});

router.delete('/:compositeId', authenticateToken, requireRole(['admin']), async (req, res) => {
  try {
    const { compositeId } = req.params;
    const { sectionId, studentId } = parseCompositeId(decodeURIComponent(compositeId));

    const [result] = await db.execute(
      'DELETE FROM enrollments WHERE section_id = ? AND student_id = ?',
      [sectionId, studentId],
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Enrollment not found' });
    }

    res.json({ message: 'Enrollment deleted successfully' });
  } catch (error) {
    if (error.message === 'INVALID_ID') {
      return res.status(400).json({ error: 'Invalid enrollment identifier' });
    }

    console.error('Delete enrollment error:', error);
    res.status(500).json({ error: 'Failed to delete enrollment' });
  }
});

module.exports = router;
