# Articles — Client Integration Guide (SvelteKit CMS + Flutter)

Tanggal: 2025-12-19 (Updated)  
**Audience**: FE admin (SvelteKit) + Mobile (Flutter)  
Backend: LiveIT NestJS (`liveit-server`)

Dokumen ini menggabungkan kontrak endpoint **articles** yang sudah ada di backend + contoh integrasi client.

> **Update 2025-12-19**: Backend sekarang mendukung **Medium-like articles** dengan:
>
> - `contentJson` (ProseMirror JSON) sebagai source-of-truth untuk Flutter renderer
> - `contentHtml` sebagai derived HTML untuk web preview
> - Derived fields: `wordCount`, `readingTimeMinutes`
> - `publishedAt` untuk scheduled publishing
> - Asset management (image + video) dengan metadata
> - Embed validation (YouTube, Instagram, TikTok, Spotify)
> - `section`, `seriesId`, `seriesOrder` untuk taxonomy

---

## 1) Ringkasan arsitektur

- **PostgreSQL (Prisma)**: menyimpan teks artikel + metadata + status + asset records.
- **Appwrite Storage**: menyimpan asset binary (gambar cover, gambar/video di konten).
- **SvelteKit (CMS Admin)**: create/upload/list/filter artikel lewat API NestJS.
- **Flutter (Mobile)**: konsumsi feed public published-only + detail by slug + asset manifest untuk offline.

### Surface API (dibagi 2)

- **CMS/admin (guarded)**
  - `POST /articles/upload-asset` — upload image/video, returns Asset record
  - `POST /articles` — create article
  - `PUT /articles/:id` — update article
  - `POST /articles/:id/publish` — publish article (set status + publishedAt)
  - `POST /articles/:id/unpublish` — revert to DRAFT
  - `POST /articles/:id/link-asset` — link asset to article for manifest
  - `GET /cms/articles` — list with filtering
  - `GET /cms/articles/:id` — get single article for edit

- **Public/mobile (open)**
  - `GET /articles/public` — cursor pagination + section/date/tag filters
  - `GET /articles/public/:slug` — detail + asset manifest for offline

> `GET /articles` masih ada untuk kompatibilitas implementasi awal, tapi untuk admin list yang butuh filtering gunakan `GET /cms/articles`.

---

## 2) Auth & authorization (CMS)

### Requirement

Endpoint write untuk CMS butuh:

- Header: `Authorization: Bearer <JWT>`
- JWT harus valid (`JwtAuthGuard`)
- `req.user.email` harus termasuk allowlist `CMS_ADMIN_EMAILS` (`CmsAdminGuard`)

### Env var

- `CMS_ADMIN_EMAILS` = comma-separated list email admin.
  - contoh: `CMS_ADMIN_EMAILS=admin@liveit.app,editor@liveit.app`

### Error modes

- **401**: token missing/invalid/expired
- **403**: email tidak ada di token atau tidak termasuk allowlist

---

## 3) Kontrak data (high level)

### ArticleStatus

- `DRAFT | PUBLISHED | ARCHIVED`

### AssetKind

- `IMAGE | VIDEO`

### Article (shape lengkap)

```typescript
{
  id: string;
  title: string;
  subtitle?: string;
  slug: string;
  snippet?: string;

  // Content
  contentJson: object;        // ProseMirror JSON (source-of-truth)
  contentHtml?: string;       // Derived HTML for web
  content?: string;           // Legacy HTML (deprecated)

  // Cover
  coverAssetId?: string;
  coverUrl?: string;          // Resolved URL
  coverImage?: string;        // Legacy URL (deprecated)

  // Author
  authorId: string;
  authorDisplayName: string;  // "LiveIt Team" if not set

  // Status & Schedule
  status: ArticleStatus;
  publishedAt?: string;       // ISO date

  // Taxonomy
  section?: string;           // devotional, learning, culture
  seriesId?: string;
  seriesOrder?: number;
  tags: string[];

  // Derived
  wordCount?: number;
  readingTimeMinutes?: number;
  contentVersion: number;     // Incremented on content change

  createdAt: string;
  updatedAt: string;
}
```

### Asset

```typescript
{
  id: string;
  kind: 'IMAGE' | 'VIDEO';
  url: string;
  mime: string;
  sizeBytes: number;
  width?: number;
  height?: number;
  durationSeconds?: number;   // For video
}
```

---

## 4) CMS endpoints (SvelteKit)

### 4.1 Upload asset — `POST /articles/upload-asset`

**Tujuan**: upload gambar/video dari editor → dapat Asset record dengan metadata.

- Guard: ✅ `JwtAuthGuard` + ✅ `CmsAdminGuard`
- Content-Type: `multipart/form-data`
- Field file: `file`

**Validasi/hardening**

- Image: max size **10MB**, MIME `image/*`
- Video: max size **50MB**, MIME `video/mp4`, `video/webm`, `video/quicktime`

**Response**

```json
{
  "assetId": "uuid",
  "url": "https://...",
  "kind": "IMAGE",
  "mime": "image/jpeg",
  "sizeBytes": 123456,
  "width": null,
  "height": null,
  "durationSeconds": null
}
```

**Kegagalan umum**

- `400`: file kosong / invalid / non-allowed MIME / size terlalu besar
- `401/403`: auth/admin gating gagal

### 4.2 Create article — `POST /articles`

**Tujuan**: CMS submit artikel baru.

- Guard: ✅ `JwtAuthGuard` + ✅ `CmsAdminGuard`
- Content-Type: `application/json`

**Request body (CreateArticleDto)**

Required:

- `title: string`
- `slug: string` (unique)
- `contentJson: object` (ProseMirror JSON)

Opsional:

- `subtitle?: string`
- `snippet?: string`
- `contentHtml?: string` (derived HTML)
- `coverAssetId?: string` (dari upload-asset)
- `tags?: string[]`
- `section?: string` (devotional, learning, culture)
- `seriesId?: string`
- `seriesOrder?: number`
- `status?: ArticleStatus` (default: DRAFT)
- `publishedAt?: string` (ISO date for scheduled)

**Server-side behavior**

- `authorId` dan `authorDisplayName` diambil dari JWT.
- `wordCount` dan `readingTimeMinutes` dihitung otomatis dari `contentJson`.
- Embed URLs di `contentJson` divalidasi (hanya YouTube, Instagram, TikTok, Spotify).

**Response**: Article object

### 4.3 Update article — `PUT /articles/:id`

**Tujuan**: Update artikel existing.

- Guard: ✅ `JwtAuthGuard` + ✅ `CmsAdminGuard`
- Content-Type: `application/json`

**Request body (UpdateArticleDto)**: Same as create, semua field optional.

**Server-side behavior**

- Jika `contentJson` diupdate: derived fields dihitung ulang, `contentVersion` increment.

### 4.4 Publish article — `POST /articles/:id/publish`

**Tujuan**: Set status ke PUBLISHED dan set `publishedAt`.

- Guard: ✅ `JwtAuthGuard` + ✅ `CmsAdminGuard`

**Request body**

```json
{
  "publishedAt": "2025-12-25T00:00:00.000Z" // optional, default: now()
}
```

### 4.5 Unpublish article — `POST /articles/:id/unpublish`

**Tujuan**: Revert status ke DRAFT.

- Guard: ✅ `JwtAuthGuard` + ✅ `CmsAdminGuard`

### 4.6 Link asset to article — `POST /articles/:id/link-asset`

**Tujuan**: Track asset usage untuk offline manifest.

- Guard: ✅ `JwtAuthGuard` + ✅ `CmsAdminGuard`

**Request body**

```json
{
  "assetId": "uuid"
}
```

### 4.7 Admin list + filtering — `GET /cms/articles`

**Tujuan**: list artikel untuk dashboard admin (termasuk draft/archived) + filtering.

- Guard: ✅ `JwtAuthGuard` + ✅ `CmsAdminGuard`

**Query params**

- `q?: string` → search ke `title`/`slug` (contains, case-insensitive)
- `title?: string` → filter title contains
- `authorId?: string` → filter berdasarkan `Profiles.id`
- `status?: DRAFT|PUBLISHED|ARCHIVED`
- `from?: string` → ISO date (filter `createdAt >= from`)
- `to?: string` → ISO date (filter `createdAt <= to`)
- `page?: number` (default 1)
- `limit?: number` (default 20, max 100)
- `sort?: string` (default `createdAt:desc`)
  - allowed field: `createdAt | updatedAt | title | status`
  - direction: `asc | desc`

**Response (shape)**

- `{ "items": Article[], "total": number, "page": number, "limit": number }`

### 4.8 Get single article for edit — `GET /cms/articles/:id`

**Tujuan**: Ambil artikel lengkap untuk form edit.

- Guard: ✅ `JwtAuthGuard` + ✅ `CmsAdminGuard`

**Response**: Full Article object including `contentJson`.

---

## 5) Public endpoints (Flutter/mobile)

### 5.1 Public feed — `GET /articles/public`

**Tujuan**: feed artikel published-only untuk mobile.

- Guard: ❌ none (public)
- Visibility rule: `status=PUBLISHED AND publishedAt <= now()`

**Query params (cursor-based)**

- `limit?: number` (default 20, max 50)
- `cursorCreatedAt?: string` (ISO date)
- `cursorId?: string`
- `section?: string` → filter by section
- `seriesId?: string` → filter by series
- `from?: string` → articles published after this date
- `tag?: string` → filter by single tag

Aturan:

- `cursorCreatedAt` dan `cursorId` harus dikirim **berpasangan**.
- Urutan list stable: `publishedAt desc`, lalu `id desc`.

**Response**

```typescript
{
  items: ArticlePublic[],
  nextCursor: { createdAt: string, id: string } | null
}

// ArticlePublic shape:
{
  id: string;
  title: string;
  subtitle?: string;
  slug: string;
  snippet?: string;
  authorDisplayName: string;
  coverUrl?: string;
  section?: string;
  seriesId?: string;
  seriesOrder?: number;
  tags: string[];
  wordCount?: number;
  readingTimeMinutes?: number;
  publishedAt: string;

  // Asset manifest for offline caching
  assets: Asset[];
}
```

**Client behavior**

- Page 1: panggil tanpa cursor.
- Next page: kirim `cursorCreatedAt=nextCursor.createdAt` dan `cursorId=nextCursor.id`.
- Stop: ketika `nextCursor` null.

### 5.2 Public detail by slug — `GET /articles/public/:slug`

**Tujuan**: ambil detail artikel published-only + full content + asset manifest.

- Guard: ❌ none (public)
- Jika slug tidak ada / status bukan published / publishedAt future → `404`

**Response**

```typescript
{
  id: string;
  title: string;
  subtitle?: string;
  slug: string;
  snippet?: string;

  // Content
  contentJson: object;        // ProseMirror JSON - render this in Flutter
  contentHtml?: string;       // HTML alternative for web

  authorDisplayName: string;
  coverUrl?: string;
  section?: string;
  seriesId?: string;
  seriesOrder?: number;
  tags: string[];
  wordCount?: number;
  readingTimeMinutes?: number;
  contentVersion: number;
  publishedAt: string;

  // Asset manifest for offline caching
  assets: Asset[];
}
```

---

## 6) SvelteKit CMS — implementasi yang disarankan

### 6.1 Token handling

- Simpan access token JWT (misalnya di cookie httpOnly via endpoint auth SvelteKit, atau di memory store jika UI sederhana).
- Set header `Authorization` untuk request ke API.

### 6.2 ProseMirror editor integration

- Gunakan ProseMirror editor (TipTap, Lexical, etc.)
- Export JSON sebagai `contentJson`
- Optionally generate HTML sebagai `contentHtml` untuk preview

### 6.3 Upload dari editor

**Image upload:**

1. Drag/drop/paste image di editor
2. Upload ke `POST /articles/upload-asset`
3. Terima response dengan `assetId` dan `url`
4. Sisipkan node ke ProseMirror:
   ```json
   { "type": "image", "attrs": { "src": "url", "assetId": "uuid" } }
   ```

**Video upload:**

1. Select video file (max 50MB)
2. Upload ke `POST /articles/upload-asset`
3. Terima response dengan `assetId`, `url`, `kind: "VIDEO"`
4. Sisipkan node ke ProseMirror:
   ```json
   { "type": "video", "attrs": { "src": "url", "assetId": "uuid" } }
   ```

### 6.4 Embed handling

Supported providers: YouTube, Instagram, TikTok, Spotify

Saat user paste URL embed:

1. Parse URL untuk detect provider
2. Jika allowed provider, sisipkan node:
   ```json
   { "type": "embed", "attrs": { "provider": "youtube", "url": "..." } }
   ```
3. Backend akan validate saat save

### 6.5 Create/update article

- Kirim `contentJson` (ProseMirror JSON)
- Jangan kirim `authorId`, `wordCount`, `readingTimeMinutes` (computed server-side)

### 6.6 Publishing workflow

1. Create article with `status: DRAFT`
2. Edit dan preview
3. Ready? Call `POST /articles/:id/publish` with optional `publishedAt` for scheduled
4. Need to revise? Call `POST /articles/:id/unpublish`

### 6.7 Admin list

- Gunakan `GET /cms/articles`.
- Untuk search: pakai `q=...`.
- Filter by section: `section=devotional`

---

## 7) Flutter — implementasi yang disarankan

### 7.1 Feed screen

```dart
// State
List<ArticlePublic> items = [];
Map<String, String>? nextCursor;
bool isLoading = false;

// Load initial
final response = await api.get('/articles/public', query: {'limit': 20});
items = response.items;
nextCursor = response.nextCursor;

// Load more
if (nextCursor != null) {
  final response = await api.get('/articles/public', query: {
    'limit': 20,
    'cursorCreatedAt': nextCursor['createdAt'],
    'cursorId': nextCursor['id'],
  });
  items.addAll(response.items);
  nextCursor = response.nextCursor;
}
```

### 7.2 Detail screen with ProseMirror rendering

```dart
// Fetch
final article = await api.get('/articles/public/$slug');

// Render contentJson
// Gunakan library seperti flutter_quill atau custom ProseMirror renderer
ProseMirrorRenderer(
  document: article.contentJson,
  imageBuilder: (src, assetId) => CachedNetworkImage(imageUrl: src),
  videoBuilder: (src, assetId) => VideoPlayerWidget(url: src),
  embedBuilder: (provider, url) => EmbedWidget(provider: provider, url: url),
);
```

### 7.3 Offline caching dengan asset manifest

```dart
// Saat fetch article, cache assets untuk offline
final article = await api.get('/articles/public/$slug');

for (final asset in article.assets) {
  await cacheManager.downloadFile(
    asset.url,
    key: asset.id,
  );
}

// Cache contentVersion untuk invalidation
await prefs.setInt('article_${article.id}_version', article.contentVersion);

// Check if needs refresh
final cachedVersion = prefs.getInt('article_${article.id}_version') ?? 0;
if (article.contentVersion > cachedVersion) {
  // Re-fetch and re-cache
}
```

### 7.4 Embed rendering

```dart
Widget buildEmbed(String provider, String url) {
  switch (provider) {
    case 'youtube':
      return YouTubePlayer(url: url);
    case 'instagram':
      return InstagramEmbed(url: url);
    case 'tiktok':
      return TikTokEmbed(url: url);
    case 'spotify':
      return SpotifyEmbed(url: url);
    default:
      return SizedBox.shrink();
  }
}
```

---

## 8) Troubleshooting

- **Upload gagal 400**:
  - pastikan field name `file`
  - Image: mime `image/*`, max 10MB
  - Video: mime `video/mp4|webm|quicktime`, max 50MB
- **Create 403**: pastikan email admin ada di `CMS_ADMIN_EMAILS` (case-insensitive)
- **Create 400 embed error**: Embed URL tidak dari provider yang allowed (YouTube, Instagram, TikTok, Spotify)
- **Feed 400**:
  - jangan kirim hanya `cursorCreatedAt` tanpa `cursorId` (harus pasangan)
  - pastikan `cursorCreatedAt` ISO date valid
- **Article not appearing in feed**:
  - Pastikan `status = PUBLISHED`
  - Pastikan `publishedAt <= now()` (bukan scheduled future)

---

## 9) Migration notes

### From legacy content to contentJson

Jika ada artikel lama dengan `content` (HTML):

1. Backend tetap support `content` field
2. Untuk artikel baru, gunakan `contentJson`
3. Flutter should check: `if (contentJson != null) renderProseMirror() else renderHtml()`

### Compatibility with old docs

`docs/liveit-feat_article-UPDATE_FIX.md` adalah draft awal implementasi sebelum:

- admin guarding via JWT + allowlist
- pemisahan endpoint public vs cms
- cursor pagination
- authorId relation
- **Medium-like features (contentJson, assets, embeds)**

Untuk implementasi client terbaru, gunakan dokumen ini (`docs/ARTICLES_CLIENT_GUIDE.md`).

---

## 10) Backend Rules & Constraints (PENTING!)

### 10.1 Content Rules

| Rule                     | Detail                                                                  |
| ------------------------ | ----------------------------------------------------------------------- |
| **contentJson required** | Artikel baru WAJIB kirim `contentJson` (ProseMirror JSON)               |
| **Embed allowlist**      | Hanya YouTube, Instagram, TikTok, Spotify. URL lain = 400 error         |
| **Embed URL patterns**   | `youtube.com`, `youtu.be`, `instagram.com`, `tiktok.com`, `spotify.com` |
| **Derived fields**       | `wordCount`, `readingTimeMinutes` dihitung otomatis dari `contentJson`  |
| **contentVersion**       | Auto-increment setiap kali `contentJson` diupdate                       |

### 10.2 Asset Rules

| Rule               | Detail                                                                |
| ------------------ | --------------------------------------------------------------------- |
| **Image max size** | 10 MB                                                                 |
| **Video max size** | 50 MB                                                                 |
| **Image MIME**     | `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/svg+xml` |
| **Video MIME**     | `video/mp4`, `video/webm`, `video/quicktime`                          |
| **Asset response** | Returns `assetId`, `url`, `kind`, `mime`, `sizeBytes`                 |

### 10.3 Publishing Rules

| Rule                   | Detail                                                                       |
| ---------------------- | ---------------------------------------------------------------------------- |
| **Visibility formula** | `status = PUBLISHED` AND `publishedAt <= now()`                              |
| **Scheduled publish**  | Set `publishedAt` ke future date, artikel tidak muncul sampai waktu tersebut |
| **Unpublish**          | Revert ke `DRAFT`, `publishedAt` di-clear                                    |
| **Default status**     | `DRAFT` jika tidak disertakan                                                |

### 10.4 Authorization Rules

| Rule                  | Detail                                             |
| --------------------- | -------------------------------------------------- |
| **CMS endpoints**     | Butuh `Authorization: Bearer <JWT>`                |
| **Admin check**       | Email di JWT harus ada di env `CMS_ADMIN_EMAILS`   |
| **Public endpoints**  | Tidak butuh auth                                   |
| **authorId**          | Auto-set dari JWT `sub` claim (Profiles.id)        |
| **authorDisplayName** | Auto-set dari profile name, fallback "LiveIt Team" |

### 10.5 Pagination Rules

| Endpoint               | Style  | Details                                       |
| ---------------------- | ------ | --------------------------------------------- |
| `GET /articles/public` | Cursor | `cursorCreatedAt` + `cursorId` harus pasangan |
| `GET /cms/articles`    | Offset | `page` + `limit` (max 100)                    |

### 10.6 Sorting Rules (CMS)

| Field         | Allowed            |
| ------------- | ------------------ |
| `createdAt`   | ✅ (default: desc) |
| `updatedAt`   | ✅                 |
| `title`       | ✅                 |
| `status`      | ✅                 |
| `publishedAt` | ❌                 |

Format: `sort=field:direction` (e.g., `sort=title:asc`)

---

## 11) Quick Reference — Endpoint Table

### CMS Endpoints (Guarded)

| Method | Endpoint                   | Purpose               | Auth        |
| ------ | -------------------------- | --------------------- | ----------- |
| `POST` | `/articles/upload-asset`   | Upload image/video    | JWT + Admin |
| `POST` | `/articles`                | Create article        | JWT + Admin |
| `PUT`  | `/articles/:id`            | Update article        | JWT + Admin |
| `POST` | `/articles/:id/publish`    | Publish article       | JWT + Admin |
| `POST` | `/articles/:id/unpublish`  | Unpublish article     | JWT + Admin |
| `POST` | `/articles/:id/link-asset` | Link asset to article | JWT + Admin |
| `GET`  | `/cms/articles`            | List with filters     | JWT + Admin |
| `GET`  | `/cms/articles/:id`        | Get single for edit   | JWT + Admin |

### Public Endpoints (No Auth)

| Method | Endpoint                 | Purpose               | Auth |
| ------ | ------------------------ | --------------------- | ---- |
| `GET`  | `/articles/public`       | Feed (published only) | ❌   |
| `GET`  | `/articles/public/:slug` | Detail by slug        | ❌   |

---

## 12) Example Payloads

### 12.1 Create Article (Minimal)

```json
{
  "title": "Hidup dalam Iman",
  "slug": "hidup-dalam-iman",
  "contentJson": {
    "type": "doc",
    "content": [
      {
        "type": "paragraph",
        "content": [{ "type": "text", "text": "Artikel pertama..." }]
      }
    ]
  }
}
```

### 12.2 Create Article (Full)

```json
{
  "title": "Hidup dalam Iman",
  "subtitle": "Renungan Harian",
  "slug": "hidup-dalam-iman",
  "snippet": "Bagaimana iman mempengaruhi kehidupan sehari-hari...",
  "contentJson": {
    "type": "doc",
    "content": [
      {
        "type": "heading",
        "attrs": { "level": 1 },
        "content": [{ "type": "text", "text": "Pendahuluan" }]
      },
      {
        "type": "paragraph",
        "content": [{ "type": "text", "text": "Lorem ipsum..." }]
      },
      {
        "type": "image",
        "attrs": {
          "src": "https://appwrite.../view",
          "assetId": "abc123"
        }
      },
      {
        "type": "embed",
        "attrs": {
          "provider": "youtube",
          "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        }
      }
    ]
  },
  "contentHtml": "<h1>Pendahuluan</h1><p>Lorem ipsum...</p>",
  "coverAssetId": "xyz789",
  "tags": ["iman", "renungan"],
  "section": "devotional",
  "seriesId": "seri-iman-2025",
  "seriesOrder": 1,
  "status": "DRAFT"
}
```

### 12.3 Publish Article

```json
{
  "publishedAt": "2025-12-25T06:00:00.000Z"
}
```

Or empty body for immediate publish:

```json
{}
```

### 12.4 Public Feed Response

```json
{
  "items": [
    {
      "id": "uuid",
      "title": "Hidup dalam Iman",
      "subtitle": "Renungan Harian",
      "slug": "hidup-dalam-iman",
      "snippet": "Bagaimana iman...",
      "authorDisplayName": "Tim LiveIt",
      "coverUrl": "https://...",
      "section": "devotional",
      "tags": ["iman"],
      "wordCount": 450,
      "readingTimeMinutes": 2,
      "publishedAt": "2025-12-20T06:00:00.000Z",
      "assets": [
        {
          "id": "abc123",
          "kind": "IMAGE",
          "url": "https://...",
          "mime": "image/jpeg",
          "sizeBytes": 102400
        }
      ]
    }
  ],
  "nextCursor": {
    "createdAt": "2025-12-20T06:00:00.000Z",
    "id": "uuid"
  }
}
```

---

## 13) ProseMirror Node Types (untuk Flutter renderer)

Berikut node types yang perlu di-handle di Flutter:

| Node Type        | Attrs                    | Render As                               |
| ---------------- | ------------------------ | --------------------------------------- |
| `doc`            | -                        | Container                               |
| `paragraph`      | -                        | `<p>` / Text widget                     |
| `heading`        | `level: 1-6`             | `<h1>`-`<h6>` / Text with style         |
| `text`           | `marks: []`              | Plain text / styled                     |
| `image`          | `src`, `assetId`, `alt?` | Image widget                            |
| `video`          | `src`, `assetId`         | Video player                            |
| `embed`          | `provider`, `url`        | YouTube/Instagram/TikTok/Spotify widget |
| `bulletList`     | -                        | Unordered list                          |
| `orderedList`    | -                        | Ordered list                            |
| `listItem`       | -                        | List item                               |
| `blockquote`     | -                        | Quote block                             |
| `codeBlock`      | `language?`              | Code block                              |
| `horizontalRule` | -                        | Divider                                 |

### Text Marks

| Mark        | Attrs  | Style                      |
| ----------- | ------ | -------------------------- |
| `bold`      | -      | FontWeight.bold            |
| `italic`    | -      | FontStyle.italic           |
| `underline` | -      | TextDecoration.underline   |
| `strike`    | -      | TextDecoration.lineThrough |
| `link`      | `href` | Clickable, blue color      |
| `code`      | -      | Monospace font             |

---

## 14) Swagger UI

Backend menyediakan dokumentasi interaktif di:

```
GET /api
```

Semua endpoint articles sudah terdokumentasi dengan:

- Request/response schemas
- Example payloads
- Error codes
- Query parameters
