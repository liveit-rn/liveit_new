import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_habit.dart';
import 'habit_model.dart';

part 'user_habit_model.g.dart';

List<int>? _fromJsonFrequencyDays(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.map((e) => e as int).toList();
  if (value is String) {
    final cleaned = value.replaceAll('[', '').replaceAll(']', '');
    if (cleaned.trim().isEmpty) return [];
    return cleaned.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
  }
  return null;
}

@JsonSerializable()
class UserHabitModel extends UserHabit {
  @JsonKey(fromJson: _fromJsonFrequencyDays)
  final List<int>? frequencyDays;

  final HabitModel? habit;

  const UserHabitModel({
    required super.id,
    super.userId,
    required super.habitId,
    super.notes,
    super.isCustom = false,
    super.title,
    super.visibility = 'public',
    super.reach = 'limited',
    super.repeatPeriod = 'forever',
    required super.repeatStartDate,
    super.repeatEndDate,
    super.frequency = 'daily',
    this.frequencyDays,
    super.currentStreak = 0,
    super.longestStreak = 0,
    super.totalCompletions = 0,
    super.color = '#6366F1',
    super.icon = '⭐',
    super.order = 0,
    super.checkedInToday = false,
    super.lastCheckinAt,
    this.habit,
  }) : super(frequencyDays: frequencyDays, habit: habit);

  factory UserHabitModel.fromJson(Map<String, dynamic> json) =>
      _$UserHabitModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserHabitModelToJson(this);
}
