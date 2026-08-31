import { createClient, type SupabaseClient } from '@supabase/supabase-js'

import { getPublicSupabaseConfig } from './config'

let browserClient: SupabaseClient | null = null

export function getSupabaseClient(): SupabaseClient {
  if (browserClient) return browserClient

  const config = getPublicSupabaseConfig()
  browserClient = createClient(config.url, config.publishableKey, {
    auth: {
      autoRefreshToken: true,
      detectSessionInUrl: true,
      persistSession: true,
    },
  })

  return browserClient
}
