import 'package:equatable/equatable.dart';
import 'habit.dart';

class UserHabit extends Equatable {
  final String id;
  final String?
      userId; // Optional as sometimes we might just have the id or it's implied
  final String? habitId; // Nullable for custom habits (no catalog reference)
  final String? notes;
  final bool isCustom;
  final String? title;
  final String visibility;
  final String reach;
  final String repeatPeriod;
  final DateTime repeatStartDate;
  final DateTime? repeatEndDate;
  final String frequency;
  final List<int>? frequencyDays; // Assuming JSON array is parsed to List<int>
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final String color;
  final String icon;
  final int order;

  // Computed/Additional fields from API response
  final bool checkedInToday;
  final DateTime? lastCheckinAt;
  final Habit? habit; // Embedded habit details

  const UserHabit({
    required this.id,
    this.userId,
    this.habitId, // Now optional for custom habits
    this.notes,
    this.isCustom = false,
    this.title,
    this.visibility = 'public',
    this.reach = 'limited',
    this.repeatPeriod = 'forever',
    required this.repeatStartDate,
    this.repeatEndDate,
    this.frequency = 'daily',
    this.frequencyDays,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCompletions = 0,
    this.color = '#6366F1',
    this.icon = '⭐',
    this.order = 0,
    this.checkedInToday = false,
    this.lastCheckinAt,
    this.habit,
  });

  UserHabit copyWith({
    String? id,
    String? userId,
    String? habitId,
    String? notes,
    bool? isCustom,
    String? title,
    String? visibility,
    String? reach,
    String? repeatPeriod,
    DateTime? repeatStartDate,
    DateTime? repeatEndDate,
    String? frequency,
    List<int>? frequencyDays,
    int? currentStreak,
    int? longestStreak,
    int? totalCompletions,
    String? color,
    String? icon,
    int? order,
    bool? checkedInToday,
    DateTime? lastCheckinAt,
    Habit? habit,
  }) {
    return UserHabit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      notes: notes ?? this.notes,
      isCustom: isCustom ?? this.isCustom,
      title: title ?? this.title,
      visibility: visibility ?? this.visibility,
      reach: reach ?? this.reach,
      repeatPeriod: repeatPeriod ?? this.repeatPeriod,
      repeatStartDate: repeatStartDate ?? this.repeatStartDate,
      repeatEndDate: repeatEndDate ?? this.repeatEndDate,
      frequency: frequency ?? this.frequency,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      checkedInToday: checkedInToday ?? this.checkedInToday,
      lastCheckinAt: lastCheckinAt ?? this.lastCheckinAt,
      habit: habit ?? this.habit,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        habitId,
        notes,
        isCustom,
        title,
        visibility,
        reach,
        repeatPeriod,
        repeatStartDate,
        repeatEndDate,
        frequency,
        frequencyDays,
        currentStreak,
        longestStreak,
        totalCompletions,
        color,
        icon,
        order,
        checkedInToday,
        lastCheckinAt,
        habit,
      ];
}
