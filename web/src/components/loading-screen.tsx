export function LoadingScreen() {
  return (
    <main className="grid min-h-dvh place-items-center bg-[#f4f7fb] px-6 text-slate-900 transition-colors dark:bg-[#070d18] dark:text-slate-100">
      <div className="text-center" role="status" aria-live="polite">
        <div className="mx-auto mb-5 size-12 animate-spin rounded-full border-3 border-cyan-500/20 border-t-cyan-600 dark:border-cyan-400/20 dark:border-t-cyan-300" />
        <p className="text-sm font-semibold text-slate-600 dark:text-slate-300">Restoring your Makko session…</p>
      </div>
    </main>
  )
}
