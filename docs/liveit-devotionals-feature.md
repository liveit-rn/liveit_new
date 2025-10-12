# LIVEIT Devotionals (Renungan Harian)

Tujuan

- Menyediakan konten renungan harian yang singkat, terkurasi, dan aplikatif sebagai pemicu pembentukan kebiasaan rohani.
- Menjadi jembatan alami ke Habit Tracker melalui aksi “Buat Habit dari Renungan”.
- Menjaga arsitektur sederhana: Appwrite sebagai penyimpanan konten, Backend NestJS sebagai facade API dan pengaman.

—

Ruang Lingkup MVP

- Baca daftar renungan “published”, urut terbaru (publication_date desc).
- Baca detail renungan by slug (published), tingkatkan views_count (opsional async).
- Like renungan (tanpa komentar; admin-only visibility untuk data like).
- Aksi “Buat Habit dari Renungan”: 1‑klik menambahkan habit aman (template mikro) ke Habit Tracker user.
- Editorial workflow: draft → pending_review → revision_needed → published → archived (dikelola tim di Appwrite Console atau tool internal).

—

Model Data (Appwrite Databases)

Mengacu dokumen: docs/Data Structure feat_Devotionals.md

- Koleksi: `devotionals`
  - Wajib: `title`, `slug` (unik), `snippet`, `content (Markdown)`, `featured_image_id`, `publication_date`, `status`, `author_profile_id`
  - Opsional: `likes_count`, `views_count`, `estimated_read_time`, `last_updated_by`, `scheduled_publish_at`
- Permissions (disarankan)
  - Read: `published` → public (role:all). Selain itu → author + kurator/admin.
  - Write: author untuk miliknya, kurator/admin untuk semua (ubah status/arsip).
- Indeks rekomendasi: `slug` (unique), `status`, `publication_date`, `author_profile_id`.

—

Workflow & Publikasi

- Publik = status `published` dan (opsi) `publication_date <= now`.
- Penjadwalan: gunakan `scheduled_publish_at` atau set `publication_date` di masa depan, lalu cron/Appwrite Function memindahkan ke `published` sesuai jadwal.
- Estimasi waktu baca: isi otomatis saat create/update (hitung dari panjang `content`) jika `estimated_read_time=0`.

—

Endpoint (Backend NestJS Facade)

Semua path di bawah prefix `/devotionals`. Backend membaca/menulis ke Appwrite melalui SDK server.

1) GET `/devotionals/today` (Publik)
- Deskripsi: Ambil renungan untuk hari ini (atau terdekat ≤ now) dengan status `published`.
- Query opsional: `tz` (default UTC) untuk pemilihan hari (fase berikut).
- Response: `{ title, slug, snippet, featuredImageUrl, publicationDate }`

2) GET `/devotionals` (Publik)
- Deskripsi: Daftar renungan `published` dengan pagination.
- Query: `page=1`, `limit=10`, `q` (search sederhana di title/snippet), `from`, `to`, `authorId`.
- Response: `{ items: [...], page, limit, total }`

3) GET `/devotionals/:slug` (Publik)
- Deskripsi: Detail renungan `published` by slug.
- Perilaku: Tingkatkan `views_count` (async, best-effort) dan hitung `estimated_read_time` bila 0.
- Response: `{ title, slug, snippet, content (HTML/Markdown), featuredImageUrl, publicationDate, author: { id, name }, likesCount, viewsCount, estimatedReadTime }`

4) POST `/devotionals/:slug/like` (JWT)
- Deskripsi: User menekan like satu kali (idempotent per user).
- Perilaku: Simpan like per user (koleksi `devotional_likes` di Appwrite atau tabel ringan), update `likes_count` agregat (async).
- Response: `{ liked: true }`

5) DELETE `/devotionals/:slug/like` (JWT)
- Deskripsi: Batalkan like.
- Perilaku: Hapus like per user, kurangi `likes_count` (async, tidak negatif).
- Response: `{ liked: false }`

6) POST `/devotionals/:slug/create-habit` (JWT)
- Deskripsi: Buat habit dari renungan (one‑click). Bentuk mikro, aman, dan publik (reach awal `limited`).
- Input opsional: `{ notes?: string }`
- Perilaku: Tambahkan `UserHabit` baru pada user (boolean habit), `title` disarankan format “Refleksi 5 menit: <title>” atau “Terapkan poin utama dari ‘<title>’ hari ini”.
- Response: `{ success: true, userHabitId }`

Admin (opsional tahap awal; bisa pakai Appwrite Console terlebih dulu)

7) Admin: POST `/admin/devotionals` (JWT admin)
- Deskripsi: Buat/ubah renungan (draft/pending_review/published/archived) di Appwrite DB.

8) Admin: POST `/admin/devotionals/:id/publish|archive` (JWT admin)
- Deskripsi: Ubah status sesuai workflow editorial.

—

Aturan & Perilaku

- Hanya `published` yang tersedia publik (daftar & detail). Draft/pending/revision/archived tersembunyi publik.
- Like idempotent per user per renungan. Data like tidak ditampilkan publik kecuali agregat `likes_count`.
- Views increment best-effort (hindari beban berlebih; bisa di‑batch oleh job/fungsi).
- Konten `content` disarankan Markdown; backend boleh merender ke HTML (opsional) atau kirim Markdown ke klien.
- Integrasi Habit Tracker: reach awal `limited`, bisa naik otomatis ke `normal` setelah T+24–48 jam jika tidak dilaporkan.

—

Validasi & Error

- 404: slug tidak ditemukan atau tidak `published`.
- 400: slug/parameter invalid.
- 401/403: aksi like/create‑habit butuh JWT; admin endpoint butuh peran admin.
- 409: like duplikat (idempotent → tidak error; cukup balas `{ liked: true }`).

—

Keamanan & Kinerja

- Rate limit: `GET /devotionals` (umum), `GET /:slug` (umum), `POST like`/`create-habit` (user) agar anti spam.
- Cache: caching 1–5 menit untuk list/detail published (Redis) + ETag/If-None-Match.
- Sanitasi HTML: jika render Markdown ke HTML, gunakan sanitizer.
- Permissions Appwrite: terapkan sesuai status; backend gunakan Server SDK dan tidak mengekspos key.

—

Monitoring & Operasional

- Logging akses & error; hitung metrik `views`, `likes`, CTR tombol “Create Habit”.
- Job/fungsi: penjadwalan publikasi harian, recompute `estimated_read_time` & agregat likes/views periodik.
- Backup: DB Appwrite (konten) sudah dikelola vendor; tetap siapkan ekspor berkala sebagai arsip.

—

Contoh Respons

GET `/devotionals/today`

```
{
  "title": "Kasih yang Mengubah Dunia",
  "slug": "kasih-yang-mengubah-dunia",
  "snippet": "Kasih menuntun kita pada tindakan kecil yang berarti...",
  "featuredImageUrl": "https://.../devotional_images/abc123",
  "publicationDate": "2025-09-21T04:00:00.000Z"
}
```

POST `/devotionals/:slug/create-habit`

```
{
  "success": true,
  "userHabitId": "uh_123"
}
```

—

Roadmap Lanjutan

- Tag/pilar untuk rekomendasi renungan dan habit kontekstual.
- Template habit per renungan (opsional field tambahan di Appwrite) agar “Create Habit” lebih spesifik.
- Notifikasi push harian (jam pilihan user) untuk renungan & pengingat habit.
- Mode offline caching di klien untuk renungan hari ini.

Dokumen ini memandu implementasi Renungan Harian berbasis Appwrite (konten) + NestJS (facade). Implementasi dapat disesuaikan mengikuti kebutuhan editorial dan integrasi Habit Tracker.

