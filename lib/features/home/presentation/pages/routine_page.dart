import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../habit_tracker/presentation/bloc/habit_bloc.dart';
import '../../../habit_tracker/presentation/bloc/habit_event.dart';
import 'home_page.dart';

@RoutePage()
class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HabitBloc>()..add(HabitStarted()),
      child: const HomePage(),
    );
  }
}
