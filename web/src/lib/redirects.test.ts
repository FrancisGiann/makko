import { describe, expect, it } from 'vitest'

import { getRedirectFromState, getSafeRedirectPath } from './redirects'

describe('safe authentication redirects', () => {
  it('preserves an internal path, query, and hash', () => {
    expect(getSafeRedirectPath('/app/dashboard?view=work#open')).toBe('/app/dashboard?view=work#open')
    expect(getRedirectFromState({ from: '/app/projects/project-1' })).toBe('/app/projects/project-1')
  })

  it('falls back for external, protocol-relative, and malformed candidates', () => {
    expect(getSafeRedirectPath('https://evil.example/phish')).toBe('/app')
    expect(getSafeRedirectPath('//evil.example/phish')).toBe('/app')
    expect(getRedirectFromState({ from: 42 })).toBe('/app')
    expect(getRedirectFromState(null)).toBe('/app')
  })
})
