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

Model tambahan (✅ Implemented - Phase 2A)

- Custom habit support melalui perluasan `UserHabit`:

  - `isCustom: Boolean @default(false)`
  - `title: String?` (wajib jika `isCustom=true`)
  - `description: String?`
  - `visibility: String @default('public')` // `public` | `private` (default publik; admin dapat set private bila perlu)
  - `reach: String @default('limited')` // `limited` | `normal` (discoverability awal terbatas)
  - `exploreIndexedAt: DateTime?` // waktu saat masuk Explore/Search
  - `lastReviewedAt: DateTime?`, `violationCount: Int @default(0)`
  - `createdBy: String?` (FK pembuat)
  - Catatan: untuk habit kurasi, `isCustom=false` dan `reach='normal'` by default.

- **Phase 2A: Repeat/Commitment Period (✅ Implemented)**

  - `repeatPeriod: String @default('forever')` // `1_day` | `1_week` | `1_month` | `1_year` | `forever`
  - `repeatStartDate: DateTime @default(now())`
  - `repeatEndDate: DateTime?` // Auto-calculated berdasarkan repeatPeriod, null jika forever

- **Phase 2A: Frequency Control (✅ Implemented)**

  - `frequency: String @default('daily')` // `daily` | `weekly` | `custom`
  - `frequencyDays: String?` // JSON array "[0,1,2,3,4,5,6]" untuk custom days (0=Sunday, 6=Saturday)

- **Phase 2A: Streak Tracking & Gamification (✅ Implemented)**

  - `currentStreak: Int @default(0)` // Streak saat ini (consecutive active days)
  - `longestStreak: Int @default(0)` // Rekor streak terpanjang sepanjang masa
  - `lastCheckinDate: DateTime?` // Tanggal checkin terakhir untuk kalkulasi streak
  - `totalCompletions: Int @default(0)` // Total checkin sepanjang masa (lifetime stat)

- **Phase 2A: Visual Customization (✅ Implemented)**

  - `color: String @default('#6366F1')` // Hex color code untuk personalisasi
  - `icon: String @default('⭐')` // Emoji atau icon identifier

- **Phase 2A: Custom Ordering (✅ Implemented)**

  - `order: Int @default(0)` // Untuk drag & drop reordering habits

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
- Body:
  ```json
  {
    "habitId": "string",
    "notes": "string?",
    // Phase 2A fields (optional):
    "repeatPeriod": "1_day|1_week|1_month|1_year|forever",
    "frequency": "daily|weekly|custom",
    "frequencyDays": "[1,2,3,4,5]",
    "color": "#RRGGBB",
    "icon": "emoji|text",
    "order": 0
  }
  ```
- Response:
  ```json
  {
    "id": "string",
    "habitId": "string",
    "notes": "string?",
    "createdAt": "DateTime",
    // Phase 2A fields:
    "repeatPeriod": "forever",
    "repeatStartDate": "DateTime",
    "repeatEndDate": "DateTime?",
    "frequency": "daily",
    "frequencyDays": null,
    "currentStreak": 0,
    "longestStreak": 0,
    "totalCompletions": 0,
    "color": "#6366F1",
    "icon": "⭐",
    "order": 0
  }
  ```
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
      "title": "Saat Teduh",
      "notes": null,
      "checkedInToday": true,
      "lastCheckinAt": "2025-03-20T10:00:00Z",
      // Phase 2A fields:
      "repeatPeriod": "1_month",
      "repeatStartDate": "2025-10-28T10:00:00Z",
      "repeatEndDate": "2025-11-28T10:00:00Z",
      "frequency": "daily",
      "frequencyDays": null,
      "currentStreak": 5,
      "longestStreak": 12,
      "totalCompletions": 42,
      "color": "#9333EA",
      "icon": "🙏",
      "order": 0
    }
  ]
  ```
- Catatan: Habits diurutkan berdasarkan field `order` (ascending), kemudian `createdAt`.

4. POST `/habits/:userHabitId/checkin` (JWT)

- Deskripsi: Check-in hari ini untuk UserHabit (idempotent).
- Response:
  ```json
  {
    "success": true,
    "created": true,
    // Phase 2A: Streak info
    "currentStreak": 5,
    "longestStreak": 12,
    "totalCompletions": 42
  }
  ```
  (`created=false` bila sudah pernah check-in hari ini).
- Perilaku:
  - Normalisasi tanggal ke UTC
  - **Phase 2A: Validasi frequency** - Checkin hanya diizinkan pada hari aktif sesuai `frequency` dan `frequencyDays`
  - **Phase 2A: Auto-update streak** - `currentStreak` increment jika consecutive, reset ke 1 jika break
  - Jika sudah ada record, kembalikan idempotent
- Error 400: Jika checkin pada hari yang tidak sesuai frequency setting

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
- Body:
  ```json
  {
    "title": "string",
    "description": "string?",
    "notes": "string?",
    // Phase 2A fields (optional):
    "repeatPeriod": "1_day|1_week|1_month|1_year|forever",
    "frequency": "daily|weekly|custom",
    "frequencyDays": "[1,2,3,4,5]",
    "color": "#RRGGBB",
    "icon": "emoji",
    "order": 0
  }
  ```
- Response:
  ```json
  {
    "id": "string",
    "isCustom": true,
    "title": "string",
    "reach": "limited",
    "visibility": "public",
    // Phase 2A fields:
    "repeatPeriod": "forever",
    "repeatStartDate": "DateTime",
    "repeatEndDate": null,
    "frequency": "daily",
    "currentStreak": 0,
    "longestStreak": 0,
    "totalCompletions": 0,
    "color": "#6366F1",
    "icon": "⭐",
    "order": 0
  }
  ```
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

- **Phase 2A: Enhanced Gamification (✅ Implemented)**

  - Streak data tersedia real-time: `currentStreak`, `longestStreak`, `totalCompletions`
  - Setiap checkin auto-update streak untuk immediate feedback
  - Data dapat digunakan untuk:
    - Streak-based rewards (7 hari, 30 hari, 100 hari, dll)
    - Streak multipliers untuk ZP (contoh: +2 ZP per hari streak, max +50 ZP)
    - Achievement badges (Week Warrior, Month Master, Year Legend)
    - Leaderboards berdasarkan longest streak
    - Milestone completions (100x, 500x, 1000x total checkins)

- Event/Hook (MVP sederhana):

  - Setelah `checkin` baru dibuat → kredit +10 ZP + streak bonus
  - Setelah semua habit user ter-check-in hari ini → kredit +20 ZP
  - Streak milestones → bonus ZP dan badges

- **Contoh Implementasi Gamifikasi:**

  ```typescript
  // Base points
  const basePoints = 10;

  // Streak bonus (max +50 ZP)
  const streakBonus = Math.min(userHabit.currentStreak * 2, 50);

  // Total points per checkin
  const totalPoints = basePoints + streakBonus;

  // Streak achievements
  if (currentStreak === 7) awardBadge("7-Day Warrior", +50 ZP);
  if (currentStreak === 30) awardBadge("Month Master", +200 ZP);
  if (longestStreak >= 100) awardBadge("Centurion", +500 ZP);
  ```

- Implementasi: Data Checkin dan Streak tersedia langsung dari UserHabit model; integrasi service/event dapat ditambahkan untuk real-time rewards.

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

Roadmap

**✅ Phase 2A - COMPLETED (2025-10-28)**

- ✅ Repeat/Commitment Period (1 day/week/month/year/forever dengan auto-calculated end date)
- ✅ Frequency control untuk non-daily habits (daily/weekly/custom days dengan validation)
- ✅ Streak tracking built-in (currentStreak, longestStreak, totalCompletions auto-updated)
- ✅ Visual customization (color hex validation, icon emoji/text)
- ✅ Custom ordering (reorder UserHabit via order field)
- ✅ Partial Unique Index DB untuk cegah duplikasi UserHabit aktif (WHERE archivedAt IS NULL)
- ✅ Enhanced gamification support dengan real-time streak data

**🚧 Phase 2B - PLANNED**

- Timezone aware (pakai `profiles.timezone` untuk local day boundary)
- Reminder system (reminderEnabled, reminderTime, reminderDays, reminderTimezone)
- Goal setting (goalType: at_least/at_most/exact, goalCount, goalPeriod)
- Enhanced categorization (category, tags untuk filtering)
- Advanced features (difficulty levels, isPositive for build vs quit habits, timeOfDay)
- Riwayat check-in (range tanggal), statistik (weekly/monthly)
- Event bus/internal hooks untuk Gamifikasi dan Notifikasi
- Auto-archive expired habits (cron job untuk check repeatEndDate)
- Tag internal (pilar) untuk kurasi dan rekomendasi

—

Phase 2A Implementation Notes

**Migration:** `20251029140612_add_habit_tracker_phase2a_fields`
**Status:** ✅ Production Ready
**Build:** Passing
**Documentation:**

- Technical Spec: `docs/habit-tracker/phase2a-fields.md`
- Testing Guide: `docs/habit-tracker/phase2a-testing-guide.md`
- Implementation Summary: `docs/habit-tracker/README.md`

**Key Features Implemented:**

1. **Repeat Period:** Users dapat set commitment duration dengan auto-calculated end date
2. **Frequency Control:** Support untuk weekday-only, weekend-only, atau custom days dengan validation
3. **Streak Tracking:** Auto-update currentStreak, longestStreak, totalCompletions pada setiap checkin
4. **Visual Customization:** Hex color validation dan icon support untuk personalisasi
5. **Custom Ordering:** Habits dapat di-reorder berdasarkan prioritas user
6. **Frequency Validation:** Checkin diblokir pada hari non-aktif dengan error message yang jelas
7. **Gamification Ready:** Data streak tersedia real-time untuk rewards, achievements, dan leaderboards

**Backward Compatibility:** ✅ Semua existing habits mendapat default values yang aman (forever, daily, streak 0, default color/icon)

—

Dokumen ini merangkum kebutuhan MVP dan Phase 2A Habit Tracker berdasarkan Blueprint, Gamifikasi, dan User Stories. Revisi dapat dilakukan seiring integrasi dengan modul Gamifikasi dan Profil Summary.
