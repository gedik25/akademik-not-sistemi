/**
 * routes/grading.js
 * Grade components, grade entry, transcript endpoints
 * Maps to: sp_DefineGradeComponent, sp_RecordGrade, sp_GetGradeBook,
 *          sp_GetStudentTranscript, sp_ApproveFinalGrades
 */

const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../db');

// POST /api/grading/component -> sp_DefineGradeComponent
router.post('/component', async (req, res) => {
    try {
        const { offeringId, componentName, weightPercent, isMandatory } = req.body;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('OfferingID', sql.Int, offeringId)
            .input('ComponentName', sql.NVarChar(50), componentName)
            .input('WeightPercent', sql.Decimal(5, 2), weightPercent)
            .input('IsMandatory', sql.Bit, isMandatory !== false)
            .output('ComponentID', sql.Int)
            .execute('dbo.sp_DefineGradeComponent');
        
        res.json({ success: true, componentId: result.output.ComponentID });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/grading/record -> sp_RecordGrade
router.post('/record', async (req, res) => {
    try {
        const { enrollmentId, componentId, score, gradedBy } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('EnrollmentID', sql.Int, enrollmentId)
            .input('ComponentID', sql.Int, componentId)
            .input('Score', sql.Decimal(5, 2), score)
            .input('GradedBy', sql.Int, gradedBy)
            .execute('dbo.sp_RecordGrade');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/grading/gradebook/:offeringId -> sp_GetGradeBook
router.get('/gradebook/:offeringId', async (req, res) => {
    try {
        const { offeringId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('OfferingID', sql.Int, parseInt(offeringId, 10))
            .execute('dbo.sp_GetGradeBook');
        
        res.json({ success: true, gradebook: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/grading/transcript/:studentId -> sp_GetStudentTranscript
router.get('/transcript/:studentId', async (req, res) => {
    try {
        const { studentId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('StudentID', sql.Int, parseInt(studentId, 10))
            .execute('dbo.sp_GetStudentTranscript');
        
        res.json({ success: true, transcript: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/grading/approve -> sp_ApproveFinalGrades
router.post('/approve', async (req, res) => {
    try {
        const { offeringId, academicId } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('OfferingID', sql.Int, offeringId)
            .input('AcademicID', sql.Int, academicId)
            .execute('dbo.sp_ApproveFinalGrades');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/grading/components/:offeringId -> sp_GetGradeComponents
router.get('/components/:offeringId', async (req, res) => {
    try {
        const { offeringId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('OfferingID', sql.Int, parseInt(offeringId, 10))
            .execute('dbo.sp_GetGradeComponents');
        
        res.json({ success: true, components: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/grading/student-grades/:offeringId -> sp_GetStudentGrades
router.get('/student-grades/:offeringId', async (req, res) => {
    try {
        const { offeringId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('OfferingID', sql.Int, parseInt(offeringId, 10))
            .execute('dbo.sp_GetStudentGrades');
        
        res.json({ success: true, grades: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;

