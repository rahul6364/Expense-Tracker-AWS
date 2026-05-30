const CREATE_TRANSACTIONS_TABLE = `
CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  type ENUM('income','expense') NOT NULL,
  category VARCHAR(100),
  date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)`;

async function tableExists(connection, databaseName) {
  const [rows] = await connection.query(
    `SELECT 1
     FROM information_schema.tables
     WHERE table_schema = ? AND table_name = 'transactions'
     LIMIT 1`,
    [databaseName]
  );
  return rows.length > 0;
}

/**
 * Verifies connectivity and ensures the transactions table exists before serving traffic.
 * @param {import('mysql2/promise').Pool} pool
 */
async function bootstrapDatabase(pool) {
  const databaseName = process.env.DB_NAME;
  let connection;

  try {
    connection = await pool.getConnection();
    await connection.ping();
    console.log('Database connected successfully.');

    const exists = await tableExists(connection, databaseName);

    if (exists) {
      console.log('Transactions table verified.');
      return;
    }

    await connection.query(CREATE_TRANSACTIONS_TABLE);
    console.log('Transactions table created.');
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`Database bootstrap failed: ${message}`, { cause: err });
  } finally {
    if (connection) {
      connection.release();
    }
  }
}

module.exports = { bootstrapDatabase };
