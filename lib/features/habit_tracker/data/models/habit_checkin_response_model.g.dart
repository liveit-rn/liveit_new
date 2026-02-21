// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_checkin_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HabitCheckinResponseModel _$HabitCheckinResponseModelFromJson(
  Map<String, dynamic> json,
) => HabitCheckinResponseModel(
  success: json['success'] as bool,
  created: json['created'] as bool,
  currentStreak: (json['currentStreak'] as num).toInt(),
  longestStreak: (json['longestStreak'] as num).toInt(),
  totalCompletions: (json['totalCompletions'] as num).toInt(),
);

Map<String, dynamic> _$HabitCheckinResponseModelToJson(
  HabitCheckinResponseModel instance,
) => <String, dynamic>{
  'success': instance.success,
  'created': instance.created,
  'currentStreak': instance.currentStreak,
  'longestStreak': instance.longestStreak,
  'totalCompletions': instance.totalCompletions,
};
