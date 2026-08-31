import { describe, expect, it } from 'vitest'

import { ConfigurationError, getPublicSupabaseConfig } from './config'

describe('public Supabase configuration', () => {
  it('rejects missing public configuration with an actionable message', () => {
    expect(() => getPublicSupabaseConfig({})).toThrowError(ConfigurationError)
    expect(() => getPublicSupabaseConfig({})).toThrow(/VITE_SUPABASE_URL/)
  })

  it('rejects malformed or unsafe project URLs', () => {
    expect(() => getPublicSupabaseConfig({
      VITE_SUPABASE_URL: 'http://supabase.example.com',
      VITE_SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_example',
    })).toThrow(/HTTPS Supabase project URL/)
    expect(() => getPublicSupabaseConfig({
      VITE_SUPABASE_URL: 'https://supabase.example.com/rest/v1',
      VITE_SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_example',
    })).toThrow(ConfigurationError)
  })

  it('allows a valid hosted URL and local development URL', () => {
    expect(getPublicSupabaseConfig({
      VITE_SUPABASE_URL: 'https://makko.supabase.co/',
      VITE_SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_example',
    })).toEqual({ url: 'https://makko.supabase.co', publishableKey: 'sb_publishable_example' })
    expect(getPublicSupabaseConfig({
      VITE_SUPABASE_URL: 'http://127.0.0.1:54321',
      VITE_SUPABASE_PUBLISHABLE_KEY: 'local-publishable-key',
    }).url).toBe('http://127.0.0.1:54321')
  })
})
