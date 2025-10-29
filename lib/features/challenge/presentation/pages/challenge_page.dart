import 'package:flutter/material.dart';

// @RoutePage() - Disabled, Challenge feature not used
class ChallengePage extends StatelessWidget {
  const ChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Challenge')),
      body: const Center(
        child: Text(
          'Challenge Page - Coming Soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
