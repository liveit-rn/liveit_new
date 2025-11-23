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

---

2025-11-09 | Bottom Navigation Theme Compliance | Replaced hardcoded colors with theme-based colorScheme values to align with centralized theming strategy | Current implementation used hardcoded black background and white icons, violating theming guidelines in AGENTS.md and .github/copilot-instructions.md | Bottom nav now uses `colorScheme.surface` for background, `colorScheme.primary` for active items, and `colorScheme.onSurfaceVariant` for inactive items; ensures brand consistency, supports light/dark modes, and follows Material Design 3 principles as defined in core/theme/app_theme.dart

Files Modified:
- lib/core/navigation/presentation/pages/navigation_shell_page.dart

Details:
- Background: `Color.fromARGB(255, 0, 0, 0)` → `colorScheme.surface`
- Active icons/text: `Colors.white` → `colorScheme.primary`
- Inactive icons/text: `Colors.white.withOpacity(0.6)` → `colorScheme.onSurfaceVariant.withOpacity(0.6)`

Impact:
- Compliant with centralized theming guidelines
- Automatically adapts to theme changes
- Better accessibility and brand consistency

---

2025-11-09 | Profile Page Redesign | Redesigned profile header with horizontal layout (large circular photo left, name/username/bio right stacked vertically), updated background to light gray, added top border to bottom nav for better separation | User requested prominent profile card with left photo and right text stack, bio field, better bottom nav visibility, and edit icon consistency | Profile header now features 112px circular avatar on left with enlarged name (22px bold uppercase), username, and bio text stacked on right; background changed from dark brown to light gray (#F5F5F5); bottom nav has white background with subtle top border for clear separation; edit icon already uses pencil (Icons.edit_outlined); all cards remain white for consistency

Files Modified:
- lib/features/profile/presentation/pages/profile_page.dart
- lib/core/navigation/presentation/pages/navigation_shell_page.dart

Details:
- Profile header: Changed from vertical centered layout to horizontal Row layout
- Avatar radius: 48 → 56 (larger and more prominent)
- Name styling: Added bold, uppercase, 22px font size
- Added bio field with italic placeholder text
- Card padding: 20 → 24 for better spacing
- Background: Color.fromARGB(255, 97, 81, 81) → Color(0xFFF5F5F5)
- Bottom nav: Added top border with outline color at 20% opacity
- Bottom nav background: Explicit white color for contrast

Impact:
- Profile card is now more dominant and visually appealing
- Better use of horizontal space with side-by-side layout
- Bio field allows for personalization
- Clearer visual hierarchy with larger, bolder name
- Bottom navigation now clearly separated from main content
- Improved contrast and readability with lighter background


---

2025-11-09 | Profile Page UI Improvements | Multiple UI refinements to Profile page following user requirements | User requested 5 specific tasks to improve profile aesthetics and usability | Changed background from red to light gray (#F9F9F9), changed bottom nav background to red with white icons/text, removed email field from profile header for privacy, added tooltip icon next to "Zoe Points" label, ensured logout button maintains red error color for visibility

Files Modified:
- lib/features/profile/presentation/pages/profile_page.dart
- lib/core/navigation/presentation/pages/navigation_shell_page.dart

Details:
1. Scaffold background changed to Color(0xFFF9F9F9) for cleaner look
2. Bottom navigation bar now has red background with white icons/labels
3. Email field removed from _ProfileHeader widget
4. Added optional showTooltip parameter to _StatItem with help icon for Zoe Points
5. Logout icon and text explicitly use colorScheme.error to maintain red accent

Impact:
- Improved visual hierarchy and contrast
- Better privacy by hiding email in public-facing profile view
- Added educational tooltip for gamification terms
- Bottom nav now uses brand primary color (red) consistently


---

## 2025-11-09 — Comprehensive Homepage UI/UX Enhancement

Context:
- User provided screenshot of homepage and requested professional UI/UX analysis
- Agent identified 7 priority improvements across contrast, typography, animations, and visual feedback
- Changes needed to align with Material Design 3 principles and brand guidelines

Choice:
- Implemented all 7 UI/UX improvements systematically:
  1. **Bottom Nav Active Indicator**: Added 2px primary color underline below active tab text with height 2 container
  2. **Hero Card Readability**: Increased inner box opacity from 0.2 to 0.28, padding from 16 to 18 for better contrast against red gradient
  3. **Stat Chip Typography**: Enlarged icon to 22px, value to 28px w800, subtitle to 12px w500, increased padding to 12h/8v
  4. **Animated Checkboxes**: Replaced static green checkboxes with tertiary color (coral #FF7B54) using 280ms easeOutBack animation, 32px size with Icons.check_rounded
  5. **Ripple Effects**: Wrapped habit items in InkWell with splashColor (primary 10% opacity) and highlightColor (primary 5% opacity)
  6. **Typography Refinement**: Increased habit title to w800 22px with -0.5 letter-spacing, header greeting to 20px w800 -0.3 spacing
  7. **Subtle Dividers**: Added left-aligned dividers (60px indent) between habit items with outline color at 12% opacity

Files Modified:
- lib/core/navigation/presentation/pages/navigation_shell_page.dart
- lib/features/home/presentation/pages/home_page.dart

Details:

**navigation_shell_page.dart**:
- Added active indicator: Container with height 2, primary color, positioned below tab text
- Improved visual feedback for selected tab with underline pattern
- Maintained ripple effects with InkWell for all nav items

**home_page.dart**:
- Hero card inner box: opacity 0.2 → 0.28, padding 16 → 18
- Stat chips: icon size 18 → 22, value font size default → 28px w800, label 11 → 12 w500, padding 10h/6v → 12h/8v
- Checkbox: color Colors.green → colorScheme.tertiary, added AnimatedContainer with 280ms Curves.easeOutBack, size 28 → 32, icon check → check_rounded
- Habit items: wrapped in InkWell with splashColor and highlightColor for tactile feedback
- Habit title: fontSize default → 22, fontWeight w700 → w800, letterSpacing → -0.5
- Header greeting: fontSize default titleMedium → 20px titleLarge, fontWeight w700 → w800, letterSpacing → -0.3
- Added celebratory badge coloring: completion badge uses tertiary color when all habits done
- Dividers: Added Padding(left: 60) with Divider using outline color at 12% opacity between habit items

Rationale:
- **Active Indicator**: Users need clear visual cue for current tab; underline pattern is Material Design 3 standard
- **Hero Card Readability**: Text contrast ratio was below WCAG guidelines; increased opacity improves legibility without losing gradient aesthetic
- **Stat Chips**: Larger typography creates better visual hierarchy and makes key metrics scannable
- **Animated Checkboxes**: Tertiary coral color (#FF7B54) provides brand-aligned celebratory accent; animation adds polish and feedback
- **Ripple Effects**: Tactile feedback essential for mobile UX; InkWell provides native Material Design interaction patterns
- **Typography**: Larger, bolder text with tighter letter-spacing improves readability and creates stronger visual hierarchy aligned with brand personality
- **Dividers**: Subtle separation improves scannability without adding visual clutter; left alignment creates flow aligned with text, not checkbox

Impact:
- Homepage now meets professional UI/UX standards with improved contrast, hierarchy, and feedback
- All changes use theme colorScheme (primary, tertiary, outline) for maintainability and theme consistency
- Animations follow Material Design motion guidelines (280ms easeOutBack curve)
- Typography improvements enhance readability on mobile devices
- Brand colors (Deep Teal primary, Coral tertiary) are reinforced through strategic use
- User feedback mechanisms (ripples, animations) improve perceived responsiveness
- All improvements tested in running app without errors
- Future UI work should follow these patterns: theme-based colors, meaningful animations, clear visual hierarchy

Typography Specifications:
- Header Greeting: 20px, FontWeight.w800, letterSpacing: -0.3
- Habit Title: 22px, FontWeight.w800, letterSpacing: -0.5
- Stat Value: 28px, FontWeight.w800
- Stat Label: 12px, FontWeight.w500
- Icon Sizes: Nav 24px, Stat 22px, Checkbox 32px

Animation Specifications:
- Checkbox: 280ms, Curves.easeOutBack
- Ripple: splashColor at 10% opacity, highlightColor at 5% opacity

Color Usage:
- Primary (#2F5D62 Deep Teal): Active nav, ripples, dividers
- Tertiary (#FF7B54 Coral): Completed checkboxes, 100% completion badge
- Outline: Dividers at 12% opacity
- Surface/Background: #F5F5F5 light gray


---

## 2025-11-16 — Profile Page UI/UX Enhancement

Context:
- User requested UI/UX analysis and improvements for Profile page similar to homepage enhancements
- Agent identified 7 priority improvements across header, stats, menu, and interactive elements
- Changes needed to improve hierarchy, contrast, and visual feedback following Material Design 3

Choice:
- Implemented all 7 UI/UX improvements systematically:
  1. **Avatar & Header Enhancement**: Reduced avatar from 56→48 radius, increased username to 15px w600, display name to w800 with -0.2 letter-spacing, improved bio contrast (alpha 0.7)
  2. **Stats Card Typography**: Enlarged stat values to 28px w800 with -0.5 letter-spacing, icon size to 24px, label to 12px w500, improved spacing (vertical 20, horizontal 12)
  3. **Stats Card Elevation**: Added elevation 1 with subtle border (outline alpha 0.08) for depth, rounded corners 12px
  4. **Menu Items Enhancement**: Increased icon size to 22px, font weight to 600, added theme-based colors for better contrast
  5. **Menu Ripple Effects**: Added splashColor (primary alpha 0.08) to all menu items for tactile feedback
  6. **Logout Button Background**: Added subtle red background (error alpha 0.06) with rounded bottom corners, increased ripple (error alpha 0.12)
  7. **Dividers Consistency**: Updated all dividers to use outline color with alpha 0.12 for subtle separation

Files Modified:
- lib/features/profile/presentation/pages/profile_page.dart

Details:

**_ProfileHeader Widget**:
- Avatar radius: 56 → 48 (better proportion)
- Display name: fontSize 22 → 20, fontWeight bold → w800, letterSpacing -0.2
- Username: fontSize default → 15, fontWeight w500 → w600
- Bio: color onSurfaceVariant.withOpacity(0.8) → onSurface.withValues(alpha: 0.7), fontSize → 13
- Spacing adjustments: height 8→6 after name, 12→10 after username

**_StatsCard Widget**:
- Added elevation: 1 for subtle shadow
- Added border: RoundedRectangleBorder with outline alpha 0.08
- Padding: symmetric vertical 20, horizontal 12 (was all 20)
- Border radius: 12px for modern look

**_StatItem Widget**:
- Icon size: 28 → 24 (consistency)
- Value fontSize: default → 28, fontWeight bold → w800, letterSpacing -0.5
- Label fontSize: default → 12, fontWeight → w500
- Spacing: icon-to-value 8→10, value-to-label 4→6

**_MenuSection Widget**:
- All icons: size 22, color onSurface (theme-based)
- All titles: fontWeight w600 for prominence
- Chevrons: color onSurfaceVariant (subtle)
- Ripple: splashColor primary alpha 0.08 for all menu items
- Dividers: outline color alpha 0.12 for consistency
- Logout container: error alpha 0.06 background, rounded bottom corners (12px)
- Logout ripple: error alpha 0.12 (stronger than other items)

Rationale:
- **Avatar Reduction**: Smaller avatar creates better visual balance and doesn't overwhelm the header
- **Typography Hierarchy**: Bolder weights (w800, w600) and strategic sizing create clear information hierarchy
- **Bio Contrast**: Changed from onSurfaceVariant to onSurface with alpha 0.7 meets WCAG contrast requirements
- **Stats Card Depth**: Subtle elevation and border create visual separation without heavy shadows
- **Larger Stat Values**: 28px size makes key metrics immediately scannable on mobile
- **Menu Improvements**: Larger icons (22px) and bolder text (w600) improve readability and tap target clarity
- **Ripple Effects**: Tactile feedback essential for mobile UX; primary color reinforces brand consistency
- **Logout Emphasis**: Subtle background warns users about destructive action without being alarming
- **Consistent Dividers**: Outline color at 12% opacity creates subtle separation aligned with Material Design 3

Impact:
- Profile page now has professional UI/UX with improved hierarchy and readability
- All changes use theme colorScheme for maintainability (primary, error, outline, onSurface)
- Typography improvements enhance scannability especially for stats (28px w800)
- Interactive feedback (ripples) improves perceived responsiveness
- Visual depth (elevation, borders) creates modern layered UI
- Brand consistency maintained through strategic color usage
- All improvements tested without errors
- Future profile work should follow these patterns: balanced spacing, bold typography for key info, subtle backgrounds for emphasis

Typography Specifications (Profile):
- Display Name: 20px, FontWeight.w800, letterSpacing: -0.2
- Username: 15px, FontWeight.w600
- Bio: 13px, onSurface alpha 0.7, italic
- Stat Value: 28px, FontWeight.w800, letterSpacing: -0.5
- Stat Label: 12px, FontWeight.w500
- Menu Items: bodyLarge, FontWeight.w600
- Icon Sizes: Menu 22px, Stats 24px, Chevron default

Color Specifications (Profile):
- Header Avatar: primaryContainer background
- Stats Icons: tertiary (Zoe Points), primary (Level), secondary (Bergabung)
- Menu Icons: onSurface
- Chevrons: onSurfaceVariant
- Logout: error with alpha 0.06 background, alpha 0.12 ripple
- Dividers: outline at alpha 0.12
- Card Borders: outline at alpha 0.08

Elevation & Depth:
- Stats Card: elevation 1, border outline alpha 0.08, borderRadius 12
- All Cards: default Material elevation with subtle shadows


```

