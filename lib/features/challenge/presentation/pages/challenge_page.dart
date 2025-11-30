import 'package:flutter/material.dart';

// @RoutePage() - Disabled, Challenge feature not used
class ChallengePage extends StatelessWidget {
  const ChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Challenge')),
      body: Center(
        child: Text(
          'Challenge Page - Coming Soon',
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
