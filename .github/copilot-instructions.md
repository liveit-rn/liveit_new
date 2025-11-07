# Copilot Instructions for liveit_new

## Core Context
- LIVEIT is a Flutter app (see docs/liveit-blueprint.md) with feature-first modules under `lib/features/*` and shared systems under `lib/core/*`.
- Entry points: `lib/main.dart` (default dev), `lib/main_dev.dart`, `lib/main_prod.dart`; each loads `.env.*` via `flutter_dotenv` before booting `AppRouter`.
- Track rationale in `decisions.md` and task flow in `project-status.md`; never rewrite history sections—append new entries only.

## Architecture & Patterns
- Follow presentation (widgets + Bloc), domain (contracts/models), and data (repositories) layering as shown in `lib/features/home/**/*`.
- State management uses Bloc (see `home_bloc.dart`); keep UI pure and drive side effects through events.
- Routes are declared in `core/router/app_router.dart` using `auto_route` v10. After changes run `dart run build_runner build --delete-conflicting-outputs` to refresh `app_router.gr.dart`.
- Theming centralised in `core/theme/app_theme.dart` using FlexColorScheme + Google Fonts aligned with docs/liveit-brand-essence.md.

## Data & Prototyping
- `InMemoryHomeRepository` provides optimistic UI flows for prototyping; real data layer should implement `HomeRepository` contract and honour the same method semantics.
- UI sample states live in `HomeUiState.sample()`; reuse or adjust via copyWith when mocking additional scenarios.
- When adding network calls, fetch base URLs through `AppConfig.apiBaseUrl` (dotenv wrapper) to keep env switching consistent.

## Testing & Tooling
- Unit and Bloc tests sit in `test/feature/...`; replicate patterns in `test/home/presentation/bloc/home_bloc_test.dart` for new blocs.
- Use `flutter test` for full runs or target files; keep waits aligned with artificial delays in repositories (~220ms currently).
- Run format/analyze before committing: `dart format .`, `flutter analyze` (rules defined in `analysis_options.yaml`).

## Developer Workflow Tips
- For web preview on non-Chrome browsers, run `flutter run -d web-server` then open the served URL manually (handy for Zen Browser).
- Keep widgets small and composable; mirror existing section cards under `lib/features/home/presentation/widget/` when expanding the homepage.
- Respect environment secrets: do not commit real keys; use `.env.example` to document expected variables.
- Update `AGENTS.md` if workflow expectations change so future agents stay aligned.
