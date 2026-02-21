# CMS Articles Authorization (JWT + Email Allowlist)

Dokumen ini menjelaskan cara mengamankan endpoint write untuk modul `articles` agar hanya bisa dipakai oleh tim internal (CMS), menggunakan JWT yang sudah ada + allowlist email di backend.

> Scope dokumen ini: **authorization** untuk CMS articles. Bukan panduan UI CMS.

---

## TL;DR

- CMS login → dapat JWT.
- CMS kirim request dengan header `Authorization: Bearer <jwt>`.
- Backend:
  - `JwtAuthGuard` memvalidasi JWT dan mengisi `req.user`.
  - `CmsAdminGuard` mengecek `req.user.email` harus ada di env `CMS_ADMIN_EMAILS`.
- Endpoint write yang diproteksi:
  - `POST /articles`
  - `POST /articles/upload-asset`
- Endpoint read dibiarkan public (saat ini):
  - `GET /articles`

---

## Kenapa pakai allowlist email di backend?

Tujuan utamanya adalah **policy admin tidak bergantung pada Appwrite role/team** (biar aman kalau nanti migrasi auth), dan implementasinya boring:

- Satu env var (`CMS_ADMIN_EMAILS`) untuk mengatur siapa yang boleh write.
- Tidak perlu “shared secret header” (tidak ada secret tambahan yang harus disebar ke client).
- Tidak perlu database table tambahan untuk admin-role (YAGNI untuk sekarang).

Trade-off yang diterima:

- Mengubah admin berarti update env + redeploy/restart.
- Ini cocok untuk jumlah admin kecil (tim internal).

---

## Kontrak (yang harus true)

1. JWT yang dikirim CMS harus valid.
2. JWT payload harus mengandung `email`.
3. `email` harus match dengan salah satu item di `CMS_ADMIN_EMAILS` (case-insensitive, whitespace di-trim).

Jika salah satu gagal → request ditolak (HTTP 403 untuk gagal guard; 401 untuk token invalid/missing).

---

## Flow end-to-end

### 1) CMS mendapatkan JWT

CMS melakukan login melalui flow auth yang sudah ada. Backend mengeluarkan access token JWT.

### 2) CMS menyimpan token dan mengirim Authorization header

Contoh header yang dikirim CMS ke backend:

- `Authorization: Bearer <access_token>`

### 3) Backend memvalidasi & authorize

1. `JwtAuthGuard`:
   - Validasi signature, expiry, issuer/audience (sesuai konfigurasi JWT di server).
   - Mengisi `req.user` dari payload JWT.

2. `CmsAdminGuard`:
   - Ambil `req.user.email`.
   - Normalize: `trim().toLowerCase()`.
   - Ambil env `CMS_ADMIN_EMAILS`, split by comma, normalize, lalu cek include.

Jika lolos → lanjut ke handler controller.

---

## Konfigurasi environment

### `.env.example`

Repo sudah menambahkan:

- `CMS_ADMIN_EMAILS=`

### Nilai env yang benar

Format:

- Comma-separated list
- Tidak masalah pakai spasi, akan di-trim
- Tidak masalah case (akan di-lowercase)

Contoh:

- `CMS_ADMIN_EMAILS=admin@liveit.app, editor@liveit.app`

---

## DigitalOcean deployment notes

Cara set env tergantung kamu deploy LiveIT server lewat apa.

### A) DigitalOcean App Platform

- Buka App → **Settings** → **App-Level Environment Variables** (atau per component)
- Tambahkan:
  - `CMS_ADMIN_EMAILS` = `admin@liveit.app,editor@liveit.app`
- Redeploy app.

### B) Droplet (Docker Compose / systemd / pm2)

- Pastikan env diekspos ke container/proses:
  - Kalau pakai Docker Compose: set di `environment:` atau `.env` file yang dibaca compose.
  - Kalau pakai systemd: set di `Environment=` atau `EnvironmentFile=`.
- Restart service/container.

### C) Kriteria sukses setelah deploy

- User non-admin login lalu coba `POST /articles` → **403**.
- User admin login lalu coba `POST /articles` → **201/200**.

---

## Endpoint summary

### `POST /articles/upload-asset`

- Guard: `JwtAuthGuard` + `CmsAdminGuard`
- Upload hardening:
  - Max file size: 10MB
  - MIME harus `image/*`

### `POST /articles`

- Guard: `JwtAuthGuard` + `CmsAdminGuard`
- Input: `CreateArticleDto`
- Catatan konten: server menyimpan HTML raw; sanitization sebaiknya dilakukan di layer yang merender.

### `GET /articles/public`

- Tanpa guard (public)
- Hanya mengembalikan artikel dengan `status=PUBLISHED`
- Pagination: cursor berbasis `createdAt + id`
  - Query params:
    - `limit` (default 20, max 50)
    - `cursorCreatedAt` (ISO date)
    - `cursorId`
  - Response:
    - `{ items: [...], nextCursor?: { createdAt, id } }`

### `GET /articles/public/:slug`

- Tanpa guard (public)
- Hanya mengembalikan artikel dengan `status=PUBLISHED`
- Jika slug tidak ada atau status bukan published → 404

### `GET /cms/articles`

- Guard: `JwtAuthGuard` + `CmsAdminGuard` (admin-only)
- Untuk admin dashboard list + filtering
- Query params yang tersedia:
  - `q` (search ke title/slug)
  - `title` (filter title contains)
  - `authorId` (Profiles.id)
  - `status` (DRAFT|PUBLISHED|ARCHIVED)
  - `from` / `to` (range berdasarkan `createdAt`, ISO date)
  - `page` (default 1)
  - `limit` (default 20, max 100)
  - `sort` (default `createdAt:desc`; allowed: createdAt, updatedAt, title, status)

### `GET /articles`

- Tanpa guard (public)

> Catatan: `GET /articles` masih ada untuk kompatibilitas implementasi awal.
> Untuk admin list yang butuh filtering, gunakan `GET /cms/articles`.

---

## Troubleshooting singkat

- Dapat 401: token tidak dikirim / expired / invalid.
- Dapat 403: email tidak ada di token atau tidak termasuk `CMS_ADMIN_EMAILS`.
- Token ada tapi `req.user.email` undefined:
  - Pastikan backend generate token dengan claim `email`.
  - Pastikan CMS mengirim access token yang benar (bukan refresh token).
