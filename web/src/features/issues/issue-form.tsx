import { useEffect, useState, type FormEvent } from 'react'

import { StatusMessage } from '../../components/status-message'
import type { Issue, IssueInput } from '../../types/domain'

interface IssueFormProps {
  initialIssue?: Issue | null
  isSubmitting: boolean
  error?: string | null
  onCancel?: () => void
  onSubmit: (input: IssueInput) => Promise<Issue | null>
}
function inputFromIssue(issue?: Issue | null): IssueInput {
  return {
    title: issue?.title ?? '',
    description: issue?.description ?? '',
    type: issue?.type ?? 'task',
    priority: issue?.priority ?? 'medium',
    status: issue?.status ?? 'todo',
  }
}

export function IssueForm({ initialIssue, isSubmitting, error, onCancel, onSubmit }: IssueFormProps) {
  const [input, setInput] = useState<IssueInput>(() => inputFromIssue(initialIssue))
  useEffect(() => { setInput(inputFromIssue(initialIssue)) }, [initialIssue])

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (isSubmitting) return
    await onSubmit(input)
  }
  const isEditing = Boolean(initialIssue)

  return (
    <form className="space-y-5" onSubmit={(event) => void handleSubmit(event)} noValidate>
      <div>
        <label htmlFor="issue-title" className="mb-2 block text-sm font-medium text-slate-200">Title</label>
        <input
          id="issue-title"
          value={input.title}
          onChange={(event) => setInput((current) => ({ ...current, title: event.target.value }))}
          maxLength={200}
          required
          aria-required="true"
          className="w-full rounded-xl border border-white/15 bg-slate-950/70 px-4 py-3 text-sm text-white outline-none transition placeholder:text-slate-600 focus:border-cyan-200/60 focus:ring-2 focus:ring-cyan-200/20"
          placeholder="What needs attention?"
        />
      </div>
      <div>
        <label htmlFor="issue-description" className="mb-2 block text-sm font-medium text-slate-200">Description <span className="font-normal text-slate-500">(optional)</span></label>
        <textarea
          id="issue-description"
          value={input.description}
          onChange={(event) => setInput((current) => ({ ...current, description: event.target.value }))}
          maxLength={10000}
          rows={4}
          className="w-full resize-y rounded-xl border border-white/15 bg-slate-950/70 px-4 py-3 text-sm text-white outline-none transition placeholder:text-slate-600 focus:border-cyan-200/60 focus:ring-2 focus:ring-cyan-200/20"
          placeholder="Leave enough context for your future self"
        />
      </div>
      <div className="grid gap-4 sm:grid-cols-3">
        <SelectField id="issue-type" label="Type" value={input.type} onChange={(value) => setInput((current) => ({ ...current, type: value as IssueInput['type'] }))} options={[['task', 'Task'], ['bug', 'Bug']]} />
        <SelectField id="issue-priority" label="Priority" value={input.priority} onChange={(value) => setInput((current) => ({ ...current, priority: value as IssueInput['priority'] }))} options={[['low', 'Low'], ['medium', 'Medium'], ['high', 'High']]} />
        <SelectField id="issue-status" label="Status" value={input.status} onChange={(value) => setInput((current) => ({ ...current, status: value as IssueInput['status'] }))} options={[['todo', 'To do'], ['in_progress', 'In progress'], ['done', 'Done']]} />
      </div>
      {error && <StatusMessage kind="error">{error}</StatusMessage>}
      <div className="flex flex-col-reverse gap-3 pt-1 sm:flex-row sm:justify-end">
        {onCancel && <button type="button" onClick={onCancel} className="rounded-xl border border-white/15 px-4 py-3 text-sm font-medium text-slate-200 transition hover:border-cyan-200/40 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-200">Cancel</button>}
        <button type="submit" disabled={isSubmitting} className="rounded-xl bg-cyan-200 px-4 py-3 text-sm font-semibold text-slate-950 transition hover:bg-cyan-100 disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-cyan-100">
          {isSubmitting ? 'Saving…' : isEditing ? 'Save changes' : 'Create issue'}
        </button>
      </div>
    </form>
  )
}

interface SelectFieldProps {
  id: string
  label: string
  value: string
  options: readonly [string, string][]
  onChange: (value: string) => void
}

function SelectField({ id, label, value, options, onChange }: SelectFieldProps) {
  return (
    <div>
      <label htmlFor={id} className="mb-2 block text-sm font-medium text-slate-200">{label}</label>
      <select id={id} value={value} onChange={(event) => onChange(event.target.value)} className="w-full rounded-xl border border-white/15 bg-slate-950/70 px-3 py-3 text-sm text-white outline-none transition focus:border-cyan-200/60 focus:ring-2 focus:ring-cyan-200/20">
        {options.map(([optionValue, optionLabel]) => <option key={optionValue} value={optionValue}>{optionLabel}</option>)}
      </select>
    </div>
  )
}
