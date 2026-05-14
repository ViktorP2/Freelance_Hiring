const express = require('express');
const db = require('../db');

const router = express.Router();

router.get('/', async (req, res) => {
    try {
        const { search = '', category = '' } = req.query;

        let sql = `
            SELECT
                j.id,
                cp.company_name AS company,
                j.title,
                j.description AS job_desc,
                j.salary_min,
                j.salary_max,
                j.category,
                j.website
            FROM freelancehub.jobs j
            JOIN freelancehub.company_profiles cp ON cp.user_id = j.company_user_id
            WHERE j.status = 'open'
        `;

        const params = [];
        let paramIndex = 1;

        if (search) {
            sql += ` AND (j.title ILIKE $${paramIndex} OR cp.company_name ILIKE $${paramIndex + 1} OR j.description ILIKE $${paramIndex + 2})`;
            const likeSearch = `%${search}%`;
            params.push(likeSearch, likeSearch, likeSearch);
            paramIndex += 3;
        }

        if (category && category !== 'All Categories') {
            sql += ` AND j.category = $${paramIndex}`;
            params.push(category);
            paramIndex += 1;
        }

        sql += ` ORDER BY j.created_at DESC`;

        const jobsResult = await db.query(sql, params);
        const jobs = jobsResult.rows;

        for (const job of jobs) {
            const skillsResult = await db.query(
                'SELECT skill_name FROM freelancehub.job_skills WHERE job_id = $1',
                [job.id]
            );

            job.skills = skillsResult.rows;
            job.desc = job.job_desc;
            delete job.job_desc;
            job.salary = `$${job.salary_min} - $${job.salary_max}`;
        }

        res.json(jobs);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

module.exports = router;