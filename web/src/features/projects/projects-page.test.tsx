import { act, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'

import { AuthProvider } from '../auth/auth-context'
import { createFakeAuthService, createSession } from '../../test/test-auth'
import type { Project } from '../../types/domain'
import type { ProjectService } from '../../services/project.service'
import { ProjectsPage } from './projects-page'

const initialProject: Project = {
  id: 'project-1', owner_id: createSession().user.id, name: 'Launch notes', description: 'Keep the launch context here.', tags: ['personal'],
  created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-01T00:00:00Z',
}

function createService() {
  let projects = [initialProject]
  const service: ProjectService = {
    listProjects: vi.fn(async () => projects),
    getProject: vi.fn(async () => projects[0] ?? null),
    createProject: vi.fn(async (_ownerId, input) => {
      const created = { ...initialProject, id: 'project-2', ...input, description: input.description || null }
      projects = [...projects, created]
      return created
    }),
    updateProject: vi.fn(async (_ownerId, projectId, input) => {
      const updated = { ...projects.find((project) => project.id === projectId)!, ...input, description: input.description || null }
      projects = projects.map((project) => project.id === projectId ? updated : project)
      return updated
    }),
    deleteProject: vi.fn(async (_ownerId, projectId) => { projects = projects.filter((project) => project.id !== projectId) }),
  }
  return service
}

function renderPage(service: ProjectService) {
  return render(<AuthProvider service={createFakeAuthService(createSession())}><MemoryRouter><ProjectsPage service={service} /></MemoryRouter></AuthProvider>)
}

describe('ProjectsPage', () => {
  it('lists and creates a project through the service boundary', async () => {
    const user = userEvent.setup()
    const service = createService()
    renderPage(service)

    expect(await screen.findByRole('link', { name: 'Launch notes' })).toBeInTheDocument()
    expect(screen.getByRole('img', { name: 'Launch notes project identity' })).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'New project' }))
    expect(screen.getByLabelText(/Tags/)).toHaveAttribute('maxLength', '838')
    await user.type(screen.getByLabelText('Project name'), 'Fresh idea')
    await user.type(screen.getByLabelText(/Tags/), 'web, mobile')
    await user.click(screen.getByRole('button', { name: 'Create project' }))

    expect(await screen.findByRole('link', { name: 'Fresh idea' })).toBeInTheDocument()
    expect(service.createProject).toHaveBeenCalledWith(createSession().user.id, { name: 'Fresh idea', description: '', tags: ['web', 'mobile'] })
  })

  it('requires confirmation before deleting a project', async () => {
    const user = userEvent.setup()
    const service = createService()
    const confirm = window.confirm
    window.confirm = vi.fn(() => false)
    try {
      renderPage(service)
      await screen.findByRole('link', { name: 'Launch notes' })
      await user.click(screen.getByRole('button', { name: 'Delete' }))
      expect(window.confirm).toHaveBeenCalled()
      expect(service.deleteProject).not.toHaveBeenCalled()
      expect(screen.getByRole('link', { name: 'Launch notes' })).toBeInTheDocument()
    } finally {
      window.confirm = confirm
    }
  })

  it('edits an existing project through the service boundary', async () => {
    const user = userEvent.setup()
    const service = createService()
    renderPage(service)

    await screen.findByRole('link', { name: 'Launch notes' })
    await user.click(screen.getByRole('button', { name: 'Edit' }))
    const name = screen.getByLabelText('Project name')
    await user.clear(name)
    await user.type(name, 'Launch plan')
    await user.click(screen.getByRole('button', { name: 'Save changes' }))

    expect(service.updateProject).toHaveBeenCalledWith(createSession().user.id, 'project-1', { name: 'Launch plan', description: 'Keep the launch context here.', tags: ['personal'] })
    expect(await screen.findByRole('link', { name: 'Launch plan' })).toBeInTheDocument()
  })

  it('keeps a failed create mutation visible with an actionable error', async () => {
    const user = userEvent.setup()
    const service = createService()
    service.createProject = vi.fn(async () => { throw new Error('Create failed') })
    renderPage(service)

    await screen.findByRole('link', { name: 'Launch notes' })
    await user.click(screen.getByRole('button', { name: 'New project' }))
    await user.type(screen.getByLabelText('Project name'), 'Broken project')
    await user.click(screen.getByRole('button', { name: 'Create project' }))

    expect(await screen.findByRole('alert')).toHaveTextContent('Create failed')
    expect(screen.getByRole('heading', { name: 'Start a project' })).toBeInTheDocument()
    expect(screen.queryByRole('link', { name: 'Broken project' })).not.toBeInTheDocument()
  })

  it('shows loading and query errors for project reads', async () => {
    const service = createService()
    let resolveList: ((projects: Project[]) => void) | undefined
    service.listProjects = vi.fn(() => new Promise<Project[]>((resolve) => { resolveList = resolve }))
    renderPage(service)

    await waitFor(() => expect(service.listProjects).toHaveBeenCalled())
    expect(screen.getByRole('status')).toHaveTextContent('Loading your projects')
    await act(async () => { resolveList?.([initialProject]) })
    expect(await screen.findByRole('link', { name: 'Launch notes' })).toBeInTheDocument()

    const errorService = createService()
    errorService.listProjects = vi.fn(async () => { throw new Error('Projects unavailable') })
    const view = renderPage(errorService)
    expect(await screen.findByRole('alert')).toHaveTextContent('Projects unavailable')
    view.unmount()
  })

  it('keeps a project visible after a failed delete', async () => {
    const user = userEvent.setup()
    const service = createService()
    service.deleteProject = vi.fn(async () => { throw new Error('Delete failed') })
    const originalConfirm = window.confirm
    window.confirm = vi.fn(() => true)
    try {
      renderPage(service)
      await screen.findByRole('link', { name: 'Launch notes' })
      await user.click(screen.getByRole('button', { name: 'Delete' }))
      expect(await screen.findByRole('alert')).toHaveTextContent('Delete failed')
      expect(screen.getByRole('link', { name: 'Launch notes' })).toBeInTheDocument()
    } finally {
      window.confirm = originalConfirm
    }
  })
})
