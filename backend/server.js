require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors({
    origin: process.env.FRONTEND_URL || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());

app.get('/', (req, res) => {
    res.json({ message: 'FreelanceHub API is running' });
});

/*Temporary check*/
const db = require('./db');

app.get('/test-db', async (req, res) => {
    try {
        const [rows] = await db.execute("SELECT 1 AS test");
        res.json(rows);
    } catch (error) {
        res.status(500).json({ message: 'Database connection failed', error: error.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port http://localhost:${PORT}`);
});