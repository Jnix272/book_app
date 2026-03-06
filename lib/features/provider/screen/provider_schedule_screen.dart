import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app_theme.dart';
import '../../../models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/provider_session.dart';
import 'provider_appt_detail_screen.dart';
import 'provider_shell.dart';
import 'block_time_screen.dart';
import 'working_hours_screen.dart';

class ProviderScheduleScreen extends StatefulWidget {
  const ProviderScheduleScreen({super.key});

  @override
  State<ProviderScheduleScreen> createState() => _ProviderScheduleScreenState();
}

class _ProviderScheduleScreenState extends State<ProviderScheduleScreen> {
  DateTime _weekStart = _mondayOf(DateTime.now());
  List<ProviderAppointment> _weekAppts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeekAppointments();
  }

  static DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  Future<void> _fetchWeekAppointments() async {
    if (mounted) setState(() => _isLoading = true);

    // BUG FIX: appointments.provider_id references providers.provider_id,
    // NOT auth uid. Use ProviderSession.
    final providerId = await ProviderSession.instance.providerId;
    if (providerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final endOfWeek = _weekStart.add(const Duration(days: 7));

    try {
      final response = await Supabase.instance.client
          .from('appointments')
          .select(
            '*, services(service_name, price, duration_minutes), '
            'users!inner(first_name, last_name)',
          )
          .eq('provider_id', providerId)
          .gte('appointment_datetime', _weekStart.toUtc().toIso8601String())
          .lt('appointment_datetime', endOfWeek.toUtc().toIso8601String());

      final appts = (response as List)
          .map((json) => ProviderAppointment.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _weekAppts = appts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedule appointments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _prevWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
    _fetchWeekAppointments();
  }

  void _nextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
    _fetchWeekAppointments();
  }

  List<DateTime> get _days =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  List<ProviderAppointment> _apptsForDay(DateTime day) =>
      _weekAppts.where((a) => DateUtils.isSameDay(a.startsAt, day)).toList()
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
              _fetchWeekAppointments();
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sage),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _days.map((day) {
                        final appts = _apptsForDay(day);
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
                                                  builder: (_) =>
                                                      ProviderApptDetailScreen(
                                                        appt: a,
                                                        onStatusChanged:
                                                            _fetchWeekAppointments,
                                                      ),
                                                ),
                                              );
                                              _fetchWeekAppointments();
                                            },
                                          ),
                                        )
                                        .toList(),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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
                _fetchWeekAppointments();
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
