const express = require('express');
const cors = require('cors');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 4000;

const allowedOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map((o) => o.trim())
  : [];

app.use(
  cors({
    origin(origin, callback) {
      if (!origin || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
  })
);
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.get('/api/transactions', async (_req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, title, amount, type, category, date, created_at FROM transactions ORDER BY date DESC, created_at DESC'
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch transactions' });
  }
});

app.post('/api/transactions', async (req, res) => {
  const { title, amount, type, category, date } = req.body;

  if (!title || amount == null || !type || !date) {
    return res.status(400).json({ error: 'title, amount, type, and date are required' });
  }
  if (!['income', 'expense'].includes(type)) {
    return res.status(400).json({ error: 'type must be income or expense' });
  }

  try {
    const [result] = await db.query(
      'INSERT INTO transactions (title, amount, type, category, date) VALUES (?, ?, ?, ?, ?)',
      [title, amount, type, category || null, date]
    );
    const [rows] = await db.query(
      'SELECT id, title, amount, type, category, date, created_at FROM transactions WHERE id = ?',
      [result.insertId]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create transaction' });
  }
});

app.delete('/api/transactions/:id', async (req, res) => {
  try {
    const [result] = await db.query('DELETE FROM transactions WHERE id = ?', [req.params.id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Transaction not found' });
    }
    res.status(204).send();
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to delete transaction' });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`API server listening on 0.0.0.0:${PORT}`);
});
