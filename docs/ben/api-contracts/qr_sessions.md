# QR Login and Device Sessions

Backend release: **1.2.0**. This is an additional login method for an existing account, not account registration or a replacement for Google sign-in. The signed-in device explicitly approves the account used on the new device.

## Configuration and Security

- Web: `VITE_API_BASE_URL`, production `https://api.mymanger.in/api/v1`; local development uses the existing same-origin Vite proxy.
- Flutter: `API_BASE_URL` via `--dart-define`, including `/api/v1`.
- Paths below are relative to that API root. Send JSON with `Content-Type: application/json`.
- Authenticated endpoints require `Authorization: Bearer <accessToken>`. Browser auth requests use credentials so the existing HttpOnly refresh cookie can be received/rotated.
- Every auth response uses `Cache-Control: no-store`. Never log codes, QR contents, poll secrets, cookies, or access tokens; do not send them to analytics or third-party QR-generation services.
- A request expires **five minutes after creation**, including after approval. A **10-digit numeric string** is shared by QR scanning and manual entry. Preserve leading zeroes.
- The QR contains only `{"type":"mymanager-login","version":1,"code":"0012345678"}`. It is not a URL or bearer token. Render the returned `qrPayload` locally as a QR image. Scanning must never approve automatically.
- Codes are HMAC-hashed and poll secrets/refresh tokens are SHA-256-hashed in the database. Only the requesting browser/app receives the random `pollToken`. Knowing the code alone cannot poll or claim a login.
- Device names and user agents are unverified descriptive metadata, not proof of device identity or location. Render them as text, not HTML. Do not imply GPS/location information is available.
- Browser write requests with an `Origin` must match configured `FRONTEND_URL` origins. Native requests without an Origin remain supported; do not add localhost to production CORS.

## Flow

1. **New, signed-out device:** create a request; display QR, numeric code, expiry countdown, cancel, and regenerate actions.
2. **Already signed-in device:** scan the QR or enter the numeric code, look up the request, review its details and the account being shared, then approve or deny.
3. **New device:** poll every **10 seconds**, wait for `approved`, then consume once. Only consumption sets that device's refresh cookie and returns access credentials.
4. Update the normal in-memory auth state and enter the dashboard. The source device remains signed in.

Never approve a QR/code received in a message or from someone else's screen. UI warning: **"Approve only a login you started on your own device. This gives that device access to your account."**

## Response and Error Envelopes

Success: `{ "success": true, "data": { ... } }`.

Application errors:

```json
{
  "success": false,
  "error": {
    "code": "LOGIN_CHALLENGE_UNAVAILABLE",
    "message": "Login request is no longer available",
    "requestId": "<request-id>"
  }
}
```

Validation errors additionally have `error.details`. Unexpected errors use the existing `500 INTERNAL_ERROR`; no stack traces are returned.

## Requester Endpoints (No Bearer Required)

### `POST /auth/qr/challenges`

Body: `{}` or `{ "deviceName": "Work laptop" }`. Optional name is trimmed, 1-120 characters. Without it, the server derives a browser/platform label from the bounded user agent.

Returns **201**:

```json
{
  "success": true,
  "data": {
    "challengeId": "6f591dea-cdce-4e88-bb0b-c9b1da497380",
    "deviceName": "Work laptop",
    "userAgent": "Mozilla ...",
    "createdAt": "2026-10-09T08:00:00.000Z",
    "expiresAt": "2026-10-09T08:05:00.000Z",
    "status": "pending",
    "code": "0012345678",
    "pollToken": "<64-character-base64url-secret>",
    "pollIntervalSeconds": 10,
    "qrPayload": "{\"type\":\"mymanager-login\",\"version\":1,\"code\":\"0012345678\"}"
  }
}
```

`userAgent` can be null. Keep the secret and challenge ID in controller memory only; never put the poll secret in the QR, URL, local storage, or the approving device's request.

Errors: `400 VALIDATION_ERROR`, `409 CONFLICT` on a rare code collision (request a new challenge), `429 RATE_LIMITED`.

### `POST /auth/qr/challenges/:challengeId/status`

Path: UUID `challengeId`. Body: `{ "pollToken": "<secret-from-create>" }`.

Returns **200**:

```json
{
  "success": true,
  "data": {
    "challengeId": "6f591dea-cdce-4e88-bb0b-c9b1da497380",
    "status": "approved",
    "expiresAt": "2026-10-09T08:05:00.000Z"
  }
}
```

States: `pending`, `approved`, `denied`, `expired`, `consumed`. No account profile, access token, or cookie is returned by polling. Denial/cancellation and consumption remain terminal states even after their expiry timestamp.

Errors: `400 VALIDATION_ERROR`, `404 LOGIN_CHALLENGE_NOT_FOUND` for unknown ID/wrong secret, `429 RATE_LIMITED`. Stop polling on terminal states or auth completion. On transport failure show a retryable error, not a fabricated status.

### `POST /auth/qr/challenges/:challengeId/consume`

Path: UUID. Body: `{ "pollToken": "<secret-from-create>" }`.

Returns **200**, using the unchanged Google-login/refresh response:

```json
{
  "success": true,
  "data": {
    "user": { "id": 7, "email": "owner@example.com", "displayName": "Owner", "avatarUrl": null, "workspace": {}, "preference": {} },
    "accessToken": "<access-token>",
    "accessTokenExpiresIn": "15m"
  }
}
```

The example abbreviates the existing user/workspace/preference fields; see [Authentication](auth.md). Sets the same HttpOnly `mm_refresh_token` cookie (or configured cookie name), `SameSite=Lax`, path `/api/v1/auth`, Secure in production. Issued credentials are bound to a new stable device session.

Errors: `400 VALIDATION_ERROR`, `404 LOGIN_CHALLENGE_NOT_FOUND`, `409 LOGIN_CHALLENGE_UNAVAILABLE` (pending/denied/expired/consumed), `401 SESSION_EXPIRED` if the approving session was revoked/expired, `403 ACCOUNT_DISABLED`, `429` refresh quota.

**One-use, not idempotent:** simultaneous claims yield one success and one 409; no duplicate sessions. If a network response is lost, attempt the normal `/auth/refresh` bootstrap first, which recovers if the cookie arrived. If it did not arrive, cancel/regenerate and approve a fresh request. Never persist or return a replay copy of the raw refresh token.

### `POST /auth/qr/challenges/:challengeId/cancel`

Path: UUID. Body: `{ "pollToken": "<secret-from-create>" }`.

Returns **200** `{ "success": true, "data": { "challengeId": "<uuid>", "status": "denied" } }`.

Cancellation may invalidate either a pending or approved request, but cannot log out a device after the request was consumed. Errors: `400 VALIDATION_ERROR`, `404 LOGIN_CHALLENGE_NOT_FOUND`, `409 LOGIN_CHALLENGE_UNAVAILABLE`, `429 RATE_LIMITED`.

## Approver Endpoints (Bearer Required)

### `POST /auth/qr/lookup`

Body: `{ "code": "0012345678" }`. Exactly 10 ASCII digits; no separators.

Returns **200** with the preview shape: `challengeId`, `deviceName`, `userAgent`, `createdAt`, `expiresAt`, `status: "pending"`. It never exposes the poll secret or account information.

Errors: `400 VALIDATION_ERROR`, `401 AUTHENTICATION_REQUIRED` / `SESSION_EXPIRED`, `404 LOGIN_CODE_INVALID` for unknown/expired/non-pending codes, `429 RATE_LIMITED`.

### `POST /auth/qr/challenges/:challengeId/decision`

Path: UUID from lookup. Body: `{ "code": "0012345678", "decision": "approve" }` or `"deny"`.

Returns **200** `{ "success": true, "data": { "challengeId": "<uuid>", "status": "approved" } }` (or `"denied"`).

The code and ID must refer to the same still-pending request. The account is always the bearer-token owner; there is no `userId` request field. Approval does not change the approving device's cookie or return login tokens.

Errors: `400 VALIDATION_ERROR`, `401 AUTHENTICATION_REQUIRED` / `SESSION_EXPIRED`, `409 LOGIN_CHALLENGE_UNAVAILABLE` for expired, already-decided, cancelled, or mismatched requests, `429 RATE_LIMITED`.

Concurrency: decisions are atomic and not idempotent; the first decision wins. Another device/account cannot replace that approval. The source session must still be active when the request is consumed.

## Device Management (Bearer Required)

### `GET /auth/devices`

No body/query/pagination. Returns all **active login sessions belonging to the current user**, sorted by last use descending, then ID:

```json
{
  "success": true,
  "data": {
    "activeCount": 2,
    "devices": [
      {
        "id": "84483246-6b54-4d73-845a-42d9b06673a4",
        "deviceName": "Chrome on Windows",
        "userAgent": "Mozilla ...",
        "createdAt": "2026-10-09T07:00:00.000Z",
        "lastUsedAt": "2026-10-09T08:00:00.000Z",
        "expiresAt": "2026-10-23T08:00:00.000Z",
        "isCurrent": true
      }
    ]
  }
}
```

The example omits the second entry. `activeCount` always equals `devices.length`. "Active" means not revoked and not expired, **not currently online**. One login session represents a browser profile/app installation login, not a fingerprinted hardware device. Tabs sharing a refresh cookie share a session; separate/incognito profiles are separate sessions. An additional sign-in can create another session on the same hardware.

- `createdAt`: "Signed in since", stable across refresh rotation.
- `lastUsedAt`: last authenticated API activity or successful refresh (ordinary requests update at most once per minute); not foreground presence.
- `expiresAt`: rolling refresh expiry, extended on successful refresh, not on ordinary API activity.
- `isCurrent`: compare against the session bound to the caller's token. Do not decode JWTs in UI to invent your own current-device logic.
- Old refresh families are backfilled as `"Existing browser or device"`; hardware information was not previously recorded.

Errors: `401 AUTHENTICATION_REQUIRED` / `SESSION_EXPIRED`. A device list is not an audit log; expired/revoked sessions are intentionally excluded.

### `DELETE /auth/devices/:deviceId`

Path: opaque device ID from the list (1-64 characters), not a refresh-row integer ID. No body.

Returns **200** `{ "success": true, "data": { "deviceId": "<id>", "isCurrent": false } }`.

Revokes the device and its entire refresh-token family atomically. Every protected endpoint checks the active device record, so that device's existing bearer tokens fail on its **next request**, rather than surviving until JWT expiry. Already-authorized in-flight requests may finish.

If `isCurrent` is true, the server also clears the caller's refresh cookie; the client must immediately clear its in-memory auth state and navigate to login. Revoking another session leaves the caller signed in.

Errors: `400 VALIDATION_ERROR`, `401 AUTHENTICATION_REQUIRED` / `SESSION_EXPIRED`, `404 DEVICE_NOT_FOUND` for unknown/other-user IDs. Repeating a revocation of an owned, already-revoked session is idempotent while the caller remains authenticated.

The existing `POST /auth/logout` now revokes the whole device family, including already-rotated cookies, and makes its access tokens fail subsequent protected requests.

## Limits and Version Behavior

- Create: 10 attempts / 15 minutes / IP.
- Lookup and decision share 20 attempts / 15 minutes / authenticated user, independent of IP.
- Status and cancel share 30 attempts / minute / IP.
- Consume shares the refresh limiter: 60 attempts / 15 minutes / IP.
- The existing overall limit of 300 requests / 15 minutes / IP also applies. Respect `Retry-After` and rate-limit headers; no tight polling loops.
- New QR-specific limiter errors use `429 RATE_LIMITED` in the error envelope; inherited overall/refresh limiters retain their existing text responses. The API client must also handle non-JSON 429 responses.
- No client resource `version` is required: conditional transactional state changes enforce concurrency.
- Old pre-1.2.0 access tokens without device binding get `401 SESSION_EXPIRED`. Existing rotating refresh cookies are preserved by the migration; the existing shared 401 refresh/retry path obtains a device-bound access token without another Google sign-in.
- Run migrations before serving the new build. After rollout, verify an existing user's cookie refresh and the new remote-logout behavior.

## Frontend Integration for Adam

### Login page

- Keep Google login in `client/src/features/onboarding/login/login_view.jsx`. Add a **"Log in with another device"** alternative showing a locally rendered QR, formatted numeric code (for example `00123 45678`), countdown, cancel, and regenerate.
- Add requester API methods to `login_repository.js`: create, status, consume, cancel. Mark unauthenticated QR calls with `skipAuthRefresh: true`, including consumption; a 401 from an expired approver is a QR-flow error, not a reason to refresh the signed-out browser repeatedly.
- Extend `use_login_controller.js` (or a focused colocated QR hook) with creation/polling/consumption state, cleanup on unmount, a single in-flight poll, and a one-time consume guard.
- On consume success call the existing `setAccessToken`, fetch `/auth/session`, set user state, and navigate to `/`, exactly as Google login does. Never clear or replace the source browser's credentials during approval.
- Stop polling before consuming. Stop timers on logout/navigation, expiry, denial, cancellation, and success. Regeneration must cancel the old request where possible and discard late replies from old requests; surface cancellation errors instead of assuming cancellation succeeded.
- States: idle, creating, waiting with countdown, approved/claiming, authenticated, denied/cancelled, expired, retryable network/rate-limit error. No silent fallback to Google or fake success.

### Signed-in account/settings area

- Add an account/settings **"Devices & sessions"** destination from the dashboard account menu in `client/src/features/dashboard/dashboard_view.jsx`.
- Suggested new feature `client/src/features/account/device_sessions/`: `device_session_repository.js`, `use_device_session_controller.js`, `device_session_view.jsx`, and focused widgets for the session list and approval dialog.
- Repository: authenticated list/revoke/lookup/decision methods using the existing shared `api_client.js`.
- Show `activeCount`, browser/device label, **This device**, **Signed in since**, **Last used**, and optionally expiry. Display timestamps in the existing account timezone; retain UTC wire values.
- Add **"Sign in another device"** with **Scan QR** and **Enter code**. Camera permission is optional; manual entry must work on desktop and without camera access. Validate QR type/version and code locally, then use lookup. Strip only the UI's display spaces before sending an otherwise exact 10-digit string.
- Show request details and the currently authenticated account email before explicit Approve/Deny. Include the security warning above; never submit a decision simply because a scan succeeded.
- Confirm remote logout; refetch the list after success. For current-device logout clear the normal login-controller state immediately. On another revoked device the shared 401 -> refresh -> login flow should clear state when refresh fails.
- States: loading, populated/empty, list/revoke errors, revoke pending, camera unavailable, lookup pending/invalid, confirmation, decision pending/success/conflict/expired. Use existing themes, accessible labels, and explicit toasts.

### Adam verification checklist

1. Start on browser A with Google login. Open browser B in an independent profile/incognito session.
2. B creates QR; A scans or enters code, reviews account/details, and approves. B becomes authenticated, A remains authenticated.
3. Repeat using leading-zero manual code; ensure a scan cannot auto-approve.
4. Try deny, cancel after approval, five-minute expiry, stale code, invalid QR, disconnected network, and repeated button presses.
5. Device count increases by one after claim, not on creation/approval; refresh and reload do not increase it.
6. Revoke B from A. B's next protected API call and refresh fail; B returns to login. A remains signed in.
7. Revoke the current device and verify local state/cookie cleanup. Repeat an owned remote revocation; try an other-user ID and expect 404.
8. Verify a pre-upgrade cookie bootstraps after deployment. Avoid simultaneous independent refreshes: the existing single-flight refresh helper must remain in use.

## Flutter Integration for Dartji

- `mobile/lib/main.dart` is currently a starter, not an implemented auth feature. Suggested new locations: `mobile/lib/features/auth/` for auth repository/session GetX controller and QR-login screen; `mobile/lib/features/device_sessions/` for repository, GetX controller, session-list screen, and approval widgets. Use shared Dio and feature bindings, not network calls from widgets.
- Follow the same requester/approver flow, typed status models, 10-second timer, lifecycle cleanup, single-claim guard, explicit security confirmation, and list/revoke semantics. Stop polling while backgrounded; recheck server status on resume. Camera failure must allow manual numeric entry.
- Native QR approvals use an existing bearer session and do not require a new Google token. They **do not resolve initial native Google-login configuration**: first-account sign-in still requires an ID-token audience matching server `GOOGLE_CLIENT_ID`. Browser GIS and native Google SDK behavior are not interchangeable.
- QR consumption still sets an HttpOnly refresh **cookie**, not a refresh token in JSON. Native Android/iOS must configure a Dio cookie manager for the API host, honor the `/api/v1/auth` cookie path, accept replacement `Set-Cookie`, and send cookies for refresh/logout.
- **Unverified native prerequisite:** no native auth/cookie client exists yet. Before shipping, verify the real Dio Android/iOS cookie lifecycle, including rotation, restart persistence, current-device cookie clearing, and refresh failure after remote logout. If persistent login is desired, persist sensitive cookie material only with OS-backed secure storage; do not use an unencrypted default persistent cookie jar. Keep access tokens in memory and poll secrets ephemeral. Do not hand-extract HttpOnly cookies or invent bearer refresh-token endpoints.
- Native CORS does not govern Dio requests; browser credential settings and SameSite behavior do not automatically describe native cookie handling. Flutter Web does need allowed browser origins and browser cookie-compatible deployment.
- Verify on two separate app/browser cookie contexts: request -> preview -> explicit approval -> consume -> refresh -> session list -> remote revoke -> 401/refresh failure -> sign-out. Include native cold restart, background/resume, camera denial, code leading zeroes, denial/expiry/cancel, and account switching.
- If secure native cookie persistence or Google audience cannot be confirmed, those native auth slices remain blocked pending an agreed mobile-safe implementation. Backend session security must not be weakened to bypass that prerequisite.

## Operations and Backend Verification

- Migration: `server/prisma/migrations/20261009080000_qr_device_sessions/migration.sql`. Additive tables; existing refresh families are backfilled without deleting user data.
- Back up populated databases before deployment. The production deployment process applies migrations before app startup.
- Build: `npm --prefix server run build`.
- Unit/regression tests: `npm --prefix server test`.
- Disposable local MySQL verification: `npm --prefix server run test:auth:integration`. Requires local `.env` credentials with permission to create/drop databases. Refuses non-local hosts, creates a random dedicated test database, tests the populated migration plus HTTP/service behavior, and drops only that database afterward.
- Schedule `npm run cleanup:auth` daily inside the built server/container. It deletes only QR challenges that expired more than 24 hours ago, in bounded batches. It does not delete user sessions or affect live login requests. See [production operations](../../../server/deploy/README.md) for the container command.
