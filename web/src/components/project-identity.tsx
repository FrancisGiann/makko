import type { CSSProperties } from 'react'

interface ProjectIdentityProps {
  name: string
  tags?: readonly string[]
  size?: 'sm' | 'md'
}

function getInitials(name: string, tags: readonly string[]): string {
  const words = name.trim().split(/\s+/).filter(Boolean)
  if (words.length >= 2) return `${Array.from(words[0]).at(0) ?? ''}${Array.from(words[words.length - 1]).at(0) ?? ''}`.toUpperCase()
  if (words[0]) return Array.from(words[0]).slice(0, 2).join('').toUpperCase()

  const tag = tags.find((value) => value.trim())?.trim() ?? ''
  return tag ? Array.from(tag).slice(0, 2).join('').toUpperCase() : 'P'
}

function getCurrentOffset(name: string, tags: readonly string[]): number {
  const signature = `${name}\u0000${tags.join('\u0000')}`
  return [...signature].reduce((sum, character) => sum + character.charCodeAt(0), 0) % 4
}

export function ProjectIdentity({ name, tags = [], size = 'md' }: ProjectIdentityProps) {
  const initials = getInitials(name, tags)
  const offset = getCurrentOffset(name, tags)
  const sizeClasses = size === 'sm' ? 'size-11 text-xs' : 'size-14 text-sm'
  const lineWidth = 18 + offset * 5

  return (
    <span
      role="img"
      aria-label={`${name || 'Project'} project identity`}
      className={`relative inline-grid shrink-0 place-items-center overflow-hidden rounded-2xl border border-cyan-500/25 bg-cyan-500/[0.08] font-semibold tracking-[0.08em] text-cyan-800 dark:border-cyan-400/25 dark:bg-cyan-400/[0.08] dark:text-cyan-200 ${sizeClasses}`}
    >
      <span aria-hidden="true">{initials}</span>
      <span
        aria-hidden="true"
        className="absolute bottom-1.5 left-1/2 h-px -translate-x-1/2 bg-cyan-500 dark:bg-cyan-300"
        style={{ width: `${lineWidth}%` } as CSSProperties}
      />
    </span>
  )
}
