# Flutter Integration Guide & Gap Analysis

**Version:** 1.0
**Last Updated:** November 2024
**Target Audience:** Mobile Developers (Flutter)

This document provides a comprehensive guide for integrating the Flutter application with the LiveIT NestJS backend. It highlights architectural patterns, critical implementation details, and identifies current gaps that need to be addressed for a smooth mobile experience.

---

## 1. Architecture Overview

The LiveIT platform uses a **Proxy/Facade Pattern**. The NestJS backend acts as the single source of truth and gateway for the mobile application.

### Key Principles

- **No Direct Appwrite Access:** The Flutter app **should not** initialize the Appwrite Client directly for Authentication. It must not hold Appwrite API Keys.
- **Single Endpoint:** All data interactions (Auth, Habits, Profiles) go through the NestJS REST API.
- **Authentication:** The backend issues its own JWT (NestJS-signed) after verifying credentials with Appwrite server-side.

---

## 2. Authentication Implementation

### The Flow

1.  **Login:** Flutter sends `POST /auth/login` with `{email, password}`.
2.  **Verification:** Backend validates against Appwrite (Server-side).
3.  **Token:** Backend returns a **NestJS JWT** (`access_token`).
4.  **Session:** Flutter stores this token safely and attaches it to all subsequent requests.

### Flutter Implementation Checklist

- [ ] **Secure Storage:** Use `flutter_secure_storage` to save the `access_token`. **DO NOT** use `SharedPreferences` for tokens.
- [ ] **HTTP Client:** Use `Dio` with an Interceptor to automatically inject `Authorization: Bearer <token>` headers.
- [ ] **Token Expiry:** The token expires in 1 day. Handle `401 Unauthorized` responses by redirecting the user to the Login screen (Auto-refresh logic is not currently implemented in backend).
- [ ] **Google Auth:**
  - Use `GET /auth/google/start` which redirects to Google.
  - **Deep Linking:** The final callback will be a deep link (e.g., `liveit://auth/callback?code=...`).
  - **Exchange:** Call `POST /auth/oauth/exchange` with the code to get the final JWT.

### ⚠️ Critical Gap: Appwrite Session

The backend verifies the user but **does not** return an Appwrite Session to the client.

- **Impact:** The Flutter app cannot use Appwrite SDK features (Realtime, Storage, Account) directly.
- **Resolution:** All features must be exposed via NestJS endpoints.

---

## 3. Feature: Profiles & Image Uploads

### Current State

The `ProfilesController` allows updating profile fields (`name`, `bio`), but relies on passing a `profileImageId`.

### ⚠️ Implementation Difficulty: Image Uploads

- **Problem:** To get a `profileImageId`, the image must be uploaded to Appwrite Storage. Since the Flutter app has no Appwrite Session, it **cannot** upload directly to Appwrite without exposing sensitive API Keys (which is forbidden).
- **Resolution:** **[COMPLETED]** Proxy endpoint `POST /profiles/upload/avatar` implemented.
  - Send `multipart/form-data` with field `file`.
  - Returns `{ fileId, viewUrl }`.
  - Use the `fileId` to update profile.

---

## 4. Feature: Habit Tracker (Offline-First)

### Data Sync Strategy

Habit tracking requires high availability. Users expect to check in even when offline.

- **Local Database:** Use **Isar** or **Hive** to mirror the `Habit` and `UserHabit` models locally.
- **Flow:**
  1.  **App Start:** Fetch `GET /habits` (User Habits) and `GET /habits/stats/today`.
  2.  **Cache:** Overwrite local DB with server data.
  3.  **Action:** User taps "Check-in".
  4.  **Optimistic UI:** Immediately show "Done" state and play animation. Update local DB.
  5.  **Background Sync:** Send `POST /habits/:id/checkin` to server.
      - _If success:_ Update local data with response (might contain new streaks/points).
      - _If fail (Offline):_ Queue the request and retry when connection is restored.

### ⚠️ Timezone Challenge

- **Current Backend:** Uses `startOfUtcDay()` (UTC midnight).
- **Problem:** A user in Jakarta (UTC+7) checking in at 01:00 AM is checking in for "Today". A user in New York (UTC-5) checking in at 11:00 PM is checking in for "Today" (local), but it might be "Tomorrow" in UTC.
- **Resolution:** **[COMPLETED]** The `POST /habits/:id/checkin` endpoint now accepts an optional `date` field (YYYY-MM-DD).
  - **Flutter Logic:** Send `{ "date": "2024-11-24" }` (Local Date) in the body.
  - **Backend Logic:** Validates date is within +/- 36h of server time, then uses _that date_ for streak/daily calculations.

---

## 5. Feature: Gamification & Feedback

- **Feedback Loop:** The `POST /checkin` endpoint handles point calculations.
- **UI Response:** The response should include `streak`, `pointsEarned`, and potentially `newLevel` or `achievementsUnlocked`.
- **Flutter:** Parse the response to trigger gamification overlays (e.g., "Level Up!" modal) immediately after a successful sync.

---

## 6. Security & Performance

### Security

- **Obfuscation:** Use `flutter_obfuscate` when building release APKs/IPAs.
- **SSL Pinning:** Consider implementing SSL Pinning for the NestJS API domain to prevent Man-in-the-Middle attacks.
- **No Secrets:** Never commit `.env` files or API Keys to the Flutter repo.

### Performance

- **Image Caching:** Use `cached_network_image` for rendering profile pictures and habit icons.
- **Lazy Loading:** The `GET /habits` endpoint might grow. If users have hundreds of history items, ensure pagination is implemented (currently not visible in `listUserHabits`, likely returns all active).
- **Minimizing Calls:** Call `GET /profiles/me/summary` for the home screen instead of fetching full profile + full habit list if not needed.

---

## 7. Summary of Required Backend Adjustments

To fully support the Flutter implementation, the backend needs:

1.  **Image Proxy Endpoint:** To handle avatar uploads securely.
2.  **Timezone Handling:** To ensure check-ins respect local days.
3.  **Pagination:** For long lists (Habit History/Logs) if planned.

## 8. Suggested Flutter Tech Stack

- **State Management:** Bloc.
- **Network:** Dio + Retrofit.
- **Local DB:** Isar (for high performance queries).
- **Routing:** AutoRoute.
- **UI:** Flutter Animate (for Gamification effects).
