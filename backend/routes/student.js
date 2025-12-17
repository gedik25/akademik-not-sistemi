/**
 * routes/student.js
 * Student & academic registration endpoints
 * Maps to: sp_RegisterStudent, sp_RegisterAcademic, sp_AssignAdvisor, sp_ListStudentsByDepartment
 */

const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../db');

// POST /api/student/register -> sp_RegisterStudent
router.post('/register', async (req, res) => {
    try {
        const {
            username, password, email, phone,
            studentNumber, nationalId, firstName, lastName,
            birthDate, gender, departmentId, programId, advisorId, enrollmentYear
        } = req.body;
        
        const pool = await poolPromise;
        const result = await pool.request()
            .input('Username', sql.NVarChar(50), username)
            .input('PasswordPlain', sql.NVarChar(255), password)
            .input('Email', sql.NVarChar(255), email)
            .input('Phone', sql.NVarChar(20), phone || null)
            .input('StudentNumber', sql.NVarChar(20), studentNumber)
            .input('NationalID', sql.NVarChar(20), nationalId)
            .input('FirstName', sql.NVarChar(50), firstName)
            .input('LastName', sql.NVarChar(50), lastName)
            .input('BirthDate', sql.Date, birthDate)
            .input('Gender', sql.Char(1), gender || null)
            .input('DepartmentID', sql.Int, departmentId)
            .input('ProgramID', sql.Int, programId || null)
            .input('AdvisorID', sql.Int, advisorId || null)
            .input('EnrollmentYear', sql.SmallInt, enrollmentYear || null)
            .output('NewStudentID', sql.Int)
            .execute('dbo.sp_RegisterStudent');
        
        res.json({ success: true, studentId: result.output.NewStudentID });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/student/academic/register -> sp_RegisterAcademic
router.post('/academic/register', async (req, res) => {
    try {
        const {
            username, password, email, phone,
            title, departmentId, office, phoneExtension
        } = req.body;
        
        const pool = await poolPromise;
        const result = await pool.request()
            .input('Username', sql.NVarChar(50), username)
            .input('PasswordPlain', sql.NVarChar(255), password)
            .input('Email', sql.NVarChar(255), email)
            .input('Phone', sql.NVarChar(20), phone || null)
            .input('Title', sql.NVarChar(50), title || null)
            .input('DepartmentID', sql.Int, departmentId)
            .input('Office', sql.NVarChar(50), office || null)
            .input('PhoneExtension', sql.NVarChar(10), phoneExtension || null)
            .output('NewAcademicID', sql.Int)
            .execute('dbo.sp_RegisterAcademic');
        
        res.json({ success: true, academicId: result.output.NewAcademicID });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// PUT /api/student/advisor -> sp_AssignAdvisor
router.put('/advisor', async (req, res) => {
    try {
        const { studentId, advisorId } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('StudentID', sql.Int, studentId)
            .input('AdvisorID', sql.Int, advisorId)
            .execute('dbo.sp_AssignAdvisor');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/student/by-department/:departmentId -> sp_ListStudentsByDepartment
router.get('/by-department/:departmentId', async (req, res) => {
    try {
        const { departmentId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('DepartmentID', sql.Int, parseInt(departmentId, 10))
            .execute('dbo.sp_ListStudentsByDepartment');
        
        res.json({ success: true, students: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;

