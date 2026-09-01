import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'

import { getSupabaseClient } from '../lib/supabase'
import type { Database } from '../types/database'
import type { ActivityLog } from '../types/domain'
import { requireId } from './validation'

const ACTIVITY_COLUMNS = 'id,project_id,issue_id,action,description,created_at'
export const ACTIVITY_PAGE_SIZE = 30
const ACTIVITY_LOOKBACK_DAYS = 30

export type ActivityScope = 'last_30_days' | 'all_time'

export interface ActivityListOptions {
  scope?: ActivityScope
  page?: number
}

export interface ActivityPage {
  items: ActivityLog[]
  page: number
  pageSize: number
  hasMore: boolean
}

export interface ActivityService {
  listProjectActivity: (projectId: string, options?: ActivityListOptions) => Promise<ActivityPage>
}

function toError(error: PostgrestError | null): Error {
  return new Error(error?.message || 'Unable to load project activity.')
}

export function createActivityService(client: SupabaseClient<Database>): ActivityService {
  return {
    async listProjectActivity(projectId, options = {}) {
      const project = requireId(projectId, 'Project')
      const scope = options.scope ?? 'last_30_days'
      if (scope !== 'last_30_days' && scope !== 'all_time') {
        throw new Error('Activity scope is invalid.')
      }
      const page = options.page ?? 1
      if (!Number.isInteger(page) || page < 1 || page > 10000) {
        throw new Error('Activity page is invalid.')
      }

      let query = client.from('activity_log')
        .select(ACTIVITY_COLUMNS)
        .eq('project_id', project)
      if (scope === 'last_30_days') {
        const cutoff = new Date(Date.now() - ACTIVITY_LOOKBACK_DAYS * 24 * 60 * 60 * 1000).toISOString()
        query = query.gte('created_at', cutoff)
      }
      const { data, error } = await query
        .order('created_at', { ascending: false })
        .order('id', { ascending: false })
        // PostgREST ranges are inclusive. Request one sentinel row to expose hasMore
        // while returning exactly ACTIVITY_PAGE_SIZE rows to the caller.
        .range((page - 1) * ACTIVITY_PAGE_SIZE, page * ACTIVITY_PAGE_SIZE)
      if (error) throw toError(error)
      const rows = data ?? []
      return {
        items: rows.slice(0, ACTIVITY_PAGE_SIZE),
        page,
        pageSize: ACTIVITY_PAGE_SIZE,
        hasMore: rows.length > ACTIVITY_PAGE_SIZE,
      }
    },
  }
}

export function getActivityService(): ActivityService {
  return {
    listProjectActivity: (projectId, options) => createActivityService(getSupabaseClient()).listProjectActivity(projectId, options),
  }
}
