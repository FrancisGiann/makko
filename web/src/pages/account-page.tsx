import { StatusMessage } from '../components/status-message'
import { useAuth } from '../features/auth/use-auth'

export function AccountPage() {
  const { state } = useAuth()

  return (
    <main className="mx-auto max-w-6xl px-5 py-12 sm:px-8 sm:py-16">
      <section className="max-w-2xl rounded-3xl border border-white/10 bg-slate-900/70 p-6 shadow-2xl shadow-cyan-950/10 sm:p-10" aria-labelledby="account-heading">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-cyan-200">Private workspace</p>
        <h1 id="account-heading" className="mt-4 text-3xl font-semibold tracking-tight text-white">You’re in, {state.session?.user.email ?? 'builder'}.</h1>
        <p className="mt-4 max-w-xl text-base leading-7 text-slate-300">
          Your Makko account is ready. The rest of your command center will take shape here as you add your own work.
        </p>
        <div className="mt-8 border-t border-white/10 pt-6">
          <h2 className="text-sm font-semibold text-white">Account status</h2>
          <p className="mt-2 text-sm text-slate-400">Authenticated with Supabase and protected by your account session.</p>
          {state.error && <div className="mt-5"><StatusMessage kind="error">{state.error}</StatusMessage></div>}
        </div>
      </section>
    </main>
  )
}
