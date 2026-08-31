interface StatusMessageProps {
  kind: 'error' | 'success' | 'status'
  children: string
}

const styles: Record<StatusMessageProps['kind'], string> = {
  error: 'border-rose-300/30 bg-rose-400/10 text-rose-100',
  success: 'border-emerald-300/30 bg-emerald-400/10 text-emerald-100',
  status: 'border-cyan-300/30 bg-cyan-400/10 text-cyan-100',
}

export function StatusMessage({ kind, children }: StatusMessageProps) {
  return (
    <p
      className={`rounded-xl border px-4 py-3 text-sm leading-6 ${styles[kind]}`}
      role={kind === 'error' ? 'alert' : 'status'}
      aria-live={kind === 'error' ? 'assertive' : 'polite'}
    >
      {children}
    </p>
  )
}
