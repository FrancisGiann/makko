import { createClient, type SupabaseClient } from '@supabase/supabase-js'

import { getPublicSupabaseConfig } from './config'
import type { Database } from '../types/database'

let browserClient: SupabaseClient<Database> | null = null

export function getSupabaseClient(): SupabaseClient<Database> {
  if (browserClient) return browserClient

  const config = getPublicSupabaseConfig()
  browserClient = createClient<Database>(config.url, config.publishableKey, {
    auth: {
      autoRefreshToken: true,
      detectSessionInUrl: true,
      persistSession: true,
    },
  })

  return browserClient
}
