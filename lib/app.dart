import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'models/open_spool_data.dart';
import 'ui/home/home_screen.dart';
import 'ui/qr/qr_display_screen.dart';
import 'ui/qr/qr_scan_screen.dart';
import 'ui/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/qr/display',
        builder: (context, state) {
          final data = state.extra! as OpenSpoolData;
          return QrDisplayScreen(data: data);
        },
      ),
      GoRoute(
        path: '/qr/scan',
        builder: (context, state) => const QrScanScreen(),
      ),
    ],
  );
});

class SpoolerTagApp extends ConsumerWidget {
  const SpoolerTagApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'SpoolerTag',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
