// screens/auth/splash_screen.dart
//
// Pure display-only splash shown by the router while AuthCubit
// is initializing. Has NO logic — AppInitializer.init() runs in main()
// before runApp(), so this screen is only ever shown for the brief
// moment before the router gets the first AuthState emission.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../widgets/auth_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BookItLogo(fontSize: 48),
            const SizedBox(height: 12),
            Text(
              'Book anything, anytime',
              style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.muted),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.sage,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
