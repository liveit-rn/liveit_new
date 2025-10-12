# LIVEIT Mobile — Development Plan (Flutter + Feature-based + BLoC)

Dokumen ini adalah rencana pengembangan end-to-end aplikasi LIVEIT berbasis Flutter dengan arsitektur feature-based dan BLoC, dari setup awal hingga rilis ke store. Rencana ini memetakan kebutuhan dari blueprint dan user stories ke langkah implementasi yang terstruktur, minimal-viable-first, dapat diuji, dan mudah dipelihara.

Referensi utama:
- Blueprint: [docs/liveit-blueprint.md](docs/liveit-blueprint.md)
- User Stories: [docs/liveit-userStories.md](docs/liveit-userStories.md)
- Repo Guidelines: [AGENTS.md](AGENTS.md)
- API Base URL (NestJS): [.env](.env)
- Source saat ini (sinkronisasi naming dan struktur):
  - [lib/main.dart](lib/main.dart)
  - [lib/core/router/app_router.dart](lib/core/router/app_router.dart)
  - [pubspec.yaml](pubspec.yaml)
  - [analysis_options.yaml](analysis_options.yaml)

Catatan prinsip:
- Minimal implementation first, lalu refactor.
- Feature-based modules (presentation, domain, data).
- State management konsisten: BLoC.
- Spec-driven (berangkat dari [docs/liveit-userStories.md](docs/liveit-userStories.md)).
- Log keputusan ke [decisions.md](decisions.md) dan status ke [project-status.md](project-status.md) sesuai [AGENTS.md](AGENTS.md). (Append-only; dilakukan ketika implementasi dijalankan.)
- Jangan ubah schema data/backend tanpa persetujuan (backend sudah siap; gunakan kontrak API dari NestJS).



## 0) Prasyarat & Setup Lingkungan

Langkah ini memastikan toolchain Flutter siap untuk build Android/iOS/Web.

- Install/upgrade Flutter SDK stable terbaru (melalui official installer).
- Jalankan tooling kesehatan:
  - Perintah: flutter doctor
- Setup IDE:
  - VS Code/Android Studio + Flutter/Dart plugin.
- Android:
  - Install Android Studio, Android SDK, Android SDK Platform-Tools, satu emulator Android (Pixel Series + API terbaru stabil).
  - Set JAVA_HOME bila diperlukan.
- iOS (macOS):
  - Xcode + command line tools, CocoaPods (gem install cocoapods), akun Apple Developer untuk signing.
- Perbarui dependencies proyek:
  - Perintah: flutter pub get
- Verifikasi run dev:
  - Perintah: flutter run (device/emulator aktif)
  - Alternatif web: flutter run -d chrome



## 1) Arsitektur & Struktur Proyek

Gunakan arsitektur feature-based modular, setiap feature memiliki 3 lapis: presentation, domain, data.

Struktur direktori disarankan (tambahkan saat implementasi):
- [lib/](lib/)
  - [lib/core/](lib/core/) — konfigurasi global dan util umum:
    - config/ (app config, env loader, constants)
    - router/ (navigasi — auto_route)
    - network/ (dio client, interceptors, serializers, error mapper)
    - storage/ (secure storage, shared preferences, token store)
    - theme/ (design system: colors, typography, spacing)
    - widgets/ (reusable shared widgets)
    - utils/ (formatting, date utils, validators)
    - logging/ (logger, error reporting hook)
  - [lib/features/](lib/features/)
    - auth/ (register, login, federated, claim-username)
      - data/ (models, dtos, auth_api, auth_repository_impl)
      - domain/ (entities, repositories, usecases)
      - presentation/ (pages, blocs, widgets)
    - habit_tracker/ (katalog habit, aktivasi user-habit, check-in, undo, list harian)
      - data/ …, domain/ …, presentation/ …
    - devotionals/ (fetch renungan harian, buat habit dari renungan)
      - data/ …, domain/ …, presentation/ …
    - gamification/ (Zoe points, levels, badges)
      - data/ …, domain/ …, presentation/ …
    - profiles/ (profil diri, privasi, profil publik)
      - data/ …, domain/ …, presentation/ …
    - home/ (homepage aggregator: ringkasan harian, daftar habit, renungan, highlight gamifikasi)
      - data/ … (opsional, seringnya read-only aggregator)
      - domain/ …
      - presentation/ …
- [test/](test/) — unit & widget test per feature dengan mirror struktur.
- Dokumen arsitektur ringkas (opsional tapi dianjurkan): docs/architecture.md (berdasarkan dokumen ini).

Kaidah lint & style:
- Ikuti lints di [analysis_options.yaml](analysis_options.yaml).
- Snake_case untuk nama file; UpperCamelCase untuk class; lowerCamelCase untuk method/variabel.
- Komponen UI kecil, composable, gunakan const di mana memungkinkan.
- Hapus dead code saat refactor.



## 2) Dependencies & Tooling

Tambahkan paket yang menunjang arsitektur dan produktivitas (dideklarasikan di [pubspec.yaml](pubspec.yaml)):

- State management:
  - flutter_bloc, bloc
  - equatable (state equality)
  - hydrated_bloc (opsional untuk caching state non-sensitif)
- Networking & serialization:
  - dio
  - pretty_dio_logger (dev only)
  - json_annotation, build_runner, json_serializable (atau pilih freezed)
  - freezed_annotation, freezed (opsional untuk immutable models)
- Routing:
  - auto_route, auto_route_generator, build_runner
- Storage & env:
  - flutter_secure_storage (token)
  - shared_preferences (preferensi ringan)
  - flutter_dotenv (load [.env](.env) ke runtime)
- Utils:
  - intl (format tanggal/angka)
  - logger (atau package lain untuk logging)
- Testing:
  - flutter_test (built-in)
  - mocktail (mocking)
  - bloc_test (test bloc)
  - integration_test (opsional untuk e2e)

Konfigurasi generator:
- Daftarkan auto_route_generator, json_serializable, freezed dalam dev_dependencies dan jalankan build:
  - Perintah: dart run build_runner watch --delete-conflicting-outputs



## 3) Konfigurasi Lingkungan & Konstanta

Sumber kebenaran API base URL:
- File env: [.env](.env) dengan kunci API_BASE_URL.

Integrasi ke app:
- Tambahkan flutter_dotenv dan muat env saat boot.
- Buat AppConfig (layer core/config) untuk menyatukan env keys di satu tempat.
- Jangan commit secrets/keys; gunakan varian env (dev/staging/prod) jika diperlukan:
  - Misal: .env.dev, .env.staging, .env.prod (didaftarkan sebagai asset di [pubspec.yaml](pubspec.yaml)).

Environment switching:
- Gunakan flavoring (opsional) atau manual switch melalui file main terpisah (main_dev.dart, main_prod.dart) yang memuat env yang sesuai.



## 4) Fondasi Aplikasi (Core)

4.1 Router (navigasi)
- Gunakan auto_route untuk deklaratif routes, strong-typed args, guard.
- Definisikan peta route di [lib/core/router/app_router.dart](lib/core/router/app_router.dart).
- Rute utama minimal:
  - splash (cek sesi)
  - auth (login/register, federated)
  - claim-username
  - home (homepage aggregator)
  - habit (katalog kurasi, aktifkan habit, daftar harian, detail/opsional)
  - devotionals (list/detail hari ini)
  - profile (self profile) dan public profile (by username)

4.2 Networking & Error handling
- Siapkan Dio singleton (core/network), baseUrl dari AppConfig.
- Tambahkan interceptors:
  - Authorization header (JWT dari secure storage).
  - Logging (pretty_dio_logger) hanya dev.
  - Retry sederhana (opsional) untuk timeout/5xx.
- Normalisasi error ke AppFailure (domain) melalui mapper. Tujuan: UI terima error yang bermakna dan dapat ditindak.
- Terapkan idempotensi di sisi klien (throttle/tap-safety) pada aksi check-in/undo.

4.3 Keamanan & Storage
- Simpan access token/refresh token di flutter_secure_storage.
- Terapkan refresh flow (jika kontrak backend menyediakan).
- Hindari menyimpan data sensitif di shared_preferences.

4.4 Theming & Design System
- Tentukan theme global (core/theme) untuk warna, tipografi, spacing.
- Gunakan komponen shared (core/widgets) untuk konsistensi.

4.5 Logging
- Gunakan logger terpusat (core/logging) dengan level yang berbeda untuk dev/prod.
- Log meaningful events (auth transitions, network failures, boundary cases).



## 5) Pemetaan User Stories → Fitur & Inkremental Delivery

Urutan implementasi MVP berdasarkan dampak dan dependency:

Step 1 — Foundation
- Core/config, env loader, router wiring, dio client + interceptors, error mapper, theme dasar, logger.

Step 2 — Auth
- Register (email, nama, password), Login (email+password).
- Redirect ke claim-username setelah register/login jika username kosong.
- Validasi email, error messaging standar.
- Federated login (tahap setelah email-password stabil; Google → Facebook → Apple).
- State persistence (sesi) dan guard route.

Step 3 — Habit Tracker (Core Loop)
- Katalog kurasi (read-only).
- Menambahkan habit ke user (aktivasi).
- Homepage: daftar habit harian (belum selesai vs selesai hari ini).
- Check-in, undo (idempotent), reset harian (UTC sementara).
- Empty state + CTA tambah habit.

Step 4 — Devotionals
- Tampilkan renungan hari ini (fallback renungan terbaru).
- Tombol buat habit dari renungan (one-click template).

Step 5 — Gamification
- Hitung & tampilkan total Zoe Points, level saat ini, progress ke level berikutnya.
- Event bonus: all-done today.
- Badge dasar: First Step, First Week Warrior, Comeback Kid.

Step 6 — Profiles
- Halaman profil self: nama, total ZP, level, badges gallery.
- Pengaturan privasi profil: public/private.
- Public profile route: akses data publik pengguna lain.

Step 7 — Notifikasi
- MVP: local notifications untuk pengingat habit harian.
- Lanjutan: push notifications (FCM) pasca-MVP (butuh setup Firebase).

Step 8 — Hardening & Polish
- Perf pass, skeleton states, error states ramah, offline read-only caching sederhana.
- A11y & i18n (opsional untuk MVP).



## 6) Detail Implementasi per Fitur

6.1 Auth
- Endpoints (via NestJS facade):
  - /auth/register, /auth/login, /auth/oauth/:provider
  - Claim username endpoint (sesuai backend): validasi ketersediaan username, update profil.
- BLoC scope:
  - Form validation states, submit progress, success/error transitions.
  - Session BLoC (atau simple session manager) untuk broadcasting status login.
- UI:
  - Register/Login form terpisah atau tab.
  - Claim-username screen:
    - Input username, cek availability on-change atau on-blur (debounce).
    - Tombol Next disabled hingga valid & available.
- Security:
  - Simpan token ke secure storage setelah login/register/federated.
  - Pasang auth guard di router.

6.2 Habit Tracker
- Data:
  - Katalog habit terkurasi (GET).
  - Aktivasi habit untuk user (POST).
  - Daftar habit harian (GET), field checkedInToday untuk state per hari.
  - Check-in (POST) dan Undo hari ini (POST/DELETE sesuai kontrak).
- BLoC:
  - ListState: dua grup (Belum Selesai, Selesai Hari Ini) dengan collapsible UI.
  - Actions throttle untuk cegah double-tap race.
- UI:
  - Homepage menampilkan ringkasan progres (selesai vs total) + progress bar/circle.
  - Jika all done today → tampilkan pesan penyemangat + highlight bonus.
  - Empty state saat belum ada habit aktif (rekomendasi 3 habit).
- Integritas:
  - Satu UserHabit aktif per (user, habit) — dikontrol oleh backend; klien tetap idempotent.

6.3 Devotionals
- Data:
  - GET devotional hari ini (atau latest published).
- Aksi:
  - Buat habit dari renungan (POST). Reach awal limited sesuai kebijakan backend.
- UI:
  - Kartu di homepage: judul, snippet, estimasi baca (jika tersedia).
  - Tombol Baca Renungan, tombol Buat Habit dari Renungan.

6.4 Gamification
- Poin:
  - +10 per check-in, +20 all-done, +50/7 day streak, +100/30 day streak.
- Level:
  - Ambang batas sesuai blueprint.
- Badge:
  - First Step, First Week Warrior, Faithful Follower, Consistency Champion, Category Explorer, Daily Completer, Comeback Kid.
- UI:
  - Ringkasan ZP, current level, progress to next level.
  - Toast/kartu refleksi saat level up atau badge baru.

6.5 Profiles
- Self Profile:
  - Nama, total ZP, current level, badges gallery.
  - Privacy toggle: Public/Private (update real-time).
- Public Profile:
  - Route by username: /profiles/u/:username
  - Jika private → tampilkan pesan privat/404.
- SEO web (opsional jika target Web): metadata minimal.

6.6 Homepage Experience
- Aggregator:
  - Ringkasan hari ini (sapaan + progres), daftar habit harian, renungan hari ini, highlight gamifikasi.
- State refresh:
  - Refresh saat halaman dibuka, juga saat check-in/undo sukses.
- Error/offline:
  - Pesan error ramah, tombol Coba Lagi.
  - Offline indicator; gunakan data lokal terakhir bila ada.



## 7) Testing Strategy

- Unit Tests (test/…):
  - Usecases/domain logic, repos (mock API), mappers, error handling.
- BLoC Tests:
  - bloc_test untuk event→state transitions, termasuk error & retry.
- Widget Tests:
  - UI states, empty/error/skeleton, interaction micro-flows (check-in/undo).
- Integration Tests (opsional di MVP akhir):
  - End-to-end skenario kritikal (login → homepage → check-in → points badge).
- Coverage:
  - Target awal 60–70% pada core critical paths.
- Mocking:
  - mocktail untuk API layer & repos.
- Static Analysis:
  - Perintah: flutter analyze
- Formatting:
  - Perintah: dart format . atau flutter format .



## 8) Observability & Quality

- Logging:
  - Level-based logging untuk event penting (tanpa PII).
- Crash/Analytics (opsional pasca-MVP):
  - Firebase Crashlytics untuk crash reporting.
  - Analytics minimal untuk funnel inti (onboarding, check-in, all-done).
- Meaningful error messages:
  - Teks ramah, suportif; hindari menyalahkan user.



## 9) Build & Release

9.1 Android
- Keystore:
  - Buat keystore release, simpan aman di local/CI secret.
  - Tambahkan konfigurasi signing di android/app (jangan commit keystore).
- Build command:
  - Debug: flutter run
  - Release APK: flutter build apk --release
  - Release AAB: flutter build appbundle --release
- Upload ke Play Console:
  - App listing, privacy policy, content rating, testing (internal/closed), rollout bertahap.

9.2 iOS (macOS)
- Signing:
  - Akun Apple Developer, App ID, Provisioning Profiles, Certificates.
- CocoaPods:
  - Perintah: cd ios && pod install (biasanya otomatis saat build).
- Build command:
  - flutter build ios --release
- Distribution:
  - Archive via Xcode → TestFlight.
  - App Store listing, privacy nutrition labels.

9.3 Web (opsional)
- Build:
  - flutter build web
- Hosting:
  - Static hosting (Netlify/Vercel/GitHub Pages) untuk landing/demo (sesuai kebutuhan).



## 10) CI/CD (Opsional tapi direkomendasikan)

- GitHub Actions minimal:
  - Workflow: lint + test + build (PR gating).
  - Secrets untuk signing Android (jika melakukan build release di CI).
- Alternatif:
  - Codemagic/Bitrise untuk mobile-focused pipelines.
- Cache build_runner untuk percepat CI.



## 11) Perencanaan Sprint & Checklist Eksekusi

Milestone 0 — Setup & Foundation (1–3 hari)
- [ ] Setup toolchain (Flutter doctor hijau).
- [ ] Tambah dependencies inti di [pubspec.yaml](pubspec.yaml).
- [ ] Core/config (AppConfig + env loader dari [.env](.env)).
- [ ] Dio client + interceptors + error mapper.
- [ ] Router dasar di [lib/core/router/app_router.dart](lib/core/router/app_router.dart).
- [ ] Theme dasar + logger.

Milestone 1 — Auth Essentials (2–4 hari)
- [ ] Register + Login (email/password).
- [ ] Simpan token (secure storage) + auth guard.
- [ ] Claim-username flow (cek ketersediaan, next enabled jika available).
- [ ] Error states dan validasi form.
- [ ] Unit/bloc/widget tests untuk flow utama.
- [ ] Federated Google (opsional di akhir M1 atau awal M2).

Milestone 2 — Habit Tracker v1 (3–5 hari)
- [ ] Katalog habit kurasi (GET) + UI pilih.
- [ ] Aktivasi habit untuk user (POST).
- [ ] Homepage: daftar harian (belum selesai vs selesai).
- [ ] Check-in, undo (idempotent), reset harian (UTC).
- [ ] Empty state dan CTA tambah habit.
- [ ] Tests pada list states dan aksi check-in/undo.

Milestone 3 — Devotionals v1 (1–2 hari)
- [ ] Renungan hari ini (atau latest published).
- [ ] Buat habit dari renungan.
- [ ] Skeleton/loading + error states.

Milestone 4 — Gamification v1 (2–4 hari)
- [ ] ZP total + current level + progress to next.
- [ ] Bonus all-done today.
- [ ] Badge First Step + First Week Warrior + Comeback Kid (prioritas).
- [ ] UI highlight + refleksi toast.
- [ ] Unit test logic perhitungan (mock backend jika perlu).

Milestone 5 — Profiles v1 (2–3 hari)
- [ ] Self profile: nama, ZP, level, badges gallery.
- [ ] Privacy toggle public/private (persist).
- [ ] Public profile by username (private → pesan/404).

Milestone 6 — Notifikasi (1–2 hari)
- [ ] Local notifications untuk reminder habit.
- [ ] Scheduling sederhana (jam preferensi user).
- [ ] Push (FCM) pasca-MVP (butuh setup Firebase).

Milestone 7 — Hardening & Release Prep (2–4 hari)
- [ ] Perf pass, audit UI states (skeleton/empty/error).
- [ ] Offline read-only cache sederhana.
- [ ] QA pass dan regression.
- [ ] Build release Android (AAB) dan iOS (TestFlight).
- [ ] Store listings dan compliance.

Catatan pelaksanaan:
- Setiap selesai batch, append keputusan ke [decisions.md](decisions.md) dan perbarui [project-status.md](project-status.md) (Checklist + Current Status + Next Steps) sesuai [AGENTS.md](AGENTS.md).



## 12) Guideline Implementasi BLoC

BLoC Scope
- BLoC per screen atau per domain use-case yang cohesive.
- Hindari god/bloc besar; jaga event/state fokus pada satu tanggung jawab.
- State ringan dengan equatable untuk efisiensi rebuild.

Event Flow Tipikal
- Submit (login/register/check-in/undo) → emit loading → panggil usecase → emit success/failure.
- Optimistic update untuk UX responsif (dengan rollback jika gagal), terutama di daftar habit harian.

Komposisi BLoC
- Gunakan MultiBlocProvider di root feature tree untuk wiring beberapa BLoC pada halaman aggregator (contoh: homepage).

Hydration
- Pertimbangkan hydrated_bloc untuk state non-sensitif yang menguntungkan offline UX (misalnya cache list terakhir).
- Jangan hydrate token/sensitive data.



## 13) Kontrak API & Integrasi Backend

Pola proksi otentikasi (lihat blueprint) — klien hanya panggil endpoint NestJS.
- Keuntungan: fleksibilitas, abstraksi, kontrol terpusat.
- Implikasi klien:
  - Hanya perlu tahu satu baseUrl dari [.env](.env).
  - Penanganan respon dan error message konsisten dari backend.
  - Rate limit/retry minimal di klien.

Endpoint contoh (arahan, sinkronkan nama final dengan kontrak backend nyata):
- Auth:
  - POST /auth/register
  - POST /auth/login
  - POST /auth/oauth/google|facebook|apple
  - POST /users/claim-username
- Habits:
  - GET /habits (kurasi)
  - POST /user-habits (aktivasi)
  - GET /user-habits/today
  - POST /user-habits/:id/check-in
  - POST /user-habits/:id/undo
- Devotionals:
  - GET /devotionals/today
  - POST /devotionals/:id/create-habit
- Gamification:
  - GET /gamification/summary
  - GET /gamification/badges
- Profiles:
  - GET /profiles/me
  - PATCH /profiles/me/privacy
  - GET /profiles/u/:username

Idempotensi & Konsistensi
- Gunakan tombol disabled saat request berlangsung.
- Debounce untuk pengecekan username.
- Cegah double-submit dengan in-flight guard di BLoC.



## 14) UX States & Empty/Error Handling

- Loading: gunakan skeleton pada list/tiles.
- Empty:
  - Habit: “Mulai Kebiasaan” + 3 rekomendasi kurasi + CTA ke katalog.
  - Devotional: tampilkan “Renungan terbaru” jika hari ini kosong.
- Error:
  - Koneksi: pesan ramah + tombol “Coba Lagi”.
  - Unauthorized: redirect ke login, jaga state agar tidak hilang (opsional).
- Success:
  - Toast non-intrusif untuk check-in, all-done, badge baru, level-up.



## 15) Non-fungsional & Risiko

- Zona Waktu:
  - Sementara UTC untuk boundary hari, update di tahap berikutnya untuk timezone-aware boundary.
- Aksesibilitas:
  - Contrast, tap target, screen reader labels.
- Privacy:
  - Minimal data, toggles publik/privat, hindari PII di logs.
- Kinerja:
  - Pagination/limit pada list jika data membesar (post-MVP).
- Keandalan:
  - Graceful degradation saat backend down (offline cache read-only).
- Moderasi:
  - Guardrails input dilakukan di backend; klien menampilkan feedback hasil validasi.



## 16) Perintah Rutin (Ringkasan)

Build & Run
- Install deps: flutter pub get
- Run dev (device/emulator): flutter run
- Run web: flutter run -d chrome
- Analyze: flutter analyze
- Format: dart format . (atau flutter format .)
- Test: flutter test
- Codegen watch: dart run build_runner watch --delete-conflicting-outputs

Build Release
- Android APK: flutter build apk --release
- Android AAB: flutter build appbundle --release
- iOS: flutter build ios --release
- Web: flutter build web



## 17) Deployment Checklist (Play Store / App Store)

Pra-rilis teknis
- [ ] App versioning (pubspec.yaml version).
- [ ] App icons & splash siap untuk iOS/Android.
- [ ] Signing: Android keystore; iOS certificates & provisioning.
- [ ] Obfuscation/minify (opsional): proguard/r8, bitcode deprecated; review size.
- [ ] Review izin (permissions) minimal.

Listing & compliance
- [ ] Deskripsi, screenshot, video (opsional), ikon, feature graphic.
- [ ] Privacy policy dan data safety form.
- [ ] Content rating (Play Console).
- [ ] Kategori & keyword.

Distribusi
- [ ] Android: upload AAB → internal/closed testing → production.
- [ ] iOS: Archive → TestFlight → App Review → App Store release.
- [ ] Monitor crash dan feedback pasca rilis.



## 18) Post-MVP Roadmap (Dari Blueprint)

- Grup akuntabilitas kecil (chat template, encouragement).
- Prayer request board (tanpa komentar; “Saya doakan”).
- Weekly community challenge.
- Konten library & challenge tematik.
- Donasi/support, event online, partnership gereja.
- Timezone-aware day boundary.
- Peningkatan offline mode dan sinkronisasi.



## 19) Pengelolaan Status & Keputusan (Agent Workflow)

Mengikuti [AGENTS.md](AGENTS.md):
- Setiap perubahan signifikan (struktur, dependensi, perilaku) → append entri baru ke [decisions.md](decisions.md) (Date, Context, Choice, Rationale, Impact).
- Setiap batch pekerjaan → perbarui [project-status.md](project-status.md):
  - Initial Ask, Initial Response, Checklist, Current Status, Next Steps.
- Idempotent dan append-only: jangan hapus histori.



## 20) Ringkasan Eksekusi Harian (Saran)

Ritme harian pengembangan:
- Pagi:
  - Review backlog yang aktif, pecah jadi unit kecil, update [project-status.md](project-status.md).
  - Jalankan flutter analyze, perbaiki lint baseline jika ada.
- Siang:
  - Implementasi 1–2 unit kerja kecil (satu fitur mikro), tulis test minimal.
  - Verifikasi manual di emulator/device.
- Sore:
  - Refactor bila perlu, hapus dead code.
  - Log keputusan mayor ke [decisions.md](decisions.md).
  - Push perubahan (sesuai kebijakan repo; jangan commit secrets).



## 21) Lampiran — Pemetaan User Stories Inti ke Deliverables

Onboarding & Manajemen Akun
- Register, Login, Claim-Username, Federated logins (Google → Facebook → Apple)
- Redirects & guards
- Validasi dan error messaging

Habit Tracker (Core Loop)
- Katalog kurasi → Aktivasi → Daftar harian
- Check-in, Undo, Reset harian (UTC)
- Ringkasan progres + all-done bonus

Gamifikasi
- ZP total, level progression
- Badges utama
- Highlight & refleksi

Devotionals
- Renungan hari ini/latest
- Buat habit dari renungan

Profile
- Self profile (ZP, level, badges)
- Privacy toggle
- Public profile (/profiles/u/:username)

Homepage Experience
- Aggregator modul: ringkasan hari ini, daftar habit, renungan, highlight gamifikasi
- Empty/error/offline states

Notifikasi
- Local notifications MVP
- Push FCM post-MVP



— Selesai —