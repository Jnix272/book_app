import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_session.dart';

/// Caches the `providers.provider_id` for the currently logged-in provider.
///
/// Why this exists:
/// The `providers` table has its own UUID (`provider_id`) that is DIFFERENT
/// from `auth.users.id`. Tables like `appointments`, `services`, and
/// `provider_time_off` all foreign-key to `providers.provider_id`.
/// Using `AuthSession.instance.userId` (the auth UID) for those queries
/// is a silent bug — the queries return empty results or fail RLS checks.
///
/// Usage:
///   final pid = await ProviderSession.instance.providerId;
///   if (pid == null) { /* not a provider or not loaded */ return; }
class ProviderSession {
  ProviderSession._();
  static final ProviderSession instance = ProviderSession._();

  String? _providerId;
  String? _businessName;
  String? _avatarUrl;
  bool _isLoading = false;

  /// Returns the cached provider_id, fetching it first if needed.
  /// Returns null if the current user is not a provider or the fetch fails.
  Future<String?> get providerId async {
    if (_providerId != null) return _providerId;
    return _resolve();
  }

  /// Returns the cached business name (available after first [providerId] call).
  String? get businessName => _businessName;

  /// Returns the cached avatar url.
  String? get avatarUrl => _avatarUrl;

  /// Force a fresh fetch — call after profile edits that change business_name.
  Future<void> refresh() async {
    _providerId = null;
    _businessName = null;
    _avatarUrl = null;
    await _resolve();
  }

  /// Wipe the cache on logout.
  void clear() {
    _providerId = null;
    _businessName = null;
    _avatarUrl = null;
  }

  Future<String?> _resolve() async {
    if (_isLoading) {
      // Debounce concurrent calls — wait briefly then return cached result.
      await Future.delayed(const Duration(milliseconds: 50));
      return _providerId;
    }

    final uid = AuthSession.instance.userId;
    if (uid == null) return null;

    _isLoading = true;
    try {
      final row = await Supabase.instance.client
          .from('providers')
          .select('provider_id, business_name, avatar_url, image_url')
          .eq('user_id', uid)
          .maybeSingle();

      _providerId = row?['provider_id'] as String?;
      _businessName = row?['business_name'] as String?;
      _avatarUrl =
          row?['avatar_url'] as String? ?? row?['image_url'] as String?;
      return _providerId;
    } catch (e) {
      debugPrint('ProviderSession: error resolving provider_id: $e');
      return null;
    } finally {
      _isLoading = false;
    }
  }
}
