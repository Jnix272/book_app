import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app_theme.dart';
import '../../../models/models.dart';

// ─────────────────────────────────────────────
// STEP 1 — Date picker + time slot selection
// ─────────────────────────────────────────────

class BookingSlotScreen extends StatefulWidget {
  final ServiceProvider provider;
  final ServiceType service;

  const BookingSlotScreen({
    super.key,
    required this.provider,
    required this.service,
  });

  @override
  State<BookingSlotScreen> createState() => _BookingSlotScreenState();
}

class _BookingSlotScreenState extends State<BookingSlotScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;

  // Generate 7 days from today
  List<DateTime> get _dates =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  List<String> _allSlots = [];
  Set<String> _unavailableSlots = {};
  bool _isLoadingSlots = true;

  @override
  void initState() {
    super.initState();
    _fetchSlotsForDate();
  }

  Future<void> _fetchSlotsForDate() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
      _allSlots = [];
      _unavailableSlots = {};
    });

    try {
      final dayOfWeek = _selectedDate.weekday % 7;
      final scheduleRes = await Supabase.instance.client
          .from('provider_schedules')
          .select('start_time, end_time')
          .eq('provider_id', widget.provider.id)
          .eq('day_of_week', dayOfWeek)
          .eq('is_open', true) // new schema: is_open not is_active
          .maybeSingle();

      String startTimeStr = '09:00:00';
      String endTimeStr = '17:00:00';
      if (scheduleRes != null) {
        startTimeStr = scheduleRes['start_time'] as String;
        endTimeStr = scheduleRes['end_time'] as String;
      }

      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');

      var current = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );
      final end = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      List<DateTime> generatedSlots = [];
      while (current.isBefore(end)) {
        generatedSlots.add(current);
        current = current.add(const Duration(minutes: 30));
      }

      final startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final nextDay = startOfDay.add(const Duration(days: 1));

      final apptsRes = await Supabase.instance.client
          .from('appointments')
          .select('appointment_datetime, duration_minutes')
          .eq('provider_id', widget.provider.id)
          .gte('appointment_datetime', startOfDay.toUtc().toIso8601String())
          .lt('appointment_datetime', nextDay.toUtc().toIso8601String())
          .neq('status', 'cancelled')
          .neq('status', 'no_show');

      List<DateTimeRange> bookedRanges = [];
      for (var row in (apptsRes as List)) {
        final apptStart = DateTime.parse(
          row['appointment_datetime'] as String,
        ).toLocal();
        final duration = row['duration_minutes'] as int;
        bookedRanges.add(
          DateTimeRange(
            start: apptStart,
            end: apptStart.add(Duration(minutes: duration)),
          ),
        );
      }

      final formatter = DateFormat('h:mm a');
      List<String> slots = [];
      Set<String> unavailable = {};

      for (var slotTime in generatedSlots) {
        final slotEnd = slotTime.add(
          Duration(minutes: widget.service.durationMin),
        );
        final slotStr = formatter.format(slotTime);
        slots.add(slotStr);

        bool isBooked = false;
        for (var range in bookedRanges) {
          if (slotTime.isBefore(range.end) && slotEnd.isAfter(range.start)) {
            isBooked = true;
            break;
          }
        }

        if (isBooked || slotTime.isBefore(DateTime.now())) {
          unavailable.add(slotStr);
        }
      }

      if (mounted) {
        setState(() {
          _allSlots = slots;
          _unavailableSlots = unavailable;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackButton(),
        title: const _StepIndicator(currentStep: 1),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Choose a time',
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.service.name} · ${widget.service.durationMin} min · ${widget.provider.name}',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Date row ──────────────────────
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
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                            });
                            _fetchSlotsForDate();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 56,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.sage
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.sage
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
                                        ? Colors.white.withValues(alpha: 0.8)
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

                  // ── Time slots ────────────────────
                  const SectionLabel('Available Times'),
                  _isLoadingSlots
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              color: AppColors.sage,
                            ),
                          ),
                        )
                      : _allSlots.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No availability on this date.',
                              style: GoogleFonts.dmSans(color: AppColors.muted),
                            ),
                          ),
                        )
                      : GridView.builder(
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
                            final unavailable = _unavailableSlots.contains(
                              slot,
                            );
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
                                      ? AppColors.sage
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: unavailable
                                        ? AppColors.line
                                        : selected
                                        ? AppColors.sage
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Sticky CTA ────────────────────────────
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
                    : () => context.push(
                        '/booking_confirm',
                        extra: {
                          'provider': widget.provider,
                          'service': widget.service,
                          'date': _selectedDate,
                          'slot': _selectedSlot!,
                        },
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sage,
                  disabledBackgroundColor: AppColors.line,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedSlot == null
                      ? 'Select a time to continue'
                      : 'Continue →',
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

// ─────────────────────────────────────────────
// STEP 2 — Confirm booking
// ─────────────────────────────────────────────

class BookingConfirmScreen extends StatefulWidget {
  final ServiceProvider provider;
  final ServiceType service;
  final DateTime date;
  final String slot;

  const BookingConfirmScreen({
    super.key,
    required this.provider,
    required this.service,
    required this.date,
    required this.slot,
  });

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  final _notesController = TextEditingController();
  bool _isConfirming = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    setState(() => _isConfirming = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User is not logged in.');
      }

      final parsedTime = DateFormat("h:mm a").parse(widget.slot);
      final appointmentStart = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      final response = await Supabase.instance.client
          .from('appointments')
          .insert({
            'customer_id': user.id,
            'provider_id': widget.provider.id,
            'service_id': widget.service.id,
            'appointment_datetime': appointmentStart.toIso8601String(),
            'duration_minutes': widget.service.durationMin,
            'status': 'confirmed',
            'notes': _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          })
          .select('appointment_id')
          .single();

      final appointmentId = response['appointment_id'] as String;

      if (mounted) {
        context.go(
          '/booking_confirmed',
          extra: {
            'provider': widget.provider,
            'service': widget.service,
            'date': widget.date,
            'slot': widget.slot,
            'appointmentId': appointmentId,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm booking: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d').format(widget.date);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackButton(),
        title: const _StepIndicator(currentStep: 2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm booking',
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 24),

            // ── Summary card ──────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _SummaryRow('Provider', widget.provider.name),
                    const AppDivider(),
                    _SummaryRow('Service', widget.service.name),
                    const AppDivider(),
                    _SummaryRow('Date', dateStr),
                    const AppDivider(),
                    _SummaryRow('Time', widget.slot),
                    const AppDivider(),
                    _SummaryRow(
                      'Duration',
                      '${widget.service.durationMin} min',
                    ),
                    const AppDivider(),
                    _SummaryRow(
                      'Total',
                      '\$${widget.service.price.toStringAsFixed(2)}',
                      highlight: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Cancellation policy ───────────────
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
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Free cancellation up to 24 hours before your appointment. Within 24 hours, a 50% fee applies.',
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
            const SizedBox(height: 16),

            // ── Notes ─────────────────────────────
            Text(
              'Notes for provider (optional)',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any requests or information for your appointment…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.line,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.line,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.sage,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            _isConfirming
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sage),
                  )
                : PrimaryButton('Confirm Booking →', onTap: _confirmBooking),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepDot(number: 1, done: currentStep > 1, active: currentStep == 1),
        _StepLine(done: currentStep > 1),
        _StepDot(number: 2, done: currentStep > 2, active: currentStep == 2),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final bool done;
  final bool active;
  const _StepDot({
    required this.number,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final bg = done
        ? AppColors.sageLight
        : active
        ? AppColors.sage
        : AppColors.line;
    final fg = done
        ? AppColors.sage
        : active
        ? Colors.white
        : AppColors.muted;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: (done || active) ? AppColors.sage : AppColors.line,
          width: 1.5,
        ),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, size: 13, color: AppColors.sage)
            : Text(
                '$number',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 1.5,
    color: done ? AppColors.sageMid : AppColors.line,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: highlight ? 15 : 14,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
              color: highlight ? AppColors.ink : AppColors.muted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: highlight ? 18 : 14,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? AppColors.sage : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
