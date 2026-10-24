import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import '../state/auth_state.dart';
import '../state/item_state.dart';
import '../state/recipe_state.dart';
import '../state/supplier_state.dart';
import '../state/stock_state.dart';
import '../state/sale_state.dart';
import '../state/report_state.dart';

class SetokeApp extends StatelessWidget {
  const SetokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => ItemState()),
        ChangeNotifierProvider(create: (_) => RecipeState()),
        ChangeNotifierProvider(create: (_) => SupplierState()),
        ChangeNotifierProvider(create: (_) => StockState()),
        ChangeNotifierProvider(create: (_) => SaleState()),
        ChangeNotifierProvider(create: (_) => ReportState()),
      ],
      child: MaterialApp.router(
        title: 'SETOKE.SU',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
