# MyManger

MyManger is a focused task and project workspace for turning a busy day into a clear operating view. It combines nested projects, recurring tasks, subtasks, progress summaries, theme preferences, and a dashboard designed for quick daily planning.

The repository is organized as two independently runnable packages:

- `client/` is the React and Vite web application.
- `server/` is the TypeScript, Express, Prisma, and MySQL REST API.

> The frontend dashboard currently works locally with browser storage. The backend provides the account-aware API foundation, but the client and server integration is still being connected feature by feature.

## What It Includes

### Dashboard

- Projects with nested child projects.
- Tasks assigned to projects or subprojects.
- Subtasks with their own completion state.
- Task filters for open, completed, overdue, upcoming, and recent work.
- Daily summary metrics and completion visualizations.
- Upcoming task grouping by due date.
- Project-specific colors with migration and uniqueness safeguards.
- Dark operations-console theme with optional light mode.
- Responsive desktop, tablet, and mobile layouts.

### Task behavior

- One-time, daily, weekly, monthly, yearly, and custom recurrence.
- Custom recurrence intervals from 1 to 365 units.
- Future-dated tasks cannot be completed early.
- Tasks with incomplete subtasks cannot be completed.
- Completing a recurring task preserves its history and creates the next occurrence.
- Reopening a subtask reopens its parent task.
- Completion timestamps support the `Done Today` metric.

### Authentication and persistence foundation

- Google identity-token verification.
- Short-lived JWT access tokens.
- Rotating refresh sessions stored as hashes.
- Session reuse detection and revocation.
- Per-user workspaces and preferences.
- Prisma schema and migrations for MySQL.
- Authenticated project, task, dashboard, and preference endpoints.

## Technology

| Area | Technology |
| --- | --- |
| Frontend | React, JSX, Vite |
| Frontend styling | Hand-written CSS, design tokens, semantic themes |
| Frontend icons and charts | Lucide React, Recharts |
| Backend | Node.js, TypeScript, Express 5 |
| Validation | Zod |
| Database access | Prisma |
| Database | MySQL |
| Authentication | Google OAuth identity tokens, JWT, secure refresh cookies |
| Security middleware | Helmet, CORS, rate limiting |
| Testing | Node's built-in test runner with `tsx` |

## Repository Layout

```text
mymanager/
├── client/                         React/Vite frontend package
│   ├── index.html
│   ├── package.json
│   ├── vite.config.js
│   └── src/
│       ├── app/                    Root composition and app-wide styles
│       ├── constants/              Shared frontend constants
│       ├── features/
│       │   ├── dashboard/          Dashboard view, state, rules, and widgets
│       │   └── onboarding/login/    Login experience
│       ├── shared/widgets/          Reusable buttons, inputs, selects, and footer
│       └── styles/                  Tokens, themes, and theme controller
│
├── server/                         TypeScript API package
│   ├── package.json
│   ├── prisma/
│   │   ├── schema.prisma           Database models and relationships
│   │   └── migrations/              Versioned MySQL migrations
│   └── src/
│       ├── app.ts                   Express middleware and route mounting
│       ├── server.ts                HTTP server entry point
│       ├── config/                  Validated environment configuration
│       ├── database/                Prisma client setup
│       ├── features/
│       │   ├── auth/                Google login and session lifecycle
│       │   ├── dashboard/           Authenticated dashboard projection
│       │   ├── preferences/         Theme and timezone preferences
│       │   ├── projects/             Project CRUD and validation
│       │   └── tasks/                Task, recurrence, and subtask behavior
│       ├── shared/                  Errors, async handling, and validation
│       └── types/                   Express type extensions
│
└── docs/                            Project guidance and agent documentation
```

## Architecture

The project follows feature-based boundaries. Each feature owns the behavior closest to its domain, while shared infrastructure handles cross-cutting concerns.

```mermaid
flowchart LR
    Browser[React client] -->|HTTP and credentials| API[Express REST API]
    Browser -->|Current local dashboard state| Storage[Browser localStorage]
    API --> Auth[Auth feature]
    API --> Features[Projects, Tasks, Dashboard, Preferences]
    Auth --> Prisma[Prisma Client]
    Features --> Prisma
    Prisma --> MySQL[(MySQL)]
    Auth --> Google[Google identity verification]
```

### Frontend flow

```text
View
  -> controller hook
    -> feature repository or local repository
      -> API client or browser storage
```

- Views are declarative and compose widgets.
- Controller hooks own state, validation, and user actions.
- Feature repositories own persistence and API calls.
- Feature widgets stay close to the feature that uses them.
- Reusable controls live under `client/src/shared/widgets/`.
- Design tokens and theme mappings live under `client/src/styles/`.

The frontend uses the `@/` alias for imports across `client/src/`. Source folders and filenames use `lower_snake_case`; React component names remain `PascalCase`.

### Backend flow

```text
HTTP route
  -> request validation and auth middleware
    -> controller
      -> service
        -> repository or Prisma query
          -> MySQL
```

- Routes define HTTP paths and middleware.
- Schemas validate external input with Zod.
- Controllers translate HTTP requests and responses.
- Services enforce business rules.
- Prisma owns safe database access and relationships.
- Shared error middleware returns consistent API errors without leaking internals.

## Requirements

Install the following before running the project:

- Node.js with npm.
- MySQL for the server package.
- A Google OAuth web client ID for Google login.

The client and server have separate `package.json` files and should be installed independently.

## Run the Frontend

From the repository root:

```sh
npm --prefix client install
npm --prefix client run dev
```

The Vite development server normally runs at `http://localhost:5173`.

To create a production build:

```sh
npm --prefix client run build
```

To preview the production build:

```sh
npm --prefix client run preview
```

The client build intentionally increments the patch version through its `prebuild` script. `client/package.json` is the frontend version source, and Vite exposes that version through `APP_VERSION` in `client/src/constants/app_constants.js`.

## Run the Server

Install dependencies:

```sh
npm --prefix server install
```

Create a server environment file at `server/.env`:

```env
NODE_ENV=development
HOST=0.0.0.0
PORT=5000
DATABASE_URL=mysql://USER:PASSWORD@localhost:3306/mymanger
FRONTEND_URL=http://localhost:5173
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
JWT_ACCESS_SECRET=replace-with-at-least-32-characters
JWT_ACCESS_EXPIRES_IN=15m
REFRESH_TOKEN_EXPIRES_DAYS=14
REFRESH_TOKEN_COOKIE_NAME=mm_refresh_token
```

`DATABASE_URL` is required. `MYSQL_URL` can also be used as its source when `DATABASE_URL` is not set. The server validates all required configuration during startup.

Generate the Prisma client and apply development migrations:

```sh
npm --prefix server run db:generate
npm --prefix server run db:migrate
```

Start the API in watch mode:

```sh
npm --prefix server run dev
```

The API normally listens at `http://localhost:5000`.

For a production-style server build:

```sh
npm --prefix server run build
npm --prefix server run start
```

For an existing database in a deployment environment, apply committed migrations with:

```sh
npm --prefix server run db:deploy
```

## API Surface

The API uses JSON responses with a `success` flag and authenticated feature routes under `/api/v1`.

| Method | Path | Purpose | Auth |
| --- | --- | --- | --- |
| `GET` | `/health` | Server health check | No |
| `POST` | `/api/v1/auth/google` | Sign in with a Google identity token | No |
| `POST` | `/api/v1/auth/refresh` | Rotate a refresh session | No, refresh cookie required |
| `POST` | `/api/v1/auth/logout` | Revoke the refresh session | No |
| `GET` | `/api/v1/auth/session` | Get the current authenticated user | Yes |
| `GET` | `/api/v1/dashboard` | Load the authenticated dashboard | Yes |
| `GET` | `/api/v1/projects` | List projects | Yes |
| `POST` | `/api/v1/projects` | Create a project | Yes |
| `GET` | `/api/v1/projects/:projectId` | Get one project | Yes |
| `PATCH` | `/api/v1/projects/:projectId` | Update a project | Yes |
| `DELETE` | `/api/v1/projects/:projectId` | Delete a project | Yes |
| `GET` | `/api/v1/tasks` | List tasks with filters | Yes |
| `POST` | `/api/v1/tasks` | Create a task | Yes |
| `GET` | `/api/v1/tasks/:taskId` | Get one task | Yes |
| `PATCH` | `/api/v1/tasks/:taskId` | Update a task | Yes |
| `DELETE` | `/api/v1/tasks/:taskId` | Delete a task | Yes |
| `POST` | `/api/v1/tasks/:taskId/complete` | Complete a task | Yes |
| `POST` | `/api/v1/tasks/:taskId/reopen` | Reopen a task | Yes |
| `POST` | `/api/v1/tasks/:taskId/subtasks` | Add a subtask | Yes |
| `PATCH` | `/api/v1/tasks/:taskId/subtasks/:subtaskId` | Update a subtask | Yes |
| `DELETE` | `/api/v1/tasks/:taskId/subtasks/:subtaskId` | Delete a subtask | Yes |
| `PATCH` | `/api/v1/me/preferences` | Update theme or timezone preferences | Yes |

All authenticated `/api/v1` routes require a valid access token. Request validation and authorization happen on the server and should not be replaced by frontend-only checks.

## Database Model

The Prisma schema currently models:

- `User`: Google identity, profile, status, and account timestamps.
- `Workspace`: the user's workspace and its project/task collections.
- `RefreshSession`: hashed, rotating refresh-token sessions.
- `UserPreference`: theme, timezone, and optimistic-concurrency version.
- `Project`: nested project hierarchy and unique workspace colors.
- `Task`: status, due date, recurrence, completion history, and project assignment.
- `Subtask`: ordered child work items attached to a task.
- `DataImport`: import lifecycle metadata for future or existing import flows.

Cascade and set-null relationships are defined in `server/prisma/schema.prisma` so deleting a workspace-owned record has predictable effects.

## Testing and Verification

Run the backend test suite with:

```sh
npm --prefix server test
```

The current test suite includes recurrence behavior. Add focused tests when changing authentication, validation, task completion, recurrence, authorization, or persistence rules.

For frontend changes, use the production script for final verification:

```sh
npm --prefix client run build
```

Remember that the frontend build updates the patch version as part of its normal lifecycle.

## Security Notes

- Never commit `.env` files, database credentials, Google secrets, or JWT secrets.
- Use a JWT access secret of at least 32 characters.
- Keep Google client IDs and server secrets in the appropriate environment configuration.
- Restrict `FRONTEND_URL` to trusted origins in deployed environments.
- Keep HTTPS enabled in production so refresh cookies and access tokens are protected in transit.
- The API uses Helmet, CORS, request-size limits, rate limiting, input validation, and request IDs.
- Do not expose Prisma errors, stack traces, tokens, or other internal details to clients.

## Current Integration Status

The codebase is in a transition from a local-first dashboard to a persisted, authenticated workspace:

1. The client dashboard currently reads and writes projects and tasks through browser `localStorage`.
2. The server already has the database schema, authentication flow, and feature routes needed for account-backed persistence.
3. Frontend repositories and controllers should be connected to the documented API contracts as each feature is migrated.
4. The `/login` screen is prepared for Google sign-in, but production integration requires the client API base URL and public Google client ID to be configured.

This distinction is intentional: local dashboard behavior remains useful during development while the server contract matures.

## Documentation

Project-specific engineering guidance lives under `docs/`:

- `docs/adam/` contains frontend architecture and design guidance.
- `docs/ben/` contains backend architecture and API handoff guidance.
- `docs/captain/` contains monitoring guidance and reports.

The previous frontend-only application is preserved on the `legacy` branch.

## Project Direction

MyManger aims to stay calm, direct, and useful: show the work, make progress legible, and keep the mechanics out of the way. Future work should preserve the feature boundaries, contract-first API integration, accessible responsive UI, and secure server-side validation already established in the project.
