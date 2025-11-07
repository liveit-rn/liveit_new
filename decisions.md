# decisions.md

This file is append-only. Each entry must include:

- Date (YYYY-MM-DD)
- Context (what area of the project the decision affects)
- Choice (the decision made)
- Rationale (why the decision was made)
- Impact (what changed / who must know)

---

2025-10-11 | Initialising repository decision log | Create `decisions.md` with template | Needed by agent workflow to record decisions and ensure traceability | No functional changes; file added
2025-10-11 | Homepage product requirements | Added Homepage Experience epic with stories 14-18 to `docs/liveit-userStories.md` | Aligns documentation with blueprint guidance so design/dev teams share same expectations | Product and engineering teams should review new homepage stories when planning UI and data integrations
2025-10-12 | Frontend environment configuration | Created root `.env` holding API base URL `https://liveit-api-dev-5jufu.ondigitalocean.app` | Needed so Flutter client can load backend base URL consistently via dotenv | Frontend devs should load `API_BASE_URL` from env when wiring network layer
2025-10-12 | Flutter routing setup | Adjusted `AppRouter` to extend `RootStackRouter` per auto_route v10 docs and restored `routerConfig` usage in `MaterialApp.router` | Fixes analyzer errors about missing `config()`/`delegate()` by aligning implementation with official installation guide | Ensures navigation builds with latest auto_route API and keeps generated routes functional
2025-10-13 | Homepage experience scaffolding | Implemented composable widgets for homepage (daily summary, habit groups, devotional highlight, gamification, empty/error banners) using brand palette and mocked sample state | Needed tangible prototype aligning with user stories 14-18 and brand essence to guide further integration work | FE team now has baseline UI to wire with real bloc/state/data and evaluate interactions per acceptance criteria
2025-10-22 | AI agent onboarding guidance | Authored `.github/copilot-instructions.md` summarising architecture, workflows, and conventions for automated assistants | Needed single-source instructions so AI agents mirror repo norms without re-reading entire codebase each session | Future agents can ramp quickly; keep file updated when workflows or patterns change
2025-10-12 | Authentication Feature Implementation | Implemented complete authentication feature with BLoC state management, clean architecture, email/password auth, username claiming, OAuth placeholders, dependency injection with get_it, secure storage | User requested full auth implementation based on documentation with BLoC pattern and existing theme | All authentication flows ready for backend integration, OAuth buttons ready for when backend supports it
2025-10-12 | Authentication Debug Logging | Added comprehensive logging throughout auth flow using Logger package - BLoC events/states, repository calls, API requests/responses, UI state changes, error handling | User reported registration not working despite data being added to database - needed detailed logging to debug null type error | Extensive logging added at all layers to identify where the issue occurs in the auth flow
2025-10-12 | Authentication needsUsername Bug Fix | Fixed type 'Null' is not a subtype of type 'bool' error in UserModel.fromJson by adding null handling for needsUsername field, defaulting to true when backend returns null | Backend was returning null for needsUsername field but model expected non-nullable bool, causing registration UI to crash after successful API call | UserModel now safely handles null needsUsername from backend, registration flow should work end-to-end without casting errors
2025-10-12 | Home Page Logout Feature | Added logout functionality to HomePage with confirmation dialog and automatic navigation back to login page | User requested logout button on home page for better UX and security | Added logout button in app bar menu and center screen with confirmation dialog, integrated with AuthBloc logout event, navigation handled via BlocListener
2025-10-12 | Logout Navigation Stack Clear | Modified logout navigation to use pushNamedAndRemoveUntil instead of pushPath to completely clear navigation stack | User requested logout should go to login page without ability to navigate back to authenticated screens | Changed from context.router.pushPath('/') to Navigator.pushNamedAndRemoveUntil('/', (route) => false) to clear entire navigation stack on logout
2025-10-19 | README Update | Expanded `README.md` with project overview, quickstart, architecture, and contribution guidelines in Indonesian | User requested README update to help onboarding and development setup; added commands, structure, and pointers to `docs/` and agent files | Improves onboarding for new contributors and documents local development steps

## 2025-10-11 — Setup routing dengan auto_route (config-based)

Context:

- Diminta men-setup route project menggunakan auto_route dan menambahkan halaman Home.
- Dependency auto_route sudah ada di pubspec.yaml; generator & build_runner telah ditambahkan.

Choice:

- Menggunakan pendekatan config-based AutoRouterConfig (sesuai dokumentasi auto_route v10).
- Menambahkan anotasi @RoutePage pada HomePage.
- Mengubah entry point aplikasi ke MaterialApp.router dengan AppRouter.
- Menambahkan part file untuk hasil generate di router.

Files:

- lib/core/router/app_router.dart
- lib/features/home/presentation/pages/home_page.dart
- lib/main.dart

Rationale:

- Config-based adalah pendekatan resmi dan lebih terstruktur untuk skala fitur.
- Memudahkan penambahan route ke depan dan konsisten dengan linter modern.

Impact:

- Analyzer akan menampilkan error sementara karena file hasil generate belum ada.
- Perlu menjalankan code generation: `dart run build_runner build` (atau `flutter pub run build_runner build`).
- Setelah generate, method seperti `config()` dan symbol `_$AppRouter` serta `HomeRoute` akan tersedia dan error hilang.

## 2025-10-12 — Theme setup using FlexColorScheme

Context:

- Implement color scheme/theme data aligned to brand palette "Grounded Growth" per docs [docs/liveit-brand-essence.md](docs/liveit-brand-essence.md) and [docs/liveit-blueprint.md](docs/liveit-blueprint.md).

Choice:

- Added centralized theme configuration [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart) with FlexColorScheme light/dark based on brand colors.
- Wired theme into all app entry points: [Dart.main()](lib/main.dart:5), [Dart.main()](lib/main_dev.dart:5), [Dart.main()](lib/main_prod.dart:5) using [Dart.AppTheme.light()](lib/core/theme/app_theme.dart:29) and [Dart.AppTheme.dark()](lib/core/theme/app_theme.dart:68).

Rationale:

- Align UI to documented brand personality and palette.
- Use minimal, centralized implementation for maintainability and consistency.
- Avoid over-scoping: Typography and component-specific styles can be added later after verification.

Impact:

- App now uses brand-consistent color scheme in both light and dark modes via ThemeMode.system.
- No changes to data schema or backend.
- Provides semantic colors via ThemeExtension for success/warning/info to support UX messaging patterns.

---

## 2025-10-29 — Bottom Navigation Bar Implementation

Context:
- User requested bottom navigation bar similar to reference image with 5 tabs: Routine, Inspire, Challenge, Library, Profile.
- Need to implement navigation using existing Bloc pattern and AutoRoute setup.

Choice:
- Created 5 feature pages: RoutinePage (moved from HomePage content), InspirePage, ChallengePage, LibraryPage, ProfilePage.
- Created NavigationBloc to manage bottom navigation state with NavigationTabChanged event.
- Created NavigationShellPage as wrapper page using AutoTabsRouter for nested navigation.
- Updated AppRouter to use NavigationShellPage as root with nested child routes.
- Simplified HomePage to basic placeholder (kept for potential future use).

Files Created:
- lib/features/home/presentation/pages/routine_page.dart (moved content from old HomePage)
- lib/features/inspire/presentation/pages/inspire_page.dart
- lib/features/challenge/presentation/pages/challenge_page.dart
- lib/features/library/presentation/pages/library_page.dart
- lib/features/profile/presentation/pages/profile_page.dart
- lib/core/navigation/presentation/bloc/navigation_bloc.dart
- lib/core/navigation/presentation/bloc/navigation_event.dart
- lib/core/navigation/presentation/bloc/navigation_state.dart
- lib/core/navigation/presentation/pages/navigation_shell_page.dart

Files Modified:
- lib/core/router/app_router.dart (added nested navigation structure)
- lib/features/home/presentation/pages/home_page.dart (simplified)

Rationale:
- Follows established architecture patterns (feature-first, Bloc state management, AutoRoute).
- Separates navigation concerns from content pages for better maintainability.
- Allows independent development of each tab while maintaining consistent navigation UX.
- Uses AutoTabsRouter for proper nested routing with deep-linking support.

Impact:
- Bottom navigation now visible on all main app screens.
- Each tab has its own route and can maintain independent state.
- Navigation state managed through Bloc for consistency and testability.
- Routine tab contains all previous HomePage functionality (habits, devotionals, gamification).
- Other tabs are placeholders ready for future feature implementation.
- Developers working on new features can now add content to respective tab pages.


2025-10-30 | Homepage mobile layout refresh | Reworked `HomePage` into a stacked scroll layout with gradient header, grouped habit card, and refreshed quick actions to match latest mobile mock | Aligns Routine tab with visual reference while keeping logic lightweight until Bloc integration lands | UI matches design expectations for demo builds; further integration work should re-hook HomeBloc and ensure design tokens stay consistent when data wiring arrives

---

## 2025-11-07 — Fix LocaleDataException for Indonesian DateFormat

Context:
- User encountered `LocaleDataException: Locale data has not been initialized, call initializeDateFormatting(<locale>)` when running the app.
- `HomePage` uses `DateFormat('EEEE, d MMM', 'id_ID')` to format dates in Indonesian locale.
- The error occurred because `intl` package locale data was not initialized before being used.

Choice:
- Added `import 'package:intl/date_symbol_data_local.dart'` to all main entry points: `main.dart`, `main_dev.dart`, `main_prod.dart`.
- Added `await initializeDateFormatting('id_ID', null);` call in the `main()` function before `runApp()` in all three entry points.
- Ensures Indonesian locale data is loaded before any `DateFormat` calls.

Files Modified:
- lib/main.dart
- lib/main_dev.dart
- lib/main_prod.dart

Rationale:
- The `intl` package requires explicit initialization of locale data before formatting dates with specific locales.
- Initializing in `main()` ensures the locale data is ready before any widgets that use `DateFormat` are built.
- Using Indonesian locale ('id_ID') aligns with the app's target audience and brand localization.

Impact:
- App will no longer crash with `LocaleDataException` when displaying formatted dates.
- All date formatting throughout the app (especially in `HomePage`) will work correctly with Indonesian locale.
- Future features using `DateFormat` with 'id_ID' will work without additional initialization.
- Developers adding new date formatting should be aware locale is already initialized for Indonesian.


```

