# MyManger Server

Express 5, TypeScript, Prisma, and MySQL API for the MyManger dashboard.

## Local setup

1. Copy `.env.example` to `.env` and provide server-only values.
2. Run `npm install` from `server/`.
3. Run `npm run db:deploy` to apply checked-in migrations.
4. Run `npm run dev` for development or `npm run build && npm start` for production.

From the repository root, use `npm --prefix server <script>` where supported by the shell. On Windows environments where npm prefix resolution is unavailable, run the same script from `server/`.

## Environment

- `DATABASE_URL`: MySQL connection URL.
- `FRONTEND_URL`: comma-separated exact browser origins allowed by CORS.
- `GOOGLE_CLIENT_ID`: Google web OAuth client ID shared with Google Identity Services.
- `JWT_ACCESS_SECRET`: random server-only secret of at least 32 characters.
- `JWT_ACCESS_EXPIRES_IN`: short access-token lifetime, default `15m`.
- `REFRESH_TOKEN_EXPIRES_DAYS`: refresh-session lifetime, default `14`.

Never place database, JWT, or Google server credentials in Vite variables. Adam needs only `VITE_API_BASE_URL` and the public Google client ID used by Google Identity Services.

## Commands

- `npm run dev`: watch server.
- `npm run build`: generate Prisma Client and compile TypeScript.
- `npm test`: run focused business-rule tests.
- `npm run db:deploy`: deploy committed migrations.
- `npm run version:patch|minor|major`: bump the semver version in `package.json` and `package-lock.json`.

Health check: `GET /health` returns `status`, `version`, `commit`, and `builtAt`; every response also carries `x-api-version`. API base path: `/api/v1`.

Versioning: `package.json` is the single source of truth. Record changes in [CHANGELOG.md](CHANGELOG.md), tag releases as `server-v<version>`, and follow [deploy/README.md](deploy/README.md) for the release flow.

Postman: [postman/mymanager_phase_1.postman_collection.json](postman/mymanager_phase_1.postman_collection.json).