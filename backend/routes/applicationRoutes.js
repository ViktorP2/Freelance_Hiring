const express = require('express');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/:jobId/apply', authRequired, requireRole('freelancer'), async (req, res) => {
  try {
    const { jobId } = req.params;
    const { coverLetter } = req.body;

    await db.execute(
      'INSERT INTO applications (job_id, freelancer_user_id, cover_letter) VALUES (?, ?, ?)',
      [jobId, req.user.id, coverLetter || null]
    );

    res.status(201).json({ message: 'Application submitted successfully' });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'You already applied for this job' });
    }

    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

router.get('/my', authRequired, requireRole('freelancer'), async (req, res) => {
  try {
    const [rows] = await db.execute(
      `SELECT
        a.id,
        a.status,
        a.applied_at,
        j.title,
        j.category
      FROM applications a
      JOIN jobs j ON a.job_id = j.id
      WHERE a.freelancer_user_id = ?
      ORDER BY a.applied_at DESC`,
      [req.user.id]
    );

    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;