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
            FROM jobs j
            JOIN company_profiles cp ON cp.user_id = j.company_user_id
            WHERE j.status = 'open'
            `;
        
        const params = [];

        if (search) {
            sql += ` AND (j.title LIKE ? OR cp.company_name LIKE ? OR j.description LIKE ?)`;

            const likeSearch = `%${search}%`;
            params.push(likeSearch, likeSearch, likeSearch);
        }

        if (category && category !== 'All Categories') {
            sql += ` AND j.category = ?`;
            params.push(category);
        }

        sql += ` ORDER BY j.created_at DESC`;

        const [jobs] = await db.execute(sql, params);

        for(const job of jobs){
            const [skills] = await db.execute(
                `SELECT skill_name FROM job_skills WHERE job_id = ?`,
                [job.id]
            );
            job.skills = skills;
            job.desc = job.job_desc;
            delete job.job_desc;
            job.salary = `$${job.salary_min} - $${job.salary_max}`;
        }
        res.json(jobs);
    }catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

module.exports = router;