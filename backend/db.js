const mysql = require('mysql2/promise');

const REQUIRED = ['DB_HOST', 'DB_USER', 'DB_PASS', 'DB_NAME', 'DB_PORT'];

function getRequiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

for (const key of REQUIRED) {
  getRequiredEnv(key);
}

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  port: parseInt(process.env.DB_PORT, 10),
  waitForConnections: true,
  connectionLimit: 10,
  enableKeepAlive: true,
});

module.exports = pool;
