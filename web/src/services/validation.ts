import type { IssueInput, ProjectInput } from '../types/domain'
import type { IssuePriority, IssueStatus, IssueType } from '../types/database'

export class ValidationError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ValidationError'
  }
}

export function normalizeProjectInput(input: ProjectInput): ProjectInput {
  if (typeof input !== 'object' || input === null) throw new ValidationError('Project input is invalid.')
  const name = typeof input.name === 'string' ? input.name.trim() : ''
  if (!name) throw new ValidationError('Project name is required.')
  if (name.length > 120) throw new ValidationError('Project name must be 120 characters or fewer.')

  const rawDescription = typeof input.description === 'string' ? input.description.trim() : ''
  if (rawDescription.length > 5000) {
    throw new ValidationError('Project description must be 5,000 characters or fewer.')
  }

  if (!Array.isArray(input.tags)) throw new ValidationError('Project tags are invalid.')
  if (input.tags.length > 20) throw new ValidationError('A project can have at most 20 tags.')
  const tags = input.tags.map((tag) => typeof tag === 'string' ? tag.trim() : '')
  if (tags.some((tag) => !tag)) throw new ValidationError('Tags cannot be blank.')
  if (tags.some((tag) => tag.length > 40)) throw new ValidationError('Tags must be 40 characters or fewer.')
  const uniqueTags = new Set(tags.map((tag) => tag.toLowerCase()))
  if (uniqueTags.size !== tags.length) throw new ValidationError('Tags must be unique.')

  return {
    name,
    description: rawDescription,
    tags,
  }
}

const issueTypes: readonly IssueType[] = ['task', 'bug']
const issuePriorities: readonly IssuePriority[] = ['low', 'medium', 'high']
const issueStatuses: readonly IssueStatus[] = ['todo', 'in_progress', 'done']

function isOneOf<T extends string>(value: string, options: readonly T[]): value is T {
  return options.includes(value as T)
}

export function normalizeIssueInput(input: IssueInput): IssueInput {
  if (typeof input !== 'object' || input === null) throw new ValidationError('Issue input is invalid.')
  const title = typeof input.title === 'string' ? input.title.trim() : ''
  if (!title) throw new ValidationError('Issue title is required.')
  if (title.length > 200) throw new ValidationError('Issue title must be 200 characters or fewer.')

  const rawDescription = typeof input.description === 'string' ? input.description.trim() : ''
  if (rawDescription.length > 10000) {
    throw new ValidationError('Issue description must be 10,000 characters or fewer.')
  }
  if (!isOneOf(input.type, issueTypes)) throw new ValidationError('Choose a valid issue type.')
  if (!isOneOf(input.priority, issuePriorities)) throw new ValidationError('Choose a valid issue priority.')
  if (!isOneOf(input.status, issueStatuses)) throw new ValidationError('Choose a valid issue status.')

  return {
    title,
    description: rawDescription,
    type: input.type,
    priority: input.priority,
    status: input.status,
  }
}

export function requireId(value: string, label: string): string {
  const id = typeof value === 'string' ? value.trim() : ''
  if (!id) throw new ValidationError(`${label} is required.`)
  return id
}
