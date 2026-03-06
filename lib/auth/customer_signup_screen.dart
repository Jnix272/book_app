// screens/auth/customer_signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../providers/sign_up_provider.dart';
import '../../widgets/auth_widgets.dart';

class CustomerSignupScreen extends ConsumerStatefulWidget {
  const CustomerSignupScreen({super.key});

  @override
  ConsumerState<CustomerSignupScreen> createState() =>
      _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends ConsumerState<CustomerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    for (final c in [
      _firstCtrl,
      _lastCtrl,
      _emailCtrl,
      _phoneCtrl,
      _passCtrl,
      _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please agree to the Terms of Service to continue.',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    ref
        .read(signUpProvider.notifier)
        .signUpCustomer(
          email: _emailCtrl.text,
          password: _passCtrl.text,
          confirmPassword: _confirmCtrl.text,
          firstName: _firstCtrl.text,
          lastName: _lastCtrl.text,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SignUpState>(signUpProvider, (prev, next) {
      if (next is SignUpSuccess) {
        context.go(
          '/email_verify',
          extra: {'email': next.email, 'role': 'customer'},
        );
      }
    });

    final state = ref.watch(signUpProvider);
    final loading =
        state is SignUpLoading || state is SignUpCheckingAvailability;
    final error = switch (state) {
      SignUpFailure(:final message) => message,
      SignUpValidationFailure(:final message) => message,
      SignUpEmailTaken() =>
        'An account with this email already exists. Try signing in.',
      _ => '',
    };

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create account',
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Let's get you booked up",
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Error banner
                      if (error.isNotEmpty) ...[
                        ErrorBanner(error),
                        const SizedBox(height: 16),
                      ],

                      // Name row
                      Row(
                        children: [
                          Expanded(
                            child: AuthTextField(
                              label: 'First name',
                              hint: 'Jane',
                              controller: _firstCtrl,
                              textInputAction: TextInputAction.next,
                              validator: Validators.required('First name'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AuthTextField(
                              label: 'Last name',
                              hint: 'Smith',
                              controller: _lastCtrl,
                              textInputAction: TextInputAction.next,
                              validator: Validators.required('Last name'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      AuthTextField(
                        label: 'Email address',
                        hint: 'jane@example.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),

                      AuthTextField(
                        label: 'Phone (optional)',
                        hint: '+1 555 000 1234',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        validator: Validators.phone,
                      ),
                      const SizedBox(height: 16),

                      AuthTextField(
                        label: 'Password',
                        hint: 'Min. 8 characters',
                        controller: _passCtrl,
                        obscure: true,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 16),

                      AuthTextField(
                        label: 'Confirm password',
                        hint: '••••••••',
                        controller: _confirmCtrl,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        accentColor: AppColors.amber,
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        validator: (v) =>
                            Validators.confirmPassword(v, _passCtrl.text),
                        onEditingComplete: _submit,
                      ),
                      const SizedBox(height: 24),

                      // Terms checkbox
                      GestureDetector(
                        onTap: () =>
                            setState(() => _agreedToTerms = !_agreedToTerms),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _agreedToTerms
                                    ? AppColors.sage
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _agreedToTerms
                                      ? AppColors.sage
                                      : AppColors.line,
                                  width: 1.5,
                                ),
                              ),
                              child: _agreedToTerms
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.sage,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.sage,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed bottom CTA
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sage,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: !loading
                          ? const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  state is SignUpCheckingAvailability
                                      ? 'Checking…'
                                      : 'Creating…',
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.pushReplacement('/customer_login'),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign in',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
