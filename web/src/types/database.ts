import type {
  ActivityLog,
  GithubCommit,
  GithubIssue,
  GithubLink,
  Issue,
  IssuePriority,
  IssueStatus,
  IssueType,
  Project,
} from './domain'

export interface Database {
  public: {
    Tables: {
      projects: {
        Row: Project
        Insert: {
          owner_id: string
          name: string
          description?: string | null
          tags?: string[]
          id?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          name?: string
          description?: string | null
          tags?: string[]
          updated_at?: string
        }
        Relationships: []
      }
      issues: {
        Row: Issue
        Insert: {
          project_id: string
          title: string
          description?: string | null
          type: IssueType
          priority?: IssuePriority
          status?: IssueStatus
          id?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          title?: string
          description?: string | null
          type?: IssueType
          priority?: IssuePriority
          status?: IssueStatus
          updated_at?: string
        }
        Relationships: []
      }
      activity_log: {
        Row: ActivityLog
        Insert: never
        Update: never
        Relationships: []
      }
      github_links: {
        Row: GithubLink
        Insert: {
          project_id: string
          repo_full_name: string
        }
        Update: never
        Relationships: []
      }
      github_commits: {
        Row: GithubCommit
        Insert: never
        Update: never
        Relationships: []
      }
      github_issues: {
        Row: GithubIssue
        Insert: never
        Update: never
        Relationships: []
      }
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: {
      issue_type: IssueType
      issue_priority: IssuePriority
      issue_status: IssueStatus
    }
    CompositeTypes: Record<string, never>
  }
}

export type { IssuePriority, IssueStatus, IssueType }
