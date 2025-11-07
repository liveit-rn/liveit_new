import 'package:auto_route/auto_route.dart';
import 'package:liveit_new/core/navigation/presentation/pages/navigation_shell_page.dart';
import 'package:liveit_new/features/auth/presentation/pages/login_page.dart';
import 'package:liveit_new/features/inspire/presentation/pages/devotion_page.dart';
import 'package:liveit_new/features/library/presentation/pages/habits_page.dart';
import 'package:liveit_new/features/profile/presentation/pages/profile_page.dart';
import 'package:liveit_new/features/auth/presentation/pages/register_page.dart';
import 'package:liveit_new/features/auth/presentation/pages/claim_username_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/routine_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: DevotionRoute.page, path: 'devotion'),
    // AutoRoute(page: HabitsRoute.page, path: 'habits'),
    // AutoRoute(page: ProfileRoute.page, path: 'profile'),
    AutoRoute(page: LoginRoute.page, path: '/', initial: true),
    AutoRoute(page: RegisterRoute.page, path: '/register'),
    AutoRoute(page: ClaimUsernameRoute.page, path: '/claim-username'),
    AutoRoute(page: HomeRoute.page, path: '/home'),
  ];
}
