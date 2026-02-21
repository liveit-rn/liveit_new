import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../../habit_tracker/presentation/pages/habit_tracker_page.dart';

@RoutePage()
class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HabitTrackerPage();
  }
}
