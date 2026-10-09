# Backend Guidelines

This document records durable backend decisions for MyManager. Update it when the owner approves a lasting convention, and keep it aligned with the implementation.

## Current State

- The React/Vite frontend remains under `client/`; the independent backend package is under root-level `server/`.
- The approved backend stack is Node.js, Express 5, TypeScript, Prisma, and MySQL, based on the established legacy backend and database.
- Keep backend dependencies, configuration, scripts, migrations, and versioning inside `server/`.
- Inspect the requested runtime, deployment target, and existing dependencies before selecting a framework, database, or supporting libraries. Do not create a backend stack as part of unrelated frontend work.

## Architecture

- Use feature-based organization for substantial domains, with routes, controllers, services, repositories, and validation schemas separated according to actual responsibility.
- Keep routes focused on HTTP routing/middleware; controllers translate requests and responses; services own business rules; repositories own persistence; schemas validate untrusted input.
- Add a layer only when it provides a real boundary. Avoid empty folders, catch-all services, oversized controllers, and business logic embedded in route declarations.
- Keep shared app startup, validated environment configuration, database initialization, middleware, error handling, and cross-feature utilities in focused shared modules.
- Use `lower_snake_case` for source folder/file paths in keeping with this project's source naming preference; use idiomatic `camelCase` for JavaScript functions and variables.

## API and Security

- Google verifies/bootstraps accounts against `GOOGLE_CLIENT_ID`; an existing authenticated device can also explicitly approve QR/numeric-code login. Issue short-lived bearer access tokens and rotate hashed refresh sessions in an HttpOnly cookie. Do not store Google tokens, refresh tokens, QR codes, or polling secrets in plaintext.
- Keep one stable device ID per refresh family; bind access tokens to it and verify active session/account state on every protected request. Refresh rotation must be atomic; logout/reuse/remote revocation invalidate the whole family. Track sign-in time and last API activity, not claimed online presence or hardware fingerprinting.
- QR requests expire after five minutes, require requester-only polling/claim secrets and explicit authenticated confirmation, and are consumed atomically once. Never auto-approve a scan or disclose requester secrets to the approver. Run the bounded `cleanup:auth` job daily for requests expired over 24 hours.
- Treat `workspaceId` from the verified access token as the tenant boundary and include it in every project/task lookup. Return `404` rather than disclose another workspace's records.
- Use optimistic `version` values for concurrent project, task, subtask, and preference updates.
- Tasks have four states: `OPEN`, `COMPLETED`, `SKIPPED`, `MISSED`. Skip/miss never count as completion; closed (skipped/missed) tasks are terminal (`TASK_NOT_REOPENABLE`) and reject completion or subtask changes. Skip and miss both require a 1–200 character reason stored in `closeReason`. State-transition commands should be idempotent replays when the target state already holds.
- Keep recurrence generation, completion rules, project deletion/reassignment, and parent reopening in server services/transactions rather than trusting client state.
- Habits are read-only views of daily task recurrence series (including Custom every one day), not duplicate persistence. Use stored due-date occurrences for calendar counts; gaps are not recorded, never inferred skipped/missed days. Habit reads must not alter recurrence/task history.
- Validate and normalize every untrusted request input on the server. Frontend validation is for usability and is not a security boundary.
- Enforce authentication and authorization in backend code. Use parameterized queries or safe ORM APIs.
- Keep secrets in server-only environment variables, validate required configuration at startup, and never commit or expose secrets to frontend builds.
- Return consistent status codes and response/error shapes. Do not send stack traces or internal system details to clients.
- Add CORS, rate limiting, secure headers, and body limits as appropriate to the actual deployment and endpoints; configure them deliberately.
- Coordinate API contract changes with the frontend and document important behavior.

## Postman Collections

- Create and maintain Postman collections when requested, matching the implemented API contract.
- Make collections reusable across environments: parameterize the base URL, auth tokens, and other environment-specific values; use collection or folder-level auth inheritance where appropriate.
- Do not embed real credentials or environment-specific URLs in exported collection files. Use Postman environment variables or secrets for sensitive values.
- Parameterize request data that varies by environment or workflow, and use scripts for token capture or setup only when the API's actual auth flow supports it.

## Frontend API Handoff

- For every new or changed API, create or update a contract guide at `docs/ben/api-contracts/<feature>.md` so Adam and Dartji can implement against the actual API rather than infer its behavior.
- Include method and path, base URL configuration for web and Flutter, authentication/authorization, path/query parameters, request and response examples, status/error shapes, concurrency/version semantics, pagination where applicable, and relevant Postman setup.
- Include `Frontend Integration for Adam` and `Flutter Integration for Dartji` sections. Name expected feature repository/controller/view or GetX controller/widget locations; map fields; describe auth/token use, loading/success/error behavior, platform-specific concerns, and verification flows.
- Explicitly verify/document native Google ID-token audience and Flutter Dio cookie/session behavior; do not assume web-only OAuth, CORS, or cookie details work identically in a native client.
- When a Postman collection is part of the task, keep it aligned with the contract, parameterize environment-dependent values, and link it from the guide. Prefer `server/postman/<feature>.postman_collection.json` unless the backend uses an established alternative.
- Update the contract guide whenever the API changes. Coordinate breaking changes with Adam and Dartji and identify any client work required.
- Keep secrets out of the guide and collection. Refer to variable names, not secret values.

## Testing and Commands

- Follow the backend package's existing test and lint scripts. Test meaningful validation, business, authorization, and persistence behavior.
- If no test framework exists, consider Node's built-in test runner before adding a dependency.
- Run scripts from the repository root with `npm --prefix server <script>` when the backend lives in `server/`; adjust to the actual package location if it differs.
- Wait for checks to finish, investigate failures, rerun the focused check after a fix, and report anything that could not be verified.
- Keep backend package scripts and versioning independent from `client/` unless the owner explicitly chooses shared monorepo tooling.
- Preserve legacy data with forward-only Prisma migrations. Validate migration chains in a disposable database and back up populated databases before deployment; never use `db push --accept-data-loss` for this project.

## Versioning and Releases

- `server/package.json` is the single source of truth for the backend version and is independent of the client version. Use semver: major for breaking client contracts, minor for additive endpoints/fields/states/migrations, patch for fixes. Bump with `npm --prefix server run version:<level>`, never by hand-editing only one file.
- Every release gets a `server/CHANGELOG.md` entry (added/changed/migrations) and a `server-v<version>` git tag on the exact commit deployed.
- Deploy only bundles produced by `server/deploy/package_release.ps1` from committed code; it stamps `RELEASE_COMMIT` and preserves LF endings. `deploy.sh` tags images `mymanager-api:<version>`, verifies `/health` reports the new build, and appends to `deployments.log`.
- `GET /health` exposes `version`, `commit` (12 characters), and `builtAt`; all responses carry `x-api-version`. Do not add secrets or environment details to this metadata.

## Production Deployment

- Deploy the backend with `server/compose.production.yml`: MySQL stays on the internal Docker network, the API binds only to host loopback, and Caddy is the sole public HTTP/HTTPS edge.
- In production Express trusts exactly the single Caddy proxy hop so per-IP rate limits use the forwarded client IP. Keep Google login and refresh in separate limiter buckets; refresh loops must not lock out Google sign-in.
- Production MySQL must initialize with `lower_case_table_names=1` because the inherited migration history contains mixed-case table creation and lowercase references. This option must be present before the MySQL data directory is initialized.
- Keep production secrets only in `/opt/mymanager/server/.env.production` with mode `600`; generate database and JWT secrets on the server rather than transferring or committing them.
- Retain daily compressed database backups for 14 days, test restores, and enable an off-server backup mechanism such as Hetzner automated backups.
- Preserve deny-by-default UFW rules, fail2ban, unattended upgrades, disabled password/root SSH login, container log rotation, and the 2 GB swap file.- Production CORS allows only deployed frontend origins. Local clients reach a remote API through the Vite dev proxy (`API_PROXY_TARGET`), never by adding `localhost` to production `FRONTEND_URL`.
