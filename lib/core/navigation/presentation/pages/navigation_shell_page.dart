import 'dart:ui';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:liveit_new/core/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:liveit_new/core/router/app_router.dart';

@RoutePage()
class NavigationShellPage extends StatefulWidget {
  const NavigationShellPage({super.key});

  @override
  State<NavigationShellPage> createState() => _NavigationShellPageState();
}

class _NavigationShellPageState extends State<NavigationShellPage>
    with TickerProviderStateMixin {
  late final AnimationController _pillController;

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavigationBloc(),
      child: _NavigationShellView(pillController: _pillController),
    );
  }
}

class _NavigationShellView extends StatefulWidget {
  final AnimationController pillController;

  const _NavigationShellView({required this.pillController});

  @override
  State<_NavigationShellView> createState() => _NavigationShellViewState();
}

class _NavigationShellViewState extends State<_NavigationShellView> {
  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        HomeRoute(),
        DevotionRoute(),
        HabitsRoute(),
        ProfileRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) widget.pillController.forward();
        });

        return BlocListener<NavigationBloc, NavigationState>(
          listener: (context, state) {
            tabsRouter.setActiveIndex(state.currentIndex);
          },
          child: Scaffold(
            body: child,
            extendBody: true,
            bottomNavigationBar: _FloatingGlassNavBar(
              controller: widget.pillController,
              tabsRouter: tabsRouter,
            ),
          ),
        );
      },
    );
  }
}

class _FloatingGlassNavBar extends StatelessWidget {
  final AnimationController controller;
  final TabsRouter tabsRouter;

  const _FloatingGlassNavBar({
    required this.controller,
    required this.tabsRouter,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(top: 6, bottom: bottomInset + 10),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final value = controller.value;
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: _GlassPillNavigation(tabsRouter: tabsRouter),
        ),
      ),
    );
  }
}

class _GlassPillNavigation extends StatelessWidget {
  final TabsRouter tabsRouter;

  const _GlassPillNavigation({required this.tabsRouter});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final pillWidth = screenWidth - 32;

    final navItems = [
      _NavItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Beranda',
      ),
      _NavItemData(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: 'Devotion',
      ),
      _NavItemData(
        icon: Icons.library_books_outlined,
        activeIcon: Icons.library_books_rounded,
        label: 'Habits',
      ),
      _NavItemData(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 56,
          width: pillWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            // Gradient border effect
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.15),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(1), // 1px gradient border
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.65),
                        colorScheme.surfaceContainerHigh
                            .withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: navItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Expanded(
                        child: _GlassNavItem(
                          item: item,
                          index: index,
                          currentIndex: state.currentIndex,
                          onTap: () {
                            context.read<NavigationBloc>().add(
                                  NavigationTabChanged(index),
                                );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _GlassNavItem extends StatelessWidget {
  final _NavItemData item;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _GlassNavItem({
    required this.item,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: colorScheme.primary.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            isActive ? item.activeIcon : item.icon,
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 22,
            shadows: isActive
                ? [
                    Shadow(
                      color: colorScheme.primary.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    ).animate(target: isActive ? 1 : 0).scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.0, 1.0),
          duration: 250.ms,
          curve: Curves.easeOutBack,
        );
  }
}
