import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app_theme.dart';
import '../../../models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────
// My Appointments screen
// ─────────────────────────────────────────────

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Appointment> _upcoming = [];
  late List<Appointment> _past = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final res = await Supabase.instance.client
          .from('appointments')
          .select(
            '*, providers(business_name), services(service_name, price, duration_minutes)',
          )
          .eq('customer_id', user.id)
          .order('appointment_datetime', ascending: true);

      final now = DateTime.now();
      final allAppts = (res as List)
          .map((a) => Appointment.fromJson(a))
          .toList();

      if (mounted) {
        setState(() {
          _upcoming = allAppts.where((a) => a.startsAt.isAfter(now)).toList();
          _past = allAppts.where((a) => a.startsAt.isBefore(now)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load appointments: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.sage,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.sage,
              indicatorWeight: 2,
              labelStyle: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 14),
              tabs: [
                Tab(text: 'Upcoming (${_upcoming.length})'),
                Tab(text: 'Past (${_past.length})'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.sage),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _AppointmentList(
                  appointments: _upcoming,
                  emptyMessage: 'No upcoming appointments',
                  emptySubtext: 'Book your first appointment to get started',
                  emptyEmoji: '📅',
                  onTap: (appt) async {
                    final result = await context.push<bool>(
                      '/appointment_detail',
                      extra: appt,
                    );
                    if (result == true) {
                      _fetchAppointments();
                    }
                  },
                ),
                _AppointmentList(
                  appointments: _past,
                  emptyMessage: 'No past appointments',
                  emptySubtext: 'Your completed appointments will appear here',
                  emptyEmoji: '🗓️',
                  onTap: (appt) async {
                    final result = await context.push<bool>(
                      '/appointment_detail',
                      extra: appt,
                    );
                    if (result == true) {
                      _fetchAppointments();
                    }
                  },
                ),
              ],
            ),
    );
  }
}

// ── Appointment list ──────────────────────────────────────────

class _AppointmentList extends StatelessWidget {
  final List<Appointment> appointments;
  final String emptyMessage;
  final String emptySubtext;
  final String emptyEmoji;
  final void Function(Appointment) onTap;

  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
    required this.emptySubtext,
    required this.emptyEmoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emptyEmoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtext,
              style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final appt = appointments[i];
        return GestureDetector(
          onTap: () => onTap(appt),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // time block
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('h:mm').format(appt.startsAt),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          DateFormat('a').format(appt.startsAt),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d').format(appt.startsAt),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // details
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
                        Text(
                          appt.providerName,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // status
                  StatusBadge(appt.status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Appointment Detail screen
// ─────────────────────────────────────────────

class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onCancelled;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.onCancelled,
  });

  bool get _canModify =>
      appointment.status == 'Confirmed' || appointment.status == 'Pending';

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(appointment.startsAt);
    final timeStr =
        '${DateFormat('h:mm a').format(appointment.startsAt)} – ${DateFormat('h:mm a').format(appointment.endsAt)}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(''),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusBadge(appointment.status),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appointment.serviceName,
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appointment.providerName,
              style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.muted),
            ),
            const SizedBox(height: 24),

            // ── Details card ──────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppColors.sage,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Appointment Details',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: dateStr,
                    ),
                    const AppDivider(),
                    _DetailRow(
                      icon: Icons.schedule,
                      label: 'Time',
                      value: timeStr,
                    ),
                    const AppDivider(),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: '12 Maple Street',
                    ),
                    const AppDivider(),
                    _DetailRow(
                      icon: Icons.payments_outlined,
                      label: 'Price',
                      value: '\$${appointment.price.toStringAsFixed(2)}',
                    ),
                    const AppDivider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tag,
                            size: 16,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reference',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sage.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              appointment.reference,
                              style: GoogleFonts.dmMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Cancellation policy ───────────────
            if (_canModify) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cancellation policy',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Free cancellation until '
                        '${DateFormat("MMM d 'at' h:mm a").format(appointment.startsAt.subtract(const Duration(hours: 24)))}. '
                        'After that, a 50% fee applies.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Action buttons ────────────────────
              OutlineButton2(
                '🔄  Reschedule Appointment',
                onTap: () async {
                  final result = await context.push<bool>(
                    '/reschedule',
                    extra: appointment,
                  );
                  if (result == true && context.mounted) {
                    context.pop(true);
                  }
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _showCancelSheet(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(
                      color: Color(0xFFF5C6C1),
                      width: 1.5,
                    ),
                    backgroundColor: AppColors.redLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '✕  Cancel Appointment',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],

            if (!_canModify) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.muted,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This appointment cannot be modified.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelSheet(BuildContext context) {
    String selectedReason = 'Change of plans';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // handle
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
                'Cancel appointment?',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.muted,
                    height: 1.6,
                  ),
                  children: const [
                    TextSpan(
                      text: 'This appointment is within the 24-hour window. A ',
                    ),
                    TextSpan(
                      text: '50% cancellation fee (\$22.50)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
                      ),
                    ),
                    TextSpan(text: ' will apply.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'REASON',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              for (final reason in [
                'Change of plans',
                'Found another provider',
                'Emergency',
                'Other',
              ])
                // ignore: deprecated_member_use_from_same_package, deprecated_member_use
                RadioListTile<String>(
                  value: reason,
                  // ignore: deprecated_member_use
                  groupValue: selectedReason,
                  // ignore: deprecated_member_use
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedReason = val);
                    }
                  },
                  title: Text(reason, style: GoogleFonts.dmSans(fontSize: 14)),
                  activeColor: AppColors.sage,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        side: const BorderSide(
                          color: AppColors.line,
                          width: 1.5,
                        ),
                        foregroundColor: AppColors.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Keep it',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await Supabase.instance.client
                              .from('appointments')
                              .update({
                                'status': 'cancelled',
                                'updated_at': DateTime.now()
                                    .toUtc()
                                    .toIso8601String(),
                              })
                              .eq('appointment_id', appointment.id);

                          if (context.mounted) {
                            context.pop(); // Close the modal
                            context.pop(true); // Pop data back to refresh view
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Appointment cancelled. Refund initiated.',
                                  style: GoogleFonts.dmSans(),
                                ),
                                backgroundColor: AppColors.ink,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to cancel: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: AppColors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel & Pay Fee',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
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
}

// ── Detail row ────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
// Reschedule screen
// ─────────────────────────────────────────────

class RescheduleScreen extends StatefulWidget {
  final Appointment appointment;
  const RescheduleScreen({super.key, required this.appointment});

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlot;

  List<DateTime> get _dates =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i + 1)));

  final List<String> _allSlots = [
    '9:00 AM',
    '9:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '1:00 PM',
    '1:30 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '4:30 PM',
    '5:00 PM',
  ];
  final Set<String> _unavailableSlots = {'10:00 AM', '1:30 PM'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'Reschedule',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick a new time',
                    style: GoogleFonts.fraunces(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.appointment.serviceName} · ${widget.appointment.providerName}',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  const SectionLabel('Select Date'),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dates.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final date = _dates[i];
                        final isSelected = DateUtils.isSameDay(
                          date,
                          _selectedDate,
                        );
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedDate = date;
                            _selectedSlot = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 56,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.amber
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.amber
                                    : AppColors.line,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE').format(date),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.sage.withValues(alpha: 0.1)
                                        : AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('d').format(date),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.ink,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM').format(date),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  const SectionLabel('Available Times'),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _allSlots.length,
                    itemBuilder: (context, i) {
                      final slot = _allSlots[i];
                      final unavailable = _unavailableSlots.contains(slot);
                      final selected = slot == _selectedSlot;
                      return GestureDetector(
                        onTap: unavailable
                            ? null
                            : () => setState(() => _selectedSlot = slot),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: unavailable
                                ? AppColors.bg
                                : selected
                                ? AppColors.amber
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: unavailable
                                  ? AppColors.line
                                  : selected
                                  ? AppColors.amber
                                  : AppColors.line,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              slot,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: unavailable
                                    ? AppColors.muted
                                    : selected
                                    ? Colors.white
                                    : AppColors.ink,
                                decoration: unavailable
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // CTA
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedSlot == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Appointment rescheduled ✓',
                              style: GoogleFonts.dmSans(),
                            ),
                            backgroundColor: AppColors.ink,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  disabledBackgroundColor: AppColors.line,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _selectedSlot == null
                      ? 'Select a time to confirm'
                      : 'Confirm Reschedule',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _selectedSlot == null
                        ? AppColors.muted
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
