/**
 * routes/reporting.js
 * Dashboard, notifications, and audit log endpoints
 * Maps to: sp_GetDashboardStats, sp_ListNotifications,
 *          sp_MarkNotificationRead, sp_SearchAuditLog
 */

const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../db');

// GET /api/reporting/dashboard/:userId -> sp_GetDashboardStats
router.get('/dashboard/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('UserID', sql.Int, parseInt(userId, 10))
            .execute('dbo.sp_GetDashboardStats');
        
        res.json({ success: true, stats: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/reporting/notifications/:userId -> sp_ListNotifications
router.get('/notifications/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('UserID', sql.Int, parseInt(userId, 10))
            .execute('dbo.sp_ListNotifications');
        
        res.json({ success: true, notifications: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// PUT /api/reporting/notifications/:notificationId/read -> sp_MarkNotificationRead
router.put('/notifications/:notificationId/read', async (req, res) => {
    try {
        const { notificationId } = req.params;
        const pool = await poolPromise;
        await pool.request()
            .input('NotificationID', sql.Int, parseInt(notificationId, 10))
            .execute('dbo.sp_MarkNotificationRead');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET /api/reporting/audit -> sp_SearchAuditLog
router.get('/audit', async (req, res) => {
    try {
        const { dateFrom, dateTo, actionType, tableName } = req.query;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('DateFrom', sql.DateTime2, dateFrom || null)
            .input('DateTo', sql.DateTime2, dateTo || null)
            .input('ActionType', sql.NVarChar(50), actionType || null)
            .input('TableName', sql.NVarChar(100), tableName || null)
            .execute('dbo.sp_SearchAuditLog');
        
        res.json({ success: true, logs: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;

