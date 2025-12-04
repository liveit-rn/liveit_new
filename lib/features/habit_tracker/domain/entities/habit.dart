import 'package:equatable/equatable.dart';

class Habit extends Equatable {
  final String id;
  final String key;
  final String name;
  final String? description;
  final String? category;
  final bool isActive;

  const Habit({
    required this.id,
    required this.key,
    required this.name,
    this.description,
    this.category,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, key, name, description, category, isActive];
}
