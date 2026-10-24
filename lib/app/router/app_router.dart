import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/home/dashboard_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/inventory/item_detail_screen.dart';
import '../../features/sales/sales_screen.dart';
import '../../features/sales/sales_result_screen.dart';
import '../../features/stock/stock_history_screen.dart';
import '../../features/supplier/supplier_detail_screen.dart';
import '../../features/report/report_screen.dart';
import '../../features/notification/notification_screen.dart';
import '../../features/profile/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Rute aplikasi: 4 tab utama + beberapa halaman lanjutan.
/// Form (tambah/ubah barang, resep, supplier, restok, pemakaian) memakai
/// bottom sheet langsung dari layar terkait, jadi tidak butuh rute sendiri.
class AppRouter {
  AppRouter._();

  static GoRoute _page(String path, String name, GoRouterWidgetBuilder builder) {
    return GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: path,
      name: name,
      builder: builder,
    );
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Empat tab utama: Beranda · Barang · Jual · Laporan
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              name: RouteNames.dashboard,
              builder: (context, state) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/inventory',
              name: RouteNames.inventory,
              builder: (context, state) => const InventoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/sales',
              name: RouteNames.sales,
              builder: (context, state) => const SalesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/report',
              name: RouteNames.report,
              builder: (context, state) => const ReportScreen(),
            ),
          ]),
        ],
      ),

      // Halaman lanjutan (menutupi navigasi bawah)
      _page('/item-detail', RouteNames.itemDetail, (context, state) {
        return ItemDetailScreen(itemName: state.extra as String? ?? '');
      }),
      _page('/supplier-detail', RouteNames.supplierDetail, (context, state) {
        return SupplierDetailScreen(supplierName: state.extra as String? ?? '');
      }),
      _page('/sale-result', RouteNames.saleResult, (context, state) {
        return SalesResultScreen(saleData: state.extra as Map<String, dynamic>?);
      }),
      _page('/stock-history', RouteNames.stockHistory, (context, state) {
        return const StockHistoryScreen();
      }),
      _page('/notifications', RouteNames.notifications, (context, state) {
        return const NotificationScreen();
      }),
      _page('/profile', RouteNames.profile, (context, state) {
        return const ProfileScreen();
      }),
    ],
  );
}
