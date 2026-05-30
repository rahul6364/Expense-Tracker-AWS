import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { BarChart3 } from 'lucide-react';
import { formatCurrency } from '../utils/format';

function CustomTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-lg border border-white/10 bg-surface-raised/95 px-3 py-2 shadow-glass backdrop-blur-xl">
      <p className="text-xs text-gray-400">{label}</p>
      <p className="text-sm font-semibold text-rose-400">{formatCurrency(payload[0].value)}</p>
    </div>
  );
}

export default function SpendingChart({ data }) {
  const hasData = data.some((d) => d.spending > 0);

  return (
    <section className="glass-card p-6">
      <div className="mb-6 flex items-center gap-2">
        <BarChart3 className="h-5 w-5 text-accent" />
        <h2 className="text-lg font-semibold text-white">6-Month Spending</h2>
      </div>

      {!hasData ? (
        <div className="flex h-48 items-center justify-center text-sm text-gray-500">
          No expense data for the chart yet
        </div>
      ) : (
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={data} margin={{ top: 4, right: 4, left: -16, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.06)" vertical={false} />
            <XAxis
              dataKey="month"
              tick={{ fill: '#9ca3af', fontSize: 12 }}
              axisLine={false}
              tickLine={false}
            />
            <YAxis
              tick={{ fill: '#9ca3af', fontSize: 12 }}
              axisLine={false}
              tickLine={false}
              tickFormatter={(v) => `$${v}`}
            />
            <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(139, 92, 246, 0.08)' }} />
            <Bar
              dataKey="spending"
              fill="url(#barGradient)"
              radius={[6, 6, 0, 0]}
              maxBarSize={48}
            />
            <defs>
              <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#f43f5e" />
                <stop offset="100%" stopColor="#be123c" />
              </linearGradient>
            </defs>
          </BarChart>
        </ResponsiveContainer>
      )}
    </section>
  );
}
