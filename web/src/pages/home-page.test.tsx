import { render, screen, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it } from 'vitest'

import { HomePage } from './home-page'

describe('HomePage', () => {
  it('shows an illustrative command center preview using Makko concepts', () => {
    render(<MemoryRouter><HomePage /></MemoryRouter>)

    expect(screen.getByRole('heading', { name: 'Keep every side project moving.' })).toBeInTheDocument()
    const hero = screen.getByRole('region', { name: 'Keep every side project moving.' })
    const preview = screen.getByRole('complementary', { name: 'Illustrative Makko command center preview' })
    expect(preview).toBeInTheDocument()
    expect(within(preview).getAllByText('Projects')).toHaveLength(2)
    expect(within(preview).getByText('Internal issues')).toBeInTheDocument()
    expect(within(preview).getByText('GitHub activity')).toBeInTheDocument()
    expect(within(preview).getByText(/External · read-only/)).toBeInTheDocument()
    expect(within(hero).getByRole('link', { name: 'Create your workspace' })).toHaveAttribute('href', '/signup')
    expect(within(hero).getByRole('link', { name: 'Sign in' })).toHaveAttribute('href', '/login')

    expect(screen.getByRole('heading', { name: 'Everything around a build, in one current.' })).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'A project has a shape, not just a title.' })).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'GitHub stays on its own current.' })).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Built for one builder’s line of sight.' })).toBeInTheDocument()
    expect(screen.getByText('Commits and open GitHub issues are external, read-only context. They never affect internal Makko dashboard statistics.')).toBeInTheDocument()

    const finalCta = screen.getByRole('region', { name: 'Make room for the next step.' })
    expect(within(finalCta).getByRole('link', { name: /Create your workspace/ })).toHaveAttribute('href', '/signup')
    expect(within(finalCta).getByRole('link', { name: 'Sign in' })).toHaveAttribute('href', '/login')
  })
})
