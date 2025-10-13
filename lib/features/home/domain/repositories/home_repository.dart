import 'package:liveit_new/features/home/presentation/models/home_ui_state.dart';

/// Contract for loading and mutating data that powers the homepage experience.
/// WHY: Allows UI/BLoC to remain decoupled from concrete data sources while we
/// stub behaviour locally for prototyping.
abstract class HomeRepository {
  /// Retrieves the latest homepage snapshot.
  Future<HomeUiState> fetchHome();

  /// Triggers a manual refresh. In a real implementation this would refetch
  /// remote data and merge offline cache.
  Future<HomeUiState> refresh();

  /// Persists a habit check-in for today and returns the updated snapshot.
  Future<HomeUiState> checkInHabit(String habitId);

  /// Reverts an accidental check-in for the given habit id.
  Future<HomeUiState> undoHabit(String habitId);

  /// Creates a habit derived from the devotional highlight.
  Future<HomeUiState> createHabitFromDevotional();
}
