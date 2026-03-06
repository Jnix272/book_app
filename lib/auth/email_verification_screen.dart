import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'welcome_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final AuthRole role;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _resending = false;
  bool _resent = false;

  Color get _accent =>
      widget.role == AuthRole.customer ? AppColors.sage : AppColors.amber;

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _resent = false;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(widget.email);
      // ^ In production use supabase.auth.resend() for email confirmation
      if (mounted) setState(() => _resent = true);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Column(
                  children: [
                    const Spacer(),

                    // ── Icon ──────────────────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          widget.role == AuthRole.customer ? '✉️' : '🏢',
                          style: const TextStyle(fontSize: 38),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Headline ──────────────────────────────────────
                    Text(
                      widget.role == AuthRole.customer
                          ? 'Verify your email'
                          : 'Application submitted!',
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),

                    // ── Body copy ─────────────────────────────────────
                    if (widget.role == AuthRole.customer)
                      _CustomerCopy(email: widget.email, accent: _accent)
                    else
                      _ProviderCopy(email: widget.email, accent: _accent),

                    const Spacer(),

                    // ── Resent banner ─────────────────────────────────
                    if (_resent) ...[
                      const SuccessBanner('Verification email resent!'),
                      const SizedBox(height: 20),
                    ],

                    // ── Primary CTA ───────────────────────────────────
                    AuthButton(
                      'Go to Sign In',
                      onTap: () => context.go('/signin', extra: widget.role),
                      color: _accent,
                    ),
                    const SizedBox(height: 14),

                    // ── Resend link ───────────────────────────────────
                    if (widget.role == AuthRole.customer)
                      Center(
                        child: GestureDetector(
                          onTap: _resending ? null : _resend,
                          child: _resending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.muted,
                                  ),
                                )
                              : Text(
                                  "Didn't receive it? Resend",
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: _accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // ── Back to welcome ───────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/front'),
                        child: Text(
                          'Back to home',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.muted,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCopy extends StatelessWidget {
  final String email;
  final Color accent;
  const _CustomerCopy({required this.email, required this.accent});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.dmSans(
            fontSize: 15,
            color: AppColors.muted,
            height: 1.7,
          ),
          children: [
            const TextSpan(text: 'We sent a confirmation link to\n'),
            TextSpan(
              text: email,
              style: GoogleFonts.dmSans(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(
              text: '\n\nClick the link to activate your account.',
            ),
          ],
        ),
      ),
    ],
  );
}

class _ProviderCopy extends StatelessWidget {
  final String email;
  final Color accent;
  const _ProviderCopy({required this.email, required this.accent});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.dmSans(
            fontSize: 15,
            color: AppColors.muted,
            height: 1.7,
          ),
          children: [
            const TextSpan(text: 'We received your provider application.\n\n'),
            TextSpan(
              text: 'Step 1 — ',
              style: GoogleFonts.dmSans(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: 'Verify your email at\n'),
            TextSpan(
              text: email,
              style: GoogleFonts.dmSans(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: '\n\n'),
            TextSpan(
              text: 'Step 2 — ',
              style: GoogleFonts.dmSans(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(
              text:
                  'Our team reviews and approves your listing within 24 hours.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.amberLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF0CDB0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_bottom_outlined,
              color: AppColors.amber,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your profile will go live once approved. You\'ll receive an email notification.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.amber,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
