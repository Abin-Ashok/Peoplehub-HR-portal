const mysql = require("mysql2/promise");
const fs = require("node:fs");

const sslCaPath = process.env.DB_SSL_CA_PATH;

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,

  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,

  ...(sslCaPath
    ? {
        ssl: {
          ca: fs.readFileSync(sslCaPath, "utf8"),
          rejectUnauthorized: true
        }
      }
    : {})
});

async function addColumnIfMissing(columnName, definition) {
  const [columns] = await pool.execute(
    `SELECT COLUMN_NAME
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME = 'employees'
       AND COLUMN_NAME = ?`,
    [columnName]
  );

  if (columns.length === 0) {
    await pool.query(
      `ALTER TABLE employees ADD COLUMN ${columnName} ${definition}`
    );
  }
}

async function initializeDatabase() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS employees (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      email VARCHAR(254) NOT NULL,
      department VARCHAR(100) NOT NULL,
      job_title VARCHAR(100) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE KEY unique_employee_email (email)
    )
  `);

  await addColumnIfMissing("joining_date", "DATE NULL");
  await addColumnIfMissing(
    "employment_status",
    "VARCHAR(20) NOT NULL DEFAULT 'Active'"
  );
}

module.exports = { pool, initializeDatabase };
