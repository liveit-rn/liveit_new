# Skill: Offline-first data flow (Hybrid Cache + Optimistic UI)

**Context**: Dokumen ini menjelaskan bagaimana project `liveit-flutter` menangani pengalaman “offline-first” untuk data (terutama Habit Tracker). Istilah "offline-first" di repo ini sebenarnya lebih tepat disebut **hybrid**:

- **Reads**: _cache-first/stale-while-revalidate_ (lebih cepat, fallback ke cache saat offline).
- **Writes**: _API-first + optimistic UI_ (UI terasa instan, tetapi bila request gagal akan rollback).

> Catatan penting: berdasarkan kode yang ada saat ini, **belum ada sistem “offline write queue/outbox”** (misalnya menyimpan perubahan saat offline lalu mengirim saat online). Kalau user melakukan aksi write ketika offline, mayoritas aksi akan **gagal** dan UI di-rollback.

## Ringkasan arsitektur (kontrak singkat)

### Data stores

- **Local cache**: Hive box `habits_cache` dengan key `user_habits`.
- **Remote source of truth**: REST API via `DioClient`.

### Perilaku utama

- App mencoba menampilkan data secepat mungkin dari cache.
- Lalu mencoba refresh data dari API.
- Kalau API gagal, UI tetap bisa hidup dari cache (kalau cache ada).
- Write (check-in/undo/add/update/archive/reorder) masih mengandalkan server.

## Komponen yang terlibat dan perannya

### 1) Dependency Injection

File: `lib/core/injection/injection_container.dart`

- Membuka Hive box sekali saat startup:
  - `final habitCacheBox = await HabitLocalDataSourceImpl.openBox();`
- Mendaftarkan:
  - `HabitLocalDataSource` (Hive)
  - `HabitRemoteDataSource` (Dio)
  - `HabitRepository` (hybrid)

**Implikasi**: cache siap dipakai sejak awal app berjalan (nggak perlu open box berkali-kali).

### 2) Local data source (Hive cache)

File: `lib/features/habit_tracker/data/datasources/habit_local_data_source.dart`

- Box: `habits_cache`
- Key: `user_habits`
- Data disimpan sebagai `List<Map<String, dynamic>>` (JSON list).

API:

- `getCachedHabits()`:
  - Baca list JSON dari Hive.
  - Convert ke `UserHabitModel`.
  - Return `[]` bila kosong.

- `cacheHabits(habits)`:
  - Convert ke list JSON.
  - Persist ke Hive.

**Sifat cache**:

- Cache hanya untuk _list of user habits_.
- Belum ada TTL/expiry/versi skema.

### 3) Remote data source (API)

File: `lib/features/habit_tracker/data/datasources/habit_remote_data_source.dart`

- Endpoint utama:
  - `GET /habits` (daftar habit user)
  - `POST /habits/{id}/checkin`
  - `DELETE /habits/{id}/checkin`
  - dll

Semua request lewat `DioClient`.

### 4) Repository (hybrid offline-ish)

File: `lib/features/habit_tracker/data/repositories/habit_repository_impl.dart`

#### Read: `getUserHabits()` menggunakan strategi _stale-while-revalidate_

Alur:

1. **Coba API dulu** (source of truth)
2. Kalau sukses:
   - simpan ke cache via `_localDataSource.cacheHabits(remoteHabits)` **tanpa await** (fire-and-forget)
   - return `remoteHabits`
3. Kalau API gagal:
   - baca cache `getCachedHabits()`
   - jika cache ada -> return cache
   - jika cache kosong -> `rethrow` (UI akan error)

**Intinya**: fallback cache terjadi hanya saat request API gagal.

#### Read tambahan: `getCachedHabits()`

- Langsung return data dari Hive.

#### Write: API-first

Untuk method seperti `checkIn`, `undoCheckIn`, `addHabit`, `updateHabit`, `archiveHabit`, `reorderHabits`:

- Repo langsung memanggil remote data source.
- Tidak ada update cache yang konsisten setelah write.
  - Misalnya `checkIn` ada komentar “invalidate cache”, tapi implementasinya belum ada invalidation/refresh di repo.
  - Refresh dilakukan di layer BLoC (lihat di bawah).

### 5) Presentasi / state management (BLoC)

File: `lib/features/habit_tracker/presentation/bloc/habit_bloc.dart`

#### Startup: `HabitStarted`

1. Emit `HabitLoading()`
2. **Load dari cache dulu** (`_repository.getCachedHabits()`)
   - kalau ada -> emit `HabitLoaded(habits: cachedHabits)`
   - error cache di-ignore
3. **Fetch dari API** (`_repository.getUserHabits()`)
   - sukses -> emit `HabitLoaded(habits: remoteHabits)`
   - gagal -> kalau sebelumnya belum ada `HabitLoaded` (cache kosong) -> emit `HabitError`

**Efek UX**:

- Ada “instant UI” dari cache.
- Data remote menimpa data cache setelah sukses.
- Kalau offline tapi cache ada, user tetap lihat data terakhir.

#### Write contoh paling penting: `HabitCheckInRequested` (Optimistic UI)

Alur:

1. Pastikan state `HabitLoaded`
2. Simpan `originalHabits`
3. Buat `optimisticHabit` (seolah check-in sukses):
   - `checkedInToday: true`
   - streak +1, totalCompletions +1, lastCheckinAt sekarang
4. Emit `HabitLoaded` dengan optimistic list (user melihat perubahan instan)
5. **Background call ke server**: `_repository.checkIn(...)`
6. Jika sukses:
   - hitung `CelebrationData`
   - trigger refresh: `add(HabitStarted())` untuk ambil state akurat dari server
7. Jika gagal:
   - rollback: emit `HabitLoaded` dengan `originalHabits`
   - emit `HabitError('Gagal menyimpan check-in...')`

#### Write lain (Undo check-in)

Mirip:

- optimistic undo
- call server
- sukses -> refresh via `HabitStarted()`
- gagal -> rollback

**Poin yang sering disalahpahami**:

- Ini _bukan_ offline write queue. Optimistic UI hanya membuat UI terasa cepat.
- Kalau offline, request akan gagal (biasanya `ApiException.noInternet` via interceptor), lalu BLoC rollback.

## Layer network: error normalization

File: `lib/core/network/interceptors/error_interceptor.dart`

- `DioExceptionType.connectionError` di-map menjadi `ApiException.noInternet(...)`.
- Timeout di-map ke `ApiException.timeout(...)`.

**Implikasi**:

- Pada kondisi offline, writes akan error cepat dan terklasifikasi.

## Diagram alur (ringkas)

### Habit list load

1. UI -> `HabitStarted`
2. BLoC -> cache -> emit cached
3. BLoC -> repo -> API
4. API ok -> repo update cache -> emit fresh
5. API fail -> repo fallback cache -> emit cached (atau error jika kosong)

### Check-in

1. UI -> `HabitCheckInRequested`
2. BLoC optimistic emit
3. BLoC -> API call
4. ok -> refresh list
5. fail -> rollback

## Edge cases yang sudah/ belum ditangani

### Sudah lumayan aman

- Offline dengan cache tersedia: user masih bisa browsing list habit.
- Cache error: di-ignore pada startup (nggak crash).

### Belum ada (gap) — penting kalau benar-benar mau “offline-first write”

- **Outbox / pending mutations** (queue of writes) untuk:
  - check-in saat offline lalu sinkron saat online
  - create/update habit saat offline
- **Conflict resolution** (mis. user check-in di dua device)
- **Cache invalidation** yang eksplisit (sekarang mengandalkan refresh).
- **Connectivity-aware sync trigger** (ada dependency `connectivity_plus`, tapi belum terlihat dipakai untuk auto-resync).

## Lokasi kode (quick links)

- DI: `lib/core/injection/injection_container.dart`
- Hive cache DS: `lib/features/habit_tracker/data/datasources/habit_local_data_source.dart`
- API DS: `lib/features/habit_tracker/data/datasources/habit_remote_data_source.dart`
- Repo hybrid: `lib/features/habit_tracker/data/repositories/habit_repository_impl.dart`
- HabitBloc: `lib/features/habit_tracker/presentation/bloc/habit_bloc.dart`
- Dio client: `lib/core/network/dio_client.dart`
- Error interceptor: `lib/core/network/interceptors/error_interceptor.dart`

## Rekomendasi kecil (kalau kamu mau next)

1. Tambahin **write outbox** sederhana (Hive box lain) untuk menyimpan event check-in saat offline.
2. Worker sync:
   - trigger manual (button “Sync”) + trigger otomatis saat koneksi pulih.
3. Tentukan aturan konflik:
   - server-wins atau last-write-wins.

Kalau kamu setuju, aku bisa bantu implement versi minimal “check-in outbox” dulu (yang paling berdampak) tanpa bikin arsitektur berat.
