// lib/core/validators/validators.dart
//
// Pure validation functions used by sign-up and sign-in forms.
// Each function follows Flutter's [FormField] validator signature:
// returns `null` on success or an error message string on failure.

// ── Name ────────────────────────────────────────────────────────────────────

String? validateName(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Please enter your name';
  if (v.length < 2) return 'Name is too short';
  return null;
}

// ── Email ───────────────────────────────────────────────────────────────────

String? validateEmail(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Please enter your email';
  if (!RegExp(r'''^[^@]+@[^@]+\.[^@]+$''').hasMatch(v)) {
    return 'Please enter a valid email';
  }
  return null;
}

// ── Phone ───────────────────────────────────────────────────────────────────

String? validatePhone(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Please enter your phone number';
  if (v.length < 10) return 'Phone number must be at least 10 digits';
  return null;
}

// ── Password — complexity requirements ──────────────────────────────────────
//
// A strong password must:
//   • Be at least 8 characters long
//   • Contain at least one uppercase letter  (A-Z)
//   • Contain at least one digit             (0-9)
//   • Contain at least one symbol            (!@#$% etc.)

class PasswordComplexity {
  const PasswordComplexity._();

  static const int minLength = 8;

  static bool hasLength(String p) => p.length >= minLength;
  static bool hasUppercase(String p) => p.contains(RegExp(r'[A-Z]'));
  static bool hasDigit(String p) => p.contains(RegExp(r'[0-9]'));
  static bool hasSymbol(String p) =>
      p.contains(RegExp(r'''[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\;'/`~]'''));

  static bool isStrong(String p) =>
      hasLength(p) && hasUppercase(p) && hasDigit(p) && hasSymbol(p);
}

/// Returns `null` when the password meets all complexity rules,
/// or a human-readable error message listing what's missing.
String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Please enter a password';

  final missing = <String>[];
  if (!PasswordComplexity.hasLength(v)) {
    missing.add('at least ${PasswordComplexity.minLength} characters');
  }
  if (!PasswordComplexity.hasUppercase(v)) missing.add('an uppercase letter');
  if (!PasswordComplexity.hasDigit(v)) missing.add('a number');
  if (!PasswordComplexity.hasSymbol(v)) missing.add('a symbol (!@#…)');

  if (missing.isEmpty) return null;
  return 'Password must contain ${missing.join(', ')}.';
}

// ── Confirm password ─────────────────────────────────────────────────────────
String? validateConfirm(String? value, String password) {
  final v = value ?? '';
  if (v.isEmpty) return 'Please confirm your password';
  if (v != password) return 'Passwords do not match';
  return null;
}

// ── Notes ────────────────────────────────────────────────────────────────────
String? validateNotes(String? value) {
  final v = value ?? '';
  if (v.length > 500) return 'Notes cannot exceed 500 characters';
  return null;
}

// ── Price ───────────────────────────────────────────────────────────────────
String? validatePrice(double? value) {
  if (value == null) return 'Price cannot be empty';
  if (value < 0) return 'Price cannot be negative';
  return null;
}
