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

## Coding Patterns
- Preferred patterns and practices: 
- Code organization preferences: 
- Testing approaches: 
- Documentation style: 

## Context7 Research History
- Libraries researched on Context7: General Flutter/mobile homepage search (no specific library results available); auto_route v10 installation & setup
- Best practices discovered: No new guidance available from initial homepage search; auto_route recommends using `routerConfig: _appRouter.config()` with generated RootStackRouter, `@AutoRouterConfig`, and part files
- Implementation patterns used: n/a
- Version-specific findings: auto_route v10.1.2 exposes config-based API via generated `RootStackRouter.config()`; dependencies require `auto_route`, `auto_route_generator`, `build_runner`

## Conversation History
- Important decisions made: Identified homepage must highlight habit checklist, devotional teaser, gamification progress per MVP docs; menambahkan Epic Homepage Experience ke dokumen user stories
- Recurring questions atau topik: Homepage experience requirements, integrasi dengan habit tracker, renungan, dan gamifikasi
- Solutions yang berhasil: Mensintesis dokumen feature untuk menyusun user stories baru dengan acceptance criteria detail
- Hal yang perlu dihindari atau tidak berhasil: Context7 search tidak menemukan library relevan

## Notes
- Homepage Experience epic dengan user stories 14-18 telah ditambahkan ke `docs/liveit-userStories.md` (ringkasan harian, daftar habit, renungan, gamifikasi, empty/error state)
- `.env` root sekarang menyimpan `API_BASE_URL` mengarah ke backend dev DigitalOcean untuk di-load via `flutter_dotenv`
