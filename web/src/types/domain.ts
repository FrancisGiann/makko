export type IssueType = 'task' | 'bug'
export type IssuePriority = 'low' | 'medium' | 'high'
export type IssueStatus = 'todo' | 'in_progress' | 'done'

export interface Project {
  [key: string]: unknown
  id: string
  owner_id: string
  name: string
  description: string | null
  tags: string[]
  created_at: string
  updated_at: string
}

export interface ProjectInput {
  name: string
  description: string
  tags: string[]
}

export interface Issue {
  [key: string]: unknown
  id: string
  project_id: string
  title: string
  description: string | null
  type: IssueType
  priority: IssuePriority
  status: IssueStatus
  created_at: string
  updated_at: string
}

export interface IssueInput {
  title: string
  description: string
  type: IssueType
  priority: IssuePriority
  status: IssueStatus
}

export interface ActivityLog {
  [key: string]: unknown
  id: string
  project_id: string
  issue_id: string | null
  action: 'project.created' | 'project.updated' | 'issue.created' | 'issue.updated' | 'issue.deleted'
  description: string
  created_at: string
}
