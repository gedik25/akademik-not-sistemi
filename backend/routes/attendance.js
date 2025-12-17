/**
 * routes/attendance.js
 * Attendance policy and recording endpoints
 * Maps to: sp_DefineAttendancePolicy, sp_RecordAttendance,
 *          sp_GetAttendanceSummary, sp_GetStudentAttendanceDetail
 */

const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../db');

// POST /api/attendance/policy -> sp_DefineAttendancePolicy
router.post('/policy', async (req, res) => {
    try {
        const { offeringId, maxAbsencePercent, warningThresholdPercent, autoFailPercent } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('OfferingID', sql.Int, offeringId)
            .input('MaxAbsencePercent', sql.Decimal(5, 2), maxAbsencePercent)
            .input('WarningThresholdPercent', sql.Decimal(5, 2), warningThresholdPercent || null)
            .input('AutoFailPercent', sql.Decimal(5, 2), autoFailPercent || null)
            .execute('dbo.sp_DefineAttendancePolicy');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/attendance/record -> sp_RecordAttendance
router.post('/record', async (req, res) => {
    try {
        const { sessionId, studentId, status, recordedBy } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('SessionID', sql.Int, sessionId)
            .input('StudentID', sql.Int, studentId)
            .input('Status', sql.NVarChar(20), status)
            .input('RecordedBy', sql.Int, recordedBy)
            .execute('dbo.sp_RecordAttendance');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/attendance/summary/:offeringId -> sp_GetAttendanceSummary
router.get('/summary/:offeringId', async (req, res) => {
    try {
        const { offeringId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('OfferingID', sql.Int, parseInt(offeringId, 10))
            .execute('dbo.sp_GetAttendanceSummary');
        
        res.json({ success: true, summary: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/attendance/detail/:studentId/:offeringId -> sp_GetStudentAttendanceDetail
router.get('/detail/:studentId/:offeringId', async (req, res) => {
    try {
        const { studentId, offeringId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('StudentID', sql.Int, parseInt(studentId, 10))
            .input('OfferingID', sql.Int, parseInt(offeringId, 10))
            .execute('dbo.sp_GetStudentAttendanceDetail');
        
        res.json({ success: true, detail: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/attendance/sessions/:offeringId -> sp_GetClassSessions
router.get('/sessions/:offeringId', async (req, res) => {
    try {
        const { offeringId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('OfferingID', sql.Int, parseInt(offeringId, 10))
            .execute('dbo.sp_GetClassSessions');
        
        res.json({ success: true, sessions: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/attendance/session/:sessionId -> sp_GetSessionAttendance
router.get('/session/:sessionId', async (req, res) => {
    try {
        const { sessionId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('SessionID', sql.Int, parseInt(sessionId, 10))
            .execute('dbo.sp_GetSessionAttendance');
        
        res.json({ success: true, students: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/attendance/bulk-record -> sp_BulkRecordAttendance
router.post('/bulk-record', async (req, res) => {
    try {
        const { sessionId, attendanceData, recordedBy } = req.body;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('SessionID', sql.Int, sessionId)
            .input('AttendanceJSON', sql.NVarChar(sql.MAX), JSON.stringify(attendanceData))
            .input('RecordedBy', sql.Int, recordedBy)
            .execute('dbo.sp_BulkRecordAttendance');
        
        res.json({ success: true, recordedCount: result.recordset[0]?.RecordedCount || 0 });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;

