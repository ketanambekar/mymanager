# Database Schema

## Core Tables
- `users` (id, name, email unique, password_hash, role)
- `sessions` (id, user_id FK, token, refresh_token, expires_at)
- `projects` (id, name, description, created_by FK)
- `project_members` (id, project_id FK, user_id FK, role owner/member)
- `boards` (id, project_id FK, name)
- `columns` (id, board_id FK, name, order_index)
- `tasks` (id, title, description, priority, status, project_id FK, column_id FK, assigned_to FK, created_by FK, due_date, order_index)
- `task_comments` (id, task_id FK, user_id FK, comment)
- `task_files` (id, task_id FK, uploaded_by FK, original_name, file_name, mime_type, size)
- `notifications` (id, user_id FK, type, reference_id, is_read)
- `activity_logs` (id, user_id FK, project_id FK nullable, task_id FK nullable, action, metadata)

## Constraints
- Soft deletes enabled via `deleted_at` on all tables.
- Cascading deletes: projects -> boards/columns/tasks/comments/files/members.
- Composite unique index: `project_members(project_id, user_id)`.

## Indexes
- `users(email)` unique
- `tasks(project_id, status)`
- `tasks(assigned_to)`
- `tasks(priority)`
- `tasks(due_date)`
- `task_comments(task_id, created_at)`
- `notifications(user_id, is_read)`
- `activity_logs(project_id, created_at)`
