import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const ink = Color(0xFF1A1A2E);
  static const ink2 = Color(0xFF3D3D5C);
  static const muted = Color(0xFF8888AA);
  static const line = Color(0xFFE8E8F0);
  static const bg = Color(0xFFF7F7FB);
  static const white = Color(0xFFFFFFFF);
  static const sage = Color(0xFF4A7C6F);
  static const sageLight = Color(0xFFE8F2EF);
  static const sageMid = Color(0xFFC2DDD7);
  static const amber = Color(0xFFD4702A);
  static const amberLight = Color(0xFFFDF0E8);
  static const red = Color(0xFFC0392B);
  static const redLight = Color(0xFFFDECEA);
  static const statusConfirmedBg = Color(0xFFE6F9F0);
  static const statusConfirmedFg = Color(0xFF1E8A5A);
  static const statusPendingBg = Color(0xFFFFF8E6);
  static const statusPendingFg = Color(0xFFB87A00);

}

class AppTheme {
  // ---- Spacing ----
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.sage,
          surface: AppColors.bg,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: GoogleFonts.fraunces(
            fontSize: 32,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          displayMedium: GoogleFonts.fraunces(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          displaySmall: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          titleLarge: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          titleMedium: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyLarge: GoogleFonts.dmSans(
            fontSize: 15,
            color: AppColors.ink,
          ),
          bodyMedium: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppColors.ink2,
          ),
          bodySmall: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.muted,
          ),
          labelSmall: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.muted,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          titleTextStyle: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.sage,
          ),
          iconTheme: const IconThemeData(color: AppColors.ink2),
          shape: const Border(
            bottom: BorderSide(color: AppColors.line),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.sage,
          unselectedItemColor: AppColors.muted,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.line, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.line, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
          ),
          hintStyle: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 15),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sage,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            elevation: 0,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.line),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.line,
          space: 0,
          thickness: 1,
        ),
      );
}

// ── Shared widget helpers ────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
}

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.line);
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = AppColors.statusConfirmedBg;
        fg = AppColors.statusConfirmedFg;
        break;
      case 'pending':
        bg = AppColors.statusPendingBg;
        fg = AppColors.statusPendingFg;
        break;
      case 'cancelled':
        bg = AppColors.redLight;
        fg = AppColors.red;
        break;
      default:
        bg = AppColors.bg;
        fg = AppColors.muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const PrimaryButton(this.label, {super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? AppColors.sage,
          ),
          child: Text(label),
        ),
      );
}

class OutlineButton2 extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const OutlineButton2(this.label, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.line, width: 1.5),
            foregroundColor: AppColors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}
