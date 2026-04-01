import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _PlaceholderScreen(title: 'Home'),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Settings'),
    ),
    GoRoute(
      path: '/qr/display',
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'QR Display'),
    ),
    GoRoute(
      path: '/qr/scan',
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'QR Scan'),
    ),
  ],
);

class SpoolerTagApp extends StatelessWidget {
  const SpoolerTagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SpoolerTag',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
