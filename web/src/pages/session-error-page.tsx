import { StatusMessage } from '../components/status-message'
import { useAuth } from '../features/auth/use-auth'

export function SessionErrorPage() {
  const { state, retrySession } = useAuth()

  return (
    <main className="grid min-h-dvh place-items-center bg-[#f4f7fb] px-5 py-10 text-slate-900 transition-colors dark:bg-[#070d18] dark:text-slate-100">
      <section className="makko-surface-raised w-full max-w-lg rounded-3xl border-rose-500/30 p-6 sm:p-8">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">We couldn’t restore your session.</h1>
        <div className="mt-5"><StatusMessage kind="error">{state.error ?? 'Please try again.'}</StatusMessage></div>
        <button
          type="button"
          onClick={() => void retrySession()}
          className="makko-control makko-primary makko-focus mt-6 w-full px-5 text-sm font-semibold"
        >
          Try again
        </button>
      </section>
    </main>
  )
}
