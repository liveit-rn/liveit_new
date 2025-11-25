# Project Analysis & Development Roadmap

**Status:** DRAFT
**Generated:** November 24, 2025
**Based on:** `flutter_integration_fromBackend_guide.md` & Current Codebase Analysis

This document provides a comprehensive analysis of the current state of the LIVEIT Flutter project and a step-by-step roadmap to align it with the backend requirements.

---

## 1. Executive Summary

The codebase has a solid foundation with the **Auth feature** being the most mature. The core networking setup (`DioClient` with Interceptors) is correctly implemented. However, there are significant gaps in **feature completeness** (Profile, Habits), **offline support** (Isar/Hive), and **Google Authentication**.

**Compliance Scorecard:**
- ✅ **Network Architecture:** High (Dio + Interceptors in place)
- ⚠️ **Authentication:** Medium (Basic Email/Pass works; Google Auth deferred)
- ❌ **Profile:** Low (Incorrect endpoint usage; Missing Image Upload Proxy)
- ❌ **Habit Tracker:** Missing (No offline sync, no timezone logic)
- ❌ **Local Database:** Missing (Isar/Hive dependencies present but not implemented)

---

## 2. Gap Analysis

### 2.1 Authentication Gaps
- **Google Auth:** The backend requires a specific flow: `GET /auth/google/start` -> Deep Link -> `POST /auth/oauth/exchange`. **(Status: DEFERRED per user request)**.
- **Token Handling:** `FlutterSecureStorage` is correctly used in `DioClient`, which is good.

### 2.2 Profile Feature Gaps
- **Image Upload:** The backend forbids direct Appwrite access. You must use the proxy endpoint `POST /profiles/upload/avatar`.
- **Current Implementation:** `ProfileRemoteDataSource` has an `updateAvatar` method that takes a string `avatarUrl`, assuming the upload happens elsewhere. This is incorrect. It needs a method to *upload* the file first to get that URL/ID.

### 2.3 Habit Tracker (The "Hard" Part)
- **Offline-First:** The guide mandates an offline-first approach using a local DB (Isar). This is currently non-existent in the codebase.
- **Timezones:** The backend needs the local date (`YYYY-MM-DD`) sent with check-ins.

---

## 3. Detailed Roadmap

Since you are learning Flutter, this roadmap is designed to build difficulty progressively.

### Phase 1: The Profile Feature (Estimated: 2-3 Days)

**Goal:** Practice "Proxy Pattern" file uploads and fix existing Profile implementation.

1.  **Fix `ProfileRemoteDataSource`:**
    *   Add `Future<String> uploadAvatar(File imageFile)` method.
    *   Implement `FormData` with `Dio` to hit `POST /profiles/upload/avatar`.
    *   Update `updateAvatar` logic to use the returned `fileId` or `viewUrl`.
2.  **UI Implementation:**
    *   Use `image_picker` package to select a photo.
    *   Call the new upload method in your Bloc.

### Phase 2: The Habit Tracker (Estimated: 4-6 Days)

**Goal:** Master Offline-First Architecture (The most complex part).

1.  **Database Setup:**
    *   Initialize **Isar**. Create collections: `HabitCollection`, `CheckInCollection`.
2.  **Sync Logic (The "Repository" Pattern):**
    *   Create `HabitRepository`.
    *   **Fetch:** Try fetching from Remote -> Save to Local -> Return Local.
    *   **Check-in:** Save to Local (mark "synced: false") -> Return "Success" to UI immediately (Optimistic) -> Try sending to Remote in background.
3.  **Timezone Handling:**
    *   When sending a check-in, always include: ` "date": DateTime.now().toIso8601String().substring(0, 10) `.

### Phase 3: Polish & Gamification

1.  **Gamification Response:** Update Check-in response parsing to look for `pointsEarned` and show a snackbar/dialog.

### Deferred: Google Authentication
*   Skipped for now. Will be revisited later.

---

## 4. Codebase Feedback & Recommendations

### `lib/core/network/dio_client.dart`
- **Verdict:** ✅ **Excellent.** You have `AuthInterceptor` and `FlutterSecureStorage` wired up correctly.
- **Note:** Ensure `AuthInterceptor` handles the `401 Unauthorized` case by triggering a logout (eventually via a stream or callback to the Bloc).

### `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- **Verdict:** ⚠️ **Good start, but incomplete.**
- **Issue:** It uses `AppConfig.apiBaseUrl` but `DioClient` already sets a `baseUrl`. You might be doubling up (e.g., `http://api.com/http://api.com/auth`).
- **Fix:** Use `dio.post('/auth/login')` instead of full URL if `DioClient` is configured with BaseURL.

### `lib/features/profile/.../profile_remote_datasource.dart`
- **Verdict:** ❌ **Incorrect approach.**
- **Issue:** `updateAvatar(String avatarUrl)` implies you already have the URL.
- **Fix:** You need a `uploadAvatar(File file)` method that hits the proxy endpoint.

## 5. Next Steps for You

1.  **Read this document carefully.**
2.  **Pick Phase 1 (Google Auth) OR Phase 2 (Profile Upload)** to start. Profile might be easier to debug visually.
3.  **Do not write code for Habits yet.** It requires a proper DB setup first.
