const express = require('express');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/:jobId/apply', authRequired, requireRole('freelancer'), async (req, res) => {
    try {
        const { jobId } = req.params;
        const { coverLetter } = req.body;

        await db.query(
            'INSERT INTO freelancehub.applications (job_id, freelancer_user_id, cover_letter) VALUES ($1, $2, $3)',
            [jobId, req.user.id, coverLetter || null]
        );

        res.status(201).json({ message: 'Application submitted successfully' });
    } catch (error) {
        if (error.code === '23505') {
            return res.status(409).json({ message: 'You already applied for this job' });
        }

        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

router.get('/my', authRequired, requireRole('freelancer'), async (req, res) => {
    try {
        const result = await db.query(
            `SELECT
                a.id,
                a.status,
                a.applied_at,
                j.title,
                j.category
             FROM freelancehub.applications a
             JOIN freelancehub.jobs j ON a.job_id = j.id
             WHERE a.freelancer_user_id = $1
             ORDER BY a.applied_at DESC`,
            [req.user.id]
        );

        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

module.exports = router;