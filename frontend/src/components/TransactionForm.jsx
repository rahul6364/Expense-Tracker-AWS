import { useState } from 'react';
import { Plus } from 'lucide-react';

const CATEGORIES = [
  'Salary',
  'Freelance',
  'Food',
  'Transport',
  'Shopping',
  'Bills',
  'Entertainment',
  'Health',
  'Other',
];

const initialForm = {
  title: '',
  amount: '',
  type: 'expense',
  category: 'Other',
  date: new Date().toISOString().split('T')[0],
};

export default function TransactionForm({ onSubmit }) {
  const [form, setForm] = useState(initialForm);
  const [submitting, setSubmitting] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.title.trim() || !form.amount) return;

    setSubmitting(true);
    try {
      await onSubmit({
        title: form.title.trim(),
        amount: parseFloat(form.amount),
        type: form.type,
        category: form.category,
        date: form.date,
      });
      setForm({ ...initialForm, date: new Date().toISOString().split('T')[0] });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="glass-card p-6 space-y-4">
      <h2 className="text-lg font-semibold text-white">Add Transaction</h2>

      <div>
        <label className="mb-1.5 block text-xs font-medium text-gray-400">Title</label>
        <input
          type="text"
          name="title"
          value={form.title}
          onChange={handleChange}
          placeholder="e.g. Grocery shopping"
          className="glass-input"
          required
        />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="mb-1.5 block text-xs font-medium text-gray-400">Amount</label>
          <input
            type="number"
            name="amount"
            value={form.amount}
            onChange={handleChange}
            placeholder="0.00"
            min="0.01"
            step="0.01"
            className="glass-input"
            required
          />
        </div>
        <div>
          <label className="mb-1.5 block text-xs font-medium text-gray-400">Type</label>
          <select name="type" value={form.type} onChange={handleChange} className="glass-input">
            <option value="expense">Expense</option>
            <option value="income">Income</option>
          </select>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="mb-1.5 block text-xs font-medium text-gray-400">Category</label>
          <select name="category" value={form.category} onChange={handleChange} className="glass-input">
            {CATEGORIES.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="mb-1.5 block text-xs font-medium text-gray-400">Date</label>
          <input
            type="date"
            name="date"
            value={form.date}
            onChange={handleChange}
            className="glass-input"
            required
          />
        </div>
      </div>

      <button type="submit" disabled={submitting} className="btn-primary flex w-full items-center justify-center gap-2">
        <Plus className="h-4 w-4" />
        {submitting ? 'Adding...' : 'Add Transaction'}
      </button>
    </form>
  );
}
