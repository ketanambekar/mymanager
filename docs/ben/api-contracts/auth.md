# Authentication API Contract

Frontend base URL variable: `VITE_API_BASE_URL`, for example `http://localhost:5000/api/v1`. Google sign-in creates/bootstraps accounts; an already authenticated device can also approve QR/code login. See [QR Login and Device Sessions](qr_sessions.md) for the complete new endpoints and Adam/Dartji handoff.

## Endpoints

### `POST /auth/google`

No bearer token. Body: `{ "credential": "<Google Identity Services ID token>" }`.

Returns `200` with `{ success, data: { user, accessToken, accessTokenExpiresIn } }` and sets the rotating refresh token as an HttpOnly cookie. `user` includes `id`, `email`, `displayName`, `avatarUrl`, `workspace`, and `preference`.

Errors: `400 VALIDATION_ERROR`, `401 GOOGLE_TOKEN_INVALID`, `401 GOOGLE_PROFILE_INVALID`, `403 ACCOUNT_DISABLED`, `429` rate limit.

Rate limit: 30 Google login attempts per 15 minutes per client IP. Login and refresh have separate quotas.

### `POST /auth/refresh`

No bearer token. Send with browser credentials enabled. The HttpOnly refresh cookie is rotated and a new access token is returned using the login response shape.

Errors: `401 REFRESH_TOKEN_MISSING`, `401 SESSION_EXPIRED`, `401 SESSION_REUSE_DETECTED`, or `403 ACCOUNT_DISABLED`. Rotation is atomic and keeps the same stable device session. Reusing a rotated refresh token revokes that device and its entire refresh family.

Rate limit: 60 refresh attempts per 15 minutes per client IP. Refresh exhaustion does not consume Google login quota. Production rate limiting trusts the single Caddy proxy hop for client IP resolution. QR consumption shares the refresh quota.

### `GET /auth/session`

Requires an access token in the Authorization header using the Bearer scheme. Returns the current dynamic Google profile, workspace, and preferences. All protected endpoints verify an active, unexpired device session and active account, not only the JWT signature.

### `POST /auth/logout`

Send with browser credentials enabled. Revokes the whole device session/refresh family and clears the cookie; its access tokens stop working on subsequent protected requests.

All auth responses are `Cache-Control: no-store`. Browser write requests with an Origin must match the server's configured frontend origins. At the 1.2.0 rollout, old access tokens without device binding return 401; preserved refresh cookies acquire a bound token through the normal refresh/retry flow.

## Frontend Integration for Adam

- Add the public Google sign-in view under `client/src/features/onboarding/login/`.
- Put calls in `login_repository.js`, state/token lifecycle in `use_login_controller.js`, and never persist the refresh token.
- Keep the access token in memory. Configure `client/src/services/api_client.js` with `VITE_API_BASE_URL`, `withCredentials: true`, and one shared 401 refresh/retry path.
- Bind `displayName` and `avatarUrl` into the dashboard account area, replacing `My workspace`/`M` placeholders.
- States: Google loading, login failure, authenticated bootstrap, refresh failure returning to login, and logout pending. Add the QR-login and device/settings states described in [QR Login and Device Sessions](qr_sessions.md).
- Verify by logging in, refreshing once, calling `/auth/session`, reloading through `/auth/refresh`, and logging out.

## Flutter Integration for Dartji

- Configure Dio with `API_BASE_URL` from Flutter `--dart-define`; use the same API root ending in `/api/v1` as the web base URL.
- `POST /auth/google` accepts `{ "credential": "<Google ID token>" }`; the server verifies the token audience against `GOOGLE_CLIENT_ID` and returns an access token while setting an HttpOnly refresh cookie scoped to `/api/v1/auth`.
- Before implementing mobile sign-in, verify with Ben that the native Google Sign-In SDK is configured to produce an ID token whose audience matches the server's configured client ID. Do not assume the browser Google Identity Services flow is usable in Flutter.
- Before implementing `/auth/refresh` and logout, verify a Dio cookie manager sends and rotates the HttpOnly cookie correctly on native Android/iOS. Keep the access token in memory. Do not extract the cookie manually, persist secrets insecurely, or change server token behavior to work around a client issue.
- Use an auth repository and GetX session controller for login, bootstrap, refresh, and logout. `/auth/session` uses a Bearer access token in the Authorization header. QR login/device sessions are documented in [their Flutter handoff](qr_sessions.md#flutter-integration-for-dartji); native secure cookie lifecycle verification is still required.
- If the native Google audience or secure cookie lifecycle cannot be confirmed, stop that auth slice and ask Ben to document/implement a mobile-safe contract before proceeding. Other authenticated feature work can use a safely provided development token only if the owner/Ben explicitly supplies a secure test flow.
