// screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_theme.dart';
import '../../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final Color accentColor;
  const ForgotPasswordScreen({super.key, required this.accentColor});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String _error = '';

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = ''; });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink2),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: _sent ? _SentState(email: _emailCtrl.text.trim(), accentColor: widget.accentColor)
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.lock_reset_outlined,
                          color: widget.accentColor, size: 26),
                    ),
                    const SizedBox(height: 20),
                    Text('Forgot password?',
                        style: GoogleFonts.fraunces(
                            fontSize: 26, fontWeight: FontWeight.w500, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    Text('Enter your email and we\'ll send you a reset link.',
                        style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted)),
                    const SizedBox(height: 32),

                    ErrorBanner(_error),
                    if (_error.isNotEmpty) const SizedBox(height: 16),

                    AuthTextField(
                      label: 'Email address',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      accentColor: widget.accentColor,
                      prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.muted),
                      validator: Validators.email,
                      onEditingComplete: _send,
                      autofocus: true,
                    ),
                    const SizedBox(height: 28),

                    AuthButton('Send Reset Link',
                        onTap: _send, isLoading: _loading, color: widget.accentColor),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SentState extends StatelessWidget {
  final String email;
  final Color accentColor;
  const _SentState({required this.email, required this.accentColor});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: AppColors.sageLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.mark_email_read_outlined, color: AppColors.sage, size: 26),
      ),
      const SizedBox(height: 20),
      Text('Check your inbox',
          style: GoogleFonts.fraunces(
              fontSize: 26, fontWeight: FontWeight.w500, color: AppColors.ink)),
      const SizedBox(height: 10),
      RichText(
        text: TextSpan(
          style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.muted, height: 1.6),
          children: [
            const TextSpan(text: 'We sent a password reset link to\n'),
            TextSpan(text: email,
                style: GoogleFonts.dmSans(color: AppColors.ink, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      const SizedBox(height: 32),
      const SuccessBanner('Reset link sent. Check your spam folder if you don\'t see it.'),
      const Spacer(),
      AuthButton('Back to Sign In',
          onTap: () => Navigator.pop(context),
          color: accentColor),
    ],
  );
}
