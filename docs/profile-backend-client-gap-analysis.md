# Profile Feature Analysis: Backend vs Flutter Client

Tanggal: 2026-02-20
Status: Analisis (tanpa implementasi kode)

## Update Implementasi (2026-02-20)

- Gap avatar backend-client untuk kontrak URL sudah diperbaiki:
  - Backend sekarang expose `avatarUrl` berbasis proxy backend (bukan URL Appwrite langsung).
  - Backend menambah endpoint `GET /profiles/assets/avatar/:fileId` untuk serve image bytes via backend.
  - `POST /profiles/upload/avatar` sekarang return `{ fileId, avatarUrl }`.
- Flow upload avatar di Flutter Profile page sudah diimplementasi:
  - tap avatar -> pilih gambar dari galeri -> upload ke backend -> update `profileImageId`.
- Mapping utama profile di Flutter juga sudah diselaraskan untuk:
  - payload parsing (`response.data` langsung / nested `data`),
  - update nama (`name`),
  - update avatar (`profileImageId`).

## Tujuan

Dokumen ini merangkum:

1. Status implementasi fitur Profile di backend (NestJS) dan Flutter client.
2. Data apa saja yang saat ini ditampilkan UI Profile Flutter.
3. Data/fitur mana yang sudah bisa disediakan backend untuk kebutuhan UI tersebut.
4. Gap kontrak API dan gap implementasi yang masih ada.

## Scope & Sumber Kebenaran

- Source of truth backend docs: `liveit-server/docs/`.
- Verifikasi dilakukan langsung terhadap implementasi code:
  - Backend: `liveit-server/src/profiles/*`, `liveit-server/src/gamification/*`, `liveit-server/src/auth/*`.
  - Flutter: `liveit-flutter/lib/features/profile/*`, `liveit-flutter/lib/features/auth/*`, `liveit-flutter/lib/core/injection/*`.

## Ringkasan Eksekutif

- UI halaman Profile Flutter sudah mature secara visual (glass-morphism) dan sudah terhubung ke `ProfileBloc`.
- Backend Profiles sudah menyediakan endpoint inti yang cukup lengkap (8 endpoint), ditambah endpoint gamification untuk statistik profile.
- Namun, parity API Flutter-Backend untuk profile masih belum selaras:
  - Ada mismatch nama field request/response.
  - Ada asumsi response envelope yang tidak sesuai.
  - Ada call endpoint yang tidak tersedia di backend.
  - Beberapa endpoint backend profile/gamification belum dimanfaatkan di client.

## A. Backend Profiles: Endpoint yang Tersedia

Backend saat ini menyediakan endpoint berikut di modul Profiles:

1. `GET /profiles/me`
2. `PUT /profiles/me`
3. `POST /profiles/upload/avatar`
4. `POST /profiles/email/claim/start`
5. `POST /profiles/email/claim/confirm`
6. `GET /profiles/u/:username`
7. `GET /profiles/me/summary`
8. `GET /profiles/u/:username/summary`

Catatan pendukung:

- Statistik gamification yang relevan untuk Profile UI juga tersedia:
  - `GET /gamification/me/points`
  - `GET /gamification/me/summary`
  - `GET /gamification/me/achievements`
  - `GET /gamification/me/history`
- Endpoint `GET /auth/profile` masih ada untuk backward compatibility, tapi sudah ditandai deprecated; disarankan pakai `GET /profiles/me`.

## B. Flutter Profile: Yang Sudah Diimplementasi

### B1. Struktur Feature

- Sudah ada data/domain/presentation layer profile:
  - `profile_remote_datasource.dart`
  - `profile_repository_impl.dart`
  - `profile_bloc.dart`
  - `profile_page.dart`
- DI untuk `ProfileRemoteDataSource`, `ProfileRepository`, dan `ProfileBloc` sudah aktif.

### B2. Endpoint yang Saat Ini Dipanggil Client

- `GET /profiles/me` (fetch profile)
- `PUT /profiles/me` (update display name/avatar/timezone)
- `DELETE /profiles/me` (delete account) -> ini tidak ada di backend.

### B3. UI Data yang Ditampilkan di Halaman Profile

UI saat ini menampilkan:

- Header:
  - avatar (`avatarUrl`)
  - display name
  - username
  - email
  - member since
- Stat cards:
  - Zoe Points
  - Level
  - Streak
  - Badge count
- Menu section:
  - Edit Profil
  - Badge & Pencapaian
  - Riwayat Aktivitas
  - Notifikasi
  - Privasi & Keamanan

Catatan: item menu di atas saat ini mayoritas masih `coming soon` di client.

## C. Ketersediaan Data Backend untuk UI Profile Saat Ini

Matriks data UI vs backend:

1. Avatar
   - UI butuh: URL image (`avatarUrl`).
   - Backend tersedia: upload avatar + simpan `profileImageId` + expose `avatarUrl` proxy backend.
   - Status: tersedia.

2. Display name
   - UI butuh: `displayName`.
   - Backend tersedia: field `name`.
   - Status: tersedia, perlu mapping `name -> displayName` di client.

3. Username
   - UI butuh: `username`.
   - Backend tersedia: `username`.
   - Status: tersedia.

4. Email
   - UI butuh: `email`.
   - Backend tersedia: `email`.
   - Status: tersedia.

5. Member since
   - UI butuh: `joinedAt`.
   - Backend tersedia: `createdAt`.
   - Status: tersedia, perlu mapping `createdAt -> joinedAt`.

6. Zoe Points
   - UI butuh: total points.
   - Backend tersedia: `GET /gamification/me/points` (`totalZP`) atau profile summary (`pointsEstimate`).
   - Status: tersedia.

7. Level
   - UI butuh: current level.
   - Backend tersedia: `GET /gamification/me/points` (`level`).
   - Status: tersedia.

8. Streak
   - UI butuh: current streak.
   - Backend tersedia: `GET /gamification/me/summary` (`streak.currentStreak`).
   - Status: tersedia.

9. Badge count
   - UI butuh: jumlah badge.
   - Backend tersedia: `GET /gamification/me/summary` (`achievements.totalUnlocked`) atau count dari `GET /gamification/me/achievements`.
   - Status: tersedia.

10. Notifikasi setting
    - UI menu ada.
    - Backend status: reminder/notification masih roadmap, belum fully implemented di MVP.
    - Status: belum tersedia penuh.

## D. Gap Utama (Backend vs Flutter)

### D1. Gap Kontrak Response

- Status terbaru: sudah diselaraskan.
- Datasource Flutter sekarang menangani kedua pola payload:
  - object langsung pada `response.data`, atau
  - nested object pada `response.data['data']`.

### D2. Gap Nama Field Request/Model

Contoh mismatch kritis:

- Update display name: sudah diselaraskan (`name`).
- Update avatar: sudah diselaraskan (`profileImageId`).
- Profile model:
  - Mapping utama sudah disesuaikan (`name -> displayName`, `createdAt -> joinedAt`, `avatarUrl` dari backend proxy).
  - Catatan: statistik gamification tetap berasal dari endpoint gamification/summary, bukan profil inti.

### D3. Gap Endpoint Usage

- Flutter memanggil `DELETE /profiles/me` untuk delete account.
- Backend tidak menyediakan endpoint itu pada modul Profiles.

### D4. Gap Fitur yang Belum Dipakai Client

Endpoint backend yang ada tetapi belum dimanfaatkan oleh client profile:

- `POST /profiles/upload/avatar`
- `POST /profiles/email/claim/start`
- `POST /profiles/email/claim/confirm`
- `GET /profiles/me/summary`
- `GET /profiles/u/:username`
- `GET /profiles/u/:username/summary`
- Endpoint gamification untuk stat profile (`/gamification/me/*`)

### D5. Gap UX Feature Profile

Di UI, menu berikut masih placeholder dan belum wired ke flow/backend:

- Edit Profil
- Badge & Pencapaian
- Riwayat Aktivitas
- Notifikasi
- Privasi & Keamanan

## E. Matrix Endpoint: Implemented vs Used by Flutter

1. `GET /profiles/me`
   - Backend: yes
   - Flutter: yes
   - Status: dipakai dan contract parsing sudah diselaraskan

2. `PUT /profiles/me`
   - Backend: yes
   - Flutter: yes
   - Status: dipakai dan field mapping utama sudah diselaraskan (`name`, `profileImageId`)

3. `POST /profiles/upload/avatar`
   - Backend: yes
   - Flutter: no
   - Status: gap (harus dipakai untuk alur avatar benar)

4. `POST /profiles/email/claim/start`
   - Backend: yes
   - Flutter: no
   - Status: gap

5. `POST /profiles/email/claim/confirm`
   - Backend: yes
   - Flutter: no
   - Status: gap

6. `GET /profiles/u/:username`
   - Backend: yes
   - Flutter: no
   - Status: gap

7. `GET /profiles/me/summary`
   - Backend: yes
   - Flutter: no
   - Status: gap

8. `GET /profiles/u/:username/summary`
   - Backend: yes
   - Flutter: no
   - Status: gap

9. `DELETE /profiles/me`
   - Backend: no
   - Flutter: yes
   - Status: invalid call di client

## F. Kesimpulan

- Secara visual UX, Profile page Flutter sudah sesuai arah desain.
- Secara data/API, backend sebenarnya sudah mampu menyuplai mayoritas kebutuhan UI profile saat ini.
- Hambatan utama bukan “backend belum ada”, tetapi mismatch kontrak API + mapping model di client.
- Area yang memang belum siap penuh dari sisi backend untuk menu profile adalah notifikasi/reminder (masih roadmap).

## G. Rekomendasi Teknis (Non-Implementasi)

1. Selaraskan kontrak profile client dengan DTO backend:
   - `name <-> displayName`
   - `createdAt <-> joinedAt`
   - `profileImageId` + resolver URL avatar

2. Ubah flow avatar client menjadi:
   - upload file ke `POST /profiles/upload/avatar`
   - simpan `profileImageId` via `PUT /profiles/me`

3. Pisahkan sumber data profile vs gamification:
   - data identitas dari `/profiles/me`
   - points/level/streak/badges dari `/gamification/me/*` (atau fallback `/profiles/me/summary` bila sesuai kebutuhan layar)

4. Hapus/replace call `DELETE /profiles/me` karena endpoint belum tersedia di backend.
