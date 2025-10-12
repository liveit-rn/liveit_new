# LIVEIT — Project Setup & Operational Guide

Tujuan dokumen ini: menjadi panduan lengkap bagi tim untuk memulai bekerja di proyek LIVEIT (Flutter), termasuk arsitektur, environment & flavors, cara menjalankan dan build untuk dev/prod, serta praktik kerja tim sesuai pedoman repo.

Referensi inti dan lokasi berkas:
- Blueprint: [docs/liveit-blueprint.md](docs/liveit-blueprint.md)
- User Stories: [docs/liveit-userStories.md](docs/liveit-userStories.md)
- Repo Guidelines: [AGENTS.md](AGENTS.md)
- Development Plan: [docs/liveit-development-plan.md](docs/liveit-development-plan.md)
- Entry points:
  - Dev: [lib/main_dev.dart](lib/main_dev.dart:6)
  - Prod: [lib/main_prod.dart](lib/main_prod.dart:6)
  - Default (saat ini mengarah ke dev): [lib/main.dart](lib/main.dart:6)
- App config (env penggunaan): [lib/core/config/app_config.dart](lib/core/config/app_config.dart:4)
- Environment files:
  - Dev: [.env.dev](.env.dev:1)
  - Prod: [.env.prod](.env.prod:1)
- Dependencies & assets: [pubspec.yaml](pubspec.yaml)
- Android Gradle config: [android/app/build.gradle.kts](android/app/build.gradle.kts)
- Android Manifest: [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)
- Status & Decisions logs:
  - [project-status.md](project-status.md)
  - [decisions.md](decisions.md)



## 1) Prasyarat

Tooling wajib:
- Flutter SDK (channel stable) → install dari situs resmi.
- VS Code atau Android Studio dengan plugin Flutter/Dart.
- Android:
  - Android Studio + Android SDK + Platform Tools.
  - Emulator Android (Pixel + API stabil).
- iOS (hanya macOS):
  - Xcode + command line tools.
  - CocoaPods (`sudo gem install cocoapods`).
  - Akun Apple Developer (untuk signing & distribusi).

Verifikasi:
- Jalankan `flutter doctor` dan pastikan tidak ada masalah yang blocking.



## 2) Struktur Proyek & Arsitektur

Struktur utama:
- `lib/` — source code aplikasi.
  - `core/` — konfigurasi global (env, router, network, storage, theme, logging).
  - `features/` — modul feature-based (auth, habit_tracker, devotionals, gamification, profiles, home).
- `test/` — unit & widget tests.
- `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/` — target platform.
- `docs/` — dokumen teknis, guideline, planning.

Arsitektur:
- Feature-based modules dengan 3 lapis: presentation, domain, data.
- State management: BLoC (flutter_bloc + equatable).
- Routing: AutoRoute (router dideklarasi di [lib/core/router/app_router.dart](lib/core/router/app_router.dart)).
- Networking: Dio (base URL dari env via AppConfig).
- Storage: flutter_secure_storage (token), shared_preferences (preferensi ringan).



## 3) Environment & Flavors

Sumber env:
- `.env.dev` dan `.env.prod` di root repo, didaftarkan sebagai assets di [pubspec.yaml](pubspec.yaml).
- App memuat file env sesuai entry point:
  - Dev: [Dart.main()](lib/main_dev.dart:6) memuat `.env.dev`.
  - Prod: [Dart.main()](lib/main_prod.dart:6) memuat `.env.prod`.
- Pemakaian env di runtime:
  - Getter base URL: [Dart.AppConfig.apiBaseUrl](lib/core/config/app_config.dart:4) menggunakan `flutter_dotenv`.

Ketentuan isi env:
- `.env.dev`:
  - `API_BASE_URL=https://liveit-api-dev-5jufu.ondigitalocean.app`
- `.env.prod`:
  - `API_BASE_URL=https://<url-backend-prod>`
  - Harus diisi sebelum build/prod run; jika kosong, fallback akan digunakan sesuai [Dart.AppConfig.apiBaseUrl](lib/core/config/app_config.dart:5).

Catatan:
- Jangan commit secrets lain (token, API keys sensitif). Hanya masukkan base URL dan konfigurasi non-sensitif.
- Untuk varian tambahan, gunakan `.env.staging`, dsb, lalu buat entry point sesuai.

Native flavors (opsional, advanced):
- Android: dapat menambahkan `productFlavors` di [android/app/build.gradle.kts](android/app/build.gradle.kts) jika ingin package name/ikon/label berbeda secara native.
- iOS: buat Scheme terpisah (LIVEIT-Dev, LIVEIT-Prod) di Xcode, lalu mapping konfigurasi.



## 4) Cara Menjalankan (Dev/Prod)

Menjalankan di perangkat/emulator:
- Dev:
  - `flutter run -t lib/main_dev.dart`
- Prod (untuk verifikasi environment prod; bukan rilis store):
  - `flutter run -t lib/main_prod.dart`

Menjalankan di web (opsional):
- Dev:
  - `flutter run -d chrome -t lib/main_dev.dart`
- Prod:
  - `flutter run -d chrome -t lib/main_prod.dart`

Tips:
- Pastikan `.env.dev`/`.env.prod` sudah terdaftar sebagai assets di [pubspec.yaml](pubspec.yaml) (sudah di-setup).
- Jika terjadi error env file tidak ditemukan, lakukan `flutter clean` lalu `flutter pub get`, kemudian coba lagi.



## 5) Build Artifacts (Debug/Release)

Android:
- Debug dev APK:
  - `flutter build apk -t lib/main_dev.dart`
- Release prod App Bundle (untuk Play Store):
  - `flutter build appbundle --release -t lib/main_prod.dart`
- Release prod APK (untuk distribusi manual):
  - `flutter build apk --release -t lib/main_prod.dart`

iOS (macOS saja):
- Release prod:
  - `flutter build ios --release -t lib/main_prod.dart`
- Distribusi:
  - Archive via Xcode → TestFlight → App Store.

Web:
- Prod build:
  - `flutter build web -t lib/main_prod.dart`



## 6) Signing & Distribusi

Android:
- Buat keystore:
  - `keytool -genkey -v -keystore liveit-release-key.jks -alias liveit -keyalg RSA -keysize 2048 -validity 10000`
- Simpan keystore dan kredensial di tempat aman (jangan commit).
- Konfigurasi signing di `android/app` untuk rilis (gradle signing config release).
- Untuk saat ini [Gradle.buildTypes()](android/app/build.gradle.kts:33) masih menggunakan debug signing (agar `flutter run --release` jalan); ubah ke release signing saat siap rilis.

iOS:
- Siapkan Apple Developer account, Certificates, App ID, Provisioning Profiles.
- Konfigurasi signing di Xcode untuk target Runner.
- Pastikan bundle identifiers konsisten antara dev/prod jika menggunakan scheme terpisah.



## 7) Perintah Rutin Pengembangan

Tooling:
- Install dependencies:
  - `flutter pub get`
- Jalankan analyzer:
  - `flutter analyze`
- Format kode:
  - `dart format .` atau `flutter format .`
- Testing:
  - Unit & widget: `flutter test`
- Codegen (AutoRoute/json_serializable/freezed):
  - Watch: `dart run build_runner watch --delete-conflicting-outputs`
  - One-off: `dart run build_runner build --delete-conflicting-outputs`



## 8) Testing & Quality

Strategi testing:
- Unit tests: domain/usecases; repos dengan mock API.
- BLoC tests: verifikasi event→state dengan `bloc_test`.
- Widget tests: komponen UI & state.
- Integration tests (opsional pada fase akhir): end-to-end flow kritikal.

Observability:
- Logging terpusat (core/logging), hindari PII.
- Crash reporting & analytics (opsional pasca-MVP): Firebase Crashlytics & minimal analytics pada funnel utama.



## 9) Error Handling & UX States

- Network errors: pesan ramah + tombol “Coba Lagi”.
- Unauthorized: redirect ke login (jaga state).
- Loading: skeleton untuk list/tiles.
- Empty states:
  - Habit: rekomendasi 3 habit + CTA tambah habit.
  - Devotional: gunakan renungan terbaru jika hari ini kosong.

Idempotensi:
- Disable tombol saat request in-flight, gunakan throttle/debounce seperlunya (contoh cek ketersediaan username di claim-username).



## 10) Kontrak API (Ringkasan)

Klien (Flutter) hanya memanggil NestJS facade (pola proksi), base URL dari env via [Dart.AppConfig.apiBaseUrl](lib/core/config/app_config.dart:4).

Contoh area endpoint (sinkronkan nama final dengan backend kontrak):
- Auth: `/auth/register`, `/auth/login`, `/auth/oauth/:provider`, `/users/claim-username`
- Habits: katalog, aktivasi, daftar harian, check-in, undo
- Devotionals: today/latest, create-habit-from-devotional
- Gamification: summary, badges
- Profiles: self profile, privacy toggle, public profile by username



## 11) Arsitektur BLoC (Guideline)

Scope:
- BLoC per screen/use-case cohesive; hindari monolitik.
- State immutable dan equatable.

Event/state pattern:
- Submit → loading → success/failure.
- Pertimbangkan optimistic update dengan rollback bila gagal (contoh check-in/undo pada daftar harian).

Hydration:
- Pakai `hydrated_bloc` hanya untuk state non-sensitif (cache UI), tidak untuk tokens/sensitive data.



## 12) Workflows Tim (AGENTS)

Ikuti pedoman [AGENTS.md](AGENTS.md):
- Log keputusan mayor (struktur, dependensi, perilaku) ke [decisions.md](decisions.md) — append-only.
- Update progres ke [project-status.md](project-status.md) — Initial Ask, Initial Response, Checklist, Current Status, Next Steps.
- Hindari commit secrets dan env spesifik perangkat.
- Jaga perubahan kecil, testable, dan mudah dibaca.



## 13) Quick Start TL;DR

1) Setup:
- Install toolchain → `flutter doctor` hijau.
- `flutter pub get`.

2) Env:
- Isi [.env.dev](.env.dev:1) dan [.env.prod](.env.prod:1) dengan `API_BASE_URL`.
- Pastikan assets env ada di [pubspec.yaml](pubspec.yaml).

3) Run:
- Dev: `flutter run -t lib/main_dev.dart`.
- Prod (verifikasi prod config): `flutter run -t lib/main_prod.dart`.

4) Build:
- Android Dev APK: `flutter build apk -t lib/main_dev.dart`.
- Android Prod AAB: `flutter build appbundle --release -t lib/main_prod.dart`.
- iOS Prod: `flutter build ios --release -t lib/main_prod.dart` (macOS).

5) Test/Quality:
- `flutter analyze`, `dart format .`, `flutter test`.
- `dart run build_runner watch --delete-conflicting-outputs` untuk codegen.

6) Logs & Status:
- Append ke [decisions.md](decisions.md) dan update [project-status.md](project-status.md) setiap batch pekerjaan.



## 14) Known Gotchas

- Env tidak termuat:
  - Pastikan `.env.dev`/`.env.prod` terdaftar di assets [pubspec.yaml](pubspec.yaml), lalu `flutter clean` + `flutter pub get`.
- Prod env kosong:
  - Isi [.env.prod](.env.prod:1) sebelum run/build prod, jika tidak akan jatuh ke fallback [Dart.AppConfig.apiBaseUrl](lib/core/config/app_config.dart:5).
- iOS build di Windows:
  - Tidak didukung; butuh macOS + Xcode.
- AutoRoute codegen:
  - Pastikan generator & build_runner berjalan; jika ada konflik, gunakan flag `--delete-conflicting-outputs`.



## 15) Pertanyaan & Eskalasi

- Arsitektur & standar: rujuk [docs/liveit-development-plan.md](docs/liveit-development-plan.md) dan [AGENTS.md](AGENTS.md).
- Backend kontrak/API: koordinasi dengan tim backend; base URL bersumber dari env.
- Rilis store: siapkan signing, listing, compliance sesuai bagian Build & Distribusi di dokumen ini dan Development Plan.



— Selesai —