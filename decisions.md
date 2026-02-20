# decisions.md

This file is append-only. Each entry must include:

- Date (YYYY-MM-DD)
- Context (what area of the project the decision affects)
- Choice (the decision made)
- Rationale (why the decision was made)
- Impact (what changed / who must know)

---

## 2026-02-11 — Document current “offline-first” behavior (Habit Tracker)

**Context:**

- User requested deep analysis of “offline-first then update server” mechanism in the Flutter app.
- Need a readable doc that matches actual implementation (no guesses).

**Choice:**

- Document the current implementation as **hybrid cache + optimistic UI**, specifically:
  - Reads: cache-first + stale-while-revalidate with fallback to Hive cache.
  - Writes: API-first with optimistic UI in BLoC and rollback on failure.
- Explicitly call out that the repo **does not implement an offline write queue/outbox** yet.

**Rationale:**

- Keeps documentation honest and directly traceable to code paths in `HabitRepositoryImpl` + `HabitBloc`.
- Avoids inventing “sync queue” behavior that could mislead future development.

**Impact:**

- Added doc: `docs/skills/offline-first-data-flow.md`
- No runtime behavior changes.

## 2026-02-08 — Navigation Shell Premium Frosted Glass Refactor

**Context:**

- Navigation shell perlu premium look dengan frosted glass effect yang lebih sophisticated
- Current design: blur σ=20, height 64px, dengan labels yang clutter UI
- Target: iOS 2026 aesthetic seperti di app-app premium (Instagram, Threads)

**Choice:**

1. **Enhanced blur**: Naik dari σ=20 ke σ=30 untuk lebih premium frosted look
2. **Darker surface**: Ganti gradient dari `surface` ke `surfaceContainerHighest/High` dengan alpha lebih rendah (0.65/0.55)
3. **Gradient border effect**: Double container pattern - outer container dengan gradient border (white alpha 0.2→0.15), inner container dengan 1px margin
4. **Compact height**: Dari 64px turun ke 56px untuk lebih streamlined
5. **Icon-only navigation**: Remove semua labels, icon-only dengan glow shadow untuk active state
6. **Active icon glow**: Tambah `Shadow` dengan blur 8px dan primary color untuk active icon

**Rationale:**

- **Premium feel**: σ=30 blur memberikan depth yang lebih baik, mirip native iOS apps
- **Minimalist**: Icon-only navigation mengurangi visual clutter, fokus pada content
- **Modern aesthetic**: Gradient border + darker surface = contemporary glass-morphism
- **YAGNI**: Height 56px cukup untuk touch target (minimum 44px), tidak perlu 64px
- **Accessibility**: Glow shadow pada active icon memberikan visual feedback yang jelas tanpa label

**Impact:**

- File modified: `lib/core/navigation/presentation/pages/navigation_shell_page.dart`
- Breaking change: Navigation jadi icon-only, users perlu adaptasi (tapi icons self-explanatory)
- Design system consistency: Glass effect sekarang se-level dengan ProfilePage dan HomePage
- Performance: σ=30 blur lebih heavy tapi modern devices handle dengan baik
- `dart analyze` clean - no issues

---

## 2026-02-07 — Refactor FAB 'Tambah' to Header Button + Inline Card

**Context:**

- Design requirement: FAB 'Tambah' di HabitTrackerPage perlu di-refactor dari floating button menjadi dua entry points yang lebih integrated
- Header butuh quick access button untuk power users
- Inline card di akhir list memberikan discovery yang lebih natural untuk new users

**Choice:**

1. **Remove FAB completely**: Hapus `floatingActionButton` property dan `_buildGlassFAB()` method
2. **Header '+' button**: Tambah glass icon button di `_buildHeader()` sebelah settings button dengan styling primary (gradient teal)
3. **Inline Add Card**: Tambah card "Tambah Kebiasaan Baru" di akhir habits list dengan glass-morphism styling
4. **Reusable helper**: Buat `_buildGlassIconButton()` dan `_navigateToAddHabit()` untuk consistency

**Rationale:**

- **UX Pattern**: FAB sering ter-hidden di mobile, dua entry points memberikan better discoverability
- **Visual Hierarchy**: Header button untuk quick add, inline card untuk contextual discovery
- **Consistency**: Glass-morphism styling sama dengan design system (ProfilePage, HomePage)
- **YAGNI**: Tidak perlu FAB floating yang kompleks, inline approach lebih predictable

**Impact:**

- File modified: `lib/features/habit_tracker/presentation/pages/habit_tracker_page.dart`
- FAB fully removed - no floating element anymore
- Both buttons navigate ke `AddHabitRoute` dengan haptic feedback
- Glass styling konsisten: BackdropFilter blur, gradient surfaces, border radius 12-20px
- `dart analyze` clean - no issues

---

## 2026-02-07 — FAB Hidden Behind Bottom Navigation Fix

**Context:**

- Floating Action Button "Tambah" di HabitTrackerPage tertutup oleh floating pill navigation bar
- Root cause: Parent Scaffold di NavigationShellPage memakai `extendBody: true` sehingga body meluas ke belakang bottom nav
- FAB child Scaffold diposisikan di default 16px dari bottom edge layar, tepat di belakang nav bar

**Choice:**

- Wrap return value `_buildGlassFAB()` dengan `Padding` widget: `EdgeInsets.only(bottom: 80)`
- Padding 80px mencakup: tinggi nav bar (64px) + padding (8px) + margin safety (8px)
- Tidak mengubah parent Scaffold atau floatingActionButtonLocation untuk minimal change

**Rationale:**

- YAGNI: Solusi terkecil yang solve masalah, tidak perlu refactor struktur Scaffold
- Maintainable: Isolasi fix di satu method, mudah diadjust jika design nav bar berubah
- No breaking change: Tidak mempengaruhi behavior FAB lain atau layout page lain

**Impact:**

- File modified: `lib/features/habit_tracker/presentation/pages/habit_tracker_page.dart` (lines 572-637)
- FAB sekarang visible dan tappable dengan clearance yang proper dari nav bar
- Tidak ada perubahan behavior atau API lain

---

## 2025-12-27 — Articles (Flutter) devotional feed contract

**Context:**

- Need to implement devotional feed in Flutter app
- Backend API specification available in docs/devotional-page/\*

**Choice:**

- Use `GET /articles/public?section=devotional` with stable ordering `publishedAt desc, id desc` (cursor pagination)
- Treat server time as UTC for MVP
- Defer Like UI until backend exposes an explicit public like endpoint

**Rationale:**

- Aligns Flutter implementation with backend guides in `docs/devotional-page/*` and LIVEIT blueprint (UTC day boundary first)
- Keeps MVP scope tight (YAGNI)

**Impact:**

- Flutter team should implement cursor-based pagination (`cursorCreatedAt` + `cursorId` pair)
- Localize `publishedAt` only for display
- Remove/disable likes in mobile UI for now

---

## 2025-12-27 — Articles (Flutter) reader MVP scope

**Context:**

- Need to implement article detail reader in Flutter app
- Backend supports both slug and ID for article identification

**Choice:**

- Route article detail by `slug` (`/articles/public/:slug`) while still storing `id` in models for cursor pagination/cache keys/analytics
- Renderer v1 supports minimum node set (heading/paragraph/text marks/lists/image) and embeds are YouTube-only

**Rationale:**

- Keeps navigation human-friendly and deep-linkable while preserving stable internal identifiers
- Limits renderer complexity for MVP while staying compatible with ProseMirror JSON

**Impact:**

- Flutter team should treat `nextCursor` as opaque and keep `id` available even if UI routes by slug
- Other node types/providers must safely fallback (no crashes)

---

## 2025-11-16 — Profile Page UI/UX Enhancement

**Context:**

- User requested UI/UX analysis and improvements for Profile page similar to homepage enhancements
- Agent identified 7 priority improvements across header, stats, menu, and interactive elements
- Changes needed to improve hierarchy, contrast, and visual feedback following Material Design 3

**Choice:**

- Implemented all 7 UI/UX improvements systematically:
  1. **Avatar & Header Enhancement**: Reduced avatar from 56→48 radius, increased username to 15px w600, display name to w800 with -0.2 letter-spacing, improved bio contrast (alpha 0.7)
  2. **Stats Card Typography**: Enlarged stat values to 28px w800 with -0.5 letter-spacing, icon size to 24px, label to 12px w500, improved spacing (vertical 20, horizontal 12)
  3. **Stats Card Elevation**: Added elevation 1 with subtle border (outline alpha 0.08) for depth, rounded corners 12px
  4. **Menu Items Enhancement**: Increased icon size to 22px, font weight to 600, added theme-based colors for better contrast
  5. **Menu Ripple Effects**: Added splashColor (primary alpha 0.08) to all menu items for tactile feedback
  6. **Logout Button Background**: Added subtle red background (error alpha 0.06) with rounded bottom corners, increased ripple (error alpha 0.12)
  7. **Dividers Consistency**: Updated all dividers to use outline color with alpha 0.12 for subtle separation

**Files Modified:**

- lib/features/profile/presentation/pages/profile_page.dart

**Details:**

**\_ProfilePage Widget:**

- Avatar radius: 56 → 48 (better proportion)
- Display name: fontSize 22 → 20, fontWeight bold → w800, letterSpacing -0.2
- Username: fontSize default → 15, fontWeight w500 → w600
- Bio: color onSurfaceVariant.withOpacity(0.8) → onSurface.withValues(alpha: 0.7), fontSize → 13
- Spacing adjustments: height 8→6 after name, 12→10 after username

**\_StatsCard Widget:**

- Added elevation: 1 for subtle shadow
- Added border: RoundedRectangleBorder with outline alpha 0.08
- Padding: symmetric vertical 20, horizontal 12 (was all 20)
- Border radius: 12px for modern look

**\_StatItem Widget:**

- Icon size: 28 → 24 (consistency)
- Value fontSize: default → 28, fontWeight bold → w800, letterSpacing -0.5
- Label fontSize: default → 12, fontWeight → w500
- Spacing: icon-to-value 8→10, value-to-label 4→6

**\_MenuSection Widget:**

- All icons: size 22, color onSurface (theme-based)
- All titles: fontWeight w600 for prominence
- Chevrons: color onSurfaceVariant (subtle)
- Ripple: splashColor primary alpha 0.08 for all menu items
- Dividers: outline color alpha 0.12 for consistency
- Logout container: error alpha 0.06 background, rounded bottom corners (12px)
- Logout ripple: error alpha 0.12 (stronger than other items)

**Rationale:**

- **Avatar Reduction**: Smaller avatar creates better visual balance and doesn't overwhelm the header
- **Typography Hierarchy**: Bolder weights (w800, w600) and strategic sizing create clear information hierarchy
- **Bio Contrast**: Changed from onSurfaceVariant to onSurface with alpha 0.7 meets WCAG contrast requirements
- **Stats Card Depth**: Subtle elevation and border create visual separation without heavy shadows
- **Larger Stat Values**: 28px size makes key metrics immediately scannable on mobile
- **Menu Improvements**: Larger icons (22px) and bolder text (w600) improve readability and tap target clarity
- **Ripple Effects**: Tactile feedback essential for mobile UX; primary color reinforces brand consistency
- **Logout Emphasis**: Subtle background warns users about destructive action without being alarming
- **Consistent Dividers**: Outline color at 12% opacity creates subtle separation aligned with Material Design 3

**Impact:**

- Profile page now has professional UI/UX with improved hierarchy and readability
- All changes use theme colorScheme for maintainability (primary, error, outline, onSurface)
- Typography improvements enhance scannability especially for stats (28px w800)
- Interactive feedback (ripples) improves perceived responsiveness
- Visual depth (elevation, borders) creates modern layered UI
- Brand consistency maintained through strategic color usage
- All improvements tested without errors
- Future profile work should follow these patterns: balanced spacing, bold typography for key info, subtle backgrounds for emphasis

**Typography Specifications (Profile):**

- Display Name: 20px, FontWeight.w800, letterSpacing: -0.2
- Username: 15px, FontWeight.w600
- Bio: 13px, onSurface alpha 0.7, italic
- Stat Value: 28px, FontWeight.w800, letterSpacing: -0.5
- Stat Label: 12px, FontWeight.w500
- Menu Items: bodyLarge, FontWeight.w600
- Icon Sizes: Menu 22px, Stats 24px, Chevron default

**Color Specifications (Profile):**

- Header Avatar: primaryContainer background
- Stats Icons: tertiary (Zoe Points), primary (Level), secondary (Bergabung)
- Menu Icons: onSurface
- Chevrons: onSurfaceVariant
- Logout: error with alpha 0.06 background, alpha 0.12 ripple
- Dividers: outline at alpha 0.12
- Card Borders: outline at alpha 0.08

**Elevation & Depth:**

- Stats Card: elevation 1, border outline alpha 0.08, borderRadius 12
- All Cards: default Material elevation with subtle shadows

---

## 2025-11-09 — Comprehensive Homepage UI/UX Enhancement

**Context:**

- User provided screenshot of homepage and requested professional UI/UX analysis
- Agent identified 7 priority improvements across contrast, typography, animations, and visual feedback
- Changes needed to align with Material Design 3 principles and brand guidelines

**Choice:**

- Implemented all 7 UI/UX improvements systematically:
  1. **Bottom Nav Active Indicator**: Added 2px primary color underline below active tab text with height 2 container
  2. **Hero Card Readability**: Increased inner box opacity from 0.2 to 0.28, padding from 16 to 18 for better contrast against red gradient
  3. **Stat Chip Typography**: Enlarged icon to 22px, value to 28px w800, subtitle to 12px w500, increased padding to 12h/8v
  4. **Animated Checkboxes**: Replaced static green checkboxes with tertiary color (coral #FF7B54) using 280ms easeOutBack animation, 32px size with Icons.check_rounded
  5. **Ripple Effects**: Wrapped habit items in InkWell with splashColor (primary 10% opacity) and highlightColor (primary 5% opacity)
  6. **Typography Refinement**: Increased habit title to w800 22px with -0.5 letter-spacing, header greeting to 20px w800 -0.3 spacing
  7. **Subtle Dividers**: Added left-aligned dividers (60px indent) between habit items with outline color at 12% opacity

**Files Modified:**

- lib/core/navigation/presentation/pages/navigation_shell_page.dart
- lib/features/home/presentation/pages/home_page.dart

**Details:**

**navigation_shell_page.dart:**

- Added active indicator: Container with height 2, primary color, positioned below tab text
- Improved visual feedback for selected tab with underline pattern
- Maintained ripple effects with InkWell for all nav items

**home_page.dart:**

- Hero card inner box: opacity 0.2 → 0.28, padding 16 → 18
- Stat chips: icon size 18 → 22, value font size default → 28px w800, label 11 → 12 w500, padding 10h/6v → 12h/8v
- Checkbox: color Colors.green → colorScheme.tertiary, added AnimatedContainer with 280ms Curves.easeOutBack, size 28 → 32, icon check → check_rounded
- Habit items: wrapped in InkWell with splashColor and highlightColor for tactile feedback
- Habit title: fontSize default → 22, fontWeight w700 → w800, letterSpacing → -0.5
- Header greeting: fontSize default titleMedium → 20px titleLarge, fontWeight w700 → w800, letterSpacing → -0.3
- Added celebratory badge coloring: completion badge uses tertiary color when all habits done
- Dividers: Added Padding(left: 60) with Divider using outline color at 12% opacity between habit items

**Rationale:**

- **Active Indicator**: Users need clear visual cue for current tab; underline pattern is Material Design 3 standard
- **Hero Card Readability**: Text contrast ratio was below WCAG guidelines; increased opacity improves legibility without losing gradient aesthetic
- **Stat Chips**: Larger typography creates better visual hierarchy and makes key metrics scannable
- **Animated Checkboxes**: Tertiary coral color (#FF7B54) provides brand-aligned celebratory accent; animation adds polish and feedback
- **Ripple Effects**: Tactile feedback essential for mobile UX; InkWell provides native Material Design interaction patterns
- **Typography**: Larger, bolder text with tighter letter-spacing improves readability and creates stronger visual hierarchy aligned with brand personality
- **Dividers**: Subtle separation improves scannability without adding visual clutter; left alignment creates flow aligned with text, not checkbox

**Impact:**

- Homepage now meets professional UI/UX standards with improved contrast, hierarchy, and feedback
- All changes use theme colorScheme (primary, tertiary, outline) for maintainability and theme consistency
- Animations follow Material Design motion guidelines (280ms easeOutBack curve)
- Typography improvements enhance readability on mobile devices
- Brand colors (Deep Teal primary, Coral tertiary) are reinforced through strategic use
- User feedback mechanisms (ripples, animations) improve perceived responsiveness
- All improvements tested in running app without errors
- Future UI work should follow these patterns: theme-based colors, meaningful animations, clear visual hierarchy

**Typography Specifications:**

- Header Greeting: 20px, FontWeight.w800, letterSpacing: -0.3
- Habit Title: 22px, FontWeight.w800, letterSpacing: -0.5
- Stat Value: 28px, FontWeight.w800
- Stat Label: 12px, FontWeight.w500
- Icon Sizes: Nav 24px, Stat 22px, Checkbox 32px

**Animation Specifications:**

- Checkbox: 280ms, Curves.easeOutBack
- Ripple: splashColor at 10% opacity, highlightColor at 5% opacity

**Color Usage:**

- Primary (#2F5D62 Deep Teal): Active nav, ripples, dividers
- Tertiary (#FF7B54 Coral): Completed checkboxes, 100% completion badge
- Outline: Dividers at 12% opacity
- Surface/Background: #F5F5F5 light gray

---

## 2025-11-09 — Profile Page UI Improvements

**Context:**

- User requested 5 specific tasks to improve profile aesthetics and usability

**Choice:**

- Multiple UI refinements to Profile page following user requirements

**Files Modified:**

- lib/features/profile/presentation/pages/profile_page.dart
- lib/core/navigation/presentation/pages/navigation_shell_page.dart

**Details:**

1. Scaffold background changed to Color(0xFFF9F9F9) for cleaner look
2. Bottom navigation bar now has red background with white icons/labels
3. Email field removed from \_ProfileHeader widget
4. Added optional showTooltip parameter to \_StatItem with help icon for Zoe Points
5. Logout icon and text explicitly use colorScheme.error to maintain red accent

**Impact:**

- Improved visual hierarchy and contrast
- Better privacy by hiding email in public-facing profile view
- Added educational tooltip for gamification terms
- Bottom nav now uses brand primary color (red) consistently

---

## 2025-11-09 — Profile Page Redesign

**Context:**

- User requested prominent profile card with left photo and right text stack, bio field, better bottom nav visibility, and edit icon consistency

**Choice:**

- Redesigned profile header with horizontal layout (large circular photo left, name/username/bio right stacked vertically), updated background to light gray, added top border to bottom nav for better separation

**Files Modified:**

- lib/features/profile/presentation/pages/profile_page.dart
- lib/core/navigation/presentation/pages/navigation_shell_page.dart

**Details:**

- Profile header: Changed from vertical centered layout to horizontal Row layout
- Avatar radius: 48 → 56 (larger and more prominent)
- Name styling: Added bold, uppercase, 22px font size
- Added bio field with italic placeholder text
- Card padding: 20 → 24 for better spacing
- Background: Color.fromARGB(255, 97, 81, 81) → Color(0xFFF5F5F5)
- Bottom nav: Added top border with outline color at 20% opacity
- Bottom nav background: Explicit white color for contrast

**Impact:**

- Profile card is now more dominant and visually appealing
- Better use of horizontal space with side-by-side layout
- Bio field allows for personalization
- Clearer visual hierarchy with larger, bolder name
- Bottom navigation now clearly separated from main content
- Improved contrast and readability with lighter background

---

## 2025-11-09 — Bottom Navigation Theme Compliance

**Context:**

- Current implementation used hardcoded black background and white icons, violating theming guidelines in AGENTS.md and .github/copilot-instructions.md

**Choice:**

- Replaced hardcoded colors with theme-based colorScheme values to align with centralized theming strategy

**Files Modified:**

- lib/core/navigation/presentation/pages/navigation_shell_page.dart

**Details:**

- Background: `Color.fromARGB(255, 0, 0, 0)` → `colorScheme.surface`
- Active icons/text: `Colors.white` → `colorScheme.primary`
- Inactive icons/text: `Colors.white.withOpacity(0.6)` → `colorScheme.onSurfaceVariant.withOpacity(0.6)`

**Impact:**

- Compliant with centralized theming guidelines
- Automatically adapts to theme changes
- Better accessibility and brand consistency

---

## 2025-11-07 — Fix LocaleDataException for Indonesian DateFormat

**Context:**

- User encountered `LocaleDataException: Locale data has not been initialized, call initializeDateFormatting(<locale>)` when running the app.
- `HomePage` uses `DateFormat('EEEE, d MMM', 'id_ID')` to format dates in Indonesian locale.
- The error occurred because `intl` package locale data was not initialized before being used.

**Choice:**

- Added `import 'package:intl/date_symbol_data_local.dart'` to all main entry points: `main.dart`, `main_dev.dart`, `main_prod.dart`.
- Added `await initializeDateFormatting('id_ID', null);` call in the `main()` function before `runApp()` in all three entry points.
- Ensures Indonesian locale data is loaded before any `DateFormat` calls.

**Files Modified:**

- lib/main.dart
- lib/main_dev.dart
- lib/main_prod.dart

**Rationale:**

- The `intl` package requires explicit initialization of locale data before formatting dates with specific locales.
- Initializing in `main()` ensures the locale data is ready before any widgets that use `DateFormat` are built.
- Using Indonesian locale ('id_ID') aligns with the app's target audience and brand localization.

**Impact:**

- App will no longer crash with `LocaleDataException` when displaying formatted dates.
- All date formatting throughout the app (especially in `HomePage`) will work correctly with Indonesian locale.
- Future features using `DateFormat` with 'id_ID' will work without additional initialization.
- Developers adding new date formatting should be aware locale is already initialized for Indonesian.

---

## 2025-10-30 — Homepage mobile layout refresh

**Context:**

- Need to align Routine tab with visual reference while keeping logic lightweight until Bloc integration lands

**Choice:**

- Reworked `HomePage` into a stacked scroll layout with gradient header, grouped habit card, and refreshed quick actions to match latest mobile mock

**Impact:**

- UI matches design expectations for demo builds
- Further integration work should re-hook HomeBloc and ensure design tokens stay consistent when data wiring arrives

---

## 2025-10-29 — Bottom Navigation Bar Implementation

**Context:**

- User requested bottom navigation bar similar to reference image with 5 tabs: Routine, Inspire, Challenge, Library, Profile.
- Need to implement navigation using existing Bloc pattern and AutoRoute setup.

**Choice:**

- Created 5 feature pages: RoutinePage (moved from HomePage content), InspirePage, ChallengePage, LibraryPage, ProfilePage.
- Created NavigationBloc to manage bottom navigation state with NavigationTabChanged event.
- Created NavigationShellPage as wrapper page using AutoTabsRouter for nested navigation.
- Updated AppRouter to use NavigationShellPage as root with nested child routes.
- Simplified HomePage to basic placeholder (kept for potential future use).

**Files Created:**

- lib/features/home/presentation/pages/routine_page.dart (moved content from old HomePage)
- lib/features/inspire/presentation/pages/inspire_page.dart
- lib/features/challenge/presentation/pages/challenge_page.dart
- lib/features/library/presentation/pages/library_page.dart
- lib/features/profile/presentation/pages/profile_page.dart
- lib/core/navigation/presentation/bloc/navigation_bloc.dart
- lib/core/navigation/presentation/bloc/navigation_event.dart
- lib/core/navigation/presentation/bloc/navigation_state.dart
- lib/core/navigation/presentation/pages/navigation_shell_page.dart

**Files Modified:**

- lib/core/router/app_router.dart (added nested navigation structure)
- lib/features/home/presentation/pages/home_page.dart (simplified)

**Rationale:**

- Follows established architecture patterns (feature-first, Bloc state management, AutoRoute).
- Separates navigation concerns from content pages for better maintainability.
- Allows independent development of each tab while maintaining consistent navigation UX.
- Uses AutoTabsRouter for proper nested routing with deep-linking support.

**Impact:**

- Bottom navigation now visible on all main app screens.
- Each tab has its own route and can maintain independent state.
- Navigation state managed through Bloc for consistency and testability.
- Routine tab contains all previous HomePage functionality (habits, devotionals, gamification).
- Other tabs are placeholders ready for future feature implementation.
- Developers working on new features can now add content to respective tab pages.

---

## 2025-10-22 — AI agent onboarding guidance

**Context:**

- Needed single-source instructions so AI agents mirror repo norms without re-reading entire codebase each session

**Choice:**

- Authored `.github/copilot-instructions.md` summarising architecture, workflows, and conventions for automated assistants

**Impact:**

- Future agents can ramp quickly
- Keep file updated when workflows or patterns change

---

## 2025-10-19 — README Update

**Context:**

- User requested README update to help onboarding and development setup

**Choice:**

- Expanded `README.md` with project overview, quickstart, architecture, and contribution guidelines in Indonesian

**Impact:**

- Improves onboarding for new contributors and documents local development steps

---

## 2025-10-13 — Homepage experience scaffolding

**Context:**

- Needed tangible prototype aligning with user stories 14-18 and brand essence to guide further integration work

**Choice:**

- Implemented composable widgets for homepage (daily summary, habit groups, devotional highlight, gamification, empty/error banners) using brand palette and mocked sample state

**Impact:**

- FE team now has baseline UI to wire with real bloc/state/data and evaluate interactions per acceptance criteria

---

## 2025-10-12 — Logout Navigation Stack Clear

**Context:**

- User requested logout should go to login page without ability to navigate back to authenticated screens

**Choice:**

- Modified logout navigation to use pushNamedAndRemoveUntil instead of pushPath to completely clear navigation stack

**Impact:**

- Changed from context.router.pushPath('/') to Navigator.pushNamedAndRemoveUntil('/', (route) => false) to clear entire navigation stack on logout

---

## 2025-10-12 — Home Page Logout Feature

**Context:**

- User requested logout button on home page for better UX and security

**Choice:**

- Added logout functionality to HomePage with confirmation dialog and automatic navigation back to login page

**Impact:**

- Added logout button in app bar menu and center screen with confirmation dialog, integrated with AuthBloc logout event, navigation handled via BlocListener

---

## 2025-10-12 — Authentication needsUsername Bug Fix

**Context:**

- Backend was returning null for needsUsername field but model expected non-nullable bool, causing registration UI to crash after successful API call

**Choice:**

- Fixed type 'Null' is not a subtype of type 'bool' error in UserModel.fromJson by adding null handling for needsUsername field, defaulting to true when backend returns null

**Impact:**

- UserModel now safely handles null needsUsername from backend, registration flow should work end-to-end without casting errors

---

## 2025-10-12 — Authentication Debug Logging

**Context:**

- User reported registration not working despite data being added to database - needed detailed logging to debug null type error

**Choice:**

- Added comprehensive logging throughout auth flow using Logger package - BLoC events/states, repository calls, API requests/responses, UI state changes, error handling

**Impact:**

- Extensive logging added at all layers to identify where the issue occurs in the auth flow

---

## 2025-10-12 — Authentication Feature Implementation

**Context:**

- User requested full auth implementation based on documentation with BLoC pattern and existing theme

**Choice:**

- Implemented complete authentication feature with BLoC state management, clean architecture, email/password auth, username claiming, OAuth placeholders, dependency injection with get_it, secure storage

**Impact:**

- All authentication flows ready for backend integration, OAuth buttons ready for when backend supports it

---

## 2025-10-12 — Flutter routing setup

**Context:**

- Analyzer errors about missing `config()`/`delegate()` by aligning implementation with official installation guide

**Choice:**

- Adjusted `AppRouter` to extend `RootStackRouter` per auto_route v10 docs and restored `routerConfig` usage in `MaterialApp.router`

**Impact:**

- Ensures navigation builds with latest auto_route API and keeps generated routes functional

---

## 2025-10-12 — Frontend environment configuration

**Context:**

- Needed so Flutter client can load backend base URL consistently via dotenv

**Choice:**

- Created root `.env` holding API base URL `https://liveit-api-dev-5jufu.ondigitalocean.app`

**Impact:**

- Frontend devs should load `API_BASE_URL` from env when wiring network layer

---

## 2025-10-12 — Theme setup using FlexColorScheme

**Context:**

- Implement color scheme/theme data aligned to brand palette "Grounded Growth" per docs [docs/liveit-brand-essence.md](docs/liveit-brand-essence.md) and [docs/liveit-blueprint.md](docs/liveit-blueprint.md).

**Choice:**

- Added centralized theme configuration [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart) with FlexColorScheme light/dark based on brand colors.
- Wired theme into all app entry points: [Dart.main()](lib/main.dart:5), [Dart.main()](lib/main_dev.dart:5), [Dart.main()](lib/main_prod.dart:5) using [Dart.AppTheme.light()](lib/core/theme/app_theme.dart:29) and [Dart.AppTheme.dark()](lib/core/theme/app_theme.dart:68).

**Rationale:**

- Align UI to documented brand personality and palette.
- Use minimal, centralized implementation for maintainability and consistency.
- Avoid over-scoping: Typography and component-specific styles can be added later after verification.

**Impact:**

- App now uses brand-consistent color scheme in both light and dark modes via ThemeMode.system.
- No changes to data schema or backend.
- Provides semantic colors via ThemeExtension for success/warning/info to support UX messaging patterns.

---

## 2025-10-11 — Setup routing dengan auto_route (config-based)

**Context:**

- Diminta men-setup route project menggunakan auto_route dan menambahkan halaman Home.
- Dependency auto_route sudah ada di pubspec.yaml; generator & build_runner telah ditambahkan.

**Choice:**

- Menggunakan pendekatan config-based AutoRouterConfig (sesuai dokumentasi auto_route v10).
- Menambahkan anotasi @RoutePage pada HomePage.
- Mengubah entry point aplikasi ke MaterialApp.router dengan AppRouter.
- Menambahkan part file untuk hasil generate di router.

**Files:**

- lib/core/router/app_router.dart
- lib/features/home/presentation/pages/home_page.dart
- lib/main.dart

**Rationale:**

- Config-based adalah pendekatan resmi dan lebih terstruktur untuk skala fitur.
- Memudahkan penambahan route ke depan dan konsisten dengan linter modern.

**Impact:**

- Analyzer akan menampilkan error sementara karena file hasil generate belum ada.
- Perlu menjalankan code generation: `dart run build_runner build` (atau `flutter pub run build_runner build`).
- Setelah generate, method seperti `config()` dan symbol `_$AppRouter` serta `HomeRoute` akan tersedia dan error hilang.

---

## 2025-10-11 — Homepage product requirements

**Context:**

- Aligns documentation with blueprint guidance so design/dev teams share same expectations

**Choice:**

- Added Homepage Experience epic with stories 14-18 to `docs/liveit-userStories.md`

**Impact:**

- Product and engineering teams should review new homepage stories when planning UI and data integrations

---

## 2025-10-11 — Initialising repository decision log

**Context:**

- Needed by agent workflow to record decisions and ensure traceability

**Choice:**

- Create `decisions.md` with template

**Impact:**

- No functional changes; file added

---

## 2026-01-15 — DevotionPage fetches Articles public feed

**Context:**

- User requested Devotion page to fetch devotional articles from `GET /articles/public`
- API returns cursor-paginated list with fields like `title`, `slug`, `snippet`, `coverUrl`, `publishedAt`

**Choice:**

- Implement lightweight DTOs for public feed response and items
- Use existing `DioClient` + interceptors via `GetIt` for network calls
- Map `subtitle` → "verse" line in UI, fallback to `authorDisplayName`, and show `snippet` fallback when null
- Keep likes UI as `0` because public feed does not expose like/clap totals

**Rationale:**

- Keeps implementation consistent with existing networking layer (timeouts/errors/auth)
- Avoids adding state management or pagination UX not requested (YAGNI)

**Impact:**

- DevotionPage now renders real data from backend in place of hardcoded cards
- Article detail navigation remains TODO (needs route/page for `/articles/public/{slug}`)

---

## 2026-01-21 — Habit Tracker Phase 2A Implementation Planning

**Context:**

- User requested full Habit Tracker implementation aligned with backend specification
- Backend at `C:\Users\Kevin\liveit-server` has complete Phase 2A features (repeat periods, frequency control, streak tracking, visual customization, custom ordering)
- Flutter currently implements only basic MVP (~30% coverage) with basic CRUD operations

**Choice:**

- Create comprehensive implementation plan with 101 tasks across 6 phases
- Use backend documentation at `C:\Users\Kevin\liveit-server\docs\liveit-habitTracker-feature.md` as source of truth
- Plan sequential implementation: Data Layer → State Management → Basic UI → Advanced UI → Polish → Testing

**Rationale:**

- Backend Phase 2A is production-ready and complete
- Flutter needs systematic upgrade to match backend capabilities
- Layer-by-layer approach minimizes confusion and ensures proper data flow
- Comprehensive checklist enables tracking progress and identifying remaining work

**Impact:**

- Implementation plan created at `docs/habit-tracker-implementation-plan.md`
- 101 tasks identified across 6 phases:
  - Phase 1: Data Layer Phase 2A Support (20 tasks)
  - Phase 2: State Management Phase 2A Support (12 tasks)
  - Phase 3: UI Layer - Basic Phase 2A (12 tasks)
  - Phase 4: UI Layer - Advanced Features (23 tasks)
  - Phase 5: Polish & Optimization (19 tasks)
  - Phase 6: Testing (15 tasks)
- Ready to begin Phase 1: Data Layer updates to support all Phase 2A fields
- Backend at `C:\Users\Kevin\liveit-server\docs\` is the definitive source of truth for all API contracts

---

## 2026-01-21 — Habit Tracker Phase 2A Data Layer Implementation

**Context:**

- Completed Phase 1 Data Layer updates for Habit Tracker Phase 2A
- Updated all layers to support backend Phase 2A specification

**Choice:**

- Updated `HabitRemoteDataSource` with all Phase 2A fields and new methods:
  - `addHabit()` with repeatPeriod, frequency, frequencyDays, color, icon, order
  - `createCustomHabit()` with same Phase 2A fields
  - `updateHabit()` PATCH endpoint for editing habits
  - `archiveHabit()` DELETE endpoint (soft delete via archivedAt)
  - `reorderHabits()` PATCH endpoint with updates array
- Updated `HabitRepository` interface with all methods and Phase 2A parameters
- Updated `HabitRepositoryImpl` with full implementation
- Updated `HabitEvent` with Phase 2A fields for add/create and new events:
  - `HabitAdded` with all Phase 2A fields
  - `CustomHabitCreated` with all Phase 2A fields
  - `HabitUpdated` for editing existing habits
  - `HabitArchived` for soft delete
  - `HabitReordered` for drag & drop reordering
- Updated `HabitBloc` with handlers for all new events
- Updated `AddHabitPage` to use new repository method signatures with named parameters
- Ran `dart run build_runner build` to regenerate .g.dart files
- Ran `dart format` to format all modified files

**Files Modified:**

- `lib/features/habit_tracker/data/datasources/habit_remote_data_source.dart`
- `lib/features/habit_tracker/domain/repositories/habit_repository.dart`
- `lib/features/habit_tracker/data/repositories/habit_repository_impl.dart`
- `lib/features/habit_tracker/presentation/bloc/habit_event.dart`
- `lib/features/habit_tracker/presentation/bloc/habit_bloc.dart`
- `lib/features/habit_tracker/presentation/pages/add_habit_page.dart`

**Rationale:**

- Complete Data Layer implementation to support all Phase 2A fields
- Follows backend API contract exactly as specified in `C:\Users\Kevin\liveit-server\docs\liveit-habitTracker-feature.md`
- Named parameters for clarity and type safety
- Clean separation of concerns across data/domain/presentation layers

**Impact:**

- Phase 1 Data Layer complete (~20 tasks)
- Ready to proceed to Phase 2: State Management updates (already integrated in Phase 1)
- Ready to proceed to Phase 3: UI Layer updates (AddHabitPage form fields for Phase 2A)
- All code passes `flutter analyze` and `build_runner`
- Next: Update UI components to display Phase 2A fields and add form inputs

---

## 2026-01-21 — Habit Tracker Phase 2A UI Layer Implementation

**Context:**

- Completed Phase 3 UI Layer updates for Habit Tracker Phase 2A
- Updated HabitCard, HabitTrackerPage, and AddHabitPage with all Phase 2A features

**Choice:**

- Updated `HabitCard` with complete Phase 2A UI:
  - Color indicator (colored container with hex color parsing)
  - Icon display (emoji from `icon` field)
  - Repeat period badge (1 Hari/Minggu/Bulan/Tahun/Selamanya)
  - Frequency badge (Harian/Mingguan/Custom days)
  - Streak badges (current streak 🔥, longest streak 🏆, total completions ✓)
  - Edit and Archive action buttons with bottom sheet menu
  - Color-coded borders and backgrounds based on habit color
- Updated `HabitTrackerPage`:
  - Uses new `HabitCard` with `UserHabit` object
  - Shows habit options bottom sheet with Edit and Archive actions
  - Archive confirmation dialog before soft delete
  - Passes `onEdit` and `onArchive` callbacks to HabitCard
- Updated `AddHabitPage` with Phase 2A form inputs:
  - Catalog tab: ExpansionTile for each habit with advanced options
  - Custom tab: Inline advanced options toggle
  - Repeat Period dropdown (Selamanya, 1 Hari, 1 Minggu, 1 Bulan, 1 Tahun)
  - Frequency dropdown (Harian, Mingguan, Custom)
  - Custom Days picker with FilterChips for Sun-Sat selection
  - Color picker with 10 preset colors in circular swatches
  - Icon picker with 12 preset emojis in colored circles
  - Auto-incremented order (default behavior)

**Files Modified:**

- `lib/features/home/presentation/widgets/habit_card.dart`
- `lib/features/habit_tracker/presentation/pages/habit_tracker_page.dart`
- `lib/features/habit_tracker/presentation/pages/add_habit_page.dart`

**Rationale:**

- Complete UI Layer implementation matching backend Phase 2A specification
- User-friendly form inputs with clear labels and Indonesian translations
- Visual feedback through color coding and icons
- Consistent UX across catalog and custom habit creation
- Smooth integration with updated BLoC events and handlers

**Impact:**

- Phase 3 UI Layer Basic complete (~12 tasks)
- HabitCard now displays color, icon, repeat period, frequency, and streak stats
- AddHabitPage supports all Phase 2A configuration options
- HabitTrackerPage has archive functionality with confirmation
- Ready to proceed to Phase 4: Advanced Features (EditHabitPage, drag & drop, gamification)
- All code passes `flutter analyze` with only deprecation info messages

---

## 2026-01-24 — Habit Tracker Phase 4 Advanced Features Implementation

**Context:**

- Completed Phase 4 UI Layer Advanced Features for Habit Tracker
- Implemented EditHabitPage, HabitStatsPage, drag & drop reordering, gamification visual feedback

**Choice:**

- Rebuilt `HabitTrackerPage` with distinctive "Grounded Growth" design:
  - Custom header with greeting, date, motivational message, and progress ring
  - SliverReorderableList for drag & drop habit reordering
  - Pending habits sorted first, completed habits moved to bottom
  - Integration with new HabitCard widget

- Created new `HabitCard` widget (`lib/features/habit_tracker/presentation/widgets/habit_card.dart`):
  - Gradient backgrounds based on completion state
  - Animated check button with haptic feedback (280ms easeOutBack)
  - Streak badges with milestone indicators (⚡ 7 days, 🔥 30 days, 👑 100 days)
  - Drag handle support for reordering mode
  - Long-press to open options menu

- Created `EditHabitPage` for editing existing habits:
  - Pre-filled form with current habit data
  - Habit preview card at top
  - Notes, schedule (repeat period, frequency, custom days), personalization (color, icon)
  - Unsaved changes confirmation dialog
  - Bottom save button

- Created `HabitStatsPage` with detailed statistics:
  - Habit header with icon, name, frequency
  - Stats cards (current streak, longest streak, total completions)
  - Calendar heatmap with month navigation
  - Streak timeline with milestone markers (7, 30, 100, 365 days)
  - Next milestone progress card

- Created `celebrations.dart` with gamification visual feedback:
  - `ConfettiOverlay` - Custom confetti animation with brand colors
  - `StreakCelebration` - Modal dialog for streak milestones
  - `AllDoneCelebration` - Modal dialog when all habits completed
  - `ZoePointsPopup` - Animated popup for Zoe Points earned

- Updated router with new routes:
  - `/edit-habit` - EditHabitRoute with UserHabit parameter
  - `/habit-stats` - HabitStatsRoute with UserHabit parameter

**Files Created:**

- `lib/features/habit_tracker/presentation/widgets/habit_card.dart`
- `lib/features/habit_tracker/presentation/pages/edit_habit_page.dart`
- `lib/features/habit_tracker/presentation/pages/habit_stats_page.dart`
- `lib/features/habit_tracker/presentation/widgets/celebrations.dart`

**Files Modified:**

- `lib/features/habit_tracker/presentation/pages/habit_tracker_page.dart` (full rebuild)
- `lib/core/router/app_router.dart` (added EditHabit and HabitStats routes)

**Rationale:**

- Distinctive design following "Grounded Growth" brand palette (Deep Teal, Warm Sand, Coral)
- Organic UI language with rounded corners, gradients, and subtle shadows
- Meaningful animations that reinforce positive behavior (check-in celebration)
- Gamification elements (streak badges, milestones) encourage consistency
- Calendar heatmap provides visual progress tracking
- Reorder functionality via SliverReorderableList for better habit prioritization

**Impact:**

- Phase 4 Advanced Features COMPLETED
- HabitTrackerPage now has professional, distinctive UI
- EditHabitPage allows full habit customization
- HabitStatsPage provides detailed progress visualization
- Gamification widgets ready for integration
- All code passes `flutter analyze` with only deprecation warnings (withOpacity → withValues)
- Router regenerated with build_runner

**Design Specifications:**

- Progress Ring: 72px diameter, 6px stroke, animated 1200ms easeOutCubic
- HabitCard: 20px border radius, gradient backgrounds, 12px bottom margin
- Streak Badges: 12px border radius, gradient fills, shadow glow
- Check Button: 44px diameter, 2px border, elasticOut animation
- Calendar: 6px cell spacing, 8px border radius, completion fill with habit color
- Milestone Markers: 40px diameter circles, 18px emoji icons

**Animation Specifications:**

- Progress ring: 1200ms, Curves.easeOutCubic
- Check button scale: 300ms, Curves.easeOutBack
- Card tap feedback: 300ms scale to 0.95
- Confetti: 3000ms duration, 50 particles
- Zoe Points popup: 2000ms with slide + scale + fade

---

## 2026-01-24 — Habit Tracker Gamification Integration

**Context:**

- Need to wire up celebration widgets (Confetti, Dialogs) with actual check-in events
- Visual feedback is crucial for habit reinforcement (Atomic Habits principle: Make it Satisfying)

**Choice:**

- Integrated `ConfettiOverlay` and celebration dialogs directly into `HabitTrackerPage` via BlocListener
- Implemented `CelebrationData` in `HabitState` to hold transient celebration events
- Added logic in `HabitBloc` to calculate points and detect milestones from check-in response

**Files Modified:**

- `lib/features/habit_tracker/presentation/bloc/habit_state.dart` (added CelebrationData)
- `lib/features/habit_tracker/presentation/bloc/habit_event.dart` (added HabitCelebrationCleared)
- `lib/features/habit_tracker/presentation/bloc/habit_bloc.dart` (added calculation logic)
- `lib/features/habit_tracker/presentation/pages/habit_tracker_page.dart` (added listener and UI overlay)

**Rationale:**

- Keeps UI logic (showing dialogs) separated from business logic (calculating milestones)
- Using a transient state (`CelebrationData`) ensures celebrations survive screen rotation but can be cleared
- `ConfettiOverlay` wrapper provides a non-intrusive way to show global effects

**Impact:**

- Users now see:
  - Confetti rain on every check-in
  - "Zoe Points +10" popup on check-in
  - Streak Celebration dialogs on days 7, 30, 100
  - "All Done" celebration when finishing last habit
- Enhances user engagement and satisfaction

---

## 2026-01-24 — Offline Caching Strategy (Me+ Benchmark)

**Context:**

- User requested "Me+ like experience" (Instant load, Optimistic UI).
- Current implementation was "Online-First" (Loading spinners, wait for server).
- Risk of ANR/Lag if using heavy database solutions on main thread.

**Choice:**

- Adopted **Hive** (NoSQL, Pure Dart) for caching `UserHabit` data.
- Implemented **Hybrid Repository Pattern**:
  1.  `getCachedHabits()`: Direct Hive read (Instant).
  2.  `getUserHabits()`: Network fetch + Write to Hive (Background update).
- Implemented **Optimistic UI** in `HabitBloc`:
  - Check-in/Undo events immediately update state (`emit`) before awaiting API.
  - Rollback state if API fails.

**Rationale:**

- **UX:** Matches "Me+" standard where data is always available and interaction is instant.
- **Performance:** Hive is significantly faster than SQLite/Drift for simple JSON lists and doesn't block UI thread (Anti-ANR).
- **Reliability:** App works in "Airplane Mode" using last known data.

**Impact:**

- Added `hive` and `hive_flutter` dependencies.
- Created `HabitLocalDataSource` and registered in DI.
- `HabitBloc` now emits state twice on load: Cache (Instant) -> API (Fresh).
- UI feels significantly faster; Check-in is instant.

---

## 2026-01-25 — Restoration of Missing Habit Tracker Files

**Context:**

- User encountered compilation errors `Target kernel_snapshot_program failed` because several files were missing from the project directory.
- Missing files: `lib/features/habit_tracker/presentation/pages/edit_habit_page.dart` and `lib/features/habit_tracker/data/datasources/habit_local_data_source.dart`.
- These files were referenced in `AppRouter` and `injection_container.dart` but were not present on disk.

**Choice:**

- Recreated `HabitLocalDataSource` with Hive support, including the `openBox()` static method required by the injection container.
- Recreated `EditHabitPage` with full Phase 2A support:
  - Pre-filled form fields (Notes, Schedule, Personalization).
  - Habit preview card for real-time feedback.
  - Unsaved changes confirmation logic using `PopScope`.
- Ran `build_runner` to regenerate `app_router.gr.dart` and ensure route definitions match the restored page.
- Cleaned up duplicate/unused imports in `injection_container.dart` and `add_habit_page.dart`.

**Rationale:**

- **Stability:** Restores the project to a buildable state after local file loss.
- **Consistency:** Re-implements features (Hive caching, Edit page) exactly as described in previous technical blueprints and decision logs.

**Impact:**

- Build error "The system cannot find the file specified" is resolved.
- Habit Tracker editing and offline caching functionality is fully restored.
- Project now passes static analysis (with only deprecation warnings from Flutter 3.27).

---

## 2026-02-01 — Profile Page Modern Glass-Morphism Refactor

**Context:**

- User requested complete refactor of ProfilePage with modern iOS 2026 glass-morphism aesthetic
- Must follow LIVEIT "Grounded Growth" brand colors (Deep Teal, Warm Sand, Coral)
- Must maintain all existing functionality while improving UX
- ProfileBloc was not integrated - ProfilePage only used AuthBloc with hardcoded stats

**Choice:**

1. **Registered ProfileBloc in DI and Global Providers:**
   - Added `ProfileBloc` registration in `injection_container.dart`
   - Added `ProfileBloc` provider to `MultiBlocProvider` in `main_dev.dart` and `main_prod.dart`
   - ProfilePage now uses both `AuthBloc` (auth state) and `ProfileBloc` (gamification data)

2. **Implemented iOS 2026 Glass-Morphism Design:**
   - **Glass Header**: Gradient background with `BackdropFilter` blur (sigmaX/Y: 20), frosted glass ring around avatar
   - **Gradient Overlay**: Multi-color gradient using brand palette (Primary 15%, Secondary 10%, Tertiary 5%)
   - **Frosted Cards**: Stats cards with glass-morphism effect, colored borders, and soft shadows
   - **Glass Menu**: BackdropFilter blur (sigmaX/Y: 10) with transparent surface and subtle borders
   - **Member Since Badge**: Glass container showing membership duration calculation

3. **Enhanced Visual Hierarchy:**
   - Centered vertical layout (avatar top, name/username/email stacked)
   - Display name in uppercase with w800 weight and -0.3 letter-spacing
   - Username in gradient container with primary color
   - Stat cards use brand colors: Tertiary (Coral) for Zoe Points, Primary (Deep Teal) for Level
   - Level names mapped (1: "Langkah Pertama", 2: "Membangun Irama", etc.)

4. **Improved Functionality:**
   - Profile data fetched from `/profiles/me` endpoint on page load
   - Real Zoe Points and Level displayed from `ProfileModel`
   - Smart member duration calculation (days/months/years)
   - Loading states with shimmer-like placeholders
   - Unauthenticated view with glass-morphism card

5. **UX Enhancements:**
   - Subtle shadows with color-tinted glow (elevation + blur)
   - Consistent 20-24px border radius throughout
   - Haptic-ready InkWell with themed splash colors
   - Coming soon snackbars for menu items (Edit Profil, Badge, etc.)
   - Glass-morphism logout dialog with brand-styled buttons

6. **Added flutter_animate package:**
   - Added `flutter_animate: ^4.2.0` for smooth entry animations
   - Staggered reveal animations for header, stats, and menu sections

7. **Extended ProfileModel:**
   - Added `currentStreak` field to support streak display
   - Updated `copyWith`, `fromJson`, and `toJson` methods

**Files Modified:**

- `lib/core/injection/injection_container.dart` (added ProfileBloc registration)
- `lib/main_dev.dart` (added ProfileBloc provider)
- `lib/main_prod.dart` (added ProfileBloc provider)
- `lib/features/profile/presentation/pages/profile_page.dart` (complete rewrite)
- `lib/features/profile/domain/models/profile_model.dart` (added currentStreak)
- `pubspec.yaml` (added flutter_animate)

**Rationale:**

- **Glass-Morphism**: iOS 2026 design trend - frosted glass, layered depth, subtle transparency
- **Brand Alignment**: Uses LIVEIT "Grounded Growth" palette throughout (Deep Teal primary, Coral tertiary)
- **Real Data**: Integrates ProfileBloc to display actual Zoe Points and Level from backend
- **Progressive Disclosure**: Clean, minimal UI that reveals more on interaction
- **Accessibility**: Maintains WCAG contrast ratios while using glass effects

**Impact:**

- ProfilePage now has distinctive, modern iOS glass-morphism aesthetic
- Real gamification data (Zoe Points, Level, Streak) fetched from `/profiles/me` endpoint
- Consistent with HabitTrackerPage "Grounded Growth" design language
- All menu items show "Coming Soon" feedback instead of TODO comments
- Member duration shows human-readable format ("3 bulan")
- Avatar supports network images from `avatarUrl` when available
- Logout flow maintains same functionality with improved glass-morphism dialog
- Entry animations provide smooth, polished user experience
- Ready for future features: Edit Profile, Badges, Activity History, Settings

**Design Specifications:**

- **Glass Blur**: Header sigma 20, Menu sigma 10
- **Border Radius**: 20-24px for cards, 12px for containers, 56px for avatar
- **Gradient**: 3-color brand palette overlay (alpha 5-15%)
- **Shadows**: Color-tinted with 20px blur and 8px vertical offset
- **Avatar Ring**: 4px gradient border (Primary → Secondary → Tertiary)
- **Stat Cards**: Glass surface with colored borders matching stat type
- **Menu Items**: Icon containers with primaryContainer alpha 30%
- **Animations**: 1200ms header, 800ms stats, staggered reveals

**Color Usage:**

- Primary (Deep Teal #2F5D62): Level stats, headers, menu icons
- Tertiary (Coral #FF7B54): Zoe Points stats, accents, streak badges
- Secondary (Warm Sand #C3B49A): Subtle backgrounds
- Surface alpha 60-80%: Glass card backgrounds
- Outline alpha 10-20%: Subtle borders and dividers

---

## 2026-02-01 — Navigation Shell Glass-Morphism Pill Design

**Context:**

- User requested refactor of NavigationShellPage with modern iOS 2026 glass-morphism aesthetic
- Requested floating pill style navigation bar matching ProfilePage design language
- Consistent with "Grounded Growth" brand (Deep Teal, Coral, Warm Sand)

**Choice:**

1. **Floating Pill Design:**
   - Converted bottom navigation to floating pill container
   - 32px border radius for pill shape
   - Positioned with margin (16px horizontal) for floating effect
   - Extended body behind nav (`extendBody: true`)

2. **Glass-Morphism Implementation:**
   - `BackdropFilter` blur sigma 20 for frosted glass effect
   - Gradient surface (surface alpha 85-92%)
   - Subtle border (outline alpha 20%)
   - Dual shadow layer: primary-tinted (blur 20) + black (blur 30)

3. **Navigation Items:**
   - 4 items: Home, Devotion, Habits, Profile
   - Active state: Gradient background (primary alpha 15%), border (primary alpha 25%)
   - Inactive state: Transparent with muted icons
   - Animated scale effect on state change (300ms easeOutBack)

4. **Animations:**
   - Entry animation: Slide up + fade in (600ms)
   - Scale animation on tab change (300ms easeOutBack)
   - SizedBox transitions for label reveal

5. **Technical Changes:**
   - Converted \_NavigationShellView from StatelessWidget to StatefulWidget
   - Added AnimationController for entry animation
   - Updated pillController lifecycle management

**Files Modified:**

- `lib/core/navigation/presentation/pages/navigation_shell_page.dart` (complete redesign)

**Rationale:**

- **Floating Pill**: iOS 2026 trend - detached, floating navigation instead of docked bar
- **Glass Effect**: Matches ProfilePage glass-morphism language
- **Brand Consistency**: Uses same primary/tertiary colors, blur amounts, shadow patterns
- **Animation**: flutter_animate scale effects provide tactile feedback on tab selection

**Design Specifications:**

- **Pill Shape**: 32px border radius, 16px horizontal margin
- **Glass Blur**: sigmaX/Y = 20
- **Shadows**: Primary alpha 15% (blur 20, offset 0,8) + Black alpha 10% (blur 30, offset 0,15)
- **Active Item**: 16h/10v padding, gradient fill, 1px border, scale to 1.0
- **Inactive Item**: 16h/10v padding, transparent, scale to 1.0
- **Animation**: 300ms easeOutBack scale, 600ms slide-up entry

**Color Usage:**

- Primary (Deep Teal #2F5D62): Active icons, text, gradient fill, borders
- Surface alpha 85-92%: Glass background
- Outline alpha 20%: Subtle border
- Inactive: onSurfaceVariant alpha 60%

**Impact:**

- Navigation bar now matches ProfilePage iOS 2026 glass-morphism aesthetic
- Floating pill design creates modern, elevated navigation experience
- Consistent animations and visual language across app
- Better visual separation from content (extendBody: true)
- Improved tactile feedback with scale animations
- Ready for future enhancements (badges, notifications on nav items)

---

## 2026-02-01 — Homepage Refactor with Glass-Morphism Design

**Context:**

- User requested complete refactor of HomePage to serve as main landing page for LiveIt app
- Must display key features prominently: Habit Tracker (primary), Zoe Points, Community, Profile
- Must follow modern iOS 2026 glass-morphism aesthetic like ProfilePage
- Must replace RoutineRoute as first tab in NavigationShellPage

**Choice:**

1. **Complete HomePage Rewrite:**
   - Complete rewrite of `home_page.dart` dengan glass-morphism design system
   - 5 main sections: Hero Section, Progress Overview, Main Features Grid, Quick Stats, Community Preview
   - Consistent dengan ProfilePage glass-morphism aesthetic

2. **Hero Section:**
   - Date badge dengan glass container dan primary gradient
   - Personalized greeting dengan dynamic time-based greeting (Pagi/Siang/Sore/Malam)
   - Tagline app: "Bangun kebiasaan rohani, hidupi iman setiap hari"
   - Entry animation: Slide up + fade (Transform translate 30px)

3. **Progress Overview Card:**
   - Gradient primary card dengan progress bar dan ring indicator
   - Shows completed/total habits dengan percentage
   - CTA untuk navigate ke HabitTrackerPage
   - Real-time progress dari HabitBloc

4. **Main Features Grid:**
   - 2x2 grid dengan glass cards (BackdropFilter blur 12)
   - Features: Habit Tracker, Zoe Points, Community, Profile
   - Each card has icon container dengan brand color
   - Navigation ke respective routes (or coming soon snackbar)

5. **Quick Stats Grid:**
   - 2x2 grid dengan glass stat cards
   - Zoe Points, Streak, Level, Badge
   - Colored borders matching stat type (Tertiary coral, Primary teal, etc.)
   - Large typography (28px w800) untuk values

6. **Community Preview:**
   - Avatar stack showing 1.2k+ active users
   - Glass card dengan BackdropFilter blur 16
   - Description dan CTA button
   - Coming soon feedback

7. **Glass-Morphism Effects:**
   - `BackdropFilter` blur sigma 12-16 untuk cards
   - Gradient backgrounds dengan brand colors (Primary 6%, Tertiary 4%)
   - Border dengan outline alpha 12-20%
   - Soft shadows dengan color-tinted glow

8. **Navigation Update:**
   - Changed NavigationShellPage first tab dari RoutineRoute ke HomeRoute
   - Updated nav items label "Home" menjadi "Beranda"
   - Updated app_router.dart routing configuration
   - Regenerated auto_route files

**Files Modified:**

- `lib/features/home/presentation/pages/home_page.dart` (complete rewrite, ~600 lines)
- `lib/core/navigation/presentation/pages/navigation_shell_page.dart` (updated routes)
- `lib/core/router/app_router.dart` (updated nested routes)
- `lib/core/router/app_router.gr.dart` (auto-generated)

**Design Specifications:**

- **Glass Blur**: Cards sigma 12-16, Header subtle gradient
- **Border Radius**: 24-28px untuk cards, 20px untuk badges
- **Gradient**: Primary 6% + Surface + Tertiary 4% untuk background
- **Typography**: Display 36px w800, Title 22px w700, Body 15px
- **Animations**: Entry slide-up (30-70px translate), 1000ms duration
- **Spacing**: 20-24px horizontal padding, 16-32px vertical gaps

**Color Usage:**

- Primary (Deep Teal #2F5D62): Progress card, headers
- Tertiary (Coral #FF7B54): Zoe Points stats, accents
- Surface alpha 45-85%: Glass card backgrounds
- Outline alpha 12-20%: Subtle borders

**Impact:**

- HomePage sekarang adalah true landing page yang showcase fitur utama LiveIt
- Design konsisten dengan ProfilePage glass-morphism aesthetic
- Real-time habit progress integration dengan HabitBloc
- Navigation flow lebih intuitive: Home → Feature Details
- Glass-morphism cards create modern iOS 2026 look
- Semua feature cards memberikan feedback "Coming Soon" jika belum implement
- Floating Action Button untuk quick add habit (later replaced with inline button)
- Analyzer clean (no errors, deprecated warnings only)

---

## 2026-02-01 — Devotion & Article Detail Pages Glass-Morphism Refactor

**Context:**

- User requested refactor of DevotionPage and ArticleDetailPage to follow same glass-morphism style as HomePage
- Must maintain all existing functionality while improving UX with iOS 2026 aesthetic
- Consistent design language across all pages

**Choice:**

1. **DevotionPage Complete Rewrite:**
   - **Header Section**: Glass badge dengan tertiary gradient, bold title "Renungan" (36px w800), tagline subtitle
   - **Entry Animations**: Slide-up + fade (1000ms) untuk header dan content
   - **Loading State**: Centered glass card dengan progress indicator
   - **Error State**: Glass card dengan error icon, message, dan retry button
   - **Empty State**: Centered glass card dengan placeholder icon dan message
   - **Article Cards**: Glass cards (BackdropFilter blur 12), cover images, badges, dan read more CTA

2. **ArticleDetailPage Complete Rewrite:**
   - **Glass AppBar**: Gradient surface dengan back button dan title truncation
   - **Cover Image**: Full-width dengan gradient overlay
   - **Typography**: Bold hierarchy - title 28px w800, meta info dengan colored chips
   - **Quote Block**: Styled container untuk subtitle dengan italic text
   - **Meta Chips**: Date, reading time, author dengan brand colors
   - **Footer**: Glass container dengan branding dan publication info
   - **Loading/Error/NotFound States**: Glass cards dengan consistent styling

3. **Glass-Morphism Effects:**
   - `BackdropFilter` blur sigma 12-16 untuk cards dan overlays
   - Gradient surfaces dengan brand colors (primary 5-10%, tertiary 5-15%)
   - Subtle borders (outline alpha 10-20%)
   - Soft shadows dengan color-tinted glow

4. **Design Specifications:**
   - **Border Radius**: 24-28px untuk cards, 20px untuk badges
   - **Animations**: Entry slide-up (30-40px translate), 800-1000ms duration
   - **Typography**: Display 36px, Title 28px, Body 15px, Labels 12-14px
   - **Spacing**: 20-24px horizontal padding, 16-24px vertical gaps

5. **Removed:**
   - FloatingActionButton dari HomePage (diganti dengan inline button)
   - Old DevotionalCard widget import (not needed anymore)
   - Hardcoded Scaffold backgrounds (replaced with gradient containers)

**Files Modified:**

- `lib/features/inspire/presentation/pages/devotion_page.dart` (complete rewrite, ~550 lines)
- `lib/features/inspire/presentation/pages/article_detail_page.dart` (complete rewrite, ~500 lines)

**Design Features:**

- **Glass Cards**: BackdropFilter blur 12-16, gradient surfaces, subtle borders
- **Meta Chips**: Date (primary), Reading Time (tertiary), Author (secondary)
- **Quote Block**: Styled container untuk verse/subtitle
- **Animations**: Entry slide-up + fade, consistent across pages
- **AppBar**: Glass surface dengan gradient, consistent dengan page design

**Color Usage:**

- Primary (Deep Teal #2F5D62): Date badges, primary UI elements
- Tertiary (Coral #FF7B54): Reading time, quote blocks, accents
- Secondary (Warm Sand #C3B49A): Author chips
- Surface alpha 45-90%: Glass card backgrounds
- Outline alpha 10-20%: Subtle borders

**Impact:**

- DevotionPage now has consistent glass-morphism design dengan HomePage
- ArticleDetailPage provides premium reading experience dengan glass effects
- All loading/error/empty states use glass card styling
- Entry animations provide smooth user experience
- Code is cleaner dengan inline widgets (no separate DevotionalCard needed)
- Analyzer clean (no errors, no warnings)
- Ready untuk further enhancement (share feature, bookmark, etc.)

---

## 2026-02-16 — Implement offline check-in outbox (server-wins)

**Context:**

- Repo sudah punya hybrid cache + optimistic UI, tetapi write saat offline masih rollback langsung.
- User meminta implementasi berdasarkan `docs/skills/offline-first-data-flow.md` dan rencana di `docs/habit-tracker/implementation-offline-first-data-flow.md`.

**Choice:**

- Menambahkan arsitektur outbox minimal untuk mutation **check-in** dan **undo check-in** saja.
- Menggunakan strategi konflik **server-wins** saat replay (4xx dibuang dari antrian).
- Menambahkan service sinkronisasi berbasis konektivitas + trigger manual dari UI.

**Rationale:**

- Ini scope terkecil dengan dampak UX terbesar: aksi harian tetap terasa instan walau offline.
- Tidak memperluas ke add/update/archive/reorder agar tetap YAGNI dan risiko perubahan terkendali.

**Impact:**

- File baru:
  - `lib/core/connectivity/connectivity_service.dart`
  - `lib/features/habit_tracker/data/models/pending_mutation.dart`
  - `lib/features/habit_tracker/data/datasources/outbox_local_data_source.dart`
  - `lib/features/habit_tracker/data/services/habit_sync_service.dart`
  - `lib/features/habit_tracker/data/services/sync_status.dart`
  - `test/features/habit_tracker/data/datasources/outbox_local_data_source_test.dart`
  - `test/features/habit_tracker/data/services/habit_sync_service_test.dart`
  - `test/features/habit_tracker/presentation/bloc/habit_bloc_test.dart`
- File diubah:
  - `lib/core/injection/injection_container.dart`
  - `lib/features/habit_tracker/domain/repositories/habit_repository.dart`
  - `lib/features/habit_tracker/data/repositories/habit_repository_impl.dart`
  - `lib/features/habit_tracker/presentation/bloc/habit_event.dart`
  - `lib/features/habit_tracker/presentation/bloc/habit_state.dart`
  - `lib/features/habit_tracker/presentation/bloc/habit_bloc.dart`
  - `lib/features/habit_tracker/presentation/pages/habit_tracker_page.dart`
- Verifikasi:
  - 3 test suite baru lulus (`outbox_local_data_source_test`, `habit_sync_service_test`, `habit_bloc_test`).
  - `fvm flutter analyze` tetap menunjukkan warning/info lama lintas modul lain, tanpa error baru dari perubahan outbox.

---

## 2026-02-17 — Add SnackBar feedback for sync result

**Context:**

- Setelah outbox aktif, pengguna hanya melihat banner pending hilang saat sync berhasil, tanpa feedback eksplisit.
- User meminta feedback visual via `BlocListener`, terutama saat transisi `pendingSyncCount > 0 -> 0`.

**Choice:**

- Menambahkan SnackBar sukses di `HabitTrackerPage` saat listener mendeteksi transisi pending `> 0` ke `0`.
- Menambahkan feedback error sinkronisasi dari `HabitBloc` ke `HabitLoaded.syncFeedbackMessage`, lalu ditampilkan sebagai SnackBar error.

**Rationale:**

- Menjaga UX tetap sederhana: cukup satu sinyal sukses dan satu sinyal gagal tanpa menambah kompleksitas UI baru.

**Impact:**

- File diubah:
  - `lib/features/habit_tracker/presentation/pages/habit_tracker_page.dart`
  - `lib/features/habit_tracker/presentation/bloc/habit_event.dart`
  - `lib/features/habit_tracker/presentation/bloc/habit_state.dart`
  - `lib/features/habit_tracker/presentation/bloc/habit_bloc.dart`
- Verifikasi:
  - `fvm flutter test test/features/habit_tracker/presentation/bloc/habit_bloc_test.dart` lulus.
  - `fvm flutter test test/features/habit_tracker/data/services/habit_sync_service_test.dart` lulus.

---

## 2026-02-17 — Replace outbox mutation ID with UUID

**Context:**

- ID mutation sebelumnya memakai `DateTime.now().microsecondsSinceEpoch` yang punya risiko collision kecil pada enqueue cepat.

**Choice:**

- Mengganti generator ID mutation menjadi UUID v4 (`Uuid().v4()`).
- Menambahkan `uuid` sebagai dependency langsung di `pubspec.yaml`.

**Rationale:**

- UUID v4 jauh lebih aman terhadap collision dibanding timestamp saja, dengan perubahan kode minimal.

**Impact:**

- File diubah:
  - `lib/features/habit_tracker/data/repositories/habit_repository_impl.dart`
  - `pubspec.yaml`
- Dependency sync:
  - `fvm flutter pub get` berhasil (uuid berubah dari transitive ke direct dependency).
- Verifikasi:
  - `fvm flutter test test/features/habit_tracker/presentation/bloc/habit_bloc_test.dart` lulus.

---

## 2026-02-19 — AddHabitPage Glass-Morphism Refactor

**Context:**

- AddHabitPage masih menggunakan design Material default yang tidak konsisten dengan halaman lain (DevotionPage, HomePage, ProfilePage)
- UX issues: ExpansionTile yang clunky, color/icon picker terlalu kecil, tidak ada live preview, duplicate imports
- User request untuk refactor mengikuti style glass-morphism design system yang sudah ada

**Choice:**

1. **Complete UI Overhaul dengan Glass-Morphism:**
   - **Glass AppBar**: BackdropFilter blur σ=20 dengan gradient surface (surface alpha 0.8→0.4)
   - **Glass TabBar**: Segmented control style dengan blur σ=12, gradient active indicator dengan shadow
   - **Glass Cards**: Semua cards menggunakan BackdropFilter blur σ=12-16, border radius 20-24px
   - **Glass Form Inputs**: TextFormField tanpa outline border, dengan glass container styling

2. **UX Improvements:**
   - **Live Habit Preview Card**: Real-time preview saat user mengisi form custom habit
   - **Haptic Feedback**: `HapticFeedback.lightImpact()` pada semua interactions, `heavyImpact()` saat success
   - **Enhanced Pickers**: 
     - Color picker: 52px circles dengan glow shadow saat selected, checkmark icon
     - Icon picker: 56px circles dengan emoji shadow dan label
   - **Chip-based Selectors**: Replace dropdowns dengan horizontal chip buttons untuk repeat period dan frequency
   - **Day Picker**: Circular day selector (44px) dengan gradient fill saat selected

3. **Layout Restructure:**
   - Catalog tab: Glass cards dengan icon container (56px), info chips, dan FAB-style add button
   - Custom tab: Section-based layout (Preview → Form → Schedule → Personalization)
   - Advanced options: Expandable card dengan AnimatedRotation icon
   - Loading/Error/Empty states: Glass-morphism styled dengan proper feedback

4. **Animation System:**
   - Entry animations: Slide-up (30px) + fade dengan 800ms duration
   - Tab switch animations: AnimatedBuilder dengan Transform.translate
   - Smooth expand/collapse: AnimatedRotation untuk advanced toggle

5. **Code Quality:**
   - Remove duplicate imports (`auto_route` imported twice)
   - Remove unused `colorScheme` variable
   - Consistent method extraction: `_buildInfoChip`, `_buildSectionHeader`
   - Proper null-safety dan error handling

**Files Modified:**

- `lib/features/habit_tracker/presentation/pages/add_habit_page.dart` (complete rewrite, ~1100 lines)

**Design Specifications:**

- **Glass Blur**: σ=12-20 untuk cards, σ=8 untuk inputs
- **Border Radius**: 16px (inputs), 20px (small cards), 24px (large cards)
- **Typography**: w700-800 untuk headers, w600 untuk labels
- **Spacing**: 16-20px internal padding, 12-16px external margins
- **Shadows**: Primary-tinted glow (alpha 0.05-0.15) + soft elevation shadows
- **Active States**: Gradient fill dengan colored border dan glow shadow

**Bug Fix:**
- **Issue**: `LateInitializationError` - `_animationController` not initialized karena pakai `SingleTickerProviderStateMixin` untuk 2 controllers
- **Fix**: Ganti ke `TickerProviderStateMixin` (support multiple tickers untuk `_tabController` dan `_animationController`)
- **File**: `lib/features/habit_tracker/presentation/pages/add_habit_page.dart` line 19

**Acceptance Criteria:**

- [x] Glass AppBar dengan blur σ=20
- [x] Glass TabBar dengan segmented control style
- [x] Glass form cards dengan BackdropFilter
- [x] Live habit preview card
- [x] Haptic feedback pada semua interactions
- [x] Enhanced color picker dengan glow effect
- [x] Enhanced icon picker dengan labels
- [x] Chip-based selectors (replace dropdowns)
- [x] Entry animations (slide-up + fade)
- [x] Fix duplicate imports
- [x] dart analyze clean (no issues)

**Impact:**

- AddHabitPage sekarang konsisten dengan design system glass-morphism
- UX significantly improved dengan live preview dan tactile feedback
- Visual hierarchy lebih jelas dengan section grouping
- User engagement meningkat melalui interactive pickers dan animations
- Code quality improved dengan proper structure dan no analyzer issues

---

## 2026-02-20 — AddHabitPage Layout Cleanup & Modernization Pass 2

**Context:**

- User feedback dari visual QA: UI AddHabitPage masih terasa berantakan (spacing, ukuran komponen, hirarki visual belum rapih).
- Perlu refinement kedua tanpa menambah fitur baru, fokus pada layout quality dan readability.

**Choice:**

1. **Visual simplification (reduce noise):**
   - Menurunkan intensitas gradient/background tint agar halaman lebih calm dan tidak "ramai".
   - Menstandarkan glass card style ke satu helper (`_buildGlassCard`) untuk konsistensi radius, border, dan alpha.

2. **Layout & spacing normalization:**
   - Menyeragamkan horizontal padding jadi 16px di seluruh section.
   - Menurunkan vertical spacing yang terlalu longgar agar flow form lebih rapih.
   - Menata ulang Custom tab menjadi urutan jelas: Preview → Informasi Habit → Jadwal → Personalisasi → Submit.

3. **Input ergonomics improvement:**
   - Field forms dipindah ke satu card grup agar visual hierarchy jelas.
   - Input tinggi dan padding diperkecil (lebih proporsional di layar mobile kecil).
   - Border/fill dibuat lebih subtle agar fokus tetap ke isi form.

4. **Selector cleanup:**
   - Repeat/Frequency diganti ke style ChoiceChip yang konsisten dan compact.
   - Day picker gunakan FilterChip compact untuk konsistensi interaksi.
   - Color/Icon picker dipadatkan (tanpa label per item) + selected state yang jelas.

5. **Catalog tab readability:**
   - Card habit katalog dibuat lebih compact (icon/button lebih kecil, text density lebih rapi).
   - Pengaturan default diringkas dengan summary line + expandable advanced settings.

**Rationale:**

- Prinsip YAGNI: tidak menambah feature baru, hanya polishing layout/UX yang memang dipakai sekarang.
- Mengurangi cognitive load dengan struktur visual yang predictable.
- Menjaga konsistensi dengan halaman lain sambil meningkatkan kejelasan di screen mobile yang sempit.

**Impact:**

- File modified: `lib/features/habit_tracker/presentation/pages/add_habit_page.dart` (rewritten for cleaner structure).
- AddHabitPage sekarang lebih rapih, modern, dan mudah discan secara visual.
- Analyzer clean: `fvm flutter analyze lib/features/habit_tracker/presentation/pages/add_habit_page.dart` → no issues.

---

## 2026-02-20 — Floating Navigation Consistency (Home/Devotion vs Profile)

**Context:**

- User melaporkan bottom navigation pill terlihat kurang "hovering" pada HomePage dan DevotionPage dibanding ProfilePage.
- Goal: samakan feel floating navigation antar tab tanpa ubah arsitektur route.

**Choice:**

1. **Lift nav bar position globally:**
   - Update `_FloatingGlassNavBar` agar offset vertikal lebih floating: tambah top padding ringan dan bottom padding dinamis berbasis `MediaQuery.padding.bottom + 10`.
   - `SafeArea(bottom: false)` dipakai agar padding bawah dikontrol eksplisit oleh shell.

2. **Align page safe-area behavior with Profile:**
   - HomePage & DevotionPage diubah ke `SafeArea(bottom: false)` supaya konten/background extend ke area belakang nav.
   - Extra bottom spacer pada scroll ditambah dari `100` ke `124` agar konten tetap aman dari overlap nav.

**Rationale:**

- Floating effect bergantung pada visual separation + content continuity di belakang nav.
- Menyamakan treatment bottom area dengan ProfilePage membuat nav terasa detached/hovering secara konsisten.
- Perubahan minimal, tidak menyentuh logic navigasi atau state management.

**Impact:**

- Files modified:
  - `lib/core/navigation/presentation/pages/navigation_shell_page.dart`
  - `lib/features/home/presentation/pages/home_page.dart`
  - `lib/features/inspire/presentation/pages/devotion_page.dart`
- Nav pill sekarang punya hover feel yang lebih konsisten di Home, Devotion, dan Profile.
- Analyzer clean: `fvm flutter analyze` pada 3 file terkait → no issues.
