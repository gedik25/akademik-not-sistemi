/**
 * db/index.js
 * MS SQL connection pool helper using mssql package.
 * All routes import poolPromise to execute stored procedures.
 */

const sql = require('mssql');
require('dotenv').config();

const config = {
    server: process.env.DB_SERVER || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 1433,
    user: process.env.DB_USER || 'sa',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'AkademikDB',
    options: {
        encrypt: false, // Docker local doesn't need encryption
        trustServerCertificate: true,
        enableArithAbort: true
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    }
};

const poolPromise = new sql.ConnectionPool(config)
    .connect()
    .then(pool => {
        console.log('✓ MS SQL bağlantısı başarılı');
        return pool;
    })
    .catch(err => {
        console.error('✗ MS SQL bağlantı hatası:', err);
        process.exit(1);
    });

module.exports = {
    sql,
    poolPromise
};

