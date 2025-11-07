import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:liveit_new/features/home/presentation/pages/home_page.dart';

@RoutePage()
class RoutinePage extends StatelessWidget {
  const RoutinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
