import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'provider_session.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  String? _userId;
  Map<String, dynamic>? _userProfile;
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _isInitializing = true;
  String? _tempRole;

  String? get userId => _userId;
  bool get isLoggedIn => _userId != null;
  bool get isInitializing => _isInitializing;

  Map<String, dynamic>? get userProfile => _userProfile;

  void setLoginRole(String role) {
    _tempRole = role;
  }

  String get userRole => _userProfile?['role'] ?? _tempRole ?? 'customer';

  String get userFullName {
    final firstName = _userProfile?['first_name'] ?? '';
    final lastName = _userProfile?['last_name'] ?? '';
    if (firstName.isEmpty && lastName.isEmpty) return 'Unknown User';
    return '$firstName $lastName'.trim();
  }

  Future<void> init() async {
    try {
      // Check initial session - wrap in try-catch in case Supabase isn't ready
      final initialSession = Supabase.instance.client.auth.currentSession;
      if (initialSession != null) {
        await _fetchProfileForUser(initialSession.user.id);
      }
    } catch (e) {
      debugPrint('AuthSession init error (likely Supabase not ready): $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }

    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) async {
          final session = data.session;
          final newUserId = session?.user.id;

          if (newUserId != null) {
            await _fetchProfileForUser(newUserId);
          } else {
            _userId = null;
            _userProfile = null;
            _tempRole = null;
            // Clear the provider cache so the next provider login starts fresh.
            ProviderSession.instance.clear();
            notifyListeners();
          }
        });
  }

  Future<void> refreshProfile() async {
    if (_userId != null) {
      await _fetchProfileForUser(_userId!);
    }
  }

  Future<void> _fetchProfileForUser(String uid) async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      _userId = uid;
      _userProfile = data;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      _userId = uid;
      _userProfile = null;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    // onAuthStateChange listener above handles clearing state + ProviderSession.
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
