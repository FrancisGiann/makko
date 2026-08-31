import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'

export type Theme = 'light' | 'dark'
export type ThemePreference = Theme | 'system'

interface ThemeContextValue {
  theme: Theme
  preference: ThemePreference
  toggleTheme: () => void
}

const THEME_STORAGE_KEY = 'makko-theme'
const ThemeContext = createContext<ThemeContextValue | null>(null)

function systemTheme(): Theme {
  return typeof window !== 'undefined' && typeof window.matchMedia === 'function' && window.matchMedia('(prefers-color-scheme: light)').matches
    ? 'light'
    : 'dark'
}

function storedPreference(): ThemePreference {
  if (typeof window === 'undefined') return 'system'
  try {
    const value = window.localStorage.getItem(THEME_STORAGE_KEY)
    return value === 'light' || value === 'dark' ? value : 'system'
  } catch {
    return 'system'
  }
}

function applyTheme(theme: Theme) {
  if (typeof document === 'undefined') return
  document.documentElement.dataset.theme = theme
  document.documentElement.style.colorScheme = theme
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [preference, setPreference] = useState<ThemePreference>(storedPreference)
  const [theme, setTheme] = useState<Theme>(() => {
    const preference = storedPreference()
    return preference === 'system' ? systemTheme() : preference
  })

  useEffect(() => {
    const media = typeof window !== 'undefined' && typeof window.matchMedia === 'function'
      ? window.matchMedia('(prefers-color-scheme: light)')
      : null
    const updateSystemTheme = (event?: MediaQueryListEvent) => {
      if (preference === 'system') setTheme(event?.matches ? 'light' : media?.matches ? 'light' : 'dark')
    }
    updateSystemTheme()
    if (media) {
      media.addEventListener?.('change', updateSystemTheme)
      return () => media.removeEventListener?.('change', updateSystemTheme)
    }
  }, [preference])

  useEffect(() => { applyTheme(theme) }, [theme])

  const value = useMemo<ThemeContextValue>(() => ({
    theme,
    preference,
    toggleTheme: () => {
      const nextTheme: Theme = theme === 'dark' ? 'light' : 'dark'
      setPreference(nextTheme)
      setTheme(nextTheme)
      try { window.localStorage.setItem(THEME_STORAGE_KEY, nextTheme) } catch { /* private browsing can deny storage */ }
    },
  }), [preference, theme])

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
}

// The hook intentionally lives beside its provider to keep the public theme API small.
// eslint-disable-next-line react-refresh/only-export-components
export function useTheme(): ThemeContextValue {
  const context = useContext(ThemeContext)
  if (!context) throw new Error('useTheme must be used within ThemeProvider')
  return context
}

export { THEME_STORAGE_KEY }
