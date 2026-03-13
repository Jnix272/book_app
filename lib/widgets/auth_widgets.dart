import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart'; // Adjust path for AppTheme

// ── BookIt logo ───────────────────────────────────────────────────────────────

class BookItLogo extends StatelessWidget {
  final double fontSize;
  const BookItLogo({super.key, this.fontSize = 32});

  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: 'Book',
          style: GoogleFonts.fraunces(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.sage,
          ),
        ),
        TextSpan(
          text: 'it',
          style: GoogleFonts.fraunces(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.amber,
          ),
        ),
      ],
    ),
  );
}

// ── Auth text field ───────────────────────────────────────────────────────────

class AuthTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final bool autofocus;
  final int maxLines;
  final Color accentColor;

  const AuthTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.prefixIcon,
    this.focusNode,
    this.onEditingComplete,
    this.autofocus = false,
    this.maxLines = 1,
    this.accentColor = AppColors.sage,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.ink2,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscure && _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          autofocus: widget.autofocus,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          onEditingComplete: widget.onEditingComplete,
          style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: widget.prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.muted,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.red, width: 2),
            ),
            errorStyle: GoogleFonts.dmSans(fontSize: 12, color: AppColors.red),
          ),
        ),
      ],
    );
  }
}

// ── Auth primary button ───────────────────────────────────────────────────────

class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? color;
  final Color? textColor;

  const AuthButton(
    this.label, {
    super.key,
    this.onTap,
    this.isLoading = false,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.sage,
        disabledBackgroundColor: AppColors.sageMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor ?? Colors.white,
              ),
            ),
    ),
  );
}

// ── Divider with text ─────────────────────────────────────────────────────────

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: AppColors.line, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          'or',
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
        ),
      ),
      const Expanded(child: Divider(color: AppColors.line, thickness: 1)),
    ],
  );
}

// ── Error banner ──────────────────────────────────────────────────────────────

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: message.isEmpty
        ? const SizedBox.shrink()
        : Container(
            key: ValueKey(message),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.redLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF5C6C1), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppColors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.red,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}

// ── Success banner ────────────────────────────────────────────────────────────

class SuccessBanner extends StatelessWidget {
  final String message;
  const SuccessBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.sageLight,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.sageMid, width: 1.5),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.sage, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.sage,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Password strength indicator ───────────────────────────────────────────────

class PasswordStrengthBar extends StatelessWidget {
  final String password;
  const PasswordStrengthBar(this.password, {super.key});

  int get _strength {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    return score;
  }

  Color get _color {
    switch (_strength) {
      case 1:
        return AppColors.red;
      case 2:
        return AppColors.amber;
      case 3:
        return const Color(0xFF7DC97A);
      case 4:
        return AppColors.sage;
      default:
        return AppColors.line;
    }
  }

  String get _label {
    switch (_strength) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: i < _strength ? _color : AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (_label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Role selector chip ────────────────────────────────────────────────────────

class RoleChip extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;

  const RoleChip({
    super.key,
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: selected ? accentColor.withValues(alpha: 0.08) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? accentColor : AppColors.line,
          width: selected ? 2 : 1.5,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected
                  ? accentColor.withValues(alpha: 0.12)
                  : AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected ? accentColor : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (selected) Icon(Icons.check_circle, color: accentColor, size: 20),
        ],
      ),
    ),
  );
}

// ── Step progress bar (for multi-step signup) ────────────────────────────────

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color color;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.color = AppColors.sage,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: List.generate(totalSteps, (i) {
          final done = i < currentStep;
          final active = i == currentStep - 1;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: done
                    ? color
                    : active
                    ? color.withValues(alpha: 0.4)
                    : AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          'Step $currentStep of $totalSteps',
          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted),
        ),
      ),
    ],
  );
}

// ── Input validators ──────────────────────────────────────────────────────────

class Validators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$');
    if (!emailRegex.hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain an uppercase letter';
    }
    if (!v.contains(RegExp(r'[a-z]'))) return 'Must contain a lowercase letter';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Must contain a digit';
    if (!v.contains(RegExp(r'[^A-Za-z0-9]'))) return 'Must contain a symbol';
    return null;
  }

  static String? Function(String?) required(String label) => (String? v) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  };

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final cleaned = v.replaceAll(RegExp(r'[\s\-()]+'), '');
    if (cleaned.length < 7) return 'Enter a valid phone number';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) {
      return 'Please confirm your password';
    }
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? businessName(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Business name is required';
    }
    if (v.trim().length < 2) {
      return 'Business name must be at least 2 characters';
    }
    return null;
  }
}
