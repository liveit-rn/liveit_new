# LiveIT Backend API (NestJS) — Frontend Integration Notes

Source of truth: Swagger UI `https://liveit-api-dev-5jufu.ondigitalocean.app/api` (OpenAPI JSON: `https://liveit-api-dev-5jufu.ondigitalocean.app/api-json`).

## Base URL

Dev:

* `https://liveit-api-dev-5jufu.ondigitalocean.app`

Health/hello:

* `GET /` → `Hello World!`

## Authentication

The API uses **Bearer JWT**.

* Send header: `Authorization: Bearer <access_token>`
* Auth response schema: `AuthResponseDto`
  * `access_token`: string
  * `expires_in`: number (seconds)
  * `user`: lightweight user info (use `GET /profiles/me` for full profile)

### Email/password flow

1. `POST /auth/register` → `AuthResponseDto`
2. `POST /auth/login` → `AuthResponseDto`
3. Use `access_token` for authenticated endpoints.

### OAuth flow (Google/Facebook/Apple)

1. Start OAuth (redirect):
   * `GET /auth/google/start` (Google)
   * `GET /auth/oauth/{provider}/start` where `{provider}` ∈ `google|facebook|apple`
2. Provider redirects back to backend callback (internal):
   * `GET /auth/google/callback?userId=...&secret=...`
   * `GET /auth/oauth/{provider}/callback?userId=...&secret=...`
3. Backend redirects to frontend with a **one-time code**.
4. Exchange code for JWT:
   * `POST /auth/oauth/exchange` body: `{ "code": "..." }` → `AuthResponseDto`

### Logout

* `POST /auth/logout` (Bearer)

### Password reset

* `POST /auth/password/forgot` body: `{ "email": "user@example.com" }`
* `POST /auth/password/reset` body:
  ```json
  {
    "userId": "...",
    "secret": "...",
    "password": "NewPassword123!"
  }
  ```

### Username

* `GET /auth/username/check?username=johndoe`
* `POST /auth/claim-username` (Bearer) body: `{ "username": "johndoe" }`

> Note: `GET /auth/profile` is **deprecated**. Prefer `GET /profiles/me`.

## Profiles

### Get / update current profile (recommended)

* `GET /profiles/me` (Bearer) → `ProfileResponseDto`
* `PUT /profiles/me` (Bearer) body: `UpdateProfileDto` → `ProfileResponseDto`

`UpdateProfileDto` fields are optional; send only what you want to change (e.g. `name`, `bio`, `location`, `privacy`, `links`, etc.).

### Upload avatar

* `POST /profiles/upload/avatar` (Bearer)
  * `multipart/form-data` with field `file` (binary)
  * Returns example:
    ```json
    {
      "fileId": "6744a...",
      "avatarUrl": "/profiles/assets/avatar/6744a..."
    }
    ```
  * Then set the avatar on profile via `PUT /profiles/me` using `profileImageId: <fileId>`.

* `GET /profiles/assets/avatar/:fileId`
  * Backend proxy endpoint for avatar image bytes (client does not call Appwrite directly).

### Email claim (for OAuth placeholder email)

* `POST /profiles/email/claim/start` (Bearer) body: `{ "email": "newemail@example.com" }` → `{ "code": "..." }`
* `POST /profiles/email/claim/confirm` (Bearer) body: `{ "code": "123456" }` → `{ "success": true }`

### Public profile

* `GET /profiles/u/{username}` → `PublicProfileResponseDto`
* `GET /profiles/u/{username}/summary` → `PublicProfileSummaryResponseDto`

### Profile summaries (dashboard)

* `GET /profiles/me/summary` (Bearer) → `ProfileSummaryResponseDto`

## Gamification

Authenticated:

* `GET /gamification/me/points` (Bearer) → `UserPointsDto`
* `GET /gamification/me/achievements` (Bearer) → `UserAchievementDto[]`
* `GET /gamification/me/history?limit=50` (Bearer) → `PointsHistoryDto[]`
* `GET /gamification/me/summary?scope=today` (Bearer) → `GamificationSummaryDto`

Public:

* `GET /gamification/leaderboard/points?limit=50` → `LeaderboardEntryDto[]`
* `GET /gamification/leaderboard/streak?limit=50` → `LeaderboardEntryDto[]`

Admin (Bearer):

* `GET /gamification/admin/daily-metrics?date=YYYY-MM-DD` → `DailyMetricsDto`
* `GET /gamification/admin/achievements`
* `POST /gamification/admin/migrate-achievements`

## Habits

Public:

* `GET /habits/catalog`
* `GET /habits/health`

Authenticated (Bearer):

* `GET /habits` (list active user habits)
* `POST /habits` body: `AddHabitDto` (requires `habitId`)
* `POST /habits/custom` body: `CreateCustomHabitDto` (requires `title`)
* `POST /habits/{userHabitId}/checkin` body (optional): `CheckinDto`
  * Example: `{ "date": "2024-11-24" }`
* `DELETE /habits/{userHabitId}/checkin` (undo today)
* `DELETE /habits/{userHabitId}` (archive)
* `POST /habits/{userHabitId}/report` body: `ReportHabitDto`
* `POST /habits/admin/{userHabitId}/moderate` (admin)
* `GET /habits/stats/today`

## Devotionals

Public:

* `GET /devotionals/today?tz=Asia/Jakarta`
* `GET /devotionals?q=...&from=YYYY-MM-DD&to=YYYY-MM-DD&authorId=...&limit=10&page=1`
* `GET /devotionals/{slug}`

Authenticated (Bearer):

* `POST /devotionals/{slug}/like`
* `DELETE /devotionals/{slug}/like` (unlike; RESTful)
* `POST /devotionals/{slug}/unlike` (legacy)
* `POST /devotionals/{slug}/create-habit` (one-click habit creation)

## DTO Cheat Sheet (selected)

### RegisterDto

```json
{
  "email": "user@example.com",
  "password": "Password123!",
  "name": "John Doe",
  "username": "johndoe"
}
```

Required: `email`, `password`.

### LoginDto

```json
{
  "email": "user@example.com",
  "password": "Password123!"
}
```

### AuthResponseDto

```json
{
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "name": "John Doe",
    "username": "johndoe",
    "needsUsername": false,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-15T10:30:00.000Z"
  },
  "access_token": "<jwt>",
  "expires_in": 86400
}
```

### ExchangeCodeDto

```json
{ "code": "abc123xyz789" }
```
