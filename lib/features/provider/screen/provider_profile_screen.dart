import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app_theme.dart';
import 'package:booking/core/services/provider_session.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/avatar_service.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  // ── Data from DB ──────────────────────────
  bool _isLoading = true;
  String _businessName = '';
  String _category = '';
  String _address = '';
  String _email = '';
  String _phone = '';
  String _description = '';
  double _rating = 0;
  int _reviewCount = 0;
  int _serviceCount = 0;
  String? _avatarUrl;
  String? _providerId;
  bool _avatarUploading = false;

  // ── Notification toggles (backed by users table) ──
  bool _emailNewBooking = true;
  bool _emailCancel = true;
  bool _smsReminder = false;
  bool _inAppUpdates = true;
  bool _dailySummary = false;

  // ── Business settings ─────────────────────
  bool _autoConfirm = false;
  bool _allowReschedule = true;
  bool _showRating = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Join providers + users in one go
      final provRow = await Supabase.instance.client
          .from('providers')
          .select(
            'provider_id, business_name, category, address, city, state, bio, average_rating, total_reviews, avatar_url, users!inner(email, phone, notification_email, notification_sms, notification_push)',
          )
          .eq('user_id', uid)
          .maybeSingle();

      if (provRow != null) {
        final userMap = provRow['users'] as Map<String, dynamic>? ?? {};

        // Count services
        final svcRes = await Supabase.instance.client
            .from('services')
            .select('service_id')
            .eq('provider_id', provRow['provider_id'] as String);

        if (mounted) {
          setState(() {
            _providerId = provRow['provider_id'] as String?;
            _businessName = provRow['business_name'] as String? ?? '';
            _category = provRow['category'] as String? ?? '';
            _address = [
              provRow['address'],
              provRow['city'],
              provRow['state'],
            ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
            _description = provRow['bio'] as String? ?? '';
            _rating =
                double.tryParse(provRow['average_rating']?.toString() ?? '0') ??
                0;
            _reviewCount = provRow['total_reviews'] as int? ?? 0;
            _serviceCount = (svcRes as List).length;
            _avatarUrl = provRow['avatar_url'] as String?;

            _email = userMap['email'] as String? ?? '';
            _phone = userMap['phone'] as String? ?? '';
            _emailNewBooking = userMap['notification_email'] as bool? ?? true;
            _smsReminder = userMap['notification_sms'] as bool? ?? false;
            _inAppUpdates = userMap['notification_push'] as bool? ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading provider profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToggle({
    required String column,
    required bool value,
    required String table,
  }) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      if (table == 'users') {
        await Supabase.instance.client
            .from('users')
            .update({column: value})
            .eq('user_id', uid);
      } else if (table == 'providers' && _providerId != null) {
        await Supabase.instance.client
            .from('providers')
            .update({column: value})
            .eq('provider_id', _providerId!);
      }
    } catch (e) {
      debugPrint('Error saving toggle $column: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.amber)),
      );
    }

    final ratingStr = _rating > 0 ? '${_rating.toStringAsFixed(1)} ⭐' : '—';
    final categoryLine = [
      if (_category.isNotEmpty) _category,
      if (_address.isNotEmpty) _address,
    ].join(' · ');
    final contactLine = [
      if (_email.isNotEmpty) _email,
      if (_phone.isNotEmpty) _phone,
    ].join(' · ');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _businessName.isNotEmpty ? _businessName : 'Provider Profile',
          style: GoogleFonts.fraunces(
            fontSize: 20,
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: const Border(bottom: BorderSide(color: AppColors.line)),
        actions: [
          TextButton(
            onPressed: () => _showEditBusinessSheet(context),
            child: Text(
              'Edit',
              style: GoogleFonts.dmSans(
                color: AppColors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── Business hero ─────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE8A020), AppColors.amber],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _avatarUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.white.withAlpha(128),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  _businessName.isNotEmpty
                                      ? _businessName[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.fraunces(
                                    fontSize: 38,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _businessName.isNotEmpty
                                    ? _businessName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.fraunces(
                                  fontSize: 38,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.line,
                              width: 1.5,
                            ),
                          ),
                          child: _avatarUploading
                              ? const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.amber,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 14,
                                  color: AppColors.ink2,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _businessName.isNotEmpty ? _businessName : 'Your Business',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (categoryLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    categoryLine,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                ],
                if (contactLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    contactLine,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCell(label: 'Rating', value: ratingStr),
                    ),
                    Container(width: 1, height: 36, color: AppColors.line),
                    Expanded(
                      child: _StatCell(
                        label: 'Reviews',
                        value: '$_reviewCount',
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.line),
                    Expanded(
                      child: _StatCell(
                        label: 'Services',
                        value: '$_serviceCount',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Notification preferences ──────────────
          const _SectionHeader('NOTIFICATIONS'),
          Container(
            color: AppColors.white,
            child: Column(
              children: [
                _ToggleRow(
                  icon: Icons.bookmark_add_outlined,
                  title: 'New bookings',
                  subtitle: 'Email when a customer books',
                  value: _emailNewBooking,
                  onChanged: (v) {
                    setState(() => _emailNewBooking = v);
                    _saveToggle(
                      column: 'notification_email',
                      value: v,
                      table: 'users',
                    );
                  },
                ),
                const AppDivider(),
                _ToggleRow(
                  icon: Icons.cancel_outlined,
                  title: 'Cancellations',
                  subtitle: 'Email when a booking is cancelled',
                  value: _emailCancel,
                  onChanged: (v) {
                    setState(() => _emailCancel = v);
                    _saveToggle(
                      column: 'notification_email_cancel',
                      value: v,
                      table: 'users',
                    );
                  },
                ),
                const AppDivider(),
                _ToggleRow(
                  icon: Icons.sms_outlined,
                  title: 'SMS reminders',
                  subtitle: '2 hours before each appointment',
                  value: _smsReminder,
                  onChanged: (v) {
                    setState(() => _smsReminder = v);
                    _saveToggle(
                      column: 'notification_sms',
                      value: v,
                      table: 'users',
                    );
                  },
                ),
                const AppDivider(),
                _ToggleRow(
                  icon: Icons.notifications_outlined,
                  title: 'In-app updates',
                  subtitle: 'Status changes and messages',
                  value: _inAppUpdates,
                  onChanged: (v) {
                    setState(() => _inAppUpdates = v);
                    _saveToggle(
                      column: 'notification_push',
                      value: v,
                      table: 'users',
                    );
                  },
                ),
                const AppDivider(),
                _ToggleRow(
                  icon: Icons.summarize_outlined,
                  title: 'Daily summary',
                  subtitle: 'Morning overview of the day\'s bookings',
                  value: _dailySummary,
                  onChanged: (v) {
                    setState(() => _dailySummary = v);
                    _saveToggle(
                      column: 'notification_daily_summary',
                      value: v,
                      table: 'users',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Business settings ─────────────────────
          const _SectionHeader('BOOKING SETTINGS'),
          Container(
            color: AppColors.white,
            child: Column(
              children: [
                _ToggleRow(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Auto-confirm bookings',
                  subtitle: 'Automatically confirm all new bookings',
                  value: _autoConfirm,
                  onChanged: (v) {
                    setState(() => _autoConfirm = v);
                    _saveToggle(
                      column: 'auto_confirm',
                      value: v,
                      table: 'providers',
                    );
                  },
                  accentColor: AppColors.amber,
                ),
                const AppDivider(),
                _ToggleRow(
                  icon: Icons.edit_calendar_outlined,
                  title: 'Allow customer reschedule',
                  subtitle: 'Up to 24 hours before appointment',
                  value: _allowReschedule,
                  onChanged: (v) {
                    setState(() => _allowReschedule = v);
                    _saveToggle(
                      column: 'allow_reschedule',
                      value: v,
                      table: 'providers',
                    );
                  },
                ),
                const AppDivider(),
                _ToggleRow(
                  icon: Icons.star_outline,
                  title: 'Show ratings publicly',
                  subtitle: 'Display your star rating to customers',
                  value: _showRating,
                  onChanged: (v) {
                    setState(() => _showRating = v);
                    _saveToggle(
                      column: 'show_rating',
                      value: v,
                      table: 'providers',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Cancellation policy ───────────────────
          const _SectionHeader('CANCELLATION POLICY'),
          Container(
            color: AppColors.white,
            child: InkWell(
              onTap: () => _showCancellationPolicySheet(context),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.policy_outlined,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current policy',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Free until 24h · 50% fee within 24h',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Account ───────────────────────────────
          const _SectionHeader('ACCOUNT'),
          Container(
            color: AppColors.white,
            child: Column(
              children: [
                _TapRow(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () => _showChangePasswordSheet(context),
                ),
                const AppDivider(),
                _TapRow(
                  icon: Icons.payment_outlined,
                  title: 'Payout Settings',
                  onTap: () {},
                ),
                const AppDivider(),
                _TapRow(
                  icon: Icons.shield_outlined,
                  title: 'Privacy & Data',
                  onTap: () {},
                ),
                const AppDivider(),
                _TapRow(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Sign out ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton(
              onPressed: () => _confirmSignOut(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.line, width: 1.5),
                foregroundColor: AppColors.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
              ),
            ),
          ),

          Center(
            child: Text(
              'BookIt Provider · v1.0.0',
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Bottom sheets & dialogs ──────────────────

  void _showEditBusinessSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _businessName);
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phone);
    final addrCtrl = TextEditingController(text: _address);
    final descCtrl = TextEditingController(text: _description);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _BottomSheet(
          title: 'Edit Business',
          child: Column(
            children: [
              _SheetField(label: 'Business name', controller: nameCtrl),
              const SizedBox(height: 12),
              _SheetField(
                label: 'Email',
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _SheetField(
                label: 'Phone',
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _SheetField(label: 'Address', controller: addrCtrl),
              const SizedBox(height: 12),
              _SheetField(label: 'Bio', controller: descCtrl, maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setSheet(() => saving = true);
                          final uid =
                              Supabase.instance.client.auth.currentUser?.id;

                          // Capture navigator and messenger before await
                          final nav = Navigator.of(ctx);
                          final msg = ScaffoldMessenger.of(context);

                          if (uid != null && _providerId != null) {
                            try {
                              await Future.wait([
                                Supabase.instance.client
                                    .from('providers')
                                    .update({
                                      'business_name': nameCtrl.text.trim(),
                                      'bio': descCtrl.text.trim(),
                                      'address': addrCtrl.text.trim(),
                                    })
                                    .eq('provider_id', _providerId!),
                                Supabase.instance.client
                                    .from('users')
                                    .update({
                                      'email': emailCtrl.text.trim(),
                                      'phone': phoneCtrl.text.trim(),
                                    })
                                    .eq('user_id', uid),
                              ]);

                              // Force cache refresh in case business name changed
                              await ProviderSession.instance.refresh();

                              if (!mounted) return;
                              setState(() {
                                _businessName = nameCtrl.text.trim();
                                _email = emailCtrl.text.trim();
                                _phone = phoneCtrl.text.trim();
                                _address = addrCtrl.text.trim();
                                _description = descCtrl.text.trim();
                              });
                              nav.pop();
                              msg.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Profile updated ✓',
                                    style: GoogleFonts.dmSans(),
                                  ),
                                  backgroundColor: AppColors.ink,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              msg.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Save failed: $e',
                                    style: GoogleFonts.dmSans(),
                                  ),
                                  backgroundColor: AppColors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                          if (mounted) setSheet(() => saving = false);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => _BottomSheet(
          title: 'Change Password',
          child: Column(
            children: [
              _SheetField(
                label: 'New password',
                controller: newPassCtrl,
                obscure: true,
              ),
              const SizedBox(height: 12),
              _SheetField(
                label: 'Confirm new password',
                controller: confirmCtrl,
                obscure: true,
              ),
              const SizedBox(height: 24),
              _AmberButton(
                label: saving ? 'Updating…' : 'Update Password',
                onTap: saving
                    ? () {}
                    : () async {
                        final newPwd = newPassCtrl.text;
                        if (newPwd.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password must be at least 8 characters.',
                              ),
                            ),
                          );
                          return;
                        }
                        if (newPwd != confirmCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Passwords do not match.'),
                            ),
                          );
                          return;
                        }
                        setSheet(() => saving = true);
                        final nav = Navigator.of(ctx);
                        final msg = ScaffoldMessenger.of(context);
                        try {
                          await Supabase.instance.client.auth.updateUser(
                            UserAttributes(password: newPwd),
                          );
                          nav.pop();
                          msg.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Password updated ✓',
                                style: GoogleFonts.dmSans(),
                              ),
                              backgroundColor: AppColors.ink,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        } on AuthException catch (e) {
                          setSheet(() => saving = false);
                          msg.showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.message}'),
                              backgroundColor: AppColors.red,
                            ),
                          );
                        } catch (_) {
                          setSheet(() => saving = false);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancellationPolicySheet(BuildContext context) {
    int window = 24;
    double feePercent = 50;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => _BottomSheet(
          title: 'Cancellation Policy',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Free cancellation window',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final h in [12, 24, 48, 72])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => window = h),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: window == h
                                ? AppColors.amber
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: window == h
                                  ? AppColors.amber
                                  : AppColors.line,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${h}h',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: window == h
                                  ? Colors.white
                                  : AppColors.ink2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Late cancellation fee',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final pct in [0.0, 25.0, 50.0, 100.0])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => feePercent = pct),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: feePercent == pct
                                ? AppColors.sage
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: feePercent == pct
                                  ? AppColors.sage
                                  : AppColors.line,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            pct == 0 ? 'None' : '${pct.toInt()}%',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: feePercent == pct
                                  ? Colors.white
                                  : AppColors.ink2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.sageLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sageMid),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.sage,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Free cancellation up to ${window}h before. '
                        '${feePercent == 0 ? 'No fee' : '${feePercent.toInt()}% fee'} within ${window}h.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.sage,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _AmberButton(
                label: 'Save Policy',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign out?',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
        content: Text(
          'You will need to sign in again to access your provider account.',
          style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await Supabase.instance.client.auth.signOut();
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.dmSans(
                color: AppColors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || _providerId == null) return;
    setState(() => _avatarUploading = true);
    final url = await AvatarService.instance.pickAndUpload(
      context: context,
      bucketFolder: 'providers',
      userId: uid,
    );
    if (url != null) {
      await Supabase.instance.client
          .from('providers')
          .update({'avatar_url': url})
          .eq('provider_id', _providerId!);
      if (mounted) setState(() => _avatarUrl = url);
    }
    if (mounted) setState(() => _avatarUploading = false);
  }
}

// ── Shared profile widgets ────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.muted,
      ),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accentColor;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: accentColor ?? AppColors.sage,
        ),
      ],
    ),
  );
}

class _TapRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _TapRow({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
        ],
      ),
    ),
  );
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w500,
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

class _BottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _BottomSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
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
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    ),
  );
}

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;

  const _SheetField({
    required this.label,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.ink2,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
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
            borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    ],
  );
}

class _AmberButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AmberButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.amber,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
  );
}
