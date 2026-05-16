import { useState, useEffect, useMemo, useCallback } from 'react';
import { Sparkles, AlertCircle } from 'lucide-react';
import Dashboard from './components/Dashboard';
import TransactionForm from './components/TransactionForm';
import TransactionList from './components/TransactionList';
import SpendingChart from './components/SpendingChart';
import { fetchTransactions, createTransaction, deleteTransaction } from './utils/api';
import { getLast6MonthsSpending } from './utils/format';

export default function App() {
  const [transactions, setTransactions] = useState([]);
  const [filter, setFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const loadTransactions = useCallback(async () => {
    try {
      setError(null);
      const data = await fetchTransactions();
      setTransactions(data);
    } catch {
      setError('Could not connect to the server. Make sure the API is running.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadTransactions();
  }, [loadTransactions]);

  const { income, expenses, balance } = useMemo(() => {
    const income = transactions
      .filter((t) => t.type === 'income')
      .reduce((sum, t) => sum + Number(t.amount), 0);
    const expenses = transactions
      .filter((t) => t.type === 'expense')
      .reduce((sum, t) => sum + Number(t.amount), 0);
    return { income, expenses, balance: income - expenses };
  }, [transactions]);

  const filtered = useMemo(
    () => (filter === 'all' ? transactions : transactions.filter((t) => t.type === filter)),
    [transactions, filter]
  );

  const chartData = useMemo(() => getLast6MonthsSpending(transactions), [transactions]);

  const handleAdd = async (data) => {
    const created = await createTransaction(data);
    setTransactions((prev) => [created, ...prev]);
  };

  const handleDelete = async (id) => {
    await deleteTransaction(id);
    setTransactions((prev) => prev.filter((t) => t.id !== id));
  };

  return (
    <div className="min-h-screen">
      <header className="border-b border-white/5 bg-white/[0.02] backdrop-blur-md">
        <div className="mx-auto flex max-w-6xl items-center gap-3 px-4 py-5 sm:px-6">
          <div className="rounded-xl bg-gradient-to-br from-accent/30 to-violet-600/20 p-2.5 ring-1 ring-accent/30">
            <Sparkles className="h-5 w-5 text-accent-glow" />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-tight text-white">Expense Tracker</h1>
            <p className="text-xs text-gray-500">Manage your finances with clarity</p>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-6xl px-4 py-8 sm:px-6 animate-fade-in">
        {error && (
          <div className="mb-6 flex items-center gap-3 rounded-xl border border-amber-500/20 bg-amber-500/10 px-4 py-3 text-sm text-amber-200">
            <AlertCircle className="h-4 w-4 shrink-0" />
            {error}
          </div>
        )}

        {loading ? (
          <div className="flex h-64 items-center justify-center">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-accent/30 border-t-accent" />
          </div>
        ) : (
          <div className="space-y-6">
            <Dashboard balance={balance} income={income} expenses={expenses} />

            <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
              <div className="lg:col-span-1">
                <TransactionForm onSubmit={handleAdd} />
              </div>
              <div className="lg:col-span-2 space-y-6">
                <SpendingChart data={chartData} />
                <TransactionList
                  transactions={filtered}
                  filter={filter}
                  onFilterChange={setFilter}
                  onDelete={handleDelete}
                />
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
