import { useCallback, useEffect, useState } from 'react'

import { useAuth } from '../features/auth/use-auth'
import { getProjectService, type ProjectService } from '../services/project.service'
import type { Project, ProjectInput } from '../types/domain'

export type ResourceStatus = 'loading' | 'ready' | 'error'

function getErrorMessage(error: unknown, fallback: string): string {
  return error instanceof Error && error.message ? error.message : fallback
}
export function useProjects(service?: ProjectService) {
  const { state: authState } = useAuth()
  const ownerId = authState.session?.user.id ?? null
  const [projectService] = useState<ProjectService>(() => service ?? getProjectService())
  const [projects, setProjects] = useState<Project[]>([])
  const [status, setStatus] = useState<ResourceStatus>('loading')
  const [error, setError] = useState<string | null>(null)
  const [isMutating, setIsMutating] = useState(false)

  const refresh = useCallback(async () => {
    if (!ownerId) {
      setProjects([])
      setStatus('ready')
      setError(null)
      return
    }

    setStatus('loading')
    setError(null)
    try {
      setProjects(await projectService.listProjects(ownerId))
      setStatus('ready')
    } catch (caught) {
      setStatus('error')
      setError(getErrorMessage(caught, 'Unable to load projects.'))
    }
  }, [ownerId, projectService])

  useEffect(() => { void refresh() }, [refresh])

  const createProject = async (input: ProjectInput): Promise<Project | null> => {
    if (!ownerId) return null
    setIsMutating(true)
    setError(null)
    try {
      const project = await projectService.createProject(ownerId, input)
      await refresh()
      return project
    } catch (caught) {
      setError(getErrorMessage(caught, 'Unable to create the project.'))
      return null
    } finally {
      setIsMutating(false)
    }
  }

  const updateProject = async (projectId: string, input: ProjectInput): Promise<Project | null> => {
    if (!ownerId) return null
    setIsMutating(true)
    setError(null)
    try {
      const project = await projectService.updateProject(ownerId, projectId, input)
      await refresh()
      return project
    } catch (caught) {
      setError(getErrorMessage(caught, 'Unable to update the project.'))
      return null
    } finally {
      setIsMutating(false)
    }
  }

  const deleteProject = async (projectId: string): Promise<boolean> => {
    if (!ownerId) return false
    setIsMutating(true)
    setError(null)
    try {
      await projectService.deleteProject(ownerId, projectId)
      await refresh()
      return true
    } catch (caught) {
      setError(getErrorMessage(caught, 'Unable to delete the project.'))
      return false
    } finally {
      setIsMutating(false)
    }
  }

  return {
    projects,
    status,
    error,
    isMutating,
    refresh,
    createProject,
    updateProject,
    deleteProject,
  }
}
