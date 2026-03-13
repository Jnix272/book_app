import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app_theme.dart';
import '../../../domain/models/models.dart';
import '../../../providers/provider_dashboard_providers.dart';
import 'provider_appt_detail_screen.dart';
import 'provider_shell.dart';
import 'block_time_screen.dart';
import 'working_hours_screen.dart';

class ProviderScheduleScreen extends ConsumerStatefulWidget {
  const ProviderScheduleScreen({super.key});

  @override
  ConsumerState<ProviderScheduleScreen> createState() => _ProviderScheduleScreenState();
}

class _ProviderScheduleScreenState extends ConsumerState<ProviderScheduleScreen> {
  DateTime _weekStart = _mondayOf(DateTime.now());

  static DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  void _prevWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  }

  void _nextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
  }

  List<DateTime> get _days =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  List<ProviderAppointment> _apptsForDay(DateTime day, List<ProviderAppointment> weekAppts) =>
      weekAppts.where((a) => DateUtils.isSameDay(a.startsAt, day)).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  String _weekLabel() {
    final end = _weekStart.add(const Duration(days: 6));
    if (_weekStart.month == end.month) {
      return '${DateFormat('MMM d').format(_weekStart)} – '
          '${DateFormat('d, yyyy').format(end)}';
    }
    return '${DateFormat('MMM d').format(_weekStart)} – '
        '${DateFormat('MMM d, yyyy').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const ProviderLogo(),
        shape: const Border(bottom: BorderSide(color: AppColors.line)),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockTimeScreen()),
              );
              ref.invalidate(providerAppointmentsProvider);
            },
            icon: const Icon(Icons.block, size: 16, color: AppColors.amber),
            label: Text(
              'Block',
              style: GoogleFonts.dmSans(
                color: AppColors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Week navigation ───────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _prevWeek,
                  icon: const Icon(Icons.chevron_left, color: AppColors.ink2),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    _weekLabel(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextWeek,
                  icon: const Icon(Icons.chevron_right, color: AppColors.ink2),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // ── Day headers ───────────────────────────
          Container(
            color: AppColors.white,
            child: Row(
              children: _days.map((day) {
                final isToday = DateUtils.isSameDay(day, DateTime.now());
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.sage : Colors.transparent,
                      border: const Border(
                        bottom: BorderSide(color: AppColors.line),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(day),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d').format(day),
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isToday ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Appointment grid ──────────────────────
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final apptsAsync = ref.watch(providerAppointmentsProvider);

                return apptsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.sage),
                  ),
                  error: (err, stack) => const Center(
                    child: Text('Error loading schedule'),
                  ),
                  data: (allAppts) {
                    final endOfWeek = _weekStart.add(const Duration(days: 7));
                    final currentWeekAppts = allAppts.where((a) {
                      return (a.startsAt.isAfter(_weekStart) ||
                              a.startsAt.isAtSameMomentAs(_weekStart)) &&
                          a.startsAt.isBefore(endOfWeek);
                    }).toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _days.map((day) {
                          final appts = _apptsForDay(day, currentWeekAppts);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                children: appts.isEmpty
                                    ? [
                                        Container(
                                          height: 40,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.remove,
                                            size: 14,
                                            color: AppColors.line,
                                          ),
                                        ),
                                      ]
                                    : appts
                                        .map(
                                          (a) => _ScheduleBlock(
                                            appt: a,
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                              MaterialPageRoute(
                                                  builder: (_) => ProviderApptDetailScreen(
                                                    appt: a,
                                                    onStatusChanged: () {
                                                      ref.invalidate(providerAppointmentsProvider);
                                                    },
                                                  ),
                                                ),
                                              );
                                              ref.invalidate(providerAppointmentsProvider);
                                            },
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ── Footer ───────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkingHoursScreen()),
                );
                ref.invalidate(providerAppointmentsProvider);
              },
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Edit Working Hours'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.line, width: 1.5),
                foregroundColor: AppColors.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleBlock extends StatelessWidget {
  final ProviderAppointment appt;
  final VoidCallback onTap;
  const _ScheduleBlock({required this.appt, required this.onTap});

  Color get _blockColor {
    switch (appt.status) {
      case 'Confirmed':
        return AppColors.sageLight;
      case 'Pending':
        return AppColors.amberLight;
      case 'Cancelled':
        return AppColors.redLight;
      case 'Completed':
        return const Color(0xFFEDF7F5);
      case 'No Show':
        return const Color(0xFFFFF3E0);
      case 'Rescheduled':
        return const Color(0xFFE8F0FE);
      default:
        return AppColors.bg;
    }
  }

  Color get _borderColor {
    switch (appt.status) {
      case 'Confirmed':
        return AppColors.sage;
      case 'Pending':
        return AppColors.amber;
      case 'Cancelled':
        return AppColors.red;
      case 'Completed':
        return const Color(0xFF2E7D6E);
      case 'No Show':
        return const Color(0xFFE65100);
      case 'Rescheduled':
        return const Color(0xFF1A56B0);
      default:
        return AppColors.line;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _blockColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: _borderColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('h:mm').format(appt.startsAt),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _borderColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            appt.customerName,
            style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
