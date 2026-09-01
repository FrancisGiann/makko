interface MakkoMarkProps {
  compact?: boolean
}

export function MakkoMark({ compact = false }: MakkoMarkProps) {
  return (
    <span className="inline-flex items-center gap-2.5" aria-label="Makko">
      <span
        className="relative grid size-9 place-items-center overflow-hidden rounded-2xl border border-cyan-500/30 bg-cyan-500/10 shadow-sm shadow-cyan-500/10 ring-2 ring-cyan-400/20 transition-transform duration-200 hover:scale-105 dark:border-cyan-400/30 dark:bg-cyan-400/10"
        aria-hidden="true"
      >
        <img src="/makko-pet.png" alt="" width={32} height={32} className="size-8 object-contain" />
      </span>
      {!compact && (
        <span className="flex items-center gap-1.5 text-xl font-bold tracking-tight text-slate-900 dark:text-white">
          <span>makko</span>
          <span className="size-1.5 rounded-full bg-cyan-500" aria-hidden="true" />
        </span>
      )}
    </span>
  )
}
