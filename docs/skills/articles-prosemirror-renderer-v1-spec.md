# Skill: ProseMirror Article Renderer v1 Spec (Flutter)

Tanggal: 2025-12-27  
Scope: Flutter reader untuk `GET /articles/public/:slug` yang mengembalikan `contentJson` (ProseMirror JSON).  
MVP keputusan: node set minimum + embed **YouTube-only**.

Dokumen ini adalah **spec** (aturan) supaya implementasi renderer v1 konsisten, predictable, dan mudah di-extend.

---

## 1) Contract

### Input

- `contentJson`: `Map<String, dynamic>` dengan bentuk ProseMirror doc.
- Root node wajib:
  - `type = "doc"`
  - `content` = array

### Output

- Widget tree (umumnya `Column` atau `SliverList` item-by-item) berisi blok teks, list, gambar, dan embed.

### Error modes

- Jika `contentJson` invalid (bukan doc / content missing): tampilkan error UI “Konten tidak dapat ditampilkan” + CTA retry (detail fetch) atau fallback text.
- Jika ada node tidak dikenal: render placeholder “Unsupported content” (non-fatal).

---

## 2) Validator & allowlist

Renderer v1 harus:

1. **Allowlist node types**:

- `doc`
- `heading`
- `paragraph`
- `text`
- `bullet_list`
- `ordered_list`
- `list_item`
- `image`
- `embed` (YouTube-only)

1. **Ignore unknown nodes safely**:

- Log internal (debug) bila perlu.
- Jangan crash.

1. **Marks allowlist** (inline styling):

- `bold`
- `italic`
- `link`

> Mark lain (underline/strike/code) boleh diabaikan dulu di MVP.

---

## 3) Rendering model: block vs inline

### Block nodes

Block node menghasilkan widget “baris/section” dan bisa punya spacing vertikal.

- `heading`
- `paragraph`
- `bullet_list` / `ordered_list`
- `image`
- `embed`

### Inline nodes

Inline node hanya bisa hidup di dalam `paragraph` atau `heading`:

- `text` + marks

Aturan:

- Jangan render `text` sebagai widget sendiri di root.
- Normalisasi whitespace: jangan bikin double-space karena node splitting.

---

## 4) Typography tokens (design direction v1)

Agar konsisten, tetapkan token (boleh pakai `Theme.of(context).textTheme` sebagai basis, tapi mapping harus tegas).

### Title & metadata (di luar contentJson)

- `Title` (article title): `headlineMedium` / bold
- `Subtitle` (optional): `titleMedium` / normal
- `Meta` (author + publishedAt + reading time): `bodySmall` + `onSurfaceVariant`

### Content text

- Body: size 16–17, height 1.6–1.75
- Paragraph spacing: 12–16 px antar paragraf
- Heading spacing:
  - sebelum heading: 20 px
  - sesudah heading: 12 px

### Link style

- Warna: `colorScheme.primary`
- Decoration: underline (opsional, tapi recommended untuk affordance)

---

## 5) Node → Widget mapping (v1)

### 5.1 `doc`

- Render children berurutan (top-to-bottom).
- Jangan ada padding di doc renderer; padding ditangani oleh page layout (mis. `Padding(horizontal: 16)` di reader).

### 5.2 `heading`

- Attributes:
  - `attrs.level` (1..6). MVP support: level 1–3.
- Mapping style:
  - level 1 → large heading (jarang dipakai)
  - level 2 → section title
  - level 3 → subsection title
- Jika level > 3: fallback ke level 3 style.

Content:

- Heading dapat berisi inline `text` nodes.

### 5.3 `paragraph`

- Render sebagai RichText (atau equivalent) dari inline content.
- Jika paragraph kosong (`content` missing/empty): render vertical spacer kecil (mis. 8 px) atau skip.

### 5.4 `text`

Field:

- `text`: string
- `marks`: array optional

Rules:

- Concatenate inline nodes dalam satu paragraph.
- Mark precedence (kalau lebih dari satu):
  1. link
  2. bold
  3. italic

> Jika bold+italic bareng, gunakan style gabungan.

### 5.5 `bullet_list` / `ordered_list`

Structure:

- list node punya `content` berisi `list_item`.

Bullet list:

- Bullet symbol: `•`
- Indent level 1: 16–20 px

Ordered list:

- Render numbering 1..n berdasarkan urutan item yang diterima.

Aturan untuk list nested:

- MVP: support 1 level nested saja.
- Nested indent tambahan: +12 px.

### 5.6 `list_item`

- `list_item.content` biasanya berisi `paragraph` (kadang list lain).

Rules:

- Render item sebagai Row: (leading bullet/number) + Expanded(content).
- Item spacing: 8 px antar item.

### 5.7 `image`

Attrs yang mungkin:

- `src` atau `url` (pilih yang disediakan CMS)
- `assetId` (optional)
- `width`, `height` (optional)
- `alt` (optional)
- `caption` (optional)

Rules:

- Image harus responsive (fit to width container).
- Jika width/height ada: gunakan untuk aspect ratio (hindari layout shift).
- Jika alt ada tapi caption tidak ada:
  - alt dipakai untuk accessibility semantics, bukan ditampilkan.
- Jika caption ada:
  - render `caption` sebagai `bodySmall` + `onSurfaceVariant`.

Error handling:

- Jika image gagal load: tampilkan placeholder container dengan icon + teks “Gambar gagal dimuat”.

### 5.8 `embed` (YouTube-only)

Attrs:

- `provider` (atau derived) harus `youtube`
- `url`

Rules:

- Jika provider bukan youtube → fallback:
  - tampilkan link text clickable (atau placeholder “Embed belum didukung”).
- Untuk YouTube:
  - Extract video id dari URL (defensive: handle `youtu.be/`, `watch?v=`, `shorts/`).
  - Render player dalam fixed aspect ratio 16:9.

UX:

- Jangan autoplay.
- Show controls.

---

## 6) Link click behavior

- Hanya `http/https`.
- `mailto:`/`tel:` boleh kamu disable untuk MVP.
- Tampilkan dialog confirm sebelum membuka browser eksternal (opsional, tapi recommended).

---

## 7) Spacing & layout rules

- Semua block node punya bottom spacing konsisten.
- Default bottom spacing:

  - paragraph: 12–16
  - list: 12–16
  - image: 16
  - embed: 16

- Jangan pakai `ListView` di dalam scroll utama untuk list nodes (hindari nested scrolling). Render list sebagai Column/Sliver children.

---

## 8) Performance & stability

- Renderer harus pure (no side-effect) untuk given JSON.
- Gunakan `const` widgets bila bisa (biasanya sulit karena konten dinamis, tapi untuk placeholder bisa).
- Batasi recursion depth untuk safety (mis. max 50 levels). Jika lewat, fallback error “Konten terlalu kompleks”.

---

## 9) Test cases (minimal)

Buat fixture JSON untuk unit test renderer logic:

1. `doc` dengan 2 paragraph + 1 heading.
2. paragraph dengan marks: bold + italic + link.
3. ordered_list dengan 3 items.
4. image dengan caption.
5. embed youtube valid + embed provider unknown.
6. invalid JSON (missing type/content) → error UI.

---

## 10) Extension path (setelah MVP)

Kalau mau naik level, urutan paling masuk akal:

1. `blockquote`
2. `code_block`
3. `video` (native player)
4. embed provider lain (Instagram/TikTok/Spotify) + policy + fallback
5. callout/pullquote
6. footnotes
