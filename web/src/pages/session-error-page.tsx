import { StatusMessage } from '../components/status-message'
import { useAuth } from '../features/auth/use-auth'

export function SessionErrorPage() {
  const { state, retrySession } = useAuth()

  return (
    <main className="grid min-h-screen place-items-center bg-slate-950 px-6 text-slate-100">
      <section className="w-full max-w-lg rounded-3xl border border-rose-200/20 bg-slate-900/80 p-8">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-rose-200">Session unavailable</p>
        <h1 className="mt-3 text-2xl font-semibold tracking-tight">We couldn’t restore your session.</h1>
        <div className="mt-5"><StatusMessage kind="error">{state.error ?? 'Please try again.'}</StatusMessage></div>
        <button
          type="button"
          onClick={() => void retrySession()}
          className="mt-6 rounded-xl bg-cyan-200 px-5 py-3 text-sm font-semibold text-slate-950 transition hover:bg-cyan-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-100"
        >
          Try again
        </button>
      </section>
    </main>
  )
}
