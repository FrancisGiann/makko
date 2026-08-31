import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it } from 'vitest'

import { THEME_STORAGE_KEY, ThemeProvider, useTheme } from './theme-context'

function ThemeProbe() {
  const { theme, toggleTheme } = useTheme()
  return <button type="button" onClick={toggleTheme}>{theme}</button>
}

describe('theme context', () => {
  beforeEach(() => {
    localStorage.clear()
    document.documentElement.removeAttribute('data-theme')
    document.documentElement.style.colorScheme = ''
  })

  it('defaults to dark without a stored preference and persists a toggle', async () => {
    const user = userEvent.setup()
    render(<ThemeProvider><ThemeProbe /></ThemeProvider>)

    expect(screen.getByRole('button')).toHaveTextContent('dark')
    await user.click(screen.getByRole('button'))

    expect(screen.getByRole('button')).toHaveTextContent('light')
    expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('light')
    expect(document.documentElement).toHaveAttribute('data-theme', 'light')
    expect(document.documentElement.style.colorScheme).toBe('light')
  })

  it('restores a persisted light preference', () => {
    localStorage.setItem(THEME_STORAGE_KEY, 'light')
    render(<ThemeProvider><ThemeProbe /></ThemeProvider>)
    expect(screen.getByRole('button')).toHaveTextContent('light')
  })
})
