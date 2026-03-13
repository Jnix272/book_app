import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/customer_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isInitializing = ref.read(authProvider.notifier).isInitializing;

    Map<String, dynamic>? profile;
    if (authState is AuthAuthenticated) {
      profile = authState.profile;
    }

    final String firstName = (profile?['first_name'] as String?) ?? 'User';
    final String lastName = (profile?['last_name'] as String?) ?? '';
    final String email = ref.read(authRepositoryProvider).currentSession?.user.email ?? '';

    final bookingsAsync = ref.watch(customerAppointmentsProvider);
    final bookingsCount = bookingsAsync.valueOrNull?.length ?? 0;
    final isLoadingBookings = bookingsAsync.isLoading;

    final favoritesAsync = ref.watch(favoriteProvidersProvider);
    final favoritesCount = favoritesAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Book',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sage,
                ),
              ),
              TextSpan(
                text: 'it',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            // ── Profile header ───────────────────────
            Container(
              width: double.infinity,
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.sageLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.sageMid,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            firstName.isNotEmpty
                                ? firstName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              color: AppColors.sage,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isInitializing ? 'Loading...' : '$firstName $lastName'.trim(),
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email.isEmpty && isInitializing ? 'Loading...' : email,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatCell(
                        value: isLoadingBookings ? '-' : bookingsCount.toString(),
                        label: 'Bookings',
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.line,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      _StatCell(
                        value: favoritesCount.toString(),
                        label: 'Favorites',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Account settings ─────────────────────
            _Section(
              title: 'Account',
              children: [
                _TapRow(
                  icon: Icons.person_outline,
                  label: 'Personal Information',
                  onTap: () => _editProfileInfo(context, ref),
                ),
                _TapRow(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: () => _changePassword(context, ref),
                ),
                const _TapRow(
                  icon: Icons.payment_outlined,
                  label: 'Payment Methods',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Preferences ──────────────────────────
            _Section(
              title: 'Preferences',
              children: [
                const _ToggleRow(
                  icon: Icons.notifications_none,
                  label: 'Push Notifications',
                  initialValue: true,
                ),
                const _ToggleRow(
                  icon: Icons.mail_outline,
                  label: 'Email Reminders',
                  initialValue: true,
                ),
                _TapRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Calendar Sync',
                  value: 'Google Calendar',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Other ────────────────────────────────
            _Section(
              title: 'Other',
              children: [
                const _TapRow(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                ),
                const _TapRow(icon: Icons.info_outline, label: 'About App'),
                _TapRow(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  isDestructive: true,
                  onTap: () => _showSignOutConfirm(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editProfileInfo(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    Map<String, dynamic>? profile;
    if (authState is AuthAuthenticated) profile = authState.profile;

    final String firstName = (profile?['first_name'] as String?) ?? 'User';
    final String lastName = (profile?['last_name'] as String?) ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        initialFirstName: firstName,
        initialLastName: lastName,
        onSaved: () {
          ref.read(authProvider.notifier).init();
        },
      ),
    );
  }

  void _changePassword(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _showSignOutConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign out?',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop("/"),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                color: AppColors.ink2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                 context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.muted,
            ),
          ),
        ),
        Container(
          color: AppColors.white,
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 56),
                    child: AppDivider(),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool initialValue;
  const _ToggleRow({
    required this.icon,
    required this.label,
    this.initialValue = false,
  });

  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  late bool _val;

  @override
  void initState() {
    super.initState();
    _val = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(widget.icon, size: 22, color: AppColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          Switch(
            value: _val,
            onChanged: (v) => setState(() => _val = v),
            activeThumbColor: AppColors.sage,
            activeTrackColor: AppColors.sageLight,
          ),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _TapRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.red : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDestructive ? color : AppColors.muted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDestructive
                  ? color.withValues(alpha: 0.5)
                  : AppColors.line,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      Text(
        label,
        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
      ),
    ],
  );
}

class _SheetField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscureText;
  final TextEditingController? controller;

  const _SheetField({
    required this.label,
    this.hint,
    this.obscureText = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.ink2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
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
              borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final String initialFirstName;
  final String initialLastName;
  final VoidCallback onSaved;

  const _EditProfileSheet({
    required this.initialFirstName,
    required this.initialLastName,
    required this.onSaved,
  });

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _firstController;
  late final TextEditingController _lastController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstController = TextEditingController(text: widget.initialFirstName);
    _lastController = TextEditingController(text: widget.initialLastName);
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).updateUserProfile(
        firstName: _firstController.text.trim(),
        lastName: _lastController.text.trim(),
      );

      if (mounted) {
        widget.onSaved();
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Edit Profile',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _SheetField(label: 'First Name', controller: _firstController),
          const SizedBox(height: 16),
          _SheetField(label: 'Last Name', controller: _lastController),
          const SizedBox(height: 32),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.sage),
                )
              : PrimaryButton('Save Changes', onTap: _save),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final pwd = _newPasswordController.text;
    if (pwd.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).updatePassword(pwd);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Change Password',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _SheetField(
            label: 'New Password',
            controller: _newPasswordController,
            obscureText: true,
            hint: 'At least 6 characters',
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.sage),
                )
              : PrimaryButton('Update Password', onTap: _updatePassword),
        ],
      ),
    );
  }
}
