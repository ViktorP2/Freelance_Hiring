const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');

const router = express.Router();

router.post('/register', async (req, res) => {
    try {
        const { email, password, role, fullName, companyName } = req.body;

        if (!email || !password || !role) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        if (!['freelancer', 'company'].includes(role)) {
            return res.status(400).json({ message: 'Invalid role' });
        }

        const existing = await db.query(
            'SELECT id FROM freelancehub.users WHERE email = $1',
            [email]
        );

        if (existing.rows.length > 0) {
            return res.status(409).json({ message: 'Email already registered' });
        }

        const passwordHash = await bcrypt.hash(password, 10);

        const userResult = await db.query(
            'INSERT INTO freelancehub.users (email, password_hash, role) VALUES ($1, $2, $3) RETURNING id',
            [email, passwordHash, role]
        );

        const userId = userResult.rows[0].id;

        if (role === 'freelancer') {
            await db.query(
                'INSERT INTO freelancehub.freelancer_profiles (user_id, full_name) VALUES ($1, $2)',
                [userId, fullName || 'New Freelancer']
            );
        }

        if (role === 'company') {
            await db.query(
                'INSERT INTO freelancehub.company_profiles (user_id, company_name) VALUES ($1, $2)',
                [userId, companyName || 'New Company']
            );
        }

        res.status(201).json({ message: 'Registered successfully', userId });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        const result = await db.query(
            'SELECT id, email, password_hash, role FROM freelancehub.users WHERE email = $1',
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const user = result.rows[0];
        const passwordMatch = await bcrypt.compare(password, user.password_hash);

        if (!passwordMatch) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const token = jwt.sign(
            { id: user.id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '1d' }
        );

        res.json({
            message: 'Login successful',
            token,
            user: {
                id: user.id,
                email: user.email,
                role: user.role
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

module.exports = router;