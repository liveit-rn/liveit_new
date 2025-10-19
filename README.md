# liveit_new

LIVEIT is a cross-platform Flutter application that implements habit tracking, daily devotionals, and light social features. This repository contains the frontend Flutter application (mobile, web, desktop) and supporting documentation for features and development.

## Ringkasan Singkat

LIVEIT membantu pengguna membangun kebiasaan sehat melalui pengingat, pelacakan streak, dan konten renungan harian. Aplikasi ini dibangun dengan arsitektur bersih (Clean Architecture) dan menggunakan BLoC untuk state management.

## Fitur Utama

- Registrasi / Login (email + password) dan dukungan OAuth (placeholder)
- Onboarding untuk klaim username
- Pelacakan kebiasaan (habits) dan daily check-ins
- Konten renungan harian (devotionals)
- Profil pengguna dan gamifikasi ringan (poin, level, streak)

## Teknologi & Pola Arsitektur

- Flutter (Dart) — cross-platform UI
- BLoC untuk state management
- Clean Architecture: `presentation`, `domain`, `data`
- `auto_route` untuk navigasi, `get_it` untuk dependency injection
- `dio` untuk HTTP, `flutter_secure_storage` untuk token storage
- Logging dengan `logger`

## Struktur Proyek (ringkasan)

- `lib/` — kode sumber aplikasi (fitur terorganisir per modul)
- `lib/features/` — folder fitur (auth, home, habit_tracker, profiles, dll.)
- `docs/` — dokumentasi fitur dan keputusan desain
- `test/` — unit dan widget tests
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` — platform wrappers

## Quickstart (pengembangan lokal)

1. Pasang dependensi:

   ```bash
   flutter pub get
   ```

2. Jika proyek menggunakan code generation (freezed / json_serializable / auto_route):

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Jalankan aplikasi di emulator / device:

   ```bash
   flutter run
   # atau untuk web
   flutter run -d chrome
   ```

4. Periksa analisis dan format:

   ```bash
   flutter analyze
   dart format .
   ```

5. Jalankan test:

   ```bash
   flutter test
   ```

## Konfigurasi & Secrets

- Hindari commit secrets ke repo; gunakan environment variables atau CI secrets.
- Lihat `docs/setup.md` untuk detail konfigurasi lokal (API base URL, env file, emulator setup).

## Pengembangan & Kontribusi

- Ikuti style dan lint yang ada (`analysis_options.yaml`).
- Gunakan `feature branches` dan buka PR ke `main` (default). Sertakan deskripsi perubahan dan langkah reproduksi.
- Jalankan `dart format .` dan `flutter analyze` sebelum membuka PR.

## Dokumentasi & Lokasi Penting

- Fitur & user stories: `docs/` (mis. `docs/liveit-auth-feature.md`)
- Keputusan arsitektural dan catatan agent: `decisions.md`
- Status proyek & checklist: `project-status.md`
- Memory agent & preferensi: `.github/instructions/memory.instruction.md`

---