import type { ConfigurationError } from '../lib/config'

interface ConfigurationErrorProps {
  error: ConfigurationError
}

export function ConfigurationErrorView({ error }: ConfigurationErrorProps) {
  return (
    <main className="grid min-h-dvh place-items-center bg-[#f4f7fb] px-5 py-10 text-slate-900 dark:bg-[#070d18] dark:text-slate-100">
      <section className="makko-surface-raised w-full max-w-lg rounded-3xl border-amber-500/25 p-6 sm:p-8">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">Connect Makko to Supabase</h1>
        <p className="mt-3 text-sm leading-6 text-slate-600 dark:text-slate-300">{error.message}</p>
        <p className="makko-readable mt-5 rounded-2xl border border-slate-200 bg-slate-100 px-4 py-3 font-mono text-xs leading-6 text-slate-700 dark:border-white/10 dark:bg-slate-950/70 dark:text-slate-400">
          Copy web/.env.example to web/.env.local, add the project URL and publishable key, then restart Vite.
        </p>
      </section>
    </main>
  )
}
