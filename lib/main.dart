// SwimTrack app entry point.
// Wraps the app in ProviderScope (Riverpod) and sets up theme + GoRouter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';

/// Initialises Flutter bindings and launches the app inside a [ProviderScope].
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SwimTrackApp(),
    ),
  );
}

/// Root widget — reads the [GoRouter] from Riverpod and applies the theme.
class SwimTrackApp extends ConsumerWidget {
  const SwimTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'SwimTrack',
      theme: swimTrackTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}