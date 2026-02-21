// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_habit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserHabitModel _$UserHabitModelFromJson(Map<String, dynamic> json) =>
    UserHabitModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      habitId: json['habitId'] as String?,
      notes: json['notes'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
      title: json['title'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      reach: json['reach'] as String? ?? 'limited',
      repeatPeriod: json['repeatPeriod'] as String? ?? 'forever',
      repeatStartDate: DateTime.parse(json['repeatStartDate'] as String),
      repeatEndDate: json['repeatEndDate'] == null
          ? null
          : DateTime.parse(json['repeatEndDate'] as String),
      frequency: json['frequency'] as String? ?? 'daily',
      frequencyDays: _fromJsonFrequencyDays(json['frequencyDays']),
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      totalCompletions: (json['totalCompletions'] as num?)?.toInt() ?? 0,
      color: json['color'] as String? ?? '#6366F1',
      icon: json['icon'] as String? ?? '⭐',
      order: (json['order'] as num?)?.toInt() ?? 0,
      checkedInToday: json['checkedInToday'] as bool? ?? false,
      lastCheckinAt: json['lastCheckinAt'] == null
          ? null
          : DateTime.parse(json['lastCheckinAt'] as String),
      habit: json['habit'] == null
          ? null
          : HabitModel.fromJson(json['habit'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserHabitModelToJson(UserHabitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'habitId': instance.habitId,
      'notes': instance.notes,
      'isCustom': instance.isCustom,
      'title': instance.title,
      'visibility': instance.visibility,
      'reach': instance.reach,
      'repeatPeriod': instance.repeatPeriod,
      'repeatStartDate': instance.repeatStartDate.toIso8601String(),
      'repeatEndDate': instance.repeatEndDate?.toIso8601String(),
      'frequency': instance.frequency,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'totalCompletions': instance.totalCompletions,
      'color': instance.color,
      'icon': instance.icon,
      'order': instance.order,
      'checkedInToday': instance.checkedInToday,
      'lastCheckinAt': instance.lastCheckinAt?.toIso8601String(),
      'frequencyDays': instance.frequencyDays,
      'habit': instance.habit,
    };
