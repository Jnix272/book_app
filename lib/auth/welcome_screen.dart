import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:booking/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // Non-nullable — always initialised in initState before first build.
  late AnimationController _heroCtrl;
  late AnimationController _orbCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _orbRotate;

  @override
  void initState() {
    super.initState();

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _orbRotate =
        Tween<double>(begin: 0, end: 2 * math.pi).animate(_orbCtrl);

    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade =
        CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic),
    );

    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1C2E),
      body: Stack(
        children: [
          // ── Animated background orbs ─────────────────────────
          AnimatedBuilder(
            animation: _orbRotate,
            builder: (context, _) => Stack(
              children: [
                Positioned(
                  top: -size.width * 0.3,
                  right: -size.width * 0.2,
                  child: Transform.rotate(
                    angle: _orbRotate.value * 0.3,
                    child: Container(
                      width: size.width * 0.85,
                      height: size.width * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.sage.withValues(alpha: 0.22),
                            AppColors.sage.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: size.height * 0.08,
                  left: -size.width * 0.25,
                  child: Transform.rotate(
                    angle: -_orbRotate.value * 0.2,
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.amber.withValues(alpha: 0.14),
                            AppColors.amber.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // ── Logo mark ───────────────────────────
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.sage, AppColors.amber],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sage.withValues(alpha: 0.45),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Wordmark — white variant for dark bg ─
                      _DarkWordmark(fontSize: 42),
                      const SizedBox(height: 10),
                      Text(
                        'Appointments made effortless.',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.55),
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(flex: 2),

                      // ── Feature pills ────────────────────────
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: const [
                          _FeaturePill(
                            icon: Icons.calendar_month_outlined,
                            label: 'Easy Booking',
                          ),
                          _FeaturePill(
                            icon: Icons.notifications_outlined,
                            label: 'Smart Reminders',
                          ),
                          _FeaturePill(
                            icon: Icons.star_outline,
                            label: 'Trusted Providers',
                          ),
                          _FeaturePill(
                            icon: Icons.lock_outline,
                            label: 'Secure Payments',
                          ),
                        ],
                      ),

                      const Spacer(flex: 3),

                      // ── Primary CTA ──────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () =>
                              context.push('/customer_signup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sage,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Create an Account',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Secondary CTA ────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () =>
                              context.push('/customer_login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color:
                                  Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Log In',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Tertiary links ───────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () =>
                                context.push('/provider_login'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.amber,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'Provider sign in',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            ' · ',
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/'),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Colors.white.withValues(alpha: 0.45),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'Browse as guest',
                              style: GoogleFonts.dmSans(fontSize: 14),
                            ),
                          ),
                        ],
                      ),

                      // SafeArea already handles the bottom notch — just
                      // add a small fixed gap so content breathes.
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dark-background wordmark ───────────────────────────────────────────────────
// BookItLogo from auth_widgets uses AppColors.sage (dark green) which is
// designed for light backgrounds. On the dark navy welcome screen those colours
// are muddy. This variant uses bright white + amber so the wordmark pops.

class _DarkWordmark extends StatelessWidget {
  final double fontSize;
  const _DarkWordmark({this.fontSize = 32});

  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Book',
              style: GoogleFonts.fraunces(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            TextSpan(
              text: 'it',
              style: GoogleFonts.fraunces(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.amber,
              ),
            ),
          ],
        ),
      );
}

// ── Feature pill chip ─────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // White icon — AppColors.sage (#4A7C6F) is near-black on this
            // dark background and barely visible.
            Icon(icon, color: Colors.white.withValues(alpha: 0.75), size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      );
}

// ── Auth role enum shared by sign-in and sign-up screens ─────────────────────

enum AuthRole { customer, provider }
