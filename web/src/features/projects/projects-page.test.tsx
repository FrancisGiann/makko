import { render, screen } from '@testing-library/react'
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
})
