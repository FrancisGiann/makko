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

export interface GithubLink {
  [key: string]: unknown
  id: string
  project_id: string
  repo_full_name: string
  last_synced_at: string | null
  sync_lease_token: string | null
  sync_lease_expires_at: string | null
  created_at: string
}

export interface GithubCommit {
  [key: string]: unknown
  id: string
  github_link_id: string
  sha: string
  message: string
  author_name: string | null
  author_login: string | null
  committed_at: string
  html_url: string
  synced_at: string
}

export type GithubIssueState = 'open' | 'closed'

export interface GithubIssue {
  [key: string]: unknown
  id: string
  github_link_id: string
  github_node_id: string
  number: number
  title: string
  state: GithubIssueState
  author_login: string | null
  labels: string[]
  github_created_at: string
  github_updated_at: string
  html_url: string
  synced_at: string
}

export interface GithubSyncResult {
  project_id: string
  repo_full_name: string
  commits_synced: number
  issues_synced: number
  last_synced_at: string
}
