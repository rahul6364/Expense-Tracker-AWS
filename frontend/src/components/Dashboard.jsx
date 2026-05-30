import { Wallet, TrendingUp, TrendingDown } from 'lucide-react';
import { formatCurrency } from '../utils/format';

const cards = [
  {
    key: 'balance',
    label: 'Total Balance',
    icon: Wallet,
    gradient: 'from-violet-500/20 to-purple-600/10',
    iconColor: 'text-violet-400',
    ring: 'ring-violet-500/20',
  },
  {
    key: 'income',
    label: 'Total Income',
    icon: TrendingUp,
    gradient: 'from-emerald-500/20 to-green-600/10',
    iconColor: 'text-emerald-400',
    ring: 'ring-emerald-500/20',
  },
  {
    key: 'expenses',
    label: 'Total Expenses',
    icon: TrendingDown,
    gradient: 'from-rose-500/20 to-red-600/10',
    iconColor: 'text-rose-400',
    ring: 'ring-rose-500/20',
  },
];

export default function Dashboard({ balance, income, expenses }) {
  const values = { balance, income, expenses };

  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
      {cards.map(({ key, label, icon: Icon, gradient, iconColor, ring }, i) => (
        <div
          key={key}
          className="glass-card p-6 animate-slide-up"
          style={{ animationDelay: `${i * 80}ms` }}
        >
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium text-gray-400">{label}</p>
              <p
                className={`mt-2 text-2xl font-bold tracking-tight ${
                  key === 'income'
                    ? 'text-emerald-400'
                    : key === 'expenses'
                      ? 'text-rose-400'
                      : 'text-white'
                }`}
              >
                {formatCurrency(values[key])}
              </p>
            </div>
            <div className={`rounded-xl bg-gradient-to-br ${gradient} p-3 ring-1 ${ring}`}>
              <Icon className={`h-5 w-5 ${iconColor}`} />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
