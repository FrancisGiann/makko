import type { PostgrestError } from '@supabase/supabase-js'
import type { SupabaseClient } from '@supabase/supabase-js'

import { getSupabaseClient } from '../lib/supabase'
import type { Database } from '../types/database'
import type { Project, ProjectInput } from '../types/domain'
import { normalizeProjectInput, requireId } from './validation'

const PROJECT_COLUMNS = 'id,owner_id,name,description,tags,created_at,updated_at'

export interface ProjectService {
  listProjects: (ownerId: string) => Promise<Project[]>
  getProject: (ownerId: string, projectId: string) => Promise<Project | null>
  createProject: (ownerId: string, input: ProjectInput) => Promise<Project>
  updateProject: (ownerId: string, projectId: string, input: ProjectInput) => Promise<Project>
  deleteProject: (ownerId: string, projectId: string) => Promise<void>
}

function toError(error: PostgrestError | null, fallback: string): Error {
  return new Error(error?.message || fallback)
}

function requireOwner(ownerId: string): string {
  return requireId(ownerId, 'Owner')
}

async function readProjectList(
  request: PromiseLike<{ data: Project[] | null; error: PostgrestError | null }>,
): Promise<Project[]> {
  const { data, error } = await request
  if (error) throw toError(error, 'Unable to load projects.')
  return data ?? []
}

async function readProject(
  request: PromiseLike<{ data: Project | null; error: PostgrestError | null }>,
  fallback: string,
): Promise<Project | null> {
  const { data, error } = await request
  if (error) throw toError(error, fallback)
  return data
}

export function createProjectService(client: SupabaseClient<Database>): ProjectService {
  return {
    async listProjects(ownerId) {
      const owner = requireOwner(ownerId)
      return readProjectList(
        client.from('projects')
          .select(PROJECT_COLUMNS)
          .eq('owner_id', owner)
          .order('updated_at', { ascending: false }),
      )
    },

    async getProject(ownerId, projectId) {
      const owner = requireOwner(ownerId)
      const id = requireId(projectId, 'Project')
      return readProject(
        client.from('projects')
          .select(PROJECT_COLUMNS)
          .eq('id', id)
          .eq('owner_id', owner)
          .maybeSingle(),
        'Unable to load that project.',
      )
    },

    async createProject(ownerId, input) {
      const owner = requireOwner(ownerId)
      const normalized = normalizeProjectInput(input)
      const { data, error } = await client.from('projects')
        .insert({
          owner_id: owner,
          name: normalized.name,
          description: normalized.description || null,
          tags: normalized.tags,
        })
        .select(PROJECT_COLUMNS)
        .single()
      if (error) throw toError(error, 'Unable to create the project.')
      if (!data) throw new Error('Project creation did not return a project.')
      return data
    },

    async updateProject(ownerId, projectId, input) {
      const owner = requireOwner(ownerId)
      const id = requireId(projectId, 'Project')
      const normalized = normalizeProjectInput(input)
      const { data, error } = await client.from('projects')
        .update({
          name: normalized.name,
          description: normalized.description || null,
          tags: normalized.tags,
        })
        .eq('id', id)
        .eq('owner_id', owner)
        .select(PROJECT_COLUMNS)
        .single()
      if (error) throw toError(error, 'Unable to update the project.')
      if (!data) throw new Error('Project update did not return a project.')
      return data
    },

    async deleteProject(ownerId, projectId) {
      const owner = requireOwner(ownerId)
      const id = requireId(projectId, 'Project')
      const { error } = await client.from('projects')
        .delete()
        .eq('id', id)
        .eq('owner_id', owner)
        .select('id')
        .single()
      if (error) throw toError(error, 'Unable to delete the project.')
    },
  }
}

export function getProjectService(): ProjectService {
  return {
    listProjects: (ownerId) => createProjectService(getSupabaseClient()).listProjects(ownerId),
    getProject: (ownerId, projectId) => createProjectService(getSupabaseClient()).getProject(ownerId, projectId),
    createProject: (ownerId, input) => createProjectService(getSupabaseClient()).createProject(ownerId, input),
    updateProject: (ownerId, projectId, input) => createProjectService(getSupabaseClient()).updateProject(ownerId, projectId, input),
    deleteProject: (ownerId, projectId) => createProjectService(getSupabaseClient()).deleteProject(ownerId, projectId),
  }
}
