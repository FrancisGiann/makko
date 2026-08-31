interface MakkoMarkProps {
  compact?: boolean
}

export function MakkoMark({ compact = false }: MakkoMarkProps) {
  return (
    <span className="inline-flex items-center gap-3" aria-label="Makko">
      <span
        className="grid size-10 place-items-center rounded-2xl border border-cyan-200/30 bg-cyan-300/10 text-lg text-cyan-200 shadow-[0_0_30px_rgba(34,211,238,0.12)]"
        aria-hidden="true"
      >
        ◒
      </span>
      {!compact && <span className="text-lg font-semibold tracking-tight text-white">makko</span>}
    </span>
  )
}
