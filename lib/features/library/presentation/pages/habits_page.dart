import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: Center(
        child: Text(
          'Habits Page - Coming Soon',
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
