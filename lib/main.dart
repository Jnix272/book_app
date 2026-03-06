import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/app_initializer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Paint the splash screen immediately — no waiting.
  // AppInitializer runs in the background; when authProvider emits its
  // final state, AuthStateListenable triggers GoRouter to re-run the redirect
  // and navigate away from /splash automatically.
  runApp(ProviderScope(child: const MainApp()));

  // Fire-and-forget — init runs after the first frame.
  AppInitializer.init();
}
