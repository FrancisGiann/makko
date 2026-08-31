import type { PostgrestError, SupabaseClient } from '@supabase/supabase-js'

import { getSupabaseClient } from '../lib/supabase'
import type { Database } from '../types/database'
import type { ActivityLog } from '../types/domain'
import { requireId } from './validation'

const ACTIVITY_COLUMNS = 'id,project_id,issue_id,action,description,created_at'

export interface ActivityService {
  listProjectActivity: (projectId: string) => Promise<ActivityLog[]>
}

function toError(error: PostgrestError | null): Error {
  return new Error(error?.message || 'Unable to load project activity.')
}

export function createActivityService(client: SupabaseClient<Database>): ActivityService {
  return {
    async listProjectActivity(projectId) {
      const project = requireId(projectId, 'Project')
      const { data, error } = await client.from('activity_log')
        .select(ACTIVITY_COLUMNS)
        .eq('project_id', project)
        .order('created_at', { ascending: false })
      if (error) throw toError(error)
      return data ?? []
    },
  }
}

export function getActivityService(): ActivityService {
  return {
    listProjectActivity: (projectId) => createActivityService(getSupabaseClient()).listProjectActivity(projectId),
  }
}
