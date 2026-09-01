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
        <label htmlFor="project-name" className="mb-2 block text-sm font-medium text-slate-800 dark:text-slate-200">
          Project name
        </label>
        <input
          id="project-name"
          value={input.name}
          onChange={(event) => setInput((current) => ({ ...current, name: event.target.value }))}
          maxLength={120}
          required
          aria-required="true"
          className="makko-field makko-readable w-full px-4 py-3 text-sm placeholder:text-slate-400 dark:placeholder:text-slate-500"
          placeholder="What are you building?"
        />
      </div>
      <div>
        <label htmlFor="project-description" className="mb-2 block text-sm font-medium text-slate-800 dark:text-slate-200">
          Description <span className="text-xs font-normal text-slate-500">(optional)</span>
        </label>
        <textarea
          id="project-description"
          value={input.description}
          onChange={(event) => setInput((current) => ({ ...current, description: event.target.value }))}
          maxLength={5000}
          rows={4}
          className="makko-field makko-readable w-full resize-y px-4 py-3 text-sm placeholder:text-slate-400 dark:placeholder:text-slate-500"
          placeholder="A short note about the project's purpose"
        />
      </div>
      <div>
        <label htmlFor="project-tags" className="mb-2 block text-sm font-medium text-slate-800 dark:text-slate-200">
          Tags <span className="text-xs font-normal text-slate-500">(comma separated, optional)</span>
        </label>
        <input
          id="project-tags"
          value={input.tagsText}
          onChange={(event) => setInput((current) => ({ ...current, tagsText: event.target.value }))}
          maxLength={MAX_PROJECT_TAG_INPUT_LENGTH}
          className="makko-field makko-readable w-full px-4 py-3 text-sm placeholder:text-slate-400 dark:placeholder:text-slate-500"
          placeholder="web, personal, launch"
        />
      </div>
      {error && <StatusMessage kind="error">{error}</StatusMessage>}
      <div className="flex flex-col gap-3 pt-2 sm:flex-row sm:justify-end">
        {onCancel && (
          <button
            type="button"
            onClick={onCancel}
            className="makko-control makko-secondary makko-focus px-4 text-sm font-semibold"
          >
            Cancel
          </button>
        )}
        <button
          type="submit"
          disabled={isSubmitting}
          className="makko-control makko-primary makko-focus px-6 text-sm font-semibold disabled:cursor-not-allowed disabled:opacity-50"
        >
          {isSubmitting ? 'Saving…' : isEditing ? 'Save changes' : 'Create project'}
        </button>
      </div>
    </form>
  )
}
