---
applyTo: '**'
---

# User Memory

## User Preferences
- Programming languages: 
- Code style preferences: 
- Development environment: 
- Communication style: 

## Project Context
- Current project type: Flutter mobile app with supporting docs for MVP
- Tech stack: Flutter front-end, NestJS + Appwrite backend, PostgreSQL, Next.js landing page (from blueprint)
- Architecture patterns: Feature-based modules, backend facade proxying to Appwrite, habit tracker core loop
- Key requirements: Support habit tracking, daily devotionals, gamification, safe community moderation
- Current focus: Homepage experience implementing daily summary, habit groups, devotionals, and gamification highlights

## Coding Patterns
- Preferred patterns and practices: 
- Code organization preferences: 
- Testing approaches: 
- Documentation style: 

## Context7 Research History
- Libraries researched on Context7: General Flutter homepage layout search (no specific entries returned); auto_route v10 installation & setup
- Best practices discovered: Context7 search results for Flutter layout returned empty grid (likely JS gated); auto_route recommends using `routerConfig: _appRouter.config()` with generated RootStackRouter, `@AutoRouterConfig`, and part files
- Implementation patterns used: n/a
- Version-specific findings: auto_route v10.1.2 exposes config-based API via generated `RootStackRouter.config()`; dependencies require `auto_route`, `auto_route_generator`, `build_runner`
- Notes: Attempts to source updated Flutter dashboard layout guidance returned landing page only; fallback to internal brand/user story docs for layout decisions

## Conversation History
- Important decisions made: Identified homepage must highlight habit checklist, devotional teaser, gamification progress per MVP docs; menambahkan Epic Homepage Experience ke dokumen user stories
- Recurring questions atau topik: Homepage experience requirements, integrasi dengan habit tracker, renungan, dan gamifikasi
- Solutions yang berhasil: Mensintesis dokumen feature untuk menyusun user stories baru dengan acceptance criteria detail
- Hal yang perlu dihindari atau tidak berhasil: Context7 search tidak menemukan library relevan
- Recent progress: Implemented homepage UI components (daily summary, habit groups, devotional card, gamification card, empty/error banners) with mocked state for prototyping

## Notes
- Homepage Experience epic dengan user stories 14-18 telah ditambahkan ke `docs/liveit-userStories.md` (ringkasan harian, daftar habit, renungan, gamifikasi, empty/error state)
- `.env` root sekarang menyimpan `API_BASE_URL` mengarah ke backend dev DigitalOcean untuk di-load via `flutter_dotenv`
- Research 2025-10-12: Referenced Flutter official layout guide (`https://docs.flutter.dev/development/ui/layout`) for dashboard composition and layout widget best practices.
- Codebase review 2025-10-12: Inspected `lib/features/home/presentation/pages/home_page.dart` (placeholder), `lib/core/theme/app_theme.dart`, and `docs/liveit-brand-essence.md` to plan homepage layout implementation.
