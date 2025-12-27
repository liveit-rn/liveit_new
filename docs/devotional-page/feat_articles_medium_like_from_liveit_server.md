# Medium-like Articles for LIVEIT (CMS → Backend → Flutter Reader)

Context: (updated from liveit-server-api) 2025-12-19

Dokumen ini menjawab kebutuhan: **konten artikel LIVEIT harus punya fleksibilitas setara Medium** untuk dibaca di **mobile app Flutter**, dengan CMS yang sudah ada sebagai dasar produksi konten.

Prinsip yang dipakai: _boring, predictable, type-safe_. Kita menghindari fitur “mungkin nanti” yang tidak mendukung outcome membaca, tapi tetap memilih fondasi yang **paling powerful** sesuai permintaan (rich content: image/video/embed/footnote/pull-quote).

---

## 1) TL;DR (Rekomendasi yang paling aman & powerful)

1. **Jangan simpan artikel sebagai HTML saja** kalau targetnya Medium-level di Flutter.
   - Simpan **ProseMirror JSON** (document model) sebagai source-of-truth.
   - HTML boleh tetap ada sebagai **derived output** untuk web/preview/SEO.

2. Flutter reader jangan render HTML mentah.
   - Render dari **ProseMirror JSON → Widget tree** (custom renderer), supaya:
     - typography konsisten,
     - embed lebih aman,
     - fitur seperti footnotes/pull-quotes bisa dibuat native.

3. Backend wajib punya:
   - **Sanitization/allowlist** (untuk HTML derived atau paste input),
   - pipeline upload asset (image/video) + metadata,
   - endpoint **public/mobile** yang stabil (slug, schedule/publishedAt, series).

4. Konten “Daily Devotional / belajar” sebaiknya **tetap satu model Article** + metadata/taxonomy (section, tags, series), bukan schema khusus dulu.
   - Template devotional bisa di-implement sebagai _content template_ di CMS (shortcut), **tanpa** bikin tabel khusus dulu (YAGNI), kecuali kamu butuh constraint yang benar-benar beda.

---

## 2) Kenapa HTML saja kurang (khususnya untuk Flutter)

HTML dari editor (mis. Tiptap) memang cepat untuk web, tapi untuk Flutter:

- HTML → widget rendering sering:
  - styling sulit dikontrol (Medium-like typography detail),
  - embed/iframe tidak natural,
  - keamanan lebih tricky (XSS bukan problem utama di Flutter, tapi **content injection** dan link/embed validation tetap penting),
  - fitur seperti footnotes/pull quotes/callouts lebih sulit dibuat konsisten.

Kalau ingin “paling powerful” dan jangka panjang, source-of-truth yang tepat adalah **structured document**, bukan markup.

---

## 3) Content model: “Satu Article” vs “Schema khusus Devotional”

Kamu bertanya: _daily devotional ini satu artikel biasa atau schema khusus?_

### Opsi A — Satu model `Article` + taxonomy (rekomendasi)

**Article** adalah kontainer universal untuk semua jenis tulisan: renungan harian, serial doktrin, bedah film, bahas tren, dll.

Kita bedakan jenis konten lewat metadata:

- `section`: mis. `devotional`, `learning`, `series`, `insight`
- `tags`: array string
- `seriesId`: untuk konten berseri
- `publishedAt`: jadwal publish
- `contentTemplate`: hanya untuk CMS (opsional)

**Kenapa ini bagus:**

- fleksibel (semua menjadi artikel),
- query gampang (filter by section/series/date),
- tidak bikin schema meledak,
- cocok dengan kebutuhan kamu yang masih eksplorasi format.

### Opsi B — Model khusus `Devotional`

Dipakai kalau kamu butuh constraint yang benar-benar beda, misalnya:

- devotional harus punya field wajib seperti `verse`, `prayer`, `actionSteps`,
- devotional punya flow scheduling & notification berbeda,
- devotional harus bisa dibuat “Private” per user,
- devotional punya interaksi khusus (mis. “buat habit” one-click).

**Trade-off:** lebih kompleks, migrasi & maintenancenya lebih mahal.

### Rekomendasi sekarang

Mulai dari **Opsi A** (Article universal) + metadata `section`.
Kalau nanti format devotional makin spesifik dan kamu sering butuh constraint khusus, baru evolusi ke Opsi B.

---

## 4) Rich content features yang kamu minta (mapping)

Target fitur wajib:

- Cover/hero image
- Inline image + caption
- Embeds (YouTube, dll)
- Footnotes
- Highlight/pull quotes
- Reading time (optional)

### 4.1 Cover/Hero image

Tambahkan field di Article:

- `cover`: `{ url, width, height, alt, caption? }`
- plus `title`, `subtitle?`

### 4.2 Inline image + caption

Di ProseMirror JSON, image sebaiknya jadi node khusus:

- `{ type: 'image', attrs: { assetId, url, width, height, alt, caption? } }`

CMS upload asset endpoint sudah ada (`/articles/upload-asset`).
Saran next: response upload tambahkan:

- `assetId`, `width`, `height`, `mime`, `sizeBytes`

### 4.3 Embeds

**Jangan izinkan arbitrary iframe HTML.**
Lebih aman: node `embed` yang hanya menerima provider tertentu.

Contoh:

- `{ type: 'embed', attrs: { provider: 'youtube', url: 'https://youtu.be/..', title? } }`

Backend harus melakukan normalisasi + validation:

- Accept URL → parse → simpan `provider` + `id`

Flutter rendering:

- YouTube: gunakan `youtube_player_flutter` atau WebView terkontrol.

### 4.4 Footnotes

Footnotes biasanya jauh lebih enak native daripada HTML.

Model sederhana:

- Node `footnote_ref` (link dari posisi di teks) dengan `id`
- Koleksi `footnotes` di bawah doc atau sebagai node list.

Flutter rendering:

- tap ref → modal/bottom sheet menampilkan footnote.

### 4.5 Pull quote / highlight

Buat node `callout` / `pullquote`:

- `{ type: 'callout', attrs: { variant: 'pullquote'|'highlight' }, content: [...] }`

Flutter:

- render box dengan typography khas.

### 4.6 Reading time

Derived field (computed), bukan input manual.

- `readingTimeMinutes = ceil(wordCount/200)` (atau 180)

---

## 5) Editor: apa yang perlu di-upgrade di CMS (Svelte)

CMS sekarang menggunakan Tiptap dan menyimpan HTML.
Kalau kita mau ProseMirror JSON:

1. Tiptap sudah bisa `editor.getJSON()`.
2. Simpan ke backend sebagai `contentJson`.
3. HTML tetap bisa disimpan sebagai `contentHtml` untuk preview.

**Minimal incremental step (boring):**

- Backend menerima keduanya: `contentJson` (required), `contentHtml` (optional derived).
- Flutter reader pakai `contentJson`.
- Web preview/landing bisa pakai `contentHtml` (tetap sanitize).

---

## 6) Backend: perubahan yang perlu kamu siapkan (high-level)

### 6.1 Data model (disarankan)

Field inti Article:

- `id`
- `title`
- `slug`
- `excerpt/snippet?`
- `status`: DRAFT/PUBLISHED/ARCHIVED
- `publishedAt` (nullable)
- `createdAt`, `updatedAt`

Content:

- `contentJson` (required)
- `contentHtml` (optional derived)

Media:

- `coverAssetId?`
- `coverUrl?` (atau join via asset)

Taxonomy:

- `section` (string enum-ish, mis. devotional/learning)
- `tags` (string[])
- `seriesId?`, `seriesOrder?`

Derived:

- `wordCount`, `readingTimeMinutes`

### 6.2 Public/mobile endpoints

Butuh endpoint stabil untuk Flutter:

- `GET /articles/public?section=devotional&date=YYYY-MM-DD` (daily)
- `GET /articles/public/:slug` (read)
- `GET /articles/public?seriesId=...&page=...`

CMS endpoint tetap:

- `GET /cms/articles` (admin list)
- `GET /cms/articles/:id`
- `POST /articles` (create)
- `PUT /articles/:id` (update)

### 6.3 Sanitization & validation (wajib kalau HTML ada)

Anggap belum ada.
Minimal:

- sanitize `contentHtml` dengan allowlist tags/attrs
- validate embed URLs (youtube only, etc)
- validate links (optional)

**Catatan:** even if Flutter does not execute JS, kamu tetap butuh sanitization untuk:

- web preview,
- future web reader,
- mencegah konten rusak/aneh.

---

## 7) Flutter reader: saran implementasi (powerful)

### 7.1 Rendering strategy (recommended)

- Fetch `ArticlePublic` dari API.
- Render `contentJson` via custom renderer:
  - map node types → Flutter widgets

Ini memang “agak ribet”, tapi ini jalur yang benar untuk fleksibilitas Medium.

### 7.2 Library/approach options

Option 1 (recommended): **Custom renderer**

- Pro: paling fleksibel dan konsisten.
- Con: perlu implement node-by-node.

Option 2: HTML renderer

- Pro: cepat.
- Con: sulit capai kualitas Medium + embed/footnote/pullquote akan messy.

### 7.3 Node set untuk v1 (minimum powerful)

Mulai dari subset node yang kamu butuhkan:

- paragraph, heading, bullet_list, ordered_list
- bold/italic/underline/link
- image (with caption)
- blockquote
- pullquote/callout
- embed (youtube)
- footnote_ref + footnote_list

---

## 8) Product guidance untuk “Daily Devotional / belajar”

Karena kamu ingin konten bisa:

- renungan harian,
- seri doktrin,
- bedah tren,
- bedah film,

maka struktur yang cocok:

1. `section` untuk membedakan area UI di app:
   - `devotional` (harian)
   - `learning` (doktrin/seri)
   - `culture` (tren/film)

2. `series` untuk konten berseri:
   - series punya: `title`, `description`, `cover`, `order`

3. Schedule/publishAt:
   - daily devotional bisa di-query via date
   - bisa lebih dari 1 per hari: gunakan `publishedAt` + `priority` atau `slot`

4. Template di CMS (bukan schema khusus dulu):
   - tombol “New Devotional Template” yang mengisi editor dengan struktur awal
   - output tetap article universal.

---

## 9) Design direction checklist (apa yang perlu kamu siapkan)

Iya, kamu perlu design direction minimal supaya hasilnya konsisten.

Checklist yang bisa kamu tulis sebagai guideline:

1. Typography tokens:

- base font family (serif untuk body? medium biasanya serif-like)
- font sizes: title, subtitle, body, caption
- line height body (mis. 1.6–1.8)
- paragraph spacing (margin bottom)

2. Layout:

- max content width (web) / padding horizontal (mobile)
- image full-bleed vs inline

3. Components style:

- blockquote
- pull quote
- callout/highlight
- footnote

4. Themes:

- light/dark
- selection/highlight color

5. Reading mode decisions:

- reader UI minimal (recommended)
- option font size (nice-to-have)

### Rekomendasi default (kalau kamu belum punya)

- Mulai dari **reading mode minimal** (judul + author/date + konten).
- Tambahkan toggle font size belakangan.

---

## 10) Next steps (urut paling efektif)

1. Backend: tambah support `contentJson` + derived `readingTimeMinutes` + `publishedAt`.
2. CMS: simpan `editor.getJSON()` dan kirim sebagai `contentJson`.
3. Backend: sanitization untuk `contentHtml` (kalau tetap disimpan).
4. Flutter: implement renderer v1 untuk node set minimum powerful.
5. Baru tambah embeds advanced (non-youtube)

---

## Pertanyaan klarifikasi yang masih diperlukan

Agar desainnya presisi (dan tidak overbuild), jawab 5 hal ini:

1. Apakah kamu mau menyediakan web reader publik juga, atau mobile-only dulu?
2. Untuk embeds selain YouTube: prioritasnya apa (Instagram/TikTok/Podcast)?
3. Apakah konten perlu bisa di-download offline di app?
4. Apakah ada multi-language rencana? (id/en)
5. Apakah artikel punya author publik (nama penulis) atau anonim/"Liveit Team"?

---

## Jawaban (Keputusan produk saat ini)

Keputusan ini akan jadi constraint utama supaya implementasi tetap _boring_ dan tidak overbuild.

1. **Web reader publik:** untuk sekarang **mobile-only**.
   - Implikasi: `contentHtml` tetap berguna untuk preview internal/CMS, tapi kita tidak perlu memprioritaskan SEO/web performance dulu.

2. **Embeds priority:** “semua mainstream socmed”, dan kamu juga mau **upload video sendiri**.
   - Implikasi arsitektur (boring tapi powerful):
     - Mulai dari **node `embed` generik** dengan `provider` + `canonicalId` + `url`.
     - Support provider bertahap via allowlist (`youtube` dulu, lalu `instagram`, `tiktok`, `spotify/podcast`, dll).
     - Untuk video upload sendiri: jangan dianggap “embed”; jadikan **node `video`** berbasis _assetId_ (file yang kamu host).

3. **Offline download:** **ya**, perlu mode baca tanpa sinyal (pesawat/commute).
   - Implikasi: backend perlu payload public yang **self-contained** dan versioned.
   - Implikasi app: Flutter butuh pipeline _download package_ (content JSON + metadata + asset manifest) lalu simpan ke local DB.

4. **Multi-language:** untuk sekarang **Indonesia-only**.
   - Implikasi: schema tetap siap “naik level” tanpa breaking change, tapi **jangan implement locale dulu**.
   - Minimal future-proof yang masih YAGNI-safe: tambahkan `language: 'id'` default di backend (optional), atau omit dulu dan tambahkan nanti.

5. **Author:** untuk sekarang penulis internal, tapi backend harus siap menyediakan **nama author**.
   - Implikasi: simpan field `authorName` (string) atau relasi `authorId` (kalau nanti ada user table).
   - Display rule (proposed, boring):
     - `authorDisplayName` derived (mis. fallback ke `"LiveIt Team"` jika kosong).
     - UI bisa memilih: tampilkan/hide tanpa ubah data.

---

## Dampak ke rancangan data (delta yang disarankan)

Tambahan yang langsung relevan dari keputusan di atas:

1. **Video upload sendiri**
   - Tambah model asset yang membedakan `type: 'image' | 'video'`.
   - Node ProseMirror:
     - `image` tetap seperti sekarang.
     - `video`: `{ type: 'video', attrs: { assetId, url, width?, height?, durationSeconds?, posterAssetId?, caption? } }`.

2. **Offline support**
   - Pastikan public payload melampirkan `assets[]` (manifest) sehingga app bisa download semuanya.
   - Tambahkan field versi untuk caching invalidation: `contentVersion` (int) atau pakai `updatedAt` sebagai ETag.

3. **Author**
   - Tambah `authorName?: string` di Article.
   - Tambah `authorDisplayName` sebagai derived (atau lakukan fallback di client; tapi lebih rapi kalau backend menyajikan ready-to-render).

---

## Next steps (re-ordered sesuai keputusan)

1. Backend: tambah support `contentJson` (required) + `publishedAt` + derived `readingTimeMinutes`.
2. Backend: upgrade asset pipeline untuk **image + video** (metadata), dan sediakan `assets[]` manifest di public payload.
3. CMS: simpan `editor.getJSON()` dan kirim sebagai `contentJson`.
4. Flutter: implement renderer v1 (node set minimum + `image`, `video`, `embed(youtube)`, footnotes).
5. Offline: implement download/caching v1 (artikel + asset manifest) sebelum nambah provider embed lain.

---

## 11) Backend implementation checklist (siap langsung kamu eksekusi)

Bagian ini sengaja dibuat super konkret supaya kamu bisa implement backend tanpa bolak-balik “nanya lagi”.

### 11.1 Contract utama (public/mobile)

Prinsip:

- Flutter (dan offline) butuh payload **stabil**.
- CMS butuh CRUD yang aman untuk draft.
- Public endpoint hanya expose yang PUBLISHED (dan sudah lewat `publishedAt`).

Minimal contract yang disarankan sudah dimirror di frontend: `src/lib/contracts/articles-public.ts`.

### 11.2 Database schema (minimal tapi powerful)

#### Table: `articles`

Field minimum:

- `id` (uuid)
- `title` (text)
- `subtitle` (text, nullable)
- `slug` (text, unique)
- `excerpt` / `snippet` (text, nullable)
- `status` (enum: DRAFT/PUBLISHED/ARCHIVED)
- `published_at` (timestamptz, nullable)
- `author_name` (text, nullable)
- `author_display_name` (text, not null, default 'LiveIt Team')
- `content_json` (jsonb, not null)
- `content_html` (text, nullable) — optional derived preview/web
- `content_version` (int, not null, default 1)
- `word_count` (int, nullable)
- `reading_time_minutes` (int, nullable)
- `cover_asset_id` (uuid, nullable)
- `created_at` / `updated_at` (timestamptz)

Indexes yang worth it (boring, tapi sangat kepake):

- unique: `slug`
- index: `(status, published_at desc)` untuk feed
- index: `updated_at` untuk incremental sync

Catatan versioning:

- Setiap update konten (title/snippet/content/cover/embed) increment `content_version`.
- `content_version` dipakai untuk offline invalidation selain `updated_at`.

#### Table: `article_assets` (atau `assets`)

Minimal:

- `id` (uuid)
- `kind` ('image'|'video')
- `url` (text)
- `mime` (text)
- `size_bytes` (int)
- `width` (int, nullable)
- `height` (int, nullable)
- `duration_seconds` (int, nullable)
- `poster_asset_id` (uuid, nullable) — untuk video
- `created_at`

#### Table: `article_asset_refs` (join)

Kenapa join table: satu asset bisa dipakai ulang (cover + inline), dan kamu bisa query “asset dipakai di artikel apa”.

- `article_id` (uuid)
- `asset_id` (uuid)
- unique: `(article_id, asset_id)`

### 11.3 Publish scheduling rule (aturan yang harus konsisten)

Public visibility rule (make illegal states unrepresentable di level query):

- Article visible di public endpoint **hanya jika**:
  - `status = 'PUBLISHED'`, dan
  - `published_at IS NOT NULL`, dan
  - `published_at <= now()`

Edge case:

- Kalau kamu set status PUBLISHED tapi lupa `published_at`, treat as invalid for public.
- CMS tetap boleh melihat draft.

### 11.4 Endpoint design (CMS vs Public)

#### CMS (admin)

Kamu sudah punya pola:

- `GET /cms/articles` (list with filters)
- `GET /cms/articles/:id` (read draft/published)
- `POST /articles` (create)
- `PUT /articles/:id` (update)

Tambahan minimal yang akan kepake untuk workflow:

- `POST /articles/:id/publish` → set `status=PUBLISHED`, set/validate `publishedAt`
- `POST /articles/:id/unpublish` → set `status=DRAFT` (opsional, tapi biasanya kepake)

#### Public/mobile (read-only)

Minimal:

- `GET /articles/public/:slug`
  - Response: `ArticlePublic` (lihat contract)
- `GET /articles/public`
  - Query: `section?`, `tag?`, `q?`, `page`, `limit`, `sort`
  - Response: list envelope

Kalau daily devotional by date:

- `GET /articles/public?section=devotional&date=YYYY-MM-DD`
  - Kembalikan 0..n item (kamu bilang bisa lebih dari 1 per hari)

### 11.5 Offline download & caching (mobile-only focus)

Tujuan: user bisa tap “Download”, lalu artikel + media bisa dibuka tanpa internet.

#### 11.5.1 Public payload wajib self-contained

Saat `GET /articles/public/:slug`:

- Sertakan `assets: ArticleAsset[]` (manifest semua media yang direferensikan oleh `contentJson` + cover).
- Sertakan `contentVersion` dan `updatedAt`.

#### 11.5.2 Endpoint opsional untuk offline bundle

Agar lebih hemat request saat download:

- `GET /articles/public/:slug/offline-bundle`
  - Response JSON: sama seperti `ArticlePublic`.
  - Bedanya: pastikan `assets[]` lengkap, dan optional `checksum` / `etag` untuk bundle.

Atau, kalau kamu mau explicit manifest:

- `GET /articles/public/:slug/assets-manifest`
  - Response: `{ contentVersion, assets: [...] }`

#### 11.5.3 HTTP caching (boring wins)

Untuk `GET /articles/public/:slug` dan list feed:

- Set `ETag` berbasis `updatedAt + contentVersion` (atau hash payload).
- Support `If-None-Match` → return 304.

Ini akan kepake juga untuk online mode (hemat kuota, cepat).

### 11.6 Asset upload pipeline (image + video)

Kamu bilang mau upload video sendiri. Ini perlu keputusan teknis backend yang tegas.

#### Upload endpoint

- `POST /articles/upload-asset`
  - menerima multipart
  - simpan ke storage (S3/R2/Appwrite storage)
  - response minimal:
    - `assetId`, `url`, `kind`, `mime`, `sizeBytes`, `width?`, `height?`, `durationSeconds?`, `posterUrl?`

#### Video specifics (minimal viable)

- v1 boleh tanpa transcoding (upload aja), tapi:
  - pastikan ada limit ukuran file
  - pastikan mime allowlist
  - pastikan streaming/fetch aman (signed URL kalau private)

Kalau nanti butuh HLS/transcoding, itu phase berikutnya (jangan sekarang kecuali dibutuhkan).

### 11.7 Embeds allowlist + normalisasi (mainstream socmed)

Jangan terima iframe HTML mentah.

#### Model embed di contentJson

Node `embed` minimal:

- `provider` (youtube/instagram/tiktok/spotify/unknown)
- `url` (original)
- `canonicalId` (hasil parse/normalize)

#### Backend rule

- Saat menerima `contentJson`:
  - traverse nodes, cari `embed`
  - validasi URL host/path
  - parse → dapatkan canonical id
  - tulis balik ke node attrs (normalize)
- Kalau provider tidak allowlisted → reject 400 (boring, eksplisit)

v1 rekomendasi provider order:

1. youtube
2. instagram
3. tiktok
4. spotify (podcast)

### 11.8 Security & validation (wajib meski mobile-only)

Walaupun Flutter tidak eksekusi JS, kamu tetap perlu memastikan:

- `contentJson` memenuhi schema minimum (node type allowlist)
- `contentHtml` (kalau disimpan) harus disanitize (tag/attr allowlist)
- URL validation:
  - link biasa: allow http/https
  - embed: provider allowlist

### 11.9 Derived fields (word count, reading time)

Saat save/publish:

- hitung word count dari `contentJson` (extract plain text)
- `readingTimeMinutes = ceil(wordCount / 200)` (atau 180)

Simpan derived ke DB supaya list/feed cepat.

### 11.10 Author handling (boring default + future-proof)

Sekarang penulis internal, jadi paling simpel:

- CMS saat create/update bisa mengirim `authorName` (optional)
- Backend compute `authorDisplayName`:
  - jika `authorName` kosong → `"LiveIt Team"`
  - else → `authorName`

Nanti kalau kamu punya user/creator table, kamu bisa migrate ke:

- `authorId` (fk) + derived `authorDisplayName`
