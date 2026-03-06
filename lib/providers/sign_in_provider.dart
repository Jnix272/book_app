import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class SignInState {
  const SignInState();
}

final class SignInInitial extends SignInState {
  const SignInInitial();
}

final class SignInLoading extends SignInState {
  const SignInLoading();
}

/// Auth succeeded. GoRouter's redirect (driven by authProvider) handles
/// navigation to the correct home screen based on the user's role.
final class SignInSuccess extends SignInState {
  const SignInSuccess();
}

final class SignInFailure extends SignInState {
  final String message;
  const SignInFailure(this.message);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Per-screen notifier for the sign-in flow.
///
/// Intentionally does NOT fetch the user's role or navigate.
/// After a successful [signIn], the global [authProvider] picks up the
/// auth-state-change event, loads the profile (including role), and
/// GoRouter's redirect sends the user to the correct home screen automatically.
class SignInNotifier extends StateNotifier<SignInState> {
  SignInNotifier() : super(const SignInInitial());

  Future<void> signIn(String email, String password) async {
    state = const SignInLoading();
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        state = const SignInFailure('Could not sign in. Please try again.');
        return;
      }

      // authProvider's onAuthStateChange listener will fire, load the profile
      // (including role), and GoRouter will redirect to the correct home screen.
      state = const SignInSuccess();
    } on AuthException catch (e) {
      state = SignInFailure(_friendly(e.message));
    } catch (_) {
      state = const SignInFailure('Something went wrong. Please try again.');
    }
  }

  void reset() => state = const SignInInitial();

  String _friendly(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid') || m.contains('credentials')) {
      return 'Incorrect email or password.';
    }
    if (m.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (m.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return msg;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// autoDispose so the state resets every time the sign-in screen is popped.
final signInProvider =
    StateNotifierProvider.autoDispose<SignInNotifier, SignInState>((ref) {
      return SignInNotifier();
    });
