import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/habit.dart';

part 'habit_model.g.dart';

@JsonSerializable()
class HabitModel extends Habit {
  const HabitModel({
    required super.id,
    required super.key,
    required super.name,
    super.description,
    super.category,
    super.isActive = true,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) =>
      _$HabitModelFromJson(json);

  Map<String, dynamic> toJson() => _$HabitModelToJson(this);

  factory HabitModel.fromEntity(Habit habit) {
    return HabitModel(
      id: habit.id,
      key: habit.key,
      name: habit.name,
      description: habit.description,
      category: habit.category,
      isActive: habit.isActive,
    );
  }
}
