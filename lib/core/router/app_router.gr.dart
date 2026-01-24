// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AddHabitPage]
class AddHabitRoute extends PageRouteInfo<void> {
  const AddHabitRoute({List<PageRouteInfo>? children})
    : super(AddHabitRoute.name, initialChildren: children);

  static const String name = 'AddHabitRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AddHabitPage();
    },
  );
}

/// generated route for
/// [ArticleDetailPage]
class ArticleDetailRoute extends PageRouteInfo<ArticleDetailRouteArgs> {
  ArticleDetailRoute({
    required String slug,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         ArticleDetailRoute.name,
         args: ArticleDetailRouteArgs(slug: slug, key: key),
         rawPathParams: {'slug': slug},
         initialChildren: children,
       );

  static const String name = 'ArticleDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ArticleDetailRouteArgs>(
        orElse: () =>
            ArticleDetailRouteArgs(slug: pathParams.getString('slug')),
      );
      return ArticleDetailPage(slug: args.slug, key: args.key);
    },
  );
}

class ArticleDetailRouteArgs {
  const ArticleDetailRouteArgs({required this.slug, this.key});

  final String slug;

  final Key? key;

  @override
  String toString() {
    return 'ArticleDetailRouteArgs{slug: $slug, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ArticleDetailRouteArgs) return false;
    return slug == other.slug && key == other.key;
  }

  @override
  int get hashCode => slug.hashCode ^ key.hashCode;
}

/// generated route for
/// [ClaimUsernamePage]
class ClaimUsernameRoute extends PageRouteInfo<void> {
  const ClaimUsernameRoute({List<PageRouteInfo>? children})
    : super(ClaimUsernameRoute.name, initialChildren: children);

  static const String name = 'ClaimUsernameRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ClaimUsernamePage();
    },
  );
}

/// generated route for
/// [DevotionPage]
class DevotionRoute extends PageRouteInfo<void> {
  const DevotionRoute({List<PageRouteInfo>? children})
    : super(DevotionRoute.name, initialChildren: children);

  static const String name = 'DevotionRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DevotionPage();
    },
  );
}

/// generated route for
/// [EditHabitPage]
class EditHabitRoute extends PageRouteInfo<EditHabitRouteArgs> {
  EditHabitRoute({
    Key? key,
    required UserHabit userHabit,
    List<PageRouteInfo>? children,
  }) : super(
         EditHabitRoute.name,
         args: EditHabitRouteArgs(key: key, userHabit: userHabit),
         initialChildren: children,
       );

  static const String name = 'EditHabitRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditHabitRouteArgs>();
      return EditHabitPage(key: args.key, userHabit: args.userHabit);
    },
  );
}

class EditHabitRouteArgs {
  const EditHabitRouteArgs({this.key, required this.userHabit});

  final Key? key;

  final UserHabit userHabit;

  @override
  String toString() {
    return 'EditHabitRouteArgs{key: $key, userHabit: $userHabit}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditHabitRouteArgs) return false;
    return key == other.key && userHabit == other.userHabit;
  }

  @override
  int get hashCode => key.hashCode ^ userHabit.hashCode;
}

/// generated route for
/// [HabitStatsPage]
class HabitStatsRoute extends PageRouteInfo<HabitStatsRouteArgs> {
  HabitStatsRoute({
    Key? key,
    required UserHabit userHabit,
    List<PageRouteInfo>? children,
  }) : super(
         HabitStatsRoute.name,
         args: HabitStatsRouteArgs(key: key, userHabit: userHabit),
         initialChildren: children,
       );

  static const String name = 'HabitStatsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HabitStatsRouteArgs>();
      return HabitStatsPage(key: args.key, userHabit: args.userHabit);
    },
  );
}

class HabitStatsRouteArgs {
  const HabitStatsRouteArgs({this.key, required this.userHabit});

  final Key? key;

  final UserHabit userHabit;

  @override
  String toString() {
    return 'HabitStatsRouteArgs{key: $key, userHabit: $userHabit}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HabitStatsRouteArgs) return false;
    return key == other.key && userHabit == other.userHabit;
  }

  @override
  int get hashCode => key.hashCode ^ userHabit.hashCode;
}

/// generated route for
/// [HabitTrackerPage]
class HabitTrackerRoute extends PageRouteInfo<void> {
  const HabitTrackerRoute({List<PageRouteInfo>? children})
    : super(HabitTrackerRoute.name, initialChildren: children);

  static const String name = 'HabitTrackerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HabitTrackerPage();
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
/// [RegisterPage]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RegisterPage();
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
    },
  );
}
