import { AlertCircle, CheckCircle2, Info } from 'lucide-react'

interface StatusMessageProps {
  kind: 'error' | 'success' | 'status'
  children: string
}

const styles: Record<StatusMessageProps['kind'], { container: string; icon: string }> = {
  error: {
    container: 'border-rose-500/30 bg-rose-500/10 text-rose-800 dark:border-rose-400/25 dark:bg-rose-950/40 dark:text-rose-200 shadow-xs',
    icon: 'text-rose-600 dark:text-rose-400',
  },
  success: {
    container: 'border-emerald-500/30 bg-emerald-500/10 text-emerald-800 dark:border-emerald-400/25 dark:bg-emerald-950/40 dark:text-emerald-200 shadow-xs',
    icon: 'text-emerald-600 dark:text-emerald-400',
  },
  status: {
    container: 'border-cyan-500/30 bg-cyan-500/10 text-cyan-800 dark:border-cyan-400/25 dark:bg-cyan-950/40 dark:text-cyan-200 shadow-xs',
    icon: 'text-cyan-600 dark:text-cyan-400',
  },
}

export function StatusMessage({ kind, children }: StatusMessageProps) {
  const current = styles[kind]
  return (
    <p
      className={`flex min-h-11 items-center gap-2.5 rounded-2xl border px-4 py-3 text-sm leading-6 font-normal transition-all ${current.container}`}
      role={kind === 'error' ? 'alert' : 'status'}
      aria-live={kind === 'error' ? 'assertive' : 'polite'}
    >
      <span className={`shrink-0 ${current.icon}`} aria-hidden="true">
        {kind === 'error' ? (
          <AlertCircle className="size-4" />
        ) : kind === 'success' ? (
          <CheckCircle2 className="size-4" />
        ) : (
          <Info className="size-4" />
        )}
      </span>
      <span>{children}</span>
    </p>
  )
}
