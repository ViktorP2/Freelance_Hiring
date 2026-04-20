const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');

const router = express.Router();

router.post('/register', async (req, res) => {
    try{
        const {email, password, role, fullName, companyName} = req.body;

        if (!email || !password || !role) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        if (!['freelancer', 'company'].includes(role)) {
            return res.status(400).json({ message: 'Invalid role'})
        }

        const [existing] = await db.execute('SELECT id FROM users WHERE email = ?', [email]);
        
        if (existing.length > 0) {
            return res.status(409).json({ message: 'Email already registered' });
        }

        const passwordHash = await bcrypt.hash(password, 10);

        const [result] = await db.execute(
            'INSERT INTO users (email, password_hash, role) VALUES (?, ?, ?)',
            [email, passwordHash, role]
        );

        const userId = result.insertId;

        if (role === 'freelancer'){
            await db.execute(
                'INSERT INTO freelancer_profiles (user_id, full_name) VALUES (?, ?)',
                [userId, fullName || 'New Freelancer']
            );
        }

        if (role === 'company') {
            await db.execute(
                'INSERT INTO company_profiles (user_id, company_name) VALUES (?, ?)',
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
        const {email, password} = req.body; 

        const [rows] = await db.execute(
            'SELECT id, email, password_hash, role FROM users WHERE email = ?',
            [email]
        );

        if (rows.length === 0) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const user = rows[0];
        const passwordMatch = await bcrypt.compare(password, user.password_hash);

        if (!passwordMatch) {
            return res.status(401).json({ message: 'Invalid credentials'});
        }

        const token = jwt.sign(
            {id: user.id, role: user.role},
            process.env.JWT_SECRET,
            {expiresIn: '1d'}
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
    }catch (error) {
        res.status(500).json({message: 'Server error', error: error.message});
    }
});

module.exports = router;