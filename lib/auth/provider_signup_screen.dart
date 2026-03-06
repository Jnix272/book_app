// screens/auth/provider_signup_screen.dart
//
// Multi-step provider sign-up (3 steps):
//   Step 1 — Account details (name, email, password)
//   Step 2 — Business info  (business name, address, city, phone)
//   Step 3 — Category       (service category, bio)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../app_theme.dart';
import '../../providers/sign_up_provider.dart';
import '../../widgets/auth_widgets.dart';

class ProviderSignupScreen extends ConsumerStatefulWidget {
  const ProviderSignupScreen({super.key});

  @override
  ConsumerState<ProviderSignupScreen> createState() =>
      _ProviderSignupScreenState();
}

class _ProviderSignupScreenState extends ConsumerState<ProviderSignupScreen> {
  final _pageCtrl = PageController();
  int _step = 1;
  static const int _totalSteps = 3;

  // ── Step 1 ──────────────────────────────────────────────────────────────────
  final _step1Key = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // ── Step 2 ──────────────────────────────────────────────────────────────────
  final _step2Key = GlobalKey<FormState>();
  final _businessCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  // ── Step 3 ──────────────────────────────────────────────────────────────────
  final _step3Key = GlobalKey<FormState>();
  final _bioCtrl = TextEditingController();
  String _selectedCategory = '';
  bool _agreedToTerms = false;

  static const List<Map<String, String>> _categories = [
    {'emoji': '✂️', 'label': 'Hair'},
    {'emoji': '💅', 'label': 'Nails'},
    {'emoji': '💆', 'label': 'Massage'},
    {'emoji': '🩺', 'label': 'Medical'},
    {'emoji': '🏋️', 'label': 'Fitness'},
    {'emoji': '🧴', 'label': 'Skincare'},
    {'emoji': '🦷', 'label': 'Dental'},
    {'emoji': '🐾', 'label': 'Pet Care'},
    {'emoji': '📚', 'label': 'Tutoring'},
    {'emoji': '🔧', 'label': 'Home Services'},
    {'emoji': '📸', 'label': 'Photography'},
    {'emoji': '✦', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in [
      _firstCtrl,
      _lastCtrl,
      _emailCtrl,
      _passCtrl,
      _confirmCtrl,
      _businessCtrl,
      _phoneCtrl,
      _addressCtrl,
      _cityCtrl,
      _stateCtrl,
      _bioCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next(BuildContext context) {
    setState(() {}); // clear snapshot error
    final key = _step == 1 ? _step1Key : (_step == 2 ? _step2Key : _step3Key);
    if (!key.currentState!.validate()) return;

    if (_step < _totalSteps) {
      setState(() => _step++);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit(context);
    }
  }

  void _back(BuildContext context) {
    if (_step > 1) {
      setState(() => _step--);
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/front');
      }
    }
  }

  void _submit(BuildContext context) {
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a service category.',
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
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please agree to the Provider Terms to continue.',
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

    final emoji = _categories.firstWhere(
      (c) => c['label'] == _selectedCategory,
      orElse: () => {'emoji': '✦'},
    )['emoji']!;

    ref
        .read(signUpProvider.notifier)
        .signUpProvider(
          email: _emailCtrl.text,
          password: _passCtrl.text,
          confirmPassword: _confirmCtrl.text,
          firstName: _firstCtrl.text,
          lastName: _lastCtrl.text,
          businessName: _businessCtrl.text,
          category: _selectedCategory,
          emoji: emoji,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
          state_: _stateCtrl.text.trim().isEmpty
              ? null
              : _stateCtrl.text.trim(),
          bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SignUpState>(signUpProvider, (prev, next) {
      if (next is SignUpSuccess) {
        context.go(
          '/email_verify',
          extra: {'email': next.email, 'role': 'provider'},
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
        leading: IconButton(
          icon: Icon(
            _step == 1 ? Icons.close : Icons.arrow_back,
            color: AppColors.ink2,
          ),
          onPressed: () => _back(context),
        ),
        title: const BookItLogo(fontSize: 22),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Step progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: StepProgressBar(
                currentStep: _step,
                totalSteps: _totalSteps,
                color: AppColors.amber,
              ),
            ),

            // Error banner
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: ErrorBanner(error),
              ),

            // Page views for each step
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(
                    formKey: _step1Key,
                    firstCtrl: _firstCtrl,
                    lastCtrl: _lastCtrl,
                    emailCtrl: _emailCtrl,
                    passCtrl: _passCtrl,
                    confirmCtrl: _confirmCtrl,
                  ),
                  _Step2(
                    formKey: _step2Key,
                    businessCtrl: _businessCtrl,
                    phoneCtrl: _phoneCtrl,
                    addressCtrl: _addressCtrl,
                    cityCtrl: _cityCtrl,
                    stateCtrl: _stateCtrl,
                  ),
                  _Step3(
                    formKey: _step3Key,
                    bioCtrl: _bioCtrl,
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    agreedToTerms: _agreedToTerms,
                    onCategorySelected: (c) =>
                        setState(() => _selectedCategory = c),
                    onTermsToggled: (v) => setState(() => _agreedToTerms = v),
                  ),
                ],
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthButton(
                    _step < _totalSteps
                        ? 'Continue →'
                        : 'Create Provider Account',
                    onTap: loading ? null : () => _next(context),
                    isLoading: loading,
                    color: AppColors.amber,
                  ),
                  if (_step == 1) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.pushReplacement('/provider_login'),
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
                                  color: AppColors.amber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1 — Account details ───────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstCtrl,
      lastCtrl,
      emailCtrl,
      passCtrl,
      confirmCtrl;

  const _Step1({
    required this.formKey,
    required this.firstCtrl,
    required this.lastCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account',
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "We'll use this to sign you in",
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: AuthTextField(
                    label: 'First name',
                    hint: 'Alex',
                    controller: firstCtrl,
                    textInputAction: TextInputAction.next,
                    accentColor: AppColors.amber,
                    validator: Validators.required('First name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AuthTextField(
                    label: 'Last name',
                    hint: 'Chen',
                    controller: lastCtrl,
                    textInputAction: TextInputAction.next,
                    accentColor: AppColors.amber,
                    validator: Validators.required('Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            AuthTextField(
              label: 'Email address',
              hint: 'alex@yourbusiness.com',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              accentColor: AppColors.amber,
              prefixIcon: const Icon(
                Icons.email_outlined,
                size: 18,
                color: AppColors.muted,
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),

            AuthTextField(
              label: 'Password',
              hint: 'Min. 8 characters',
              controller: passCtrl,
              obscure: true,
              textInputAction: TextInputAction.next,
              accentColor: AppColors.amber,
              prefixIcon: const Icon(
                Icons.lock_outlined,
                size: 18,
                color: AppColors.muted,
              ),
              validator: Validators.password,
            ),
            ValueListenableBuilder(
              valueListenable: passCtrl,
              builder: (ctx, val, child) => PasswordStrengthBar(passCtrl.text),
            ),
            const SizedBox(height: 16),

            AuthTextField(
              label: 'Confirm password',
              hint: '••••••••',
              controller: confirmCtrl,
              obscure: true,
              textInputAction: TextInputAction.done,
              accentColor: AppColors.amber,
              prefixIcon: const Icon(
                Icons.lock_outlined,
                size: 18,
                color: AppColors.muted,
              ),
              validator: (v) => Validators.confirmPassword(v, passCtrl.text),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2 — Business info ────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController businessCtrl,
      phoneCtrl,
      addressCtrl,
      cityCtrl,
      stateCtrl;

  const _Step2({
    required this.formKey,
    required this.businessCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.stateCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your business',
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Customers will see this on your profile',
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 28),

            AuthTextField(
              label: 'Business name',
              hint: 'Aria Hair Studio',
              controller: businessCtrl,
              textInputAction: TextInputAction.next,
              accentColor: AppColors.amber,
              prefixIcon: const Icon(
                Icons.storefront_outlined,
                size: 18,
                color: AppColors.muted,
              ),
              validator: Validators.businessName,
            ),
            const SizedBox(height: 16),

            AuthTextField(
              label: 'Business phone',
              hint: '+1 555 000 9999',
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              accentColor: AppColors.amber,
              prefixIcon: const Icon(
                Icons.phone_outlined,
                size: 18,
                color: AppColors.muted,
              ),
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),

            AuthTextField(
              label: 'Street address (optional)',
              hint: '12 Maple Street',
              controller: addressCtrl,
              textInputAction: TextInputAction.next,
              accentColor: AppColors.amber,
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AuthTextField(
                    label: 'City',
                    hint: 'New York',
                    controller: cityCtrl,
                    textInputAction: TextInputAction.next,
                    accentColor: AppColors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AuthTextField(
                    label: 'State',
                    hint: 'NY',
                    controller: stateCtrl,
                    textInputAction: TextInputAction.done,
                    accentColor: AppColors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                    Icons.info_outline,
                    color: AppColors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your listing requires approval before going live. We\'ll notify you within 24 hours.',
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
        ),
      ),
    );
  }
}

// ── Step 3 — Category & bio ───────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController bioCtrl;
  final List<Map<String, String>> categories;
  final String selectedCategory;
  final bool agreedToTerms;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<bool> onTermsToggled;

  const _Step3({
    required this.formKey,
    required this.bioCtrl,
    required this.categories,
    required this.selectedCategory,
    required this.agreedToTerms,
    required this.onCategorySelected,
    required this.onTermsToggled,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What you offer',
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick your main service category',
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 24),

            // Category grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final selected = selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () => onCategorySelected(cat['label']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.amberLight : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.amber : AppColors.line,
                        width: selected ? 2 : 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cat['emoji']!,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat['label']!,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? AppColors.amber : AppColors.ink2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Bio
            Text(
              'Bio (optional)',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: bioCtrl,
              maxLines: 3,
              style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Tell customers about your experience and services…',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.line,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.line,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.amber,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Terms
            GestureDetector(
              onTap: () => onTermsToggled(!agreedToTerms),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: agreedToTerms
                          ? AppColors.amber
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: agreedToTerms ? AppColors.amber : AppColors.line,
                        width: 1.5,
                      ),
                    ),
                    child: agreedToTerms
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
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
                            text: 'Provider Terms',
                            style: GoogleFonts.dmSans(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: GoogleFonts.dmSans(
                              color: AppColors.amber,
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
    );
  }
}
