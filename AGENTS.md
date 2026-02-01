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
add 'fvm' because we are using it for version management, so if you want to run flutter commands, you should use 'fvm flutter' instead of just 'flutter'.
- `fvm flutter pub get` — install dependencies.
- `fvm flutter run` — run on connected device or emulator.
- `fvm flutter run -d chrome` — run on web.
- `fvm flutter build apk` / `fvm flutter build ios` / `fvm flutter build web` — produce release artifacts.
- `fvm flutter analyze` / `dart analyze` — static analysis.
- `dart format .` or `flutter format .` — format code with the Dart formatter.
- `fvm flutter test` — run unit and widget tests.

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

## Development flow:

- One feature → verify → refactor
- Comment the WHY, not the what
- Commit each working thought (updates to strict consistency files)
- Not working? Stash/revert
- Readable > optimized (prematurely)
- Meaningful error logging
- Review every change
- REMOVE DEADCODE

## Agent Workflow Addendum: Decisions & Status Files

To ensure reliable context and traceable progress, maintain the following files at the repository root. This process is idempotent and append-only.

- decisions.md
  - Purpose: Append-only log of choices made during work.
  - Format per entry: Date, Context, Choice, Rationale, Impact.
  - Policy: Do not rewrite or remove entries; append new entries at the end.

- project-status.md
  - Purpose: Consolidate the initial ask, initial response, and a running Checklist that serves as the single TODO list.
  - Sections: Initial Ask, Initial Response, Checklist, Current Status, Next Steps.
  - Policy: Keep the Checklist current; mark items with `[ ]` or `[x]`.

### Step-by-Step Flow (each task/session)

1. Read this AGENTS.md to align on scope, style, and constraints.
2. Ensure `decisions.md` exists; append any new choices with Date, Context, Choice, Rationale, Impact.
3. Ensure `project-status.md` exists; update the Checklist (add/check items) and Current Status.
4. Implement planned steps; after each significant choice, append to `decisions.md` and sync the Checklist.
5. Keep changes minimal and style-compliant; do not commit/PR per guidelines.

### TODO List Policy

- Treat `project-status.md` → Checklist as the single source of truth for TODOs.
- Represent tasks with `- [ ]` and mark completion with `- [x]`.
- Update the Checklist at the end of each working session.

### Idempotency & logging

- File creation/updates should be append-only (do not overwrite or remove historical entries from the status files).
- Log every significant decision that affects scope, structure, dependencies, or user-facing behavior.

### Auto‑Sync Status (Mandatory)

- Always update `decisions.md` and `project-status.md` proactively without user prompts whenever you:
  - Apply code/doc patches, add/remove files, or change behaviors.
  - Make architecture/config/infrastructure choices (e.g., enable rate limits, add modules, adjust envs).
  - Finalize a mini‑milestone (feature, spec, deployment prep, costs).
- Sync cadence:
  - Before yielding control after a batch of changes, append a decisions entry and refresh the Checklist, Current Status, and Next Steps.
  - If a change is reverted, append a new decision explaining the rollback.
- Format discipline:
  - `decisions.md` is append‑only (Date, Context, Choice, Rationale, Impact).
  - `project-status.md` uses `[x]/[ ]` checklist and keeps descriptions concise and action‑oriented.

---

Notes:

- This `AGENTS.md` is tailored for a Flutter/Dart app. If you want a lightweight version that focuses only on CI/CD (Fastlane, Codemagic/Bitrise), testing strategy, or packaging guidelines (flavors, Firebase config), tell me which area to expand.

**If you provided backend-specific content originally (NestJS / Prisma), I preserved the agent workflow items (decisions.md, project-status.md) and adapted the technical sections to Flutter/Dart.**
