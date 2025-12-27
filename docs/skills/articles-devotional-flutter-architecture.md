# Skill: Articles / Daily Devotional (Flutter) — Big-picture Architecture & Implementation Guide

Tanggal: 2025-12-27  
Scope: Flutter app LIVEIT (MVP fokus Daily Devotional), backend endpoint tetap bernama **Articles**.  
Kontrak backend/CMS rujukan: `docs/devotional-page/*`.

Dokumen ini **tidak** membuat file/kode Dart. Tujuannya memberi gambaran arsitektur dan checklist implementasi yang “boring, predictable, type-safe”.

---

## 1) Konsep utama (cara berpikir feature ini)

LIVEIT ingin mengubah _knowing_ → _living_. Untuk konten renungan/artikel, implikasinya:

- Konten harus **enak dibaca** (typography + struktur), bukan sekadar HTML mentah.
- Data flow harus **stabil** dan **defensive**: error jelas, state tidak tumpang tindih.
- Backend menyebutnya **Articles** karena konten akan berkembang (serial, tema khusus, dsb). Di MVP, Flutter cukup treat “Daily Devotional” sebagai:
  - `Article` dengan filter `section=devotional` (atau aturan tanggal publish), dan
  - UI yang menampilkan “feed daily” + “detail reader”.

---

## 2) Surface API yang relevan untuk Flutter (public)

Flutter (public/mobile) **tidak** pakai endpoint CMS (yang butuh JWT + allowlist). Ia konsumsi endpoint public:

- `GET /articles/public`

  - Cursor pagination
  - supports filters: `section`, `date`, `tag` (lihat backend, minimal `section`)
  - response: `{ items: [...], nextCursor?: { createdAt, id } }`

- `GET /articles/public/:slug`
  - detail artikel published-only
  - response mengandung `contentJson` (ProseMirror JSON), dan **asset manifest** untuk offline (jika backend menambahkannya)

Catatan penting (sumber: `ARTICLES_CLIENT_GUIDE.md`):

- Visibility rule: `status=PUBLISHED AND publishedAt <= now()`.
- Urutan list stable: `publishedAt desc`, lalu `id desc`.
- Cursor untuk pagination dikirim berpasangan: `cursorCreatedAt` + `cursorId`.
- `nextCursor.createdAt` adalah **cursor timestamp** yang dikembalikan backend (jangan diasumsikan sama dengan `publishedAt` item terakhir jika backend memilih field lain).

Catatan:

- `GET /articles` masih ada untuk kompatibilitas awal, tapi saran backend: gunakan `GET /articles/public`.

---

## 3) Target experience di Flutter (MVP)

Di MVP (Daily Devotional), minimal UX yang “pas”:

1. **Devotional feed**

   - list artikel terbaru (published-only) dengan kartu ringkas (title, verse/snippet, date, likes optional)
   - optional: filter `section=devotional`

2. **Devotional detail / reader**

   - hero/cover
   - title + metadata (author, reading time)
   - render isi dari `contentJson` → widget tree

3. **Resiliency**
   - loading skeleton
   - error state (retry)
   - empty state (tidak ada devotional hari ini)

---

## 4) Architecture di Flutter (boring + feature-first)

Ikuti pola repo:

- `lib/features/inspire/` (feature ini sudah ada)

Tambahkan 3 layer seperti feature lain (home):

1. **presentation**

- Pages, widgets
- Bloc/Cubit (state management)

1. **domain**

- Entity/value objects (mis. `Article`, `ArticleId`, `ArticleSlug` bila mau)
- Repository contract (interface)
- Use cases kecil (opsional) — _hanya jika_ mengurangi kompleksitas UI. Kalau belum perlu, skip.

1. **data**

- DTO (JSON serialization)
- Remote data source (HTTP)
- Repository implementation (mapping DTO → domain)
- (Optional) local cache data source

### 4.1 Prinsip “Defensive Data Architecture”

Hindari state seperti `isLoading + error + data` barengan.

Gunakan discriminated union (di Dart bisa pakai `sealed class` / `freezed` / pattern manual).

Contoh shape state (konsep, bukan kode):

- `FeedState = idle | loading | success(items, nextCursor) | empty | failure(error)`
- `DetailState = idle | loading | success(article) | failure(error)`

Error type juga sebaiknya tipe yang jelas:

- `NetworkError` (timeout, no connection)
- `ApiError` (status code + message)
- `ParseError`

---

## 5) DTO & mapping (yang perlu kamu buat)

Backend contract (ringkas) dari `ARTICLES_CLIENT_GUIDE.md`:

### 5.1 Article (backend shape)

Field penting untuk MVP reader:

- `id: string`
- `title: string`
- `subtitle?: string`
- `slug: string`
- `snippet?: string`
- `contentJson: object` (ProseMirror JSON)
- `coverUrl?: string` (atau dari `Asset`)
- `authorDisplayName: string`
- `status: DRAFT|PUBLISHED|ARCHIVED` (public harusnya selalu PUBLISHED)
- `publishedAt?: ISO string`
- `section?: string` (devotional)
- `tags: string[]`
- `wordCount?: number`
- `readingTimeMinutes?: number`
- `contentVersion: number`
- `createdAt`, `updatedAt`

### 5.2 Cursor pagination (feed)

Response pattern:

- `items: Article[]`
- `nextCursor?: { createdAt: string, id: string }`

DTO yang kamu bikin di Flutter (saran):

- `ArticleDto`
- `ArticlesPageDto` (items + nextCursor)
- `CursorDto` (createdAt + id)

### 5.3 Mapping rules (tegas)

- Fail fast jika field wajib null/missing.
- Tanggal: parse `publishedAt/createdAt` → `DateTime` **UTC** dulu (blueprint menyebut tahap awal UTC).
- `contentJson`: simpan sebagai `Map<String, dynamic>` (structured JSON). Validasi minimal:
  - `type` harus `doc` (jika memakai ProseMirror default)
  - `content` array ada

---

## 6) Rendering strategy untuk `contentJson` (penting)

Backend doc menekankan: **jangan render HTML mentah** untuk Flutter reader.

Dokumen spec renderer v1 (tanpa kode): `docs/skills/articles-prosemirror-renderer-v1-spec.md`.

### 6.1 Jalur rekomendasi: ProseMirror JSON → Widget tree

Bikin renderer yang:

- Input: `contentJson` (Map)
- Output: list of widgets (atau satu widget yang membangun tree)

Mapping minimal node types untuk MVP:

- `paragraph` → `Text` (selectable optional)
- `text` (marks: bold/italic/link)
- `heading` (level 1-3)
- `bullet_list` / `ordered_list`
- `list_item`
- `image` (gunakan `url` atau resolve via assetId)

Keputusan MVP (minimum dulu):

- Fokus support node: `heading`, `paragraph`, `text` (bold/italic/link), `bullet_list`, `ordered_list`, `list_item`, `image`.
- Node lain (mis. `blockquote`, `callout`, `code_block`, `video`) boleh fallback ke placeholder “Unsupported content” untuk v1.

### 6.3 Embed policy (MVP)

- Embed yang disupport di MVP: **YouTube saja**.
- Provider lain ditampilkan sebagai link biasa atau placeholder (jangan crash).

### 6.2 Security & validation

- Allowlist node types yang kamu support.
- Jika ketemu node type unknown:
  - fallback ke widget “Unsupported content” tapi jangan crash.

---

## 7) State management (Bloc) — contract yang boring

Feature ini minimal butuh 2 Bloc (atau 1 Bloc dengan 2 sub-state, tapi 2 lebih jelas):

1. `ArticlesFeedBloc`

   - load first page
   - load next page (cursor)
   - refresh
   - apply filter `section=devotional`

2. `ArticleDetailBloc`
   - load by `slug`

### 7.1 Events (konsep)

Feed:

- `Started(section)`
- `Refreshed`
- `NextPageRequested`

Detail:

- `Started(slug)`

### 7.2 States (konsep)

Feed state:

- `Loading`
- `Success(items, nextCursor, isFetchingMore)` (atau pisah state `FetchingMore`)
- `Empty`
- `Failure(error)`

Detail state:

- `Loading`
- `Success(article)`
- `Failure(error)`

Catatan: pastikan `isFetchingMore` tidak bikin illegal state:

- Jangan mixing “Failure” dan “Success” sekaligus.
- Kalau fetch next page gagal, bisa:
  1. keep current items + show “inline error” (ini valid), atau
  2. move to failure state (biasanya UX lebih buruk).

Kalau kamu pilih (1), definisikan state yang eksplisit: `Success(..., paginationFailure?)` agar legal & jelas.

---

## 8) Repository contract (domain) & implementation (data)

### 8.1 Domain contract (public)

Buat `ArticlesRepository` dengan minimal method:

- `Future<ArticlesPage> getPublicArticles({ section, limit, cursor })`
- `Future<Article> getPublicArticleBySlug(String slug)`

### 8.2 Data implementation

- `ArticlesRemoteDataSource` (pakai `http`/`dio` — sesuaikan preferensi repo)
- `ArticlesRepositoryImpl`
  - memanggil data source
  - mapping DTO → domain
  - translate error → domain error

### 8.3 AppConfig baseUrl

Ikuti repo: base URL harus lewat `AppConfig.apiBaseUrl` (dotenv wrapper) agar env switching konsisten.

---

## 9) Caching & offline (MVP vs next)

Dokumen backend menyebut asset manifest untuk offline.

Catatan:

- Public feed (`GET /articles/public`) mengembalikan `assets: Asset[]` pada tiap item (lihat `ArticlePublic` di backend guide). Detail endpoint juga mengembalikan asset manifest.
- Untuk MVP, kamu boleh abaikan prefetch asset dan cukup gunakan image caching default. Gunakan asset manifest saat kamu benar-benar butuh offline mode.

Saran implementasi bertahap:

### MVP (recommended minimal)

- No offline caching.
- Rely on normal HTTP cache (jika ada) + image caching dari Flutter.

### Step berikut (kalau kamu mau)

- Cache list page hasil `GET /articles/public` per `section` + cursor di local storage.
- Cache detail artikel by slug dengan `contentVersion`.

Kunci: jangan implement offline sebelum benar-benar dibutuhkan (YAGNI).

---

## 10) Like / engagement (optional, tergantung backend)

Di UI kamu sekarang ada `likes` dummy.

Keputusan MVP (berdasarkan Q&A Flutter team):

- Like endpoint untuk **articles public** belum ada → **skip dulu**.
- Jangan expose UI like sampai backend contract-nya jelas.

---

## 11) Integrasi ke UI `DevotionPage`

Target refactor minimal:

- Replace hardcoded `SliverChildListDelegate([...DevotionalCard(...)])` dengan:
  - BlocBuilder pada `ArticlesFeedBloc`
  - map `items` → `DevotionalCard`

Navigation:

- Tap card → route ke detail page dengan parameter `slug`.

## 11.1 Slug vs ID (keputusan + use case)

MVP keputusan:

- **Routing/navigasi detail**: pakai `slug` saja (`/articles/public/:slug`). Ini paling natural untuk reader dan stabil untuk deep link.
- **Tetap simpan `id`** di model/domain sebagai identifier internal.

Kenapa `id` masih berguna walau navigasi pakai `slug`?

- **Cursor pagination**: `nextCursor` mengandung `id`, jadi feed state perlu menyimpannya untuk request page berikutnya.
- **Cache keys** (kalau nanti ada caching): `id` cocok sebagai key internal yang tidak berubah; `slug` bisa berubah kalau editorial revisi.
- **Analytics / logging**: event tracking lebih aman memakai `id` sebagai primary key.
- **Future interactions** (bukan MVP): like, bookmark, report—sering lebih aman pakai `id` dibanding slug.

---

## 12) Checklist implementasi (urut paling aman)

1. Buat DTO berdasarkan kontrak backend:

- ArticleDto
- CursorDto
- ArticlesPageDto

1. Buat remote data source:

- GET `/articles/public`
- GET `/articles/public/:slug`

1. Buat domain models + repository contract.

1. Buat repository impl + mapping + error translation.

1. Buat `ArticlesFeedBloc` + `ArticleDetailBloc`.

1. Wiring dependency injection (sesuaikan pattern di repo; kalau belum ada DI, bisa manual di widget tree).

1. Update `DevotionPage` untuk pakai Bloc state.

1. Buat `DevotionDetailPage` untuk render contentJson.

1. Testing:

- unit test mapping DTO → domain
- bloc test untuk feed & detail success/failure

---

## 12.1 Step-by-step implementasi MVP (operasional, tanpa kode)

Bagian ini adalah urutan kerja yang paling aman supaya kamu bisa implement cepat, tapi tetap type-safe.

### Step 1 — Kunci “contract” yang akan kamu implement

1. Pastikan base URL sudah kebaca dari env yang dipakai app.
1. Pastikan kamu hanya pakai public endpoints:

- `GET /articles/public?section=devotional&limit=...`
- `GET /articles/public/:slug`

1. Kunci keputusan MVP:

- Devotional feed: `section=devotional`
- Ordering server: `publishedAt desc` (backend already handles)
- Pagination: cursor pair `cursorCreatedAt` + `cursorId`
- Detail route: pakai `slug`
- Like: skip
- Embed: YouTube-only

Output yang harus kamu punya setelah step ini:

- Satu catatan kontrak (bisa copy dari dokumen ini) yang jadi pegangan saat bikin DTO/repository.

### Step 2 — Buat DTO (data layer) + JSON parsing rules

Implement DTO sesuai `ArticlePublic` di backend guide.

Checklist DTO:

1. `CursorDto`

- `createdAt: DateTime` (parse ISO)
- `id: String`

1. `AssetDto` (minimal)

- `id`, `kind`, `url`, `mime`, `sizeBytes`
- `width/height/durationSeconds` optional

1. `ArticlePublicDto`

- Wajib: `id`, `title`, `slug`, `authorDisplayName`, `tags`, `publishedAt`, `contentJson` (detail), `assets`
- Optional: `subtitle`, `snippet`, `coverUrl`, `section`, `readingTimeMinutes`, `wordCount`

1. `ArticlesPageDto`

- `items: List<ArticlePublicDto>`
- `nextCursor: CursorDto?` (null artinya stop pagination)

Rules:

- `cursorCreatedAt` dan `cursorId` harus dikirim berpasangan di request.
- Parse `publishedAt` sebagai UTC (`DateTime.parse(...).toUtc()`), dan baru `toLocal()` saat display.
- `contentJson` untuk list endpoint: boleh saja tidak ada / minimal (tergantung server). Jangan asumsi feed selalu bawa full doc.

### Step 3 — Buat Remote Data Source (HTTP) dengan request params yang jelas

Checklist fungsi yang kamu butuhkan:

1. `fetchPublicArticlesPage(section, limit, cursor?)`

- kalau `cursor == null`: request tanpa cursor params
- kalau `cursor != null`: kirim `cursorCreatedAt` + `cursorId`
- handle response → `ArticlesPageDto`

1. `fetchPublicArticleDetail(slug)`

- handle 404 → map menjadi “not found” error untuk UI

Error handling minimal:

- 5xx/timeout/no-network → `NetworkError`
- 4xx (selain 404) → `ApiError`
- parse JSON gagal → `ParseError`

### Step 4 — Buat Domain model + mapping DTO → domain

Tujuan domain layer:

- Menyederhanakan kebutuhan UI (jangan UI berurusan dengan JSON map mentah).

Checklist:

1. Domain `Article`

- simpan `id` dan `slug` keduanya
- simpan `publishedAt` sebagai `DateTime`
- simpan `contentJson` sebagai `Map<String, dynamic>` untuk reader
- simpan `assets` sebagai list domain asset (atau minimal pass-through)

1. Domain `ArticlesPage`

- `items`
- `nextCursor?`

Mapping rules:

- Fail fast di mapping jika field wajib missing.
- `nextCursor` diperlakukan opaque: simpan dan kirim kembali apa adanya.

### Step 5 — Buat Repository (domain contract + impl)

Checklist:

1. Domain contract `ArticlesRepository`

- `getPublicArticlesPage(...)`
- `getPublicArticleBySlug(slug)`

1. Impl memanggil remote datasource
1. Impl melakukan mapping DTO → domain
1. Impl translate error ke domain error

### Step 6 — Implement state management (2 Bloc)

#### 6A) Feed bloc

Checklist behavior:

1. Start → load page pertama
1. Next page → hanya jika:

- tidak sedang loading page berikut
- `nextCursor != null`

1. Refresh → reset items + cursor, lalu load ulang

Kontrak UX:

- Pagination error tidak boleh menghapus items yang sudah ada.
- Ketika `nextCursor == null`: UI stop infinite scroll.

#### 6B) Detail bloc

Checklist behavior:

1. Start(slug) → load detail
2. Handle 404 seperti “Artikel tidak ditemukan” (bukan generic error)

### Step 7 — Wiring UI: `DevotionPage` (feed)

Checklist:

1. Replace dummy cards → render dari state success items
1. Infinite scroll trigger:

- trigger `NextPageRequested` saat posisi list mendekati bawah
- tampilkan loading indicator row di bawah list saat pagination

1. Empty state:

- kalau items kosong → tampilkan copy yang sesuai brand voice (actionable)

1. Error state:

- tampilkan retry yang memicu `Refreshed`

### Step 8 — Buat Reader page (detail)

Checklist UI:

1. Header: cover + title + meta
1. Content: render `contentJson` dengan renderer v1 spec

- rujukan: `docs/skills/articles-prosemirror-renderer-v1-spec.md`

1. Fallback:

- jika contentJson empty/invalid → tampilkan “Konten tidak dapat ditampilkan”

### Step 9 — Implement renderer v1 (minimum)

Ikuti spec renderer v1.

Checklist minimal done:

- `heading`, `paragraph`, `text` marks (bold/italic/link)
- lists
- image (plus caption jika ada)
- embed YouTube-only
- unknown nodes → safe fallback

### Step 10 — Tests (paling worth it untuk menghindari regresi)

Minimal tests yang murah tapi impactful:

1. DTO parsing: JSON sample → DTO
2. Mapping DTO → domain (field required + optional)
3. Feed bloc: success page 1, next page, stop when nextCursor null
4. Detail bloc: success + 404
5. Renderer: fixtures JSON (heading/paragraph/list/image/youtube)

---

## 13) Clarifying questions (biar implementasi kamu tepat)

Bagian ini awalnya berupa pertanyaan untuk mengunci keputusan. Karena kamu sudah kirim jawaban Q&A dari tim Flutter, maka keputusan yang dipakai untuk MVP adalah:

1. **Daily Devotional fetch rule**: gunakan `section=devotional` + urutan `publishedAt desc`.
2. **Timezone**: MVP pakai UTC sebagai source-of-truth di server (Flutter hanya menampilkan `publishedAt` dalam local time untuk UI).
3. **Like**: skip dulu (belum ada endpoint).

Hal yang masih perlu dikunci (kalau ingin dokumen ini makin presisi):

1. **Slug vs ID**: sudah dikunci (route pakai slug; simpan id untuk cursor/cache/analytics).
2. **Renderer scope**: sudah dikunci (minimum node set untuk v1).
3. **Embed policy**: sudah dikunci (YouTube-only di MVP).

---

## 14) Decision notes (rationale)

- Kita pakai `Article` universal + metadata `section` untuk devotional: **YAGNI** dan sesuai roadmap (serial/topik khusus nanti).
- Flutter render dari `contentJson` (ProseMirror JSON), bukan HTML: ini satu keputusan besar yang bikin reader “Medium-like” dan konsisten.
- State dibuat discriminated/explicit agar illegal states tidak representable.
