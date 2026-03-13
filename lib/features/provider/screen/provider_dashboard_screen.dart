import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_theme.dart';
import '../../../domain/models/models.dart';
import '../../../core/services/provider_session.dart';
import '../../../providers/provider_dashboard_providers.dart';
import 'provider_appt_detail_screen.dart';
import 'provider_shell.dart';
import 'block_time_screen.dart';
import 'working_hours_screen.dart';
import 'add_edit_service_screen.dart';

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends ConsumerState<ProviderDashboardScreen> {



  // Use ProviderSession for business name — no more hardcoded "Aria Studio"
  String get _businessName =>
      ProviderSession.instance.businessName ?? 'My Business';
  String get _avatarInitial =>
      _businessName.isNotEmpty ? _businessName[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final apptsAsync = ref.watch(providerAppointmentsProvider);
    final isPageLoading = apptsAsync.isLoading;
    final allAppts = apptsAsync.valueOrNull ?? [];

    final todayAppts = allAppts
        .where((a) => DateUtils.isSameDay(a.startsAt, now))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    final weekAgo = now.subtract(const Duration(days: 7));
    final weekAppts = allAppts.where((a) => a.status != 'Cancelled' && a.startsAt.isAfter(weekAgo));
    final weekApptCount = weekAppts.length;
    final weekRevenue = weekAppts.fold(0.0, (sum, a) => sum + a.price);

    return CustomScrollView(
      slivers: [
        // ── App bar ─────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          title: const ProviderLogo(),
          shape: const Border(bottom: BorderSide(color: AppColors.line)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.amber,
                child: Text(
                  _avatarInitial,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ────────────────────────
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$_businessName ',
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                      TextSpan(
                        text: '✦',
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          color: AppColors.sage,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('EEEE, MMMM d').format(now)} · '
                  '${todayAppts.length} appointment${todayAppts.length == 1 ? '' : 's'} today',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Stats row ────────────────────────
                Row(
                  children: [
                    _StatCard(
                      value: '${todayAppts.length}',
                      label: 'Today',
                      color: AppColors.sage,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: '$weekApptCount',
                      label: 'This week',
                      color: AppColors.amber,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: '\$${weekRevenue.toStringAsFixed(0)}',
                      label: 'Revenue',
                      color: AppColors.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Quick actions ────────────────────
                const SectionLabel('QUICK ACTIONS'),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.block_outlined,
                      label: 'Block Time',
                      color: AppColors.amberLight,
                      iconColor: AppColors.amber,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BlockTimeScreen(),
                          ),
                        );
                        ref.invalidate(providerAppointmentsProvider);
                      },
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.schedule,
                      label: 'Set Hours',
                      color: AppColors.sageLight,
                      iconColor: AppColors.sage,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WorkingHoursScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.add_circle_outline,
                      label: 'Add Service',
                      color: const Color(0xFFF0F4FE),
                      iconColor: const Color(0xFF4A6FA5),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditServiceScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Today's schedule ─────────────────
                const SectionLabel("TODAY'S SCHEDULE"),
              ],
            ),
          ),
        ),

        if (isPageLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.sage),
            ),
          )
        else if (todayAppts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _EmptyDay(),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList.separated(
              itemCount: todayAppts.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _AppointmentCard(
                appt: todayAppts[i],
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderApptDetailScreen(
                        appt: todayAppts[i],
                        onStatusChanged: () {
                          ref.invalidate(providerAppointmentsProvider);
                        },
                      ),
                    ),
                  );
                  ref.invalidate(providerAppointmentsProvider);
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ── Dashboard widgets ─────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

class _AppointmentCard extends StatelessWidget {
  final ProviderAppointment appt;
  final VoidCallback onTap;
  const _AppointmentCard({required this.appt, required this.onTap});

  bool get _isNow {
    final now = DateTime.now();
    return now.isAfter(appt.startsAt) && now.isBefore(appt.endsAt);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isNow ? AppColors.sage : AppColors.line,
          width: _isNow ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time block
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _isNow ? AppColors.sage : AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('h:mm').format(appt.startsAt),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _isNow ? Colors.white : AppColors.ink,
                    ),
                  ),
                  Text(
                    DateFormat('a').format(appt.startsAt),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: _isNow
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.muted,
                    ),
                  ),
                  if (_isNow) ...[
                    const SizedBox(height: 4),
                    Text(
                      'NOW',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appt.serviceName,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 13,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appt.customerName,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  if (appt.notes != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.notes,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appt.notes!,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(appt.status),
                const SizedBox(height: 6),
                Text(
                  '\$${appt.price.toStringAsFixed(0)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        const Text('📅', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(
          'No appointments today',
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enjoy the day off!',
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
        ),
      ],
    ),
  );
}
