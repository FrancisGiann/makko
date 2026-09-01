import { Link } from 'react-router-dom'

export function NotFoundPage() {
  return (
    <main className="grid min-h-[70dvh] place-items-center px-5 py-16 text-center sm:px-8">
      <section>
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white sm:text-4xl">That page isn’t in the current.</h1>
        <p className="mx-auto mt-3 max-w-md text-sm font-normal leading-7 text-slate-600 dark:text-slate-400">The link may be old, or the page may have moved.</p>
        <Link
          to="/"
          className="makko-control makko-primary makko-focus mt-8 inline-flex items-center gap-2 px-6 text-sm font-semibold"
        >
          Return home
        </Link>
      </section>
    </main>
  )
}
