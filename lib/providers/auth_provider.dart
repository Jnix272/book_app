import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/provider_session.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

/// Initial state before the session has been checked.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Supabase session is being resolved.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A valid session exists; carries the user's profile data.
final class AuthAuthenticated extends AuthState {
  final String userId;
  final String role;
  final Map<String, dynamic>? profile;

  const AuthAuthenticated({
    required this.userId,
    required this.role,
    this.profile,
  });

  String get fullName {
    final first = profile?['first_name'] as String? ?? '';
    final last = profile?['last_name'] as String? ?? '';
    if (first.isEmpty && last.isEmpty) return 'Unknown User';
    return '$first $last'.trim();
  }
}

/// No active session (logged out, or never logged in).
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Global auth notifier. Provided via [authProvider] at the root of the widget
/// tree (inside ProviderScope).
///
/// Reacts to Supabase auth events and fetches the user's profile from
/// `public.users` after each sign-in. The router's `refreshListenable`
/// should point to [AuthStateListenable], which wraps this notifier.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthInitial());

  // ignore: cancel_subscriptions
  StreamSubscription<dynamic>? _authSub;

  // ── Public getters ─────────────────────────────────────────────────────────

  bool get isInitializing => state is AuthInitial || state is AuthLoading;
  bool get isAuthenticated => state is AuthAuthenticated;

  String get userRole => state is AuthAuthenticated
      ? (state as AuthAuthenticated).role
      : 'customer';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Call once from [AppInitializer] before [runApp]. Emits the first real
  /// state so GoRouter can route immediately.
  Future<void> init() async {
    state = const AuthLoading();

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _loadProfile(session.user.id);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      debugPrint('AuthNotifier.init error: $e');
      state = const AuthUnauthenticated();
    }

    // Subscribe to future auth state changes (sign-in, sign-out, token refresh)
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final session = data.session;
      if (session != null) {
        final user = session.user;
        final lastSignIn = user.lastSignInAt;
        final isFreshSignup =
            lastSignIn != null &&
            DateTime.parse(
                  lastSignIn,
                ).difference(DateTime.parse(user.createdAt)).abs() <
                const Duration(seconds: 5);

        if (isFreshSignup) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
        }
        await _loadProfile(session.user.id);
      } else {
        ProviderSession.instance.clear();
        state = const AuthUnauthenticated();
      }
    });
  }

  /// Fetch `public.users` row and emit [AuthAuthenticated].
  Future<void> _loadProfile(String uid) async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      state = AuthAuthenticated(
        userId: uid,
        role: data?['role'] as String? ?? 'customer',
        profile: data,
      );
    } catch (e) {
      debugPrint('AuthNotifier._loadProfile error: $e');
      // Still authenticated — fall back gracefully
      state = AuthAuthenticated(userId: uid, role: 'customer');
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    // onAuthStateChange listener above handles the state transition.
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// ── GoRouter Listenable bridge ────────────────────────────────────────────────

/// Wraps an [AuthNotifier] so GoRouter can use it as a [Listenable] for
/// `refreshListenable`. Notifies listeners whenever the auth state changes.
class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(AuthNotifier notifier) {
    _sub = notifier.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
