import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/validators/validators.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class SignUpState {
  const SignUpState();
}

/// No signup in progress.
final class SignUpInitial extends SignUpState {
  const SignUpInitial();
}

// ─── Step 1: Input & Validation ───────────────────────────────────────────────

/// Client-side input validation failed.
/// [field] is the name of the failed field (e.g. 'email', 'password'),
/// [message] is the human-readable error.
final class SignUpValidationFailure extends SignUpState {
  final String field;
  final String message;
  const SignUpValidationFailure({required this.field, required this.message});
}

// ─── Step 2: Availability Check ───────────────────────────────────────────────

/// Checking with the server whether the email is already registered.
final class SignUpCheckingAvailability extends SignUpState {
  const SignUpCheckingAvailability();
}

/// Email was found to already be in use before even attempting signup.
final class SignUpEmailTaken extends SignUpState {
  const SignUpEmailTaken();
}

// ─── Step 3 + 4: Hashing & Persistence ────────────────────────────────────────
// Password hashing is done entirely server-side by Supabase Auth (bcrypt).

/// Auth.signUp call is in flight (hashing + persisting server-side).
final class SignUpLoading extends SignUpState {
  const SignUpLoading();
}

// ─── Step 5: Post-Signup ──────────────────────────────────────────────────────

/// Account created. [email] is forwarded to the email-verify screen.
final class SignUpSuccess extends SignUpState {
  final String email;
  const SignUpSuccess(this.email);
}

/// An unrecoverable error occurred at any step.
final class SignUpFailure extends SignUpState {
  final String message;
  const SignUpFailure(this.message);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Per-screen notifier for the full 5-step registration flow.
///
/// **Step 1** – Input validation (client-side, synchronous)
/// **Step 2** – Availability check (async, before auth call)
/// **Step 3** – Password hashing (server-side, transparent)
/// **Step 4** – Persistence (server-side)
/// **Step 5** – Post-signup: emits [SignUpSuccess] with email
class SignUpNotifier extends StateNotifier<SignUpState> {
  SignUpNotifier() : super(const SignUpInitial());

  // ── Supabase client shorthand ─────────────────────────────────────────────
  SupabaseClient get _db => Supabase.instance.client;

  // ── Customer ──────────────────────────────────────────────────────────────

  Future<void> signUpCustomer({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    // ── Step 1: Input validation ────────────────────────────────────────────
    final validationError = _validateInputs(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      firstName: firstName,
      lastName: lastName,
    );
    if (validationError != null) {
      state = validationError;
      return;
    }

    // ── Step 2: Email availability check ───────────────────────────────────
    state = const SignUpCheckingAvailability();
    final taken = await _isEmailTaken(email.trim());
    if (taken) {
      state = const SignUpEmailTaken();
      return;
    }

    // ── Steps 3 & 4: Hashing (server) + Persistence ────────────────────────
    state = const SignUpLoading();
    try {
      final res = await _db.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
      );

      if (res.user == null) {
        state = const SignUpFailure('Failed to create account.');
        return;
      }

      // ── Step 5: Post-signup ───────────────────────────────────────────────
      state = SignUpSuccess(email.trim());
    } on AuthException catch (e) {
      state = SignUpFailure(_friendly(e.message));
    } catch (_) {
      state = const SignUpFailure('Something went wrong. Please try again.');
    }
  }

  // ── Provider ──────────────────────────────────────────────────────────────

  Future<void> signUpProvider({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String businessName,
    required String category,
    required String emoji,
    String? phone,
    String? address,
    String? city,
    String? state_,
    String? bio,
  }) async {
    // ── Step 1: Input validation ────────────────────────────────────────────
    final validationError = _validateInputs(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      firstName: firstName,
      lastName: lastName,
    );
    if (validationError != null) {
      state = validationError;
      return;
    }

    final businessError = _validateBusinessName(businessName);
    if (businessError != null) {
      state = SignUpValidationFailure(
        field: 'businessName',
        message: businessError,
      );
      return;
    }

    // ── Step 2: Email availability check ───────────────────────────────────
    state = const SignUpCheckingAvailability();
    final taken = await _isEmailTaken(email.trim());
    if (taken) {
      state = const SignUpEmailTaken();
      return;
    }

    // ── Steps 3 & 4: Hashing (server) + Persistence ────────────────────────
    state = const SignUpLoading();
    try {
      final res = await _db.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'first_name': firstName.trim(), 'last_name': lastName.trim()},
      );

      final user = res.user;
      if (user == null) {
        state = const SignUpFailure('Failed to create account.');
        return;
      }

      // Insert provider profile.
      // The `handle_new_provider` trigger elevates the user's role → 'provider'.
      await _db.from('providers').insert({
        'user_id': user.id,
        'business_name': businessName.trim(),
        'category': category,
        'emoji': emoji,
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        if (address != null && address.isNotEmpty) 'address': address.trim(),
        if (city != null && city.isNotEmpty) 'city': city.trim(),
        if (state_ != null && state_.isNotEmpty) 'state': state_.trim(),
        if (bio != null && bio.isNotEmpty) 'bio': bio.trim(),
      });

      // ── Step 5: Post-signup ───────────────────────────────────────────────
      state = SignUpSuccess(email.trim());
    } on AuthException catch (e) {
      state = SignUpFailure(_friendly(e.message));
    } catch (e) {
      state = SignUpFailure(e.toString());
    }
  }

  void reset() => state = const SignUpInitial();

  // ── Private helpers ────────────────────────────────────────────────────────

  SignUpValidationFailure? _validateInputs({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
  }) {
    final emailErr = validateEmail(email);
    if (emailErr != null) {
      return SignUpValidationFailure(field: 'email', message: emailErr);
    }

    final firstErr = validateName(firstName);
    if (firstErr != null) {
      return SignUpValidationFailure(field: 'firstName', message: firstErr);
    }

    final lastErr = validateName(lastName);
    if (lastErr != null) {
      return SignUpValidationFailure(field: 'lastName', message: lastErr);
    }

    final passErr = validatePassword(password);
    if (passErr != null) {
      return SignUpValidationFailure(field: 'password', message: passErr);
    }

    final confirmErr = validateConfirm(confirmPassword, password);
    if (confirmErr != null) {
      return SignUpValidationFailure(
        field: 'confirmPassword',
        message: confirmErr,
      );
    }

    return null; // ✓ all checks pass
  }

  Future<bool> _isEmailTaken(String email) async {
    try {
      final row = await _db
          .from('users')
          .select('user_id')
          .eq('email', email)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  String? _validateBusinessName(String name) {
    final v = name.trim();
    if (v.isEmpty) return 'Business name is required';
    if (v.length < 2) return 'Business name is too short';
    return null;
  }

  String _friendly(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (m.contains('password')) {
      return 'Password must be at least 8 characters.';
    }
    return msg;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// autoDispose so the state resets every time the signup screen is popped.
final signUpProvider =
    StateNotifierProvider.autoDispose<SignUpNotifier, SignUpState>((ref) {
      return SignUpNotifier();
    });
