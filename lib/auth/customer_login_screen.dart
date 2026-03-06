// screens/auth/customer_login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../providers/sign_in_provider.dart';
import '../../widgets/auth_widgets.dart';

class CustomerSignInScreen extends ConsumerStatefulWidget {
  const CustomerSignInScreen({super.key});

  @override
  ConsumerState<CustomerSignInScreen> createState() =>
      _CustomerSignInScreenState();
}

class _CustomerSignInScreenState extends ConsumerState<CustomerSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(signInProvider.notifier).signIn(_emailCtrl.text, _passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for side-effects (toast on success)
    ref.listen<SignInState>(signInProvider, (prev, next) {
      if (next is SignInSuccess) {
        _toast(context, 'Signed in successfully ✓');
      }
    });

    final state = ref.watch(signInProvider);
    final loading = state is SignInLoading;
    final error = state is SignInFailure ? state.message : '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink2),
        title: const BookItLogo(fontSize: 22),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Customer Sign In',
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 32),

                // Error banner
                if (error.isNotEmpty) ...[
                  ErrorBanner(error),
                  const SizedBox(height: 16),
                ],

                // Email
                AuthTextField(
                  label: 'Email address',
                  hint: 'you@example.com',
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onEditingComplete: () => _passFocus.requestFocus(),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),

                // Password
                AuthTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passCtrl,
                  focusNode: _passFocus,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(
                    Icons.lock_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onEditingComplete: _submit,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Password is required' : null,
                ),
                const SizedBox(height: 10),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () =>
                        context.push('/forgot_password', extra: AppColors.sage),
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.sage,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Sign in button
                AuthButton(
                  'Sign In',
                  onTap: loading ? null : _submit,
                  isLoading: loading,
                  color: AppColors.sage,
                ),
                const SizedBox(height: 24),

                // Divider
                const OrDivider(),
                const SizedBox(height: 24),

                // Create account
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/customer_signup'),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Create one',
                            style: GoogleFonts.dmSans(
                              color: AppColors.sage,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
