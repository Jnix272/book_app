import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;
  
  /// Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Stream of Auth state changes
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Sign In
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign Up (Customer)
  Future<AuthResponse> signUpCustomer({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
      },
    );
  }

  /// Sign Up (Provider)
  Future<AuthResponse> signUpProvider({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String businessName,
    required String category,
    required String emoji,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? bio,
  }) async {
    // 1. Create auth user
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
      },
    );

    final user = res.user;
    if (user != null) {
      // 2. Insert provider profile. The database trigger `handle_new_provider` elevates role.
      await _client.from('providers').insert({
        'user_id': user.id,
        'business_name': businessName.trim(),
        'category': category,
        'emoji': emoji,
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        if (address != null && address.isNotEmpty) 'address': address.trim(),
        if (city != null && city.isNotEmpty) 'city': city.trim(),
        if (state != null && state.isNotEmpty) 'state': state.trim(),
        if (bio != null && bio.isNotEmpty) 'bio': bio.trim(),
      });
    }

    return res;
  }

  /// Check if email is available
  Future<bool> isEmailTaken(String email) async {
    try {
      final row = await _client
          .from('users')
          .select('user_id')
          .eq('email', email.trim())
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  /// Load core user profile (role, names)
  Future<Map<String, dynamic>?> loadProfile(String uid) async {
    try {
      return await _client
          .from('users')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
    } catch (e) {
      debugPrint('AuthRepository.loadProfile error: $e');
      return null;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Update User Profile (first name, last name)
  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('users').update({
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', user.id);

    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
        },
      ),
    );
  }

  /// Update Password
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
