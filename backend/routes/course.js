/**
 * routes/course.js
 * Course catalog, offerings, and enrollment endpoints
 * Maps to: sp_CreateCourse, sp_UpdateCourse, sp_DeleteCourse,
 *          sp_OpenCourseOffering, sp_GetCourseCatalog,
 *          sp_EnrollStudent, sp_DropEnrollment, sp_GetStudentSchedule
 */

const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../db');

// POST /api/course -> sp_CreateCourse
router.post('/', async (req, res) => {
    try {
        const { courseCode, courseName, programId, credit, ects, semesterOffered } = req.body;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('CourseCode', sql.NVarChar(20), courseCode)
            .input('CourseName', sql.NVarChar(150), courseName)
            .input('ProgramID', sql.Int, programId)
            .input('Credit', sql.Decimal(4, 2), credit)
            .input('ECTS', sql.Decimal(4, 1), ects)
            .input('SemesterOffered', sql.TinyInt, semesterOffered || null)
            .output('NewCourseID', sql.Int)
            .execute('dbo.sp_CreateCourse');
        
        res.json({ success: true, courseId: result.output.NewCourseID });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// PUT /api/course/:courseId -> sp_UpdateCourse
router.put('/:courseId', async (req, res) => {
    try {
        const { courseId } = req.params;
        const { courseName, credit, ects, semesterOffered } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('CourseID', sql.Int, parseInt(courseId, 10))
            .input('CourseName', sql.NVarChar(150), courseName)
            .input('Credit', sql.Decimal(4, 2), credit)
            .input('ECTS', sql.Decimal(4, 1), ects)
            .input('SemesterOffered', sql.TinyInt, semesterOffered || null)
            .execute('dbo.sp_UpdateCourse');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// DELETE /api/course/:courseId -> sp_DeleteCourse
router.delete('/:courseId', async (req, res) => {
    try {
        const { courseId } = req.params;
        const pool = await poolPromise;
        await pool.request()
            .input('CourseID', sql.Int, parseInt(courseId, 10))
            .execute('dbo.sp_DeleteCourse');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/course/offering -> sp_OpenCourseOffering
router.post('/offering', async (req, res) => {
    try {
        const { courseId, academicId, term, section, capacity, scheduleJSON } = req.body;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('CourseID', sql.Int, courseId)
            .input('AcademicID', sql.Int, academicId)
            .input('Term', sql.NVarChar(20), term)
            .input('Section', sql.NVarChar(5), section)
            .input('Capacity', sql.Int, capacity)
            .input('ScheduleJSON', sql.NVarChar(sql.MAX), scheduleJSON || null)
            .output('NewOfferingID', sql.Int)
            .execute('dbo.sp_OpenCourseOffering');
        
        res.json({ success: true, offeringId: result.output.NewOfferingID });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/course/catalog -> sp_GetCourseCatalog
router.get('/catalog', async (req, res) => {
    try {
        const { programId, term } = req.query;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('ProgramID', sql.Int, programId ? parseInt(programId, 10) : null)
            .input('Term', sql.NVarChar(20), term || null)
            .execute('dbo.sp_GetCourseCatalog');
        
        res.json({ success: true, courses: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/course/enroll -> sp_EnrollStudent
router.post('/enroll', async (req, res) => {
    try {
        const { offeringId, studentId } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('OfferingID', sql.Int, offeringId)
            .input('StudentID', sql.Int, studentId)
            .execute('dbo.sp_EnrollStudent');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/course/drop -> sp_DropEnrollment
router.post('/drop', async (req, res) => {
    try {
        const { enrollmentId, reason } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('EnrollmentID', sql.Int, enrollmentId)
            .input('Reason', sql.NVarChar(255), reason || null)
            .execute('dbo.sp_DropEnrollment');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/course/schedule/:studentId -> sp_GetStudentSchedule
router.get('/schedule/:studentId', async (req, res) => {
    try {
        const { studentId } = req.params;
        const { term } = req.query;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('StudentID', sql.Int, parseInt(studentId, 10))
            .input('Term', sql.NVarChar(20), term)
            .execute('dbo.sp_GetStudentSchedule');
        
        res.json({ success: true, schedule: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/course/academic-courses/:academicId -> sp_GetAcademicCourses
router.get('/academic-courses/:academicId', async (req, res) => {
    try {
        const { academicId } = req.params;
        const { term } = req.query;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('AcademicID', sql.Int, parseInt(academicId, 10))
            .input('Term', sql.NVarChar(20), term || null)
            .execute('dbo.sp_GetAcademicCourses');
        
        res.json({ success: true, courses: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/course/enrolled-students/:offeringId -> sp_GetEnrolledStudents
router.get('/enrolled-students/:offeringId', async (req, res) => {
    try {
        const { offeringId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('OfferingID', sql.Int, parseInt(offeringId, 10))
            .execute('dbo.sp_GetEnrolledStudents');
        
        res.json({ success: true, students: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/course/generate-sessions -> sp_GenerateClassSessions
router.post('/generate-sessions', async (req, res) => {
    try {
        const { offeringId, startDate, dayOfWeek, startTime, endTime, sessionType, location, weekCount } = req.body;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('OfferingID', sql.Int, offeringId)
            .input('StartDate', sql.Date, startDate)
            .input('DayOfWeek', sql.Int, dayOfWeek || 1)
            .input('StartTime', sql.Time, startTime || '09:00')
            .input('EndTime', sql.Time, endTime || '11:00')
            .input('SessionType', sql.NVarChar(20), sessionType || 'Lecture')
            .input('Location', sql.NVarChar(50), location || null)
            .input('WeekCount', sql.Int, weekCount || 14)
            .execute('dbo.sp_GenerateClassSessions');
        
        res.json({ success: true, sessionsCreated: result.recordset[0]?.SessionsCreated || 0 });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;

