import { Trash2, Receipt } from 'lucide-react';
import { formatCurrency, formatDate } from '../utils/format';

const FILTERS = [
  { value: 'all', label: 'All' },
  { value: 'income', label: 'Income' },
  { value: 'expense', label: 'Expense' },
];

export default function TransactionList({ transactions, filter, onFilterChange, onDelete }) {
  return (
    <section className="glass-card p-6">
      <div className="mb-5 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <h2 className="text-lg font-semibold text-white">Transactions</h2>
        <div className="flex gap-1 rounded-xl bg-white/5 p-1">
          {FILTERS.map(({ value, label }) => (
            <button
              key={value}
              type="button"
              onClick={() => onFilterChange(value)}
              className={`filter-btn ${
                filter === value ? 'filter-btn-active' : 'filter-btn-inactive'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {transactions.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-12 text-gray-500">
          <Receipt className="mb-3 h-10 w-10 opacity-40" />
          <p className="text-sm">No transactions yet</p>
        </div>
      ) : (
        <ul className="space-y-2 max-h-[420px] overflow-y-auto pr-1 custom-scrollbar">
          {transactions.map((tx) => (
            <li
              key={tx.id}
              className="group flex items-center gap-4 rounded-xl border border-white/5 bg-white/[0.03] px-4 py-3 transition-all duration-200 hover:border-white/10 hover:bg-white/[0.06]"
            >
              <div className="min-w-0 flex-1">
                <p className="truncate font-medium text-gray-100">{tx.title}</p>
                <div className="mt-1 flex flex-wrap items-center gap-2 text-xs text-gray-500">
                  <span>{formatDate(tx.date)}</span>
                  {tx.category && (
                    <>
                      <span className="text-gray-600">·</span>
                      <span>{tx.category}</span>
                    </>
                  )}
                </div>
              </div>

              <span
                className={`shrink-0 rounded-full px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wide ${
                  tx.type === 'income'
                    ? 'bg-emerald-500/15 text-emerald-400 ring-1 ring-emerald-500/30'
                    : 'bg-rose-500/15 text-rose-400 ring-1 ring-rose-500/30'
                }`}
              >
                {tx.type}
              </span>

              <span
                className={`shrink-0 font-semibold tabular-nums ${
                  tx.type === 'income' ? 'text-emerald-400' : 'text-rose-400'
                }`}
              >
                {tx.type === 'income' ? '+' : '-'}
                {formatCurrency(tx.amount)}
              </span>

              <button
                type="button"
                onClick={() => onDelete(tx.id)}
                className="shrink-0 rounded-lg p-2 text-gray-500 opacity-0 transition-all duration-200 hover:bg-rose-500/10 hover:text-rose-400 group-hover:opacity-100"
                aria-label="Delete transaction"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
