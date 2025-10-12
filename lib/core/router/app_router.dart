import 'package:auto_route/auto_route.dart';
import 'package:liveit_new/features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, path: '/home', initial: false),
    AutoRoute(page: LoginRoute.page, path: '/'),
  ];
}
