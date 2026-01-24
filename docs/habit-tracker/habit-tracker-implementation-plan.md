# Habit Tracker Implementation Plan - Flutter

**Created:** 2026-01-21
**Source of Truth:** Backend docs at `C:\Users\Kevin\liveit-server\docs\liveit-habitTracker-feature.md`
**Current Status:** Flutter MVP (~30%) | Backend Phase 2A Complete (100%)

---

## Overview

This implementation plan aligns Flutter Habit Tracker with Backend Phase 2A specification. The backend provides comprehensive features including repeat periods, frequency control, streak tracking, visual customization, and custom ordering. Flutter currently implements only basic CRUD and needs to be upgraded to support all Phase 2A features.

**Backend Phase 2A Features:**
- Repeat Period: 1_day, 1_week, 1_month, 1_year, forever
- Frequency: daily, weekly, custom days
- Streak Tracking: currentStreak, longestStreak, totalCompletions
- Visual Customization: color (hex), icon (emoji)
- Custom Ordering: order field for drag & drop
- Custom Habits: reach limited, visibility public/private
- Gamification: Points earned, streak milestones

---

## Implementation Phases

### Phase 1: Data Layer Phase 2A Support
**Goal:** Complete data models, datasources, and repositories to support all Phase 2A fields.

#### 1.1 Update Domain Layer
- [ ] Review and update `UserHabit` entity to ensure all Phase 2A fields are present
- [ ] Verify `HabitCheckinResponseModel` has streak fields (currentStreak, longestStreak, totalCompletions)
- [ ] Add enums for RepeatPeriod, Frequency, Visibility, Reach if not present

#### 1.2 Update Data Models
- [ ] Verify `UserHabitModel.fromJson` handles all Phase 2A fields correctly
- [ ] Ensure `frequencyDays` JSON parsing works (string "[1,2,3]" to List<int>)
- [ ] Verify color hex validation in models if needed
- [ ] Run `dart run build_runner build` to regenerate `.g.dart` files

#### 1.3 Update Datasource Layer (`HabitRemoteDataSource`)
- [ ] Update `addHabit()` method signature:
  ```dart
  Future<UserHabitModel> addHabit({
    required String habitId,
    String? notes,
    String? repeatPeriod,
    String? frequency,
    String? frequencyDays,
    String? color,
    String? icon,
    int? order,
  })
  ```
- [ ] Update `createCustomHabit()` method signature:
  ```dart
  Future<UserHabitModel> createCustomHabit({
    required String title,
    String? description,
    String? notes,
    String? repeatPeriod,
    String? frequency,
    String? frequencyDays,
    String? color,
    String? icon,
    int? order,
  })
  ```
- [ ] Add `updateHabit()` method:
  ```dart
  Future<UserHabitModel> updateHabit(String userHabitId, {
    String? notes,
    String? repeatPeriod,
    String? frequency,
    String? frequencyDays,
    String? color,
    String? icon,
    int? order,
  })
  ```
- [ ] Add `deleteHabit()` method:
  ```dart
  Future<void> deleteHabit(String userHabitId)
  ```
- [ ] Add `reorderHabits()` method:
  ```dart
  Future<void> reorderHabits(List<Map<String, dynamic>> updates)
  ```

#### 1.4 Update Repository Layer (`HabitRepository`)
- [ ] Update `addHabit()` interface to match datasource signature
- [ ] Update `createCustomHabit()` interface to match datasource signature
- [ ] Add `updateHabit()` to interface
- [ ] Add `deleteHabit()` to interface
- [ ] Add `reorderHabits()` to interface
- [ ] Update `HabitRepositoryImpl` to implement all new methods

#### 1.5 Dependency Injection
- [ ] Verify `service_locator.dart` has correct bindings for updated repository

---

### Phase 2: State Management Phase 2A Support
**Goal:** Update BLoC to handle all Phase 2A operations.

#### 2.1 Update Events (`HabitEvent`)
- [ ] Add `HabitUpdated` event with all updatable fields
- [ ] Add `HabitArchived` event
- [ ] Add `HabitReordered` event
- [ ] Update `HabitAdded` event to include Phase 2A fields
- [ ] Update `CustomHabitCreated` event to include Phase 2A fields

#### 2.2 Update States (`HabitState`)
- [ ] Verify `HabitLoaded` contains full `UserHabit` entities with Phase 2A fields
- [ ] Add optimistic loading states if needed (e.g., `HabitReordering`)

#### 2.3 Update BLoC (`HabitBloc`)
- [ ] Register new event handlers (HabitUpdated, HabitArchived, HabitReordered)
- [ ] Update `onHabitCheckInRequested` to parse and show streak info from response
- [ ] Update `onHabitAdded` to handle Phase 2A fields
- [ ] Update `onCustomHabitCreated` to handle Phase 2A fields
- [ ] Implement `onHabitUpdated` handler
- [ ] Implement `onHabitArchived` handler
- [ ] Implement `onHabitReordered` handler

#### 2.4 Error Handling
- [ ] Add specific error handling for frequency validation (check-in on non-active day)
- [ ] Add specific error handling for invalid color format
- [ ] Add user-friendly error messages for all scenarios

---

### Phase 3: UI Layer - Basic Phase 2A
**Goal:** Update existing UI components to display Phase 2A data and allow basic customization.

#### 3.1 Update HabitCard
- [ ] Display color indicator (colored dot or border) using `color` field
- [ ] Display icon using `icon` field
- [ ] Display repeat period badge (e.g., "Forever", "1 Month")
- [ ] Display frequency badge (e.g., "Daily", "Weekdays")
- [ ] Show longestStreak in stats section (tap to expand?)
- [ ] Show totalCompletions in stats section
- [ ] Add delete/archive action button (icon or menu)
- [ ] Add edit action button

#### 3.2 Update AddHabitPage - Catalog Tab
- [ ] Add optional form fields for Phase 2A configuration
  - Repeat Period dropdown (Forever, 1 Day, 1 Week, 1 Month, 1 Year)
  - Frequency dropdown (Daily, Weekly, Custom)
  - Custom Days picker (if Frequency = Custom) - checkboxes for Sun-Sat
  - Color picker (preset colors or hex input)
  - Icon picker (preset emojis)
  - Order input (auto-incremented by default)
- [ ] Show/hide advanced options toggle (to keep UI clean)
- [ ] Add validation for Phase 2A fields

#### 3.3 Update AddHabitPage - Custom Tab
- [ ] Add same Phase 2A form fields as catalog tab
- [ ] Keep title, description, notes fields
- [ ] Add preview section showing how habit will look

#### 3.4 Update HabitTrackerPage
- [ ] Add refresh button (pull-to-refresh already exists, verify it works)
- [ ] Add progress summary (e.g., "3/5 completed today")
- [ ] Add empty state illustration for no habits

---

### Phase 4: UI Layer - Advanced Features
**Goal:** Implement edit, reorder, archive, and advanced visual feedback.

#### 4.1 Create EditHabitPage
- [ ] Create page at `lib/features/habit_tracker/presentation/pages/edit_habit_page.dart`
- [ ] Pre-fill form with existing habit data
- [ ] Allow editing all Phase 2A fields
- [ ] Add save button
- [ ] Add cancel button
- [ ] Add route in `app_router.dart`
- [ ] Add navigation from HabitCard

#### 4.2 Implement Drag & Drop Reordering
- [ ] Add drag & drop library if needed (e.g., `flutter_reorderable_list`)
- [ ] Implement reorderable list in HabitTrackerPage
- [ ] Update BLoC to send reorder events after drag completes
- [ ] Persist new order to backend

#### 4.3 Implement Archive/Delete
- [ ] Add confirmation dialog for archive action
- [ ] Update HabitCard to show archive button
- [ ] Add undo option after archive (snackbar with "Undo")
- [ ] Handle archive success/error in BLoC

#### 4.4 Gamification Visual Feedback
- [ ] Create celebration animation for check-in (confetti or streak flame)
- [ ] Show streak milestone popup (e.g., "7-Day Warrior! 🎉")
- [ ] Display points earned after check-in (e.g., "+10 ZP")
- [ ] Show progress bar for daily completion
- [ ] Create streak badge widget (display in HabitCard or separate section)

#### 4.5 Habit Statistics View
- [ ] Create HabitStatsPage to show:
  - Current streak vs longest streak chart
  - Weekly completion rate
  - Monthly completion rate
  - Total completions history
  - Best day of week
- [ ] Add route and navigation
- [ ] Add stats button in HabitTrackerPage

---

### Phase 5: Polish & Optimization
**Goal:** Improve UX, performance, and error handling.

#### 5.1 Offline Support (Optional - Per PROJECT_ANALYSIS.md)
- [ ] Set up Isar or Hive for local storage
- [ ] Implement local-first strategy for check-ins
- [ ] Sync pending check-ins when connection restored
- [ ] Show "Offline" indicator

#### 5.2 Animations & Transitions
- [ ] Add page transition animations
- [ ] Add check-in animation (checkbox scale + flame)
- [ ] Add swipe actions (delete/edit)
- [ ] Add loading skeletons for better perceived performance

#### 5.3 Accessibility
- [ ] Add semantic labels for all buttons
- [ ] Ensure color contrast meets WCAG AA
- [ ] Add screen reader support for streak counters
- [ ] Test with screen reader

#### 5.4 Error States
- [ ] Improve error messages to be user-friendly
- [ ] Add retry buttons for failed operations
- [ ] Handle network timeout gracefully
- [ ] Show specific error for frequency validation

#### 5.5 Performance
- [ ] Optimize list rendering (use const widgets where possible)
- [ ] Implement lazy loading for large habit lists (pagination if needed)
- [ ] Add image caching for avatars/icons
- [ ] Profile and reduce unnecessary rebuilds

---

### Phase 6: Testing
**Goal:** Ensure reliability with comprehensive test coverage.

#### 6.1 Unit Tests
- [ ] Test UserHabitModel JSON parsing
- [ ] Test HabitCheckinResponseModel parsing
- [ ] Test datasource methods (mock DioClient)
- [ ] Test repository methods
- [ ] Test BLoC event handlers
- [ ] Test BLoC state transitions

#### 6.2 Widget Tests
- [ ] Test HabitCard rendering with various states
- [ ] Test HabitTrackerPage loading/error/empty states
- [ ] Test AddHabitPage form validation
- [ ] Test EditHabitPage pre-filling
- [ ] Test check-in toggle behavior

#### 6.3 Integration Tests
- [ ] Test full flow: Add habit → Check-in → View stats
- [ ] Test custom habit creation
- [ ] Test habit archiving
- [ ] Test reorder persistence
- [ ] Test gamification feedback display

---

## Implementation Order Recommendation

**Suggested sequence:**

1. **Start with Phase 1** (Data Layer) - This is the foundation
   - Do 1.1 → 1.2 → 1.3 → 1.4 → 1.5 in order

2. **Then Phase 2** (State Management)
   - Do 2.1 → 2.2 → 2.3 → 2.4

3. **Then Phase 3** (Basic UI)
   - Start with 3.1 (HabitCard) as it's the most visible
   - Then 3.2 and 3.3 (AddHabitPage)
   - Then 3.4 (HabitTrackerPage)

4. **Then Phase 4.1-4.3** (Edit, Reorder, Archive)
   - These are core features users expect

5. **Then Phase 4.4** (Gamification)
   - This adds delight and engagement

6. **Then Phase 4.5** (Stats)
   - Nice to have but not critical for MVP

7. **Then Phase 5** (Polish)
   - Do this when core features work

8. **Finally Phase 6** (Testing)
   - Write tests as you implement, not all at the end

---

## Current Progress Tracking

### Overall Progress
- [ ] Phase 1: Data Layer Phase 2A Support (0/20 tasks)
- [ ] Phase 2: State Management Phase 2A Support (0/12 tasks)
- [ ] Phase 3: UI Layer - Basic Phase 2A (0/12 tasks)
- [ ] Phase 4: UI Layer - Advanced Features (0/23 tasks)
- [ ] Phase 5: Polish & Optimization (0/19 tasks)
- [ ] Phase 6: Testing (0/15 tasks)

**Total: 101 tasks | 0 completed | 101 remaining**

---

## Notes

1. **Backend is Source of Truth**: Always reference `C:\Users\Kevin\liveit-server\docs\liveit-habitTracker-feature.md` for field specifications and API contracts.

2. **YAGNI Principle**: Don't over-engineer. Implement only what's documented in Phase 2A. Save advanced features for Phase 2B.

3. **Incremental Updates**: Work on one layer at a time (Data → State → UI) to avoid confusion.

4. **Update Status Files**: After completing each phase, update `project-status.md` and append decisions to `decisions.md`.

5. **Code Review**: Review each phase with backend team to ensure alignment before moving to next phase.

---

## References

- Backend Spec: `C:\Users\Kevin\liveit-server\docs\liveit-habitTracker-feature.md`
- Backend Analysis: `C:\Users\Kevin\liveit-server\docs\habit-tracker\habit-tracker-implementation-analysis.md`
- Flutter Docs: `docs/liveit-habbitTracker-feature.md` (may be outdated)
- Project Analysis: `docs/PROJECT_ANALYSIS_AND_ROADMAP.md`
- Decisions Log: `decisions.md`
- Project Status: `project-status.md`
