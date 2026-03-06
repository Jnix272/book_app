import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../app_theme.dart';

class GlobalErrorHandler {
  static void init() {
    // 1. Catch async errors that didn't go through FlutterError pipeline
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('🚨 ASYNC ERROR CAUGHT: $error');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      // Return true to prevent the app from forcefully crashing natively
      return true;
    };

    // 3. Customize the dreaded "Red Screen of Death"
    ErrorWidget.builder = (FlutterErrorDetails details) {
      bool isDebug = false;
      assert(() {
        // Assertions are only executed in debug mode.
        isDebug = true;
        return true;
      }());

      return Material(
        color: AppColors.bg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.red, size: 64),
                const SizedBox(height: 24),
                Text(
                  'Oh no! Something went wrong.',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We encountered an unexpected error. Please restart the app or try again later.',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppColors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isDebug) ...[
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        details.exceptionAsString(),
                        style: GoogleFonts.dmMono(
                          fontSize: 12,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    };
  }
}
