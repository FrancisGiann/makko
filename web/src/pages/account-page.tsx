import { StatusMessage } from '../components/status-message'
import { useAuth } from '../features/auth/use-auth'
import { getDisplayName } from '../utils/display-name'

export function AccountPage() {
  const { state } = useAuth()

  return (
    <main className="makko-page">
      <section className="makko-surface-raised max-w-2xl rounded-3xl p-6 sm:p-10" aria-labelledby="account-heading">
        <h1 id="account-heading" className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-3xl">
          You’re in, {getDisplayName(state.session?.user)}.
        </h1>
        <p className="mt-3 max-w-xl text-base font-normal leading-7 text-slate-600 dark:text-slate-300">
          Your Makko account is ready. The rest of your command center will take shape here as you add your own work.
        </p>
        <div className="mt-8 border-t border-slate-100/80 pt-6 dark:border-white/[0.06]">
          <h2 className="text-sm font-semibold text-slate-900 dark:text-white">Account status</h2>
          <p className="mt-1 text-sm font-normal text-slate-600 dark:text-slate-400">Authenticated with Supabase and protected by your account session.</p>
          {state.error && <div className="mt-5"><StatusMessage kind="error">{state.error}</StatusMessage></div>}
        </div>
      </section>
    </main>
  )
}
