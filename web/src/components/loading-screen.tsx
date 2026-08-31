export function LoadingScreen() {
  return (
    <main className="grid min-h-screen place-items-center bg-slate-950 px-6 text-slate-100">
      <div className="text-center" role="status" aria-live="polite">
        <div className="mx-auto mb-5 size-10 animate-pulse rounded-full border-2 border-cyan-200/30 border-t-cyan-200" />
        <p className="text-sm text-slate-300">Restoring your Makko session…</p>
      </div>
    </main>
  )
}
