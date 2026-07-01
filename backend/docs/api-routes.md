# MyManager API Routes (Phase 1)

Base URL: /api/v1

## Authentication
- POST /auth/google
- POST /auth/refresh
- POST /auth/logout
- GET /auth/me

## Auth Requirement
- All routes except /auth/google and /auth/refresh require a valid Bearer access token.
- Refresh uses an HTTP-only cookie set by /auth/google.

## Project Types
- POST /project-types
- GET /project-types
- GET /project-types/:id
- PUT /project-types/:id
- DELETE /project-types/:id

## Priorities
- POST /priorities
- GET /priorities
- GET /priorities/:id
- PUT /priorities/:id
- DELETE /priorities/:id

## Project Colors
- POST /project-colors
- GET /project-colors
- GET /project-colors/:id
- PUT /project-colors/:id
- DELETE /project-colors/:id

## Projects
- POST /projects
- GET /projects
- GET /projects/:id
- PUT /projects/:id
- DELETE /projects/:id

## Tasks
- POST /tasks
- GET /tasks
- GET /tasks/project/:projectId
- GET /tasks/:id
- PUT /tasks/:id
- DELETE /tasks/:id

## Subtasks
- POST /subtasks
- GET /subtasks
- GET /subtasks/:id
- PUT /subtasks/:id
- DELETE /subtasks/:id
