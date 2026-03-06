import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'services/favorites_service.dart';
import 'error_handler.dart';
import '../providers/auth_provider.dart';
import '../firebase_options.dart';

/// Shared ProviderContainer — created before runApp so the router can read
/// auth state directly without going through BuildContext.
final container = ProviderContainer();

class AppInitializer {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
    } catch (e) {
      debugPrint("Firebase init failed: $e");
    }

    GlobalErrorHandler.init();

    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Failed to load .env file");
    }

    String? supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
    String? supabaseKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();

    String sanitize(String s) {
      if ((s.startsWith("'") && s.endsWith("'")) ||
          (s.startsWith('"') && s.endsWith('"'))) {
        return s.substring(1, s.length - 1);
      }
      return s;
    }

    if (supabaseUrl != null &&
        supabaseUrl.isNotEmpty &&
        sanitize(supabaseUrl) != 'YOUR_SUPABASE_URL') {
      supabaseUrl = sanitize(supabaseUrl);
      supabaseKey = sanitize(supabaseKey ?? '');

      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
    }

    await FavoritesService.instance.init();

    // Initialize the global AuthNotifier (subscribes to Supabase auth events)
    await container.read(authProvider.notifier).init();
  }
}
