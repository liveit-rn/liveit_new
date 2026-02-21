# Architecture Strategy: Offline Caching & Optimistic UI (Me+ Benchmark)

**Date:** 2026-01-24
**Feature:** Habit Tracker
**Objective:** Mencapai User Experience (UX) yang instan, *snappy*, dan *reliable* setara dengan aplikasi **Me+ (Daily Routine Planner)**, namun tetap aman dari sisi performa (Memory Leak/ANR).

---

## 1. The "Me+" Benchmark: Why & How

### Why: Masalah "Online-First"
Saat ini, LIVEIT menggunakan pendekatan *Online-First*.
1.  User buka halaman → Loading Spinner (tunggu sinyal) → Data muncul.
2.  Sinyal buruk = Aplikasi tidak bisa dipakai (Blank/Error).
3.  Check-in harus menunggu respon server (terasa lambat).

### How: Pendekatan "Me+" (Offline-First)
Aplikasi habit tracker kelas dunia seperti **Me+** menggunakan pendekatan *Offline-First*.
1.  User buka halaman → **Data LANGSUNG muncul** (dari memori lokal).
2.  Internet bekerja di *background* untuk sinkronisasi.
3.  Check-in bersifat **Optimistic**: UI berubah hijau seketika, sinkronisasi server urusan belakangan.

---

## 2. Performance & Safety Analysis (Anti-ANR)

Salah satu kekhawatiran utama adalah: **"Apakah menambah database lokal bikin aplikasi berat, memory leak, atau Crash/ANR?"**

### Jawabannya: Tidak, jika menggunakan **Hive**.

| Aspek | SQLite (Tradisional) | Hive (Pilihan Kita) | Dampak ke Performa |
|-------|----------------------|---------------------|--------------------|
| **Tipe** | Relational (SQL) | NoSQL (Key-Value) | Hive jauh lebih ringan karena tidak ada query complex. |
| **I/O** | Native Bridge | Pure Dart (Binary) | Tidak membebani thread native Android/iOS. |
| **Speed** | Medium | Extreme Fast | Read data < 1ms, UI tidak akan freeze (ANR). |
| **Memory** | Perlu manage cursor | Load all keys to RAM | Data Habit teks (JSON) sangat kecil (<100KB), aman untuk RAM HP modern (4GB+). |

### Pencegahan Memory Leak & Crash
1.  **Singleton Pattern:** Hive box dibuka sekali saat app start (`main.dart`) melalui `GetIt`. Tidak ada *open/close* database berulang-ulang.
2.  **Clean Architecture:** Logic caching terisolasi di `LocalDataSource`. Bloc tidak tahu menahu soal cache, dia hanya minta data ke Repository.
3.  **Error Handling:** Jika cache rusak (corrupt), aplikasi akan *fallback* otomatis ke API (re-fetch) dan menimpa cache rusak tersebut.

---

## 3. Architecture Flow

### Current Flow (Lambat)
```mermaid
UI (Bloc) <--> Repository <--> RemoteDataSource (API) <--> Internet
```

### New Hybrid Flow (Cepat & Robust)
```mermaid
UI (Bloc) <--> Repository
               |
               +--> 1. Cek LocalDataSource (Hive) --> RETURN DATA INSTAN (Cache)
               |
               +--> 2. Cek RemoteDataSource (API) --> Background Process
                                                       |
                    (Jika Sukses) ---------------------+
                    Update Hive & Emit Data Baru ke UI
```

---

## 4. Implementation Guide

### A. Dependency Setup
Kita menggunakan `hive` dan `hive_flutter`.

### B. Habit Local Data Source
Class ini bertugas membaca/menulis ke Hive.

```dart
// lib/features/habit_tracker/data/datasources/habit_local_data_source.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_habit_model.dart';

abstract class HabitLocalDataSource {
  Future<List<UserHabitModel>> getLastHabits();
  Future<void> cacheHabits(List<UserHabitModel> habits);
}

class HabitLocalDataSourceImpl implements HabitLocalDataSource {
  static const String boxName = 'habits_cache';
  
  // Singleton Box (Safe Memory)
  final Box _box; 

  HabitLocalDataSourceImpl(this._box);

  @override
  Future<List<UserHabitModel>> getLastHabits() async {
    // Read instant dari memory
    final data = _box.get('user_habits');
    if (data != null) {
      // Decode JSON/List
      return (data as List).map((e) => UserHabitModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<void> cacheHabits(List<UserHabitModel> habits) async {
    // Simpan data terbaru dari API untuk pemakaian berikutnya
    final jsonList = habits.map((e) => e.toJson()).toList();
    await _box.put('user_habits', jsonList);
  }
}
```

### C. Repository Strategy (Stale-While-Revalidate)
Repository menjadi "otak" yang mengatur strategi: **"Tampilkan cache dulu, lalu update dari internet"**.

```dart
// lib/features/habit_tracker/data/repositories/habit_repository_impl.dart

class HabitRepositoryImpl implements HabitRepository {
  final HabitRemoteDataSource remoteDataSource;
  final HabitLocalDataSource localDataSource;
  // ...

  @override
  Future<List<UserHabit>> getUserHabits() async {
    // 1. Coba ambil data lokal dulu (Anti-Loading Spinner)
    try {
      final localHabits = await localDataSource.getLastHabits();
      if (localHabits.isNotEmpty) {
        // Jika arsitektur mendukung Stream, kita bisa emit localHabits dulu
        // Untuk pola Future sederhana, kita bisa jadikan ini fallback
        // Atau return localHabits jika tidak ada internet
      }
    } catch (e) {
      // Ignore cache error, lanjut ke API
    }

    // 2. Ambil data segar dari API
    try {
      final remoteHabits = await remoteDataSource.getUserHabits();
      
      // 3. Simpan ke cache untuk pemakaian berikutnya
      localDataSource.cacheHabits(remoteHabits);
      
      return remoteHabits;
    } catch (e) {
      // 4. Jika API gagal (Offline), return Cache terakhir (Emergency Mode)
      // Ini yang membuat app tetap jalan di mode pesawat!
      final localHabits = await localDataSource.getLastHabits();
      if (localHabits.isNotEmpty) {
        return localHabits;
      }
      rethrow; // Menyerah jika API mati dan Cache kosong
    }
  }
}
```

### D. Optimistic UI (Untuk Check-in)
Membuat tombol centang terasa instan.

```dart
// Di dalam HabitBloc

Future<void> _onHabitCheckInRequested(...) async {
  // 1. UPDATE STATE DULUAN (Optimistic)
  // Buat copy list habit, ubah status jadi checked-in
  final optimisticHabits = ...; 
  emit(HabitLoaded(habits: optimisticHabits, ...));

  // 2. Kirim ke Server belakangan
  try {
    await repository.checkIn(...);
    // Sukses? Bagus. State sudah benar.
  } catch (e) {
    // 3. Gagal? Rollback state (Revert UI)
    // Tampilkan snackbar "Koneksi gagal"
    emit(HabitLoaded(habits: originalHabits, ...)); 
  }
}
```

---

## 5. Next Steps

1.  **Add Dependencies:** `hive`, `hive_flutter`.
2.  **Register Module:** Update `service_locator.dart` untuk inisialisasi Hive Box.
3.  **Implement Datasource:** Buat `HabitLocalDataSource`.
4.  **Update Repository:** Terapkan logika *fallback to cache* saat offline.

Dengan strategi ini, LIVEIT akan memiliki fondasi performa yang solid, minim crash, dan UX yang setara dengan aplikasi top-tier di pasar.
