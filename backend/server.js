/**
 * server.js
 * Main Express server wiring routes, middleware, and error handling.
 * Listens on PORT (default 5000).
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
const authRoutes = require('./routes/auth');
const studentRoutes = require('./routes/student');
const courseRoutes = require('./routes/course');
const gradingRoutes = require('./routes/grading');
const attendanceRoutes = require('./routes/attendance');
const reportingRoutes = require('./routes/reporting');

app.use('/api/auth', authRoutes);
app.use('/api/student', studentRoutes);
app.use('/api/course', courseRoutes);
app.use('/api/grading', gradingRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/reporting', reportingRoutes);

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ success: false, message: 'Endpoint bulunamadı' });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('Sunucu hatası:', err);
    res.status(500).json({ success: false, message: 'Sunucu hatası', error: err.message });
});

// Start server
app.listen(PORT, () => {
    console.log(`✓ Backend sunucusu http://localhost:${PORT} adresinde çalışıyor`);
});

