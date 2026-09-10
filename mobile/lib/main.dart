import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/catalogue_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/admin_provider.dart';

import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('fr_FR', null);
    await initializeDateFormatting('fr', null);
  } catch (_) {}
  runApp(const ExamSecureApp());
}

class ExamSecureApp extends StatelessWidget {
  const ExamSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CatalogueProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp.router(
        title: 'ExamSecure',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.student,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
