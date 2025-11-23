import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liveit_new/core/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:liveit_new/core/router/app_router.dart';

@RoutePage()
class NavigationShellPage extends StatelessWidget {
  const NavigationShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavigationBloc(),
      child: const _NavigationShellView(),
    );
  }
}

class _NavigationShellView extends StatelessWidget {
  const _NavigationShellView();

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        RoutineRoute(),
        DevotionRoute(),
        HabitsRoute(),
        ProfileRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        return BlocListener<NavigationBloc, NavigationState>(
          listener: (context, state) {
            tabsRouter.setActiveIndex(state.currentIndex);
          },
          child: Scaffold(
            body: child,
            bottomNavigationBar: BlocBuilder<NavigationBloc, NavigationState>(
              builder: (context, state) {
                return _buildBottomNavigationBar(
                  context,
                  state.currentIndex,
                  tabsRouter,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    int currentIndex,
    TabsRouter tabsRouter,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background for bottom nav
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2), // Subtle top border
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined, // ← Icon untuk tidak aktif
                activeIcon: Icons.home,
                label: 'Homepage',
                index: 0,
                currentIndex: currentIndex,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book,
                label: 'Devotion',
                index: 1,
                currentIndex: currentIndex,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.library_books_outlined,
                activeIcon: Icons.library_books,
                label: 'Habits',
                index: 2,
                currentIndex: currentIndex,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 3,
                currentIndex: currentIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
  }) {
    final isActive = currentIndex == index;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () {
          context.read<NavigationBloc>().add(NavigationTabChanged(index));
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withOpacity(0.5),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withOpacity(0.5),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              // Active indicator - underline
              Container(
                height: 2,
                width: 32,
                decoration: BoxDecoration(
                  color: isActive ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
