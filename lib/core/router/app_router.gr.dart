// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [DevotionPage]
class DevotionRoute extends PageRouteInfo<void> {
  const DevotionRoute({List<PageRouteInfo>? children})
    : super(DevotionRoute.name, initialChildren: children);

  static const String name = 'DevotionRoute';
/// [ClaimUsernamePage]
class ClaimUsernameRoute extends PageRouteInfo<void> {
  const ClaimUsernameRoute({List<PageRouteInfo>? children})
    : super(ClaimUsernameRoute.name, initialChildren: children);

  static const String name = 'ClaimUsernameRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DevotionPage();
    },
  );
}

/// generated route for
/// [HabitsPage]
class HabitsRoute extends PageRouteInfo<void> {
  const HabitsRoute({List<PageRouteInfo>? children})
    : super(HabitsRoute.name, initialChildren: children);

  static const String name = 'HabitsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HabitsPage();
      return const ClaimUsernamePage();
    },
  );
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginPage();
    },
  );
}

/// generated route for
/// [NavigationShellPage]
class NavigationShellRoute extends PageRouteInfo<void> {
  const NavigationShellRoute({List<PageRouteInfo>? children})
    : super(NavigationShellRoute.name, initialChildren: children);

  static const String name = 'NavigationShellRoute';
/// [RegisterPage]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NavigationShellPage();
    },
  );
}

/// generated route for
/// [ProfilePage]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfilePage();
    },
  );
}

/// generated route for
/// [RoutinePage]
class RoutineRoute extends PageRouteInfo<void> {
  const RoutineRoute({List<PageRouteInfo>? children})
    : super(RoutineRoute.name, initialChildren: children);

  static const String name = 'RoutineRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RoutinePage();
      return const RegisterPage();
    },
  );
}
