# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

LIVEIT is a cross-platform Flutter application for Christian habit tracking, daily devotionals, and light social features. The app follows Clean Architecture with BLoC state management, targeting mobile (Android/iOS), web, and desktop platforms.

**Key characteristics:**
- Faith-based habit tracker with gamification (zoe points, streaks, badges)
- Daily devotional content with actionable micro-habits
- Small accountability groups and community features
- Backend: NestJS proxy to Appwrite (auth) and PostgreSQL (core data)

## Common Development Commands

### Setup & Dependencies
```bash
# Install dependencies
flutter pub get

# Code generation (auto_route, json_serializable, freezed)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation (recommended during development)
dart run build_runner watch --delete-conflicting-outputs
```

### Running the Application
```bash
# Run development build (loads .env.dev)
flutter run -t lib/main_dev.dart

# Run production build (loads .env.prod)
flutter run -t lib/main_prod.dart

# Run on web (Chrome)
flutter run -d chrome -t lib/main_dev.dart

# Run on specific platform for web preview (non-Chrome browsers)
flutter run -d web-server -t lib/main_dev.dart
# Then open the served URL manually in your preferred browser
```

### Building Artifacts
```bash
# Android development APK
flutter build apk -t lib/main_dev.dart

# Android production App Bundle (Play Store)
flutter build appbundle --release -t lib/main_prod.dart

# Android production APK (manual distribution)
flutter build apk --release -t lib/main_prod.dart

# iOS production (macOS only)
flutter build ios --release -t lib/main_prod.dart

# Web production
flutter build web -t lib/main_prod.dart
```

### Code Quality & Testing
```bash
# Static analysis
flutter analyze

# Format code
dart format .

# Run all tests
flutter test

# Run specific test file
flutter test test/home/presentation/bloc/home_bloc_test.dart
```

## Architecture & Code Organization

### Clean Architecture Layers

The codebase follows strict Clean Architecture with three layers per feature:

**Presentation Layer** (`lib/features/{feature}/presentation/`)
- **Widgets**: Composable UI components
- **Pages**: Route-level screens with `@RoutePage` annotation
- **BLoC**: State management (events, states, bloc)
  - Events: User actions (e.g., `AuthLoginRequested`)
  - States: UI states (e.g., `AuthLoading`, `AuthAuthenticated`, `AuthError`)
  - BLoC: Business logic coordinator between UI and domain

**Domain Layer** (`lib/features/{feature}/domain/`)
- **Entities**: Business models (pure Dart, no framework dependencies)
- **Repositories**: Abstract contracts (interfaces)
- **UseCases**: Single-responsibility business operations
  - Each use case handles one specific action
  - Called by BLoC, orchestrates repository calls

**Data Layer** (`lib/features/{feature}/data/`)
- **Models**: Data transfer objects with JSON serialization
- **DataSources**: Remote (API via Dio) and Local (secure storage)
- **Repositories**: Concrete implementations of domain contracts

### Core Systems (`lib/core/`)

- **config/**: Environment configuration via `flutter_dotenv`
  - `AppConfig.apiBaseUrl` — API base URL from `.env.dev` or `.env.prod`
- **router/**: Navigation using `auto_route` v10
  - `app_router.dart` — Route declarations with `@AutoRouterConfig`
  - After adding routes, run `dart run build_runner build --delete-conflicting-outputs`
- **theme/**: Centralized theming with FlexColorScheme
  - `app_theme.dart` — Light/dark themes based on brand colors
  - Semantic colors via ThemeExtension for success/warning/info
- **injection/**: Dependency injection with `get_it`
  - `injection_container.dart` — Registers all dependencies
  - Repositories, use cases, and BLoCs registered here
- **navigation/**: Bottom navigation shell
  - `NavigationShellPage` wraps main tabs (Routine, Inspire, Challenge, Library, Profile)
  - `NavigationBloc` manages tab state

### Feature Modules (`lib/features/`)

Current features:
- **auth**: Registration, login, OAuth placeholders, username claiming
- **home**: Daily summary, habit groups, devotional highlights (Routine tab content)
- **inspire**: Devotional content (placeholder)
- **challenge**: Community challenges (placeholder)
- **library**: Habit catalog and management (placeholder)
- **profile**: User profiles and settings (placeholder)

### State Management Pattern

All features use BLoC:
1. UI dispatches events to BLoC
2. BLoC calls use cases from domain layer
3. Use cases coordinate repository operations
4. BLoC emits new states based on results
5. UI rebuilds via `BlocBuilder` or `BlocListener`

**Example flow (Login):**
```
LoginPage → AuthLoginRequested event → AuthBloc
AuthBloc → LoginUseCase → AuthRepository
AuthRepository → AuthRemoteDataSource (API) + AuthLocalDataSource (storage)
AuthRepository → AuthBloc → AuthAuthenticated state → UI updates
```

### Routing Strategy

- Uses `auto_route` v10 with `@AutoRouterConfig`
- All pages annotated with `@RoutePage`
- Main shell uses `AutoTabsRouter` for bottom navigation
- Generated routes in `app_router.gr.dart` (never edit manually)
- Always use router for navigation: `context.router.push(RouteNameRoute())`

### Environment & Configuration

**Environment files:**
- `.env.dev` — Development environment (API: `https://liveit-api-dev-5jufu.ondigitalocean.app`)
- `.env.prod` — Production environment (configure before release)
- `.env.example` — Template for required variables

**Entry points:**
- `lib/main.dart` — Default (currently dev)
- `lib/main_dev.dart` — Development entry point
- `lib/main_prod.dart` — Production entry point

Each entry point loads its corresponding `.env` file via `flutter_dotenv` before initializing the app.

### Dependency Injection

Uses `get_it` for service locator pattern:
- Initialize in `main()` via `configureDependencies()`
- Register singletons for core services (Dio, FlutterSecureStorage)
- Register factories for BLoCs (new instance per screen)
- Access via `getIt<T>()` or inject into constructors

## Development Workflow

### Adding a New Feature

1. Create feature structure under `lib/features/{feature_name}/`:
   ```
   {feature_name}/
   ├── data/
   │   ├── datasources/
   │   ├── models/
   │   └── repositories/
   ├── domain/
   │   ├── entities/
   │   ├── repositories/
   │   └── usecases/
   └── presentation/
       ├── bloc/
       ├── pages/
       └── widgets/
   ```

2. Define domain entities and repository contracts
3. Implement data layer (models, datasources, repository implementation)
4. Create use cases for business operations
5. Build BLoC (events, states, bloc logic)
6. Create UI (pages with `@RoutePage`, widgets)
7. Register dependencies in `injection_container.dart`
8. Add routes to `app_router.dart` and run code generation
9. Write tests for BLoC and use cases

### Adding Routes

1. Create page with `@RoutePage` annotation:
   ```dart
   @RoutePage()
   class MyNewPage extends StatelessWidget { ... }
   ```

2. Add route to `app_router.dart`:
   ```dart
   AutoRoute(page: MyNewRoute.page, path: '/my-new-path')
   ```

3. Generate routes:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Navigate:
   ```dart
   context.router.push(MyNewRoute());
   ```

### Testing Strategy

- **Unit tests**: Domain logic, use cases, repository logic with mocked dependencies
- **BLoC tests**: Event → State transitions using `bloc_test` package
- **Widget tests**: UI components and user interactions
- **Integration tests**: Critical end-to-end flows (planned post-MVP)

Test structure mirrors `lib/` structure in `test/` directory.

### Working with BLoC

**Creating a new BLoC:**
1. Define events in `{feature}_event.dart` (extend Equatable)
2. Define states in `{feature}_state.dart` (extend Equatable)
3. Implement bloc in `{feature}_bloc.dart`:
   - Constructor injects use cases and dependencies
   - Register event handlers via `on<EventType>(_handler)`
   - Handlers emit states based on use case results
4. Add comprehensive logging for debugging
5. Register as factory in `injection_container.dart`

**Using BLoC in UI:**
```dart
BlocProvider(
  create: (context) => getIt<MyBloc>(),
  child: BlocBuilder<MyBloc, MyState>(
    builder: (context, state) {
      if (state is MyLoading) return LoadingWidget();
      if (state is MySuccess) return SuccessWidget(state.data);
      if (state is MyError) return ErrorWidget(state.message);
      return InitialWidget();
    },
  ),
)
```

### Code Generation

The project uses code generation for:
- **auto_route**: Route generation
- **json_serializable**: JSON serialization
- **freezed**: Immutable data classes (when added)

Always run `dart run build_runner build --delete-conflicting-outputs` after:
- Adding/modifying routes
- Adding/modifying models with JSON annotations
- Adding/modifying freezed classes

Use watch mode during active development:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Project-Specific Conventions

### Naming Conventions
- **Files**: snake_case (e.g., `auth_repository.dart`, `home_page.dart`)
- **Classes**: UpperCamelCase (e.g., `AuthRepository`, `HomePage`)
- **Variables/methods**: lowerCamelCase (e.g., `apiBaseUrl`, `getCurrentUser()`)
- **Constants**: lowerCamelCase with `const` or `final` (e.g., `const kDefaultPadding`)

### Widget Composition
- Keep widgets small and composable
- Extract reusable widgets to separate files in `widgets/` directory
- Use `const` constructors wherever possible for performance
- Prefer stateless widgets; use stateful only when necessary

### Logging
- Use `Logger` package for debug logging
- Add logging at critical points: BLoC events/states, API calls, error handling
- Log format: emoji prefix + descriptive message
  - 🔐 Auth operations
  - 📤 API requests
  - ✅ Success states
  - ❌ Errors with stack traces

### Error Handling
- Network errors: User-friendly messages with retry button
- Authentication errors: Redirect to login, clear stored credentials
- Validation errors: Show inline validation in forms
- Always emit specific error states from BLoC (not generic Exception)

### Environment Secrets
- Never commit sensitive data to version control
- Use `.env` files for base URLs and non-sensitive config
- Reference `.env.example` for required variables
- For sensitive keys, use CI/CD secrets or secure storage

## Documentation & Decision Tracking

### Required Documentation Files

When making significant changes, update these append-only logs:

**`decisions.md`** — Architecture and design decisions
Format:
```
YYYY-MM-DD | Context | Choice | Rationale | Impact
```

**`project-status.md`** — Current task tracking
Sections: Initial Ask, Initial Response, Checklist, Current Status, Next Steps

### Additional Documentation

- `docs/liveit-blueprint.md` — Product vision, features, MVP scope
- `docs/liveit-userStories.md` — User stories and acceptance criteria
- `docs/liveit-development-plan.md` — Technical implementation plan
- `docs/liveit-brand-essence.md` — Brand guidelines and design system
- `docs/setup.md` — Detailed setup and operational guide
- `AGENTS.md` — General repository guidelines (more detailed, agent-focused)

## Important Notes

### Backend Integration

The app communicates with a NestJS backend that acts as a proxy/facade to:
- **Appwrite**: Authentication services
- **PostgreSQL**: Core application data (managed via Prisma)

All API calls go through the NestJS backend, never directly to Appwrite. Base URL configured in `.env` files via `AppConfig.apiBaseUrl`.

### Multi-Entry Point Architecture

The project uses multiple entry points for environment separation:
- Each entry point loads its specific `.env` file
- Run with `-t` flag: `flutter run -t lib/main_dev.dart`
- Build with `-t` flag: `flutter build apk -t lib/main_prod.dart`

### Code Quality Standards

Before committing:
1. Run `dart format .` to format code
2. Run `flutter analyze` and fix all issues
3. Ensure tests pass: `flutter test`
4. Update relevant documentation if architecture/patterns changed

### Timezone Handling

Currently uses UTC for day boundaries. Timezone-aware boundaries planned for future iterations. When implementing, consider user timezone settings and day boundary calculations for check-ins and streaks.

### Bottom Navigation Structure

Main app uses nested navigation via `NavigationShellPage`:
- Tab switching managed by `NavigationBloc`
- Each tab can have its own navigation stack
- Tabs: Routine (home), Inspire (devotionals), Challenge, Library (habits), Profile

### Authentication Flow

1. App launches → `AuthCheckRequested` event → Check stored token
2. If authenticated → Navigate to home
3. If not authenticated → Show login/register
4. After registration → Check if username needed → Claim username flow
5. Store token via `flutter_secure_storage`
6. Logout clears token and navigation stack

### Gamification System

Points system:
- +10 per habit check-in
- +20 for completing all habits in a day
- +50 for 7-day streak
- +100 for 30-day streak

Levels based on accumulated points (defined in blueprint).

Badges: First Step, Week Warrior, Faithful Follower, Consistency Champion, Category Explorer, Daily Completer, Comeback Kid.

## Common Issues & Solutions

**Issue**: Routes not found after adding new route
**Solution**: Run `dart run build_runner build --delete-conflicting-outputs`

**Issue**: Environment variables not loading
**Solution**: Ensure `.env.dev`/`.env.prod` registered in `pubspec.yaml` assets, run `flutter clean` then `flutter pub get`

**Issue**: Dio/network errors
**Solution**: Check `AppConfig.apiBaseUrl` is correctly set, verify backend is running, check device/emulator network connectivity

**Issue**: BLoC not rebuilding UI
**Solution**: Ensure states extend Equatable and override props, use `BlocBuilder` or `BlocListener`, check event is being dispatched

**Issue**: Dependency injection errors
**Solution**: Ensure dependency registered in `injection_container.dart`, call `configureDependencies()` in `main()`, check for circular dependencies
