# Articles Public API — Response Shapes (Server-Accurate)

> This doc describes the **exact JSON shape** returned by the NestJS server for the public Articles endpoints.
>
> Source of truth: implementation in `src/articles/articles.controller.ts` and `src/articles/articles.service.ts`.
>
> Notes:
>
> - Timestamps are returned as ISO 8601 strings when the service calls `.toISOString()`.
> - For feed cursor, the service currently returns a `Date` object for `nextCursor.createdAt` (derived from `publishedAt`). In practice, JSON serialization yields an ISO string.

---

## GET `/articles/public?section=devotional&limit=2`

### Purpose

Public feed for mobile/web clients.

### Query params

- `limit` (number, optional): default `20`, min `1`, max `50`
- `cursorCreatedAt` (string ISO datetime, optional) — must be provided together with `cursorId`
- `cursorId` (string, optional) — must be provided together with `cursorCreatedAt`
- `section` (string, optional) e.g. `devotional`
- `tag` (string, optional)
- `seriesId` (string, optional)
- `q` (string, optional)
- `date` (string `YYYY-MM-DD`, optional) — special daily devotional date filter

### Root response shape

```json
{
  "items": [
    {
      "id": "string",
      "title": "string",
      "subtitle": "string | null",
      "slug": "string",
      "snippet": "string | null",
      "coverImage": "string | null",
      "coverAssetId": "string | null",
      "coverAsset": { "url": "string" },
      "tags": ["string"],
      "section": "string | null",
      "seriesId": "string | null",
      "seriesOrder": 0,
      "authorDisplayName": "string",
      "wordCount": 0,
      "readingTimeMinutes": 0,
      "contentVersion": 1,
      "publishedAt": "2025-12-27T00:00:00.000Z",
      "createdAt": "2025-12-27T00:00:00.000Z",
      "updatedAt": "2025-12-27T00:00:00.000Z",

      "coverUrl": "string | null"
    }
  ],
  "nextCursor": {
    "createdAt": "2025-12-27T00:00:00.000Z",
    "id": "string"
  }
}
```

### `nextCursor` details (exact)

When there are more results (`hasMore === true`):

- Field name: `nextCursor`
- Type: object with **exact fields**:
  - `createdAt`: derived from the last item’s `publishedAt`
  - `id`: derived from the last item’s `id`

When there are no more results:

- `nextCursor` is `undefined` from the service.
- In JSON output, it may be omitted or appear as `null` depending on serialization/interceptors (current service returns `undefined`).

### Item fields actually sent in list

The feed uses a Prisma `select` (so only the following fields are returned), then adds `coverUrl`:

- `id`
- `title`
- `subtitle`
- `slug`
- `snippet`
- `coverImage` (legacy)
- `coverAssetId`
- `coverAsset: { url }`
- `tags`
- `section`
- `seriesId`
- `seriesOrder`
- `authorDisplayName`
- `wordCount`
- `readingTimeMinutes`
- `contentVersion`
- `publishedAt`
- `createdAt`
- `updatedAt`
- `coverUrl` (computed): `coverAsset.url || coverImage || null`

> Important: The list endpoint does **not** include `contentJson` or `contentHtml`.

---

## GET `/articles/public/:slug`

### Purpose

Fetch full published article by slug, including **asset manifest** for offline caching.

### Success response (200)

```json
{
  "id": "string",
  "title": "string",
  "subtitle": "string | null",
  "slug": "string",
  "snippet": "string | null",

  "contentJson": {},
  "contentHtml": "string | null",

  "coverUrl": "string | null",
  "authorDisplayName": "string",
  "tags": ["string"],
  "section": "string | null",
  "seriesId": "string | null",
  "seriesOrder": 0,
  "wordCount": 0,
  "readingTimeMinutes": 0,
  "contentVersion": 1,

  "publishedAt": "2025-12-27T00:00:00.000Z",
  "createdAt": "2025-12-27T00:00:00.000Z",
  "updatedAt": "2025-12-27T00:00:00.000Z",

  "assets": [
    {
      "id": "string",
      "kind": "IMAGE | VIDEO",
      "url": "https://...",
      "mime": "image/jpeg",
      "sizeBytes": 1234,
      "width": 1080,
      "height": 720,
      "durationSeconds": null
    }
  ]
}
```

### `contentJson` notes

- `contentJson` is returned exactly as stored in DB (`article.contentJson`).
- Because this doc is server-accurate (not environment-real), it cannot embed a real ProseMirror document. Use `/articles/public?limit=1` to grab a real article then copy its `contentJson`.

### `contentHtml` notes

- The server returns `contentHtml` with a fallback:
  - `contentHtml: article.contentHtml || article.content`
- So legacy records may still get HTML from `content`.

---

## Assets manifest (detail endpoint)

### Shape (important)

- `assets` is an **array** (ordered list), not a map.

### How it’s built

- Base list comes from the join table `article.assetRefs` (records created by `POST /articles/:id/link-asset`).
- If the article has a `coverAsset` and it’s not already in the list, it will be inserted at the start via `assets.unshift(...)`.

### “How does contentJson reference assets?”

- The API does **not** rewrite `contentJson` to inject links.
- The `assets` list is for clients that want to prefetch/cache assets.
- Any linkage between editor nodes and assets (e.g., `assetId` stored in a node) depends on the editor schema; the backend’s manifest linkage is tracked independently via `link-asset`.

---

## 404 behavior (optional but useful)

If the slug is not found, not published, or scheduled for the future (`publishedAt > now`):

- HTTP status: **404**
- Exception thrown: `NotFoundException('Article not found')`

Default NestJS JSON body (unless overridden by a global exception filter):

```json
{
  "statusCode": 404,
  "message": "Article not found",
  "error": "Not Found"
}
```

---

## Examples (copy/paste)

Because this repository workspace can’t call your dev/staging environments, this doc can only provide **shape-accurate** examples.

To capture **real environment JSON** for fixtures, run (PowerShell recommended on Windows) and paste the results into your fixture:

```powershell
# Feed
$base = "https://YOUR-BASE-URL"
Invoke-RestMethod "$base/articles/public?section=devotional&limit=2" | ConvertTo-Json -Depth 100

# Detail (pick a slug from feed)
$slug = "PASTE-SLUG"
Invoke-RestMethod "$base/articles/public/$slug" | ConvertTo-Json -Depth 200
```
