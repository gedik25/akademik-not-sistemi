/**
 * routes/auth.js
 * Authentication & user management endpoints
 * Maps to: sp_LoginUser, sp_CreateUser, sp_UpdateUserContact, sp_DeactivateUser
 */

const express = require('express');
const router = express.Router();
const { sql, poolPromise } = require('../db');

// POST /api/auth/login -> sp_LoginUser
router.post('/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('Username', sql.NVarChar(50), username)
            .input('PasswordPlain', sql.NVarChar(255), password)
            .execute('dbo.sp_LoginUser');
        
        if (result.recordset && result.recordset.length > 0) {
            res.json({ success: true, user: result.recordset[0] });
        } else {
            res.status(401).json({ success: false, message: 'Giriş başarısız' });
        }
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/auth/register -> sp_CreateUser
router.post('/register', async (req, res) => {
    try {
        const { roleName, username, password, email, phone } = req.body;
        const pool = await poolPromise;
        const result = await pool.request()
            .input('RoleName', sql.NVarChar(50), roleName)
            .input('Username', sql.NVarChar(50), username)
            .input('PasswordPlain', sql.NVarChar(255), password)
            .input('Email', sql.NVarChar(255), email)
            .input('Phone', sql.NVarChar(20), phone || null)
            .output('NewUserID', sql.Int)
            .execute('dbo.sp_CreateUser');
        
        res.json({ success: true, userId: result.output.NewUserID });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// PUT /api/auth/contact -> sp_UpdateUserContact
router.put('/contact', async (req, res) => {
    try {
        const { userId, email, phone } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('UserID', sql.Int, userId)
            .input('Email', sql.NVarChar(255), email)
            .input('Phone', sql.NVarChar(20), phone || null)
            .execute('dbo.sp_UpdateUserContact');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST /api/auth/deactivate -> sp_DeactivateUser
router.post('/deactivate', async (req, res) => {
    try {
        const { userId, reason } = req.body;
        const pool = await poolPromise;
        await pool.request()
            .input('UserID', sql.Int, userId)
            .input('Reason', sql.NVarChar(255), reason || null)
            .execute('dbo.sp_DeactivateUser');
        
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;

