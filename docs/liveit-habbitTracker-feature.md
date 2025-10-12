# LIVEIT Habit Tracker

Tujuan

- Menyediakan loop inti untuk memilih dan melakukan check-in kebiasaan rohani harian.
- Menjadi sumber data utama bagi Gamifikasi (Zoe Points, Level, Badges) dan Profil Summary.
- Menjaga desain yang sederhana, idempotent, dan mudah diekspansi (streak, statistik, dsb.).

Kebijakan Discoverability (Tanpa Pending)

- Custom habit langsung aktif untuk user (tanpa menunggu). Untuk menjaga kualitas publik, jangkauan publiknya dibatasi sementara: tidak muncul di Explore/Pencarian selama 24–48 jam pertama atau hingga lulus pengecekan otomatis. Habit tetap terlihat di profil user sendiri dan dapat di-check-in normal.
- Jika tim menemukan masalah, intervensi dilakukan pasca‑publikasi (tegur ramah, saran perbaikan, batasi jangkauan, set private, atau arsip) tanpa mempermalukan user.

—

Ruang Lingkup MVP

- Katalog Habit terkurasi (dibuat/seed oleh BE).
- User dapat memilih habit dari katalog (UserHabit).
- Check-in harian per UserHabit (maks 1x per hari; idempotent; bisa undo).
- Daftar habit user + status check-in hari ini.
- Zona waktu sementara: UTC (nantinya gunakan `profiles.timezone`).

Tambahan (Custom Habit & Moderasi Pasca‑Publikasi)

- User bebas membuat custom habit dengan guardrails halus (panduan input, deteksi kata berisiko).
- Custom habit langsung aktif dan terlihat di profil user, namun jangkauan publiknya awalnya terbatas (tidak masuk Explore/Pencarian sementara). Setelah periode awal atau lulus pengecekan otomatis, jangkauan menjadi normal.
- Tim dapat menindak: membatasi jangkauan lebih lanjut, menyetel private, mengarsipkan, dan/atau memberi pesan bimbingan personal.

—

Model Data (Prisma)

- Habit
  - `id: String @id @default(uuid())`
  - `key: String @unique` (identifier stabil, mis: `saat-teduh`, `baca-alkitab`)
  - `name: String`
  - `description: String?`
  - `category: String?` (opsional; tag/pilar internal untuk kurasi; UI tidak wajib menampilkan kategori)
  - `isActive: Boolean @default(true)`
  - `createdAt / updatedAt`

- UserHabit
  - `id: String @id @default(uuid())`
  - `userId: String` (FK ke `Profiles.id`)
  - `habitId: String` (FK ke `Habit.id`)
  - `notes: String?` (opsional catatan personal)
  - `archivedAt: DateTime?` (soft-archive tanpa menghapus check-in historis)
  - Unique: `(userId, habitId, archivedAt IS NULL)` untuk mencegah duplikasi aktif
  - `createdAt / updatedAt`

Rencana model tambahan (fase berikut)

- Mendukung custom habit tanpa pending melalui perluasan `UserHabit`:
  - `isCustom: Boolean @default(false)`
  - `title: String?` (wajib jika `isCustom=true`)
  - `description: String?`
  - `visibility: String @default('public')` // `public` | `private` (default publik; admin dapat set private bila perlu)
  - `reach: String @default('limited')` // `limited` | `normal` (discoverability awal terbatas)
  - `exploreIndexedAt: DateTime?` // waktu saat masuk Explore/Search
  - `lastReviewedAt: DateTime?`, `violationCount: Int @default(0)`
  - `createdBy: String?` (FK pembuat)
  - Catatan: untuk habit kurasi, `isCustom=false` dan `reach='normal'` by default.

- Checkin
  - `id: String @id @default(uuid())`
  - `userId: String` (FK ke `Profiles.id`)
  - `userHabitId: String` (FK ke `UserHabit.id`)
  - `day: DateTime` (tanggal harian normalisasi UTC; tanpa waktu)
  - Unique: `(userId, userHabitId, day)`
  - Index: `(userId, day)` dan `(userHabitId, day)`
  - `createdAt`

Catatan:

- Normalisasi `day` ke 00:00:00 UTC dari `now()` untuk idempotensi.
- Nantinya, `day` dihitung berdasarkan `profiles.timezone` (local day boundary).

—

Endpoint

Semua endpoint user-spesifik memakai JWT (JwtAuthGuard). Respons minimal dan konsisten.

1. GET `/habits/catalog` (Publik atau JWT)

- Deskripsi: Ambil daftar habit kurasi aktif.
- Response: `[{ id, key, name, description, category }]`

2. POST `/habits` (JWT)

- Deskripsi: Tambah habit kurasi ke profil user.
- Body: `{ habitId: string, notes?: string }`
- Response: `{ id, habitId, notes, createdAt }`
- Validasi: habit aktif, belum ada UserHabit aktif untuk habitId yang sama.

3. GET `/habits` (JWT)

- Deskripsi: Daftar Habit user, status check-in untuk hari ini.
- Query opsional: `includeHistory=false` (future)
- Response:
  ```json
  [
    {
      "id": "userHabitId",
      "habit": { "id": "...", "key": "saat-teduh", "name": "Saat Teduh" },
      "notes": null,
      "checkedInToday": true,
      "lastCheckinAt": "2025-03-20T10:00:00Z"
    }
  ]
  ```

4. POST `/habits/:userHabitId/checkin` (JWT)

- Deskripsi: Check-in hari ini untuk UserHabit (idempotent).
- Response: `{ success: true, created: boolean }` (`created=false` bila sudah pernah check-in hari ini).
- Perilaku: normalisasi tanggal ke UTC; jika sudah ada record, kembalikan idempotent.

5. DELETE `/habits/:userHabitId/checkin` (JWT)

- Deskripsi: Undo check-in hari ini (hanya hari berjalan).
- Response: `{ success: true, deleted: boolean }`.
- Perilaku: hanya menghapus check-in untuk `day` hari ini; tidak memengaruhi hari lain.

6. DELETE `/habits/:userHabitId` (JWT)

- Deskripsi: Arsipkan habit dari daftar user (soft delete via `archivedAt`).
- Response: `{ success: true }`.
- Perilaku: tidak menghapus check-in historis; endpoint check-in menolak jika `archivedAt` terisi.

7. POST `/habits/custom` (JWT) — buat custom habit (langsung aktif)

- Deskripsi: User membuat custom habit yang langsung aktif dan dapat di‑check‑in.
- Body: `{ title: string, description?: string, notes?: string }`
- Response: `{ id, isCustom: true, title, reach: 'limited', visibility: 'public' }`
- Perilaku: reach awal `limited` (tidak muncul di Explore/Pencarian) selama 24–48 jam atau hingga lulus pengecekan otomatis; tetap terlihat di profil user.

8. POST `/habits/:userHabitId/report` (JWT) — laporkan habit

- Deskripsi: Pengguna lain dapat melaporkan habit publik yang dianggap tidak selaras.
- Body: `{ reason: string }`
- Response: `{ success: true }`
- Perilaku: jika laporan menumpuk melewati ambang, reach dapat di‑auto‑limit dan masuk antrean review admin.

9. Admin: POST `/admin/habits/:userHabitId/moderate` (JWT admin)

- Body: `{ action: 'limit_reach' | 'set_private' | 'archive' | 'message', reason?: string, message?: string }`
- Perilaku: admin dapat membatasi jangkauan, menyetel private, mengarsipkan, dan/atau mengirim pesan pembinaan personal kepada user.

—

Aturan & Perilaku

- Idempotensi Check-in: satu entry per `(userHabitId, day)`.
- Kebijakan Hari (MVP): gunakan UTC. Next: gunakan `profiles.timezone` untuk hitung boundary hari lokal.
- Validasi Kepemilikan: setiap operasi pada `UserHabit` dan `Checkin` memverifikasi `userId === req.user.sub`.
- Arsip vs Hapus: archive `UserHabit` untuk mempertahankan histori; check-in pada habit terarsip ditolak.
- Katalog: hanya `Habit.isActive = true` yang tampil dan dapat dipilih.

Custom habit & Moderasi pasca‑publikasi

- Guardrails input: panduan contoh kalimat baik/buruk; deteksi kata/frasa berisiko (self‑harm, kekerasan, praktik manipulatif, klaim supranatural yang menyesatkan, dll.) untuk prioritas review.
- Discoverability: reach awal `limited` (tidak masuk Explore/Pencarian); menjadi `normal` setelah window awal atau lulus pengecekan otomatis.
- Pelaporan komunitas: endpoint `POST /habits/:userHabitId/report` untuk laporan; ambang tertentu memicu auto‑limit dan antrean review.
- Intervensi admin: batasi jangkauan, set private, arsip, atau kirim pesan pembinaan.
- Contoh tidak sesuai (awal): “Belajar Bahasa Roh” (tim Anda melengkapi daftar rinci sesuai kebijakan; sistem memfasilitasi intervensi yang ramah).

—

Interaksi dengan Gamifikasi

- Event/Hook (MVP sederhana):
  - Setelah `checkin` baru dibuat → kredit +10 ZP.
  - Setelah semua habit user ter-check-in hari ini → kredit +20 ZP.
  - Streak dihitung di Gamifikasi berdasarkan `Checkin` (future: materialized/cached).
- Implementasi awal: cukup expose data Checkin agar modul Gamifikasi dapat menghitung; integrasi service/event bisa ditambahkan kemudian.

Publik vs Privasi (Tampilan)

- Default: custom habit publik di profil user, namun reach awal terbatas (tidak ikut Explore/Pencarian).
- Statistik agregat (jumlah habit aktif, streak, total check‑in) dapat tampil publik.
- Admin dapat menyetel private atau membatasi jangkauan lebih lanjut bila diperlukan.

—

Validasi & Error

- 400: `habitId` tidak valid atau tidak aktif; format ID tidak valid.
- 403: akses ke `userHabitId` yang bukan milik user.
- 404: `Habit`/`UserHabit` tidak ditemukan; `UserHabit` terarsip saat check-in.
- 409: duplikasi `UserHabit` aktif untuk habit yang sama.

—

Keamanan & Privasi

- JWT wajib untuk endpoint user-spesifik (daftar, tambah, check-in, arsip).
- Limitasi rate (rekomendasi): batasi spam check-in/undo per menit.
- Data historis check-in bersifat privat; tidak terekspos publik.

—

Contoh Payload

- POST `/habits`:
  `{ "habitId": "b2a...", "notes": "pagi hari" }`

- POST `/habits/:userHabitId/checkin` → `{ success: true, created: true }`

- GET `/habits`:
  ```json
  [
    {
      "id": "uh_123",
      "habit": { "id": "h_1", "key": "saat-teduh", "name": "Saat Teduh" },
      "checkedInToday": false,
      "lastCheckinAt": null
    }
  ]
  ```

—

Catatan Implementasi

- Normalisasi `day` (UTC): `new Date(Date.UTC(y, m, d))` dari `now()`.
- Query "all done today": hitung jumlah `UserHabit` aktif vs jumlah check-in hari ini.
- Index penting: `Checkin(userId, day)`, `Checkin(userHabitId, day)`.
- Seed katalog Habit via migration atau script seed terpisah.
 - Integrasi moderation (fase berikut): role admin/editor, antrean review, pesan pembinaan, dan audit log ringkas.

—

Roadmap Lanjutan

- Timezone aware (pakai `profiles.timezone`).
- Reorder UserHabit, custom reminder per habit, kategori/ikon.
- Riwayat check-in (range tanggal), statistik (weekly/monthly), streak bawaan.
- Event bus/internal hooks untuk Gamifikasi dan Notifikasi.
 - Partial Unique Index DB untuk cegah duplikasi UserHabit aktif (WHERE archivedAt IS NULL).
 - Tag internal (pilar) untuk kurasi dan rekomendasi tanpa memaksa kategori UI.

Dokumen ini merangkum kebutuhan MVP Habit Tracker berdasarkan Blueprint, Gamifikasi, dan User Stories. Revisi dapat dilakukan seiring integrasi dengan modul Gamifikasi dan Profil Summary.
