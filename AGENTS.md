# Repository Guidelines (Flutter / Dart)

## Project structure & module organization

This repository is a Flutter app. Key top-level folders and their purposes:

- `lib/` — application source code (widgets, pages, models, services).
- `test/` — unit & widget tests.
- `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/` — platform-specific build wrappers and native code.
- `pubspec.yaml` — dependencies, assets, and package configuration.
- `analysis_options.yaml` — static analysis (lint rules) for Dart.
- `docs/` — feature briefs, API docs, user stories.

Organize `lib/` into feature modules (feature directories or `src/`), e.g. `lib/auth/`, `lib/profiles/`, `lib/habit_tracker/`. Keep UI, state management, and data layers clearly separated (presentation, domain, data).

## Build, test, and development commands

Use Flutter and Dart tooling:

- `flutter pub get` — install dependencies.
- `flutter run` — run on connected device or emulator.
- `flutter run -d chrome` — run on web.
- `flutter build apk` / `flutter build ios` / `flutter build web` — produce release artifacts.
- `flutter analyze` / `dart analyze` — static analysis.
- `dart format .` or `flutter format .` — format code with the Dart formatter.
- `flutter test` — run unit and widget tests.

Prefer using the Flutter tasks in your editor (VS Code/Android Studio) for quick iteration.

## Coding style & naming conventions

- Use Dart and null-safety idioms. Prefer immutability (`final`, `const`) where appropriate.
- Follow the Dart style guide and the project's `analysis_options.yaml` lints.
- File names: snake_case, e.g. `profiles_service.dart`, `habit_tracker_page.dart`.
- Class names and enum values: UpperCamelCase. Method and variable names: lowerCamelCase.
- Keep widgets small and composable. Prefer extracting widgets and methods rather than creating large build methods.
- Use `const` constructors and `const` widgets when possible for performance.

## State management and architecture

Pick a consistent approach across the app: Provider, Riverpod, BLoC, or another well-known pattern. Document the chosen pattern in `docs/` and keep a small `architecture.md` if necessary.

## Testing guidelines

- Unit tests: `test/` for pure Dart logic.
- Widget tests: render widgets in a test harness to verify UI behavior.
- Integration tests: use `integration_test/` with `flutter drive` or the newer integration_test harness.
- Keep tests fast and deterministic. Mock external services and use fakes for platform channels and HTTP.

## Commit & PR guidelines

DO NOT push secrets or environment-specific files. If this repository is used locally, follow the team policy about commit/PRs (the original guideline said avoid committing directly from the agent).

## Environment & secrets

- Keep secrets out of version control. Use `.env`-style files or CI secrets for API keys; do not commit them.
- Document how to set up local environment variables and device emulators in `docs/setup.md`.

## Core principles

- Small, testable units of work.
- Make the minimal change that solves the problem, then refactor.
- Prefer readability over clever tricks.

## Developer workflow & agent-specific addendum (decisions & project status)

To keep work traceable when an automated agent or developer makes changes, maintain the following append-only files at the repository root:

- `decisions.md` — append-only log of choices. Each entry should include: Date, Context, Choice, Rationale, Impact.
- `project-status.md` — running checklist for the current task/session with these sections: Initial Ask, Initial Response, Checklist, Current Status, Next Steps.

### Session flow for the agent

1. Read this `AGENTS.md` to align on repo style and constraints.
2. Ensure `decisions.md` exists; append new choices when making changes.
3. Ensure `project-status.md` exists; update the checklist and status.
4. Implement planned steps and append to `decisions.md` after significant choices.
5. Keep changes minimal and style-compliant.

### Idempotency & logging

- File creation/updates should be append-only (do not overwrite or remove historical entries from the status files).
- Log every significant decision that affects scope, structure, dependencies, or user-facing behavior.

### Auto-sync status (recommended)

- When you apply code or doc patches, add or remove files, or change behaviors, append an entry to `decisions.md` and update `project-status.md`.
- Before finishing a batch of changes, append the decision entry and refresh the Checklist and Current Status.

---

Notes:

- This `AGENTS.md` is tailored for a Flutter/Dart app. If you want a lightweight version that focuses only on CI/CD (Fastlane, Codemagic/Bitrise), testing strategy, or packaging guidelines (flavors, Firebase config), tell me which area to expand.

**If you provided backend-specific content originally (NestJS / Prisma), I preserved the agent workflow items (decisions.md, project-status.md) and adapted the technical sections to Flutter/Dart.**
