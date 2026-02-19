# Habit Tracker Technical Blueprint & Logic

**Version:** 1.0 (Phase 5 Completed)
**Last Updated:** 2026-01-25
**Scope:** End-to-End Habit Tracker Feature (Flutter)

---

## 1. Architecture Overview

Fitur Habit Tracker dibangun dengan prinsip **Offline-First** dan **Optimistic UI**, mengadopsi standar aplikasi produktivitas modern (seperti Me+). Arsitektur mengikuti pola **Clean Architecture** dengan pemisahan layer yang tegas.

### High-Level Data Flow

```mermaid
[UI Layer]              [Presentation Layer]       [Domain Layer]          [Data Layer]
HabitTrackerPage  <-->  HabitBloc            <-->  HabitRepository   <-->  [Hybrid Strategy]
(View)                  (State Management)         (Interface)             |
                                                                           +-- LocalDataSource (Hive)
                                                                           |   (Cache/Offline)
                                                                           |
                                                                           +-- RemoteDataSource (Dio)
                                                                               (API/Server)
```

---

## 2. Business Logic & State Management (`HabitBloc`)

`HabitBloc` bertindak sebagai "otak" fitur ini. Ia tidak hanya meneruskan data, tetapi juga menangani logika presentasi yang kompleks.

### A. Initialization Flow (`HabitStarted`)
Event ini dipanggil saat aplikasi/halaman dimuat. Menggunakan strategi **Stale-While-Revalidate**:

1.  **Emit Loading:** UI menampilkan skeleton/loading (jika data kosong).
2.  **Fetch Cache:** Meminta data dari `Repository.getCachedHabits()`.
3.  **Emit Cached State:** Jika ada cache, **langsung emit** `HabitLoaded`. User melihat data instan (< 100ms).
4.  **Fetch API:** Secara paralel, memanggil `Repository.getUserHabits()` untuk data segar.
5.  **Re-Emit Fresh State:** Setelah API merespon, emit `HabitLoaded` lagi dengan data baru (update background).

### B. Optimistic Check-in Logic (`HabitCheckInRequested`)
Tujuannya adalah *Zero Latency Feedback*. User tidak boleh menunggu loading saat menekan tombol centang.

**Flow:**
1.  **Clone & Mutate:** Mengambil list habit saat ini, mencari habit target, dan membuat copy baru dengan `checkedInToday = true` dan increment `currentStreak`.
2.  **Emit Optimistic State:** Langsung emit `HabitLoaded` dengan list yang sudah dimutasi. UI berubah hijau seketika.
3.  **Call API (Background):** Mengirim request check-in ke server.
4.  **Handle Response:**
    *   **Success:** Server mengembalikan data streak/points terbaru. Bloc menghitung gamifikasi (`_calculateCelebration`) lalu trigger refresh data.
    *   **Failure:** Rollback state ke kondisi semula dan tampilkan error (Snackbar).

### C. Gamification Calculator (`_calculateCelebration`)
Logika ini berjalan di Bloc setelah respon check-in sukses diterima dari server.

*   **Pemicu:** Respon API `HabitCheckinResponse`.
*   **Aturan Poin:**
    *   Base Check-in: +10 Zoe Points.
    *   Bonus Streak 7 Hari: +50 Points.
    *   Bonus Streak 30 Hari: +100 Points.
    *   All Habits Done Today: +20 Points.
*   **Output:** Object `CelebrationData` di dalam state `HabitLoaded`.
*   **Efek UI:** `HabitTrackerPage` mendengarkan perubahan ini dan memicu `ConfettiOverlay` atau Dialog Milestone.

---

## 3. Data Layer Strategy (The "Hybrid Engine")

Repository (`HabitRepositoryImpl`) adalah penjaga gawang data yang menentukan sumber data mana yang dipakai.

### A. Local Storage (Hive)
*   **Technology:** Hive (NoSQL, Key-Value, Pure Dart).
*   **Box Name:** `habits_cache`.
*   **Key:** `user_habits` (List of JSON).
*   **Safety:** Singleton pattern via `GetIt`. Box dibuka sekali di `main.dart`.
*   **Why Hive?** Mencegah ANR (Application Not Responding) karena operasi I/O sangat cepat dibanding SQLite.

### B. Repository Logic
*   **Read (`getUserHabits`):**
    1.  Coba fetch API.
    2.  Jika Sukses: Simpan ke Hive (`cacheHabits`), return data.
    3.  Jika Gagal (Exception/Offline): Ambil dari Hive (`getCachedHabits`). Jika Hive kosong, baru lempar error.
*   **Write (`checkIn`, `addHabit`):**
    *   Selalu tembak API.
    *   Update cache dilakukan implisit saat refresh data (`getUserHabits`) dipanggil setelah write sukses.

---

## 4. UI Component System ("Grounded Growth" Design)

Sistem UI dibangun modular untuk maintainability dan konsistensi visual.

### A. `HabitCard`
Komponen paling kompleks di halaman ini.
*   **States:** Default, Checked-in (Green/Gradient), Reordering (Drag handle).
*   **Animations:**
    *   `ScaleAnimation`: Saat ditekan (bounce effect).
    *   `CheckAnimation`: Transisi icon centang (Curves.easeOutBack).
*   **Visual Logic:**
    *   Warna background menyesuaikan warna habit (opacity 10-15%).
    *   Streak Badge muncul dinamis (🔥/⚡/👑) berdasarkan jumlah streak.

### B. `HabitStatsPage`
Halaman detail analitik.
*   **Calendar Heatmap:** Render grid manual menggunakan `GridView`. Logika warna: Habit Color jika checked-in, Transparent jika miss.
*   **Milestone Progress:** Linear indicator menghitung `%` menuju target streak berikutnya (7 -> 30 -> 100 -> 365).

### C. `CelebrationOverlay`
Wrapper global di `HabitTrackerPage`.
*   Menggunakan `CustomPainter` untuk merender partikel confetti.
*   Performant karena menggunakan `Canvas` langsung, bukan Widget tree yang berat.

---

## 5. Data Entities & Rules

### `UserHabit` Entity
Objek utama yang merepresentasikan habit milik user.

| Field | Tipe | Deskripsi | Aturan Bisnis |
|-------|------|-----------|---------------|
| `id` | String | UUID dari backend | Primary Key. |
| `title` | String | Nama Habit | Diambil dari Catalog atau Input User. |
| `color` | String | Hex Code (#RRGGBB) | Default: #6366F1 (Indigo). |
| `frequency` | Enum | daily, weekly, custom | Menentukan aturan jadwal. |
| `frequencyDays`| List<int> | [1, 3, 5] (Sen, Rab, Jum) | Hanya aktif jika frequency = custom. |
| `repeatPeriod` | Enum | forever, 1_week, dll | Durasi masa aktif habit. |
| `currentStreak`| Int | Counter | Direset backend jika user bolos > grace period. |
| `checkedInToday`| Bool | Status Harian | Reset otomatis setiap jam 00:00 (Server Time). |

### Aturan Sortir (Sorting Logic)
Daftar habit diurutkan di UI (`HabitTrackerPage`) dengan prioritas:
1.  **Status:** Belum dikerjakan (Pending) selalu di atas. Yang sudah selesai (Checked-in) pindah ke bawah.
2.  **Order Index:** Jika status sama, urutkan berdasarkan `order` (hasil drag & drop user).

---

## 6. Implementation Details & File Structure

### Directory: `lib/features/habit_tracker/`

```text
├── data/
│   ├── datasources/
│   │   ├── habit_local_data_source.dart  # Hive Implementation
│   │   └── habit_remote_data_source.dart # Dio/API Implementation
│   ├── models/
│   │   ├── user_habit_model.dart         # JSON Serialization
│   │   └── habit_checkin_response.dart   # API Response DTO
│   └── repositories/
│       └── habit_repository_impl.dart    # Hybrid Logic
├── domain/
│   ├── entities/                         # Pure Dart Classes
│   └── repositories/                     # Abstract Interface
├── presentation/
│   ├── bloc/                             # HabitBloc, Events, States
│   ├── pages/
│   │   ├── habit_tracker_page.dart       # Main Dashboard
│   │   ├── add_habit_page.dart           # Form Create
│   │   ├── edit_habit_page.dart          # Form Edit
│   │   └── habit_stats_page.dart         # Analytics Detail
│   └── widgets/
│       ├── habit_card.dart               # List Item Widget
│       └── celebrations.dart             # Confetti & Dialogs
```

### Critical Dependencies
*   `flutter_bloc`: State management.
*   `hive_flutter`: Offline storage.
*   `auto_route`: Navigation & Parameter passing.
*   `get_it`: Dependency Injection (Singleton management).

---

## 7. Future Roadmap (To Be Implemented)

Fitur yang didesain tapi belum masuk fase ini:
1.  **Offline Queue:** Check-in saat offline saat ini hanya *optimistic* di UI tapi gagal di background (error snackbar). Idealnya disimpan di *queue* lokal dan di-retry otomatis saat online (WorkManager).
2.  **Grace Period:** Logika "Freeze Streak" jika lupa absen (Logic ada di backend).
3.  **Reminders:** Push notification lokal (`flutter_local_notifications`) berdasarkan jam pengingat habit.

---

*Dokumen ini adalah acuan kebenaran (Source of Truth) untuk pengembangan fitur Habit Tracker di sisi mobile.*
