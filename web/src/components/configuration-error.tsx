import type { ConfigurationError } from '../lib/config'

interface ConfigurationErrorProps {
  error: ConfigurationError
}

export function ConfigurationErrorView({ error }: ConfigurationErrorProps) {
  return (
    <main className="grid min-h-screen place-items-center bg-slate-950 px-6 py-12 text-slate-100">
      <section className="w-full max-w-lg rounded-3xl border border-amber-200/20 bg-slate-900/80 p-8 shadow-2xl shadow-cyan-950/20">
        <p className="mb-3 text-xs font-semibold uppercase tracking-[0.2em] text-amber-200">Setup needed</p>
        <h1 className="text-2xl font-semibold tracking-tight">Connect Makko to Supabase</h1>
        <p className="mt-3 text-sm leading-6 text-slate-300">{error.message}</p>
        <p className="mt-5 rounded-xl bg-slate-950/70 px-4 py-3 font-mono text-xs leading-6 text-slate-400">
          Copy web/.env.example to web/.env.local, add the project URL and publishable key, then restart Vite.
        </p>
      </section>
    </main>
  )
}
