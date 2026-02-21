import 'package:json_annotation/json_annotation.dart';

part 'habit_checkin_response_model.g.dart';

@JsonSerializable()
class HabitCheckinResponseModel {
  final bool success;
  final bool created;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;

  const HabitCheckinResponseModel({
    required this.success,
    required this.created,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
  });

  factory HabitCheckinResponseModel.fromJson(Map<String, dynamic> json) =>
      _$HabitCheckinResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$HabitCheckinResponseModelToJson(this);
}
