const API_BASE = (import.meta.env.VITE_API_URL || '').replace(/\/$/, '');

function apiUrl(path) {
  return `${API_BASE}${path}`;
}

export async function fetchTransactions() {
  const res = await fetch(apiUrl('/api/transactions'));
  if (!res.ok) throw new Error('Failed to fetch transactions');
  return res.json();
}

export async function createTransaction(data) {
  const res = await fetch(apiUrl('/api/transactions'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error('Failed to create transaction');
  return res.json();
}

export async function deleteTransaction(id) {
  const res = await fetch(apiUrl(`/api/transactions/${id}`), { method: 'DELETE' });
  if (!res.ok && res.status !== 204) throw new Error('Failed to delete transaction');
}
