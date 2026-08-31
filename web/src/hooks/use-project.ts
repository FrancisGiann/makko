import { useCallback, useEffect, useState } from 'react'

import { useAuth } from '../features/auth/use-auth'
import { getProjectService, type ProjectService } from '../services/project.service'
import type { Project, ProjectInput } from '../types/domain'
import type { ResourceStatus } from './use-projects'

function getErrorMessage(error: unknown, fallback: string): string {
  return error instanceof Error && error.message ? error.message : fallback
}

export function useProject(projectId: string | undefined, service?: ProjectService) {
  const { state: authState } = useAuth()
  const ownerId = authState.session?.user.id ?? null
  const [projectService] = useState<ProjectService>(() => service ?? getProjectService())
  const [project, setProject] = useState<Project | null>(null)
  const [status, setStatus] = useState<ResourceStatus>('loading')
  const [error, setError] = useState<string | null>(null)
  const [isMutating, setIsMutating] = useState(false)

  const refresh = useCallback(async () => {
    if (!ownerId || !projectId) {
      setProject(null)
      setStatus('ready')
      setError(null)
      return
    }
    setStatus('loading')
    setError(null)
    try {
      setProject(await projectService.getProject(ownerId, projectId))
      setStatus('ready')
    } catch (caught) {
      setStatus('error')
      setError(getErrorMessage(caught, 'Unable to load that project.'))
    }
  }, [ownerId, projectId, projectService])

  useEffect(() => { void refresh() }, [refresh])

  const updateProject = async (input: ProjectInput): Promise<Project | null> => {
    if (!ownerId || !projectId) return null
    setIsMutating(true)
    setError(null)
    try {
      const updated = await projectService.updateProject(ownerId, projectId, input)
      setProject(updated)
      await refresh()
      return updated
    } catch (caught) {
      setError(getErrorMessage(caught, 'Unable to update the project.'))
      return null
    } finally {
      setIsMutating(false)
    }
  }

  const deleteProject = async (): Promise<boolean> => {
    if (!ownerId || !projectId) return false
    setIsMutating(true)
    setError(null)
    try {
      await projectService.deleteProject(ownerId, projectId)
      setProject(null)
      return true
    } catch (caught) {
      setError(getErrorMessage(caught, 'Unable to delete the project.'))
      return false
    } finally {
      setIsMutating(false)
    }
  }

  return { project, status, error, isMutating, refresh, updateProject, deleteProject }
}
