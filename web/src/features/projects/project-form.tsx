import { useEffect, useState, type FormEvent } from 'react'

import { StatusMessage } from '../../components/status-message'
import type { Project, ProjectInput } from '../../types/domain'

const MAX_PROJECT_TAG_INPUT_LENGTH = (20 * 40) + ((20 - 1) * 2)

interface ProjectFormProps {
  initialProject?: Project | null
  isSubmitting: boolean
  error?: string | null
  onCancel?: () => void
  onSubmit: (input: ProjectInput) => Promise<Project | null>
}

interface ProjectFormState {
  name: string
  description: string
  tagsText: string
}

function inputFromProject(project?: Project | null): ProjectFormState {
  return {
    name: project?.name ?? '',
    description: project?.description ?? '',
    tagsText: project?.tags.join(', ') ?? '',
  }
}

export function ProjectForm({ initialProject, isSubmitting, error, onCancel, onSubmit }: ProjectFormProps) {
  const [input, setInput] = useState<ProjectFormState>(() => inputFromProject(initialProject))

  useEffect(() => { setInput(inputFromProject(initialProject)) }, [initialProject])

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (isSubmitting) return
    const tags = input.tagsText.trim()
      ? input.tagsText.split(',').map((tag) => tag.trim())
      : []
    await onSubmit({ name: input.name, description: input.description, tags })
  }

  const isEditing = Boolean(initialProject)

  return (
    <form className="space-y-5" onSubmit={(event) => void handleSubmit(event)} noValidate>
      <div>
        <label htmlFor="project-name" className="mb-2 block text-sm font-medium text-slate-200">Project name</label>
        <input
          id="project-name"
          value={input.name}
          onChange={(event) => setInput((current) => ({ ...current, name: event.target.value }))}
          maxLength={120}
          required
          aria-required="true"
          className="w-full rounded-xl border border-white/15 bg-slate-950/70 px-4 py-3 text-sm text-white outline-none transition placeholder:text-slate-600 focus:border-cyan-200/60 focus:ring-2 focus:ring-cyan-200/20"
          placeholder="What are you building?"
        />
      </div>
      <div>
        <label htmlFor="project-description" className="mb-2 block text-sm font-medium text-slate-200">Description <span className="font-normal text-slate-500">(optional)</span></label>
        <textarea
          id="project-description"
          value={input.description}
          onChange={(event) => setInput((current) => ({ ...current, description: event.target.value }))}
          maxLength={5000}
          rows={4}
          className="w-full resize-y rounded-xl border border-white/15 bg-slate-950/70 px-4 py-3 text-sm text-white outline-none transition placeholder:text-slate-600 focus:border-cyan-200/60 focus:ring-2 focus:ring-cyan-200/20"
          placeholder="A short note about the project's purpose"
        />
      </div>
      <div>
        <label htmlFor="project-tags" className="mb-2 block text-sm font-medium text-slate-200">Tags <span className="font-normal text-slate-500">(comma separated, optional)</span></label>
        <input
          id="project-tags"
          value={input.tagsText}
          onChange={(event) => setInput((current) => ({ ...current, tagsText: event.target.value }))}
          maxLength={MAX_PROJECT_TAG_INPUT_LENGTH}
          className="w-full rounded-xl border border-white/15 bg-slate-950/70 px-4 py-3 text-sm text-white outline-none transition placeholder:text-slate-600 focus:border-cyan-200/60 focus:ring-2 focus:ring-cyan-200/20"
          placeholder="web, personal, launch"
        />
      </div>
      {error && <StatusMessage kind="error">{error}</StatusMessage>}
      <div className="flex flex-col-reverse gap-3 pt-1 sm:flex-row sm:justify-end">
        {onCancel && (
          <button type="button" onClick={onCancel} className="rounded-xl border border-white/15 px-4 py-3 text-sm font-medium text-slate-200 transition hover:border-cyan-200/40 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">
            Cancel
          </button>
        )}
        <button type="submit" disabled={isSubmitting} className="rounded-xl bg-cyan-200 px-4 py-3 text-sm font-semibold text-slate-950 transition hover:bg-cyan-100 disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-100">
          {isSubmitting ? 'Saving…' : isEditing ? 'Save changes' : 'Create project'}
        </button>
      </div>
    </form>
  )
}
