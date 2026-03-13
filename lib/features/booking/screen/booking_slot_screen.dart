import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_theme.dart';
import '../../../domain/models/models.dart';
import '../../../providers/repository_providers.dart';

// ─────────────────────────────────────────────
// STEP 1 — Date picker + time slot selection
// ─────────────────────────────────────────────

class BookingSlotScreen extends ConsumerStatefulWidget {
  final ServiceProvider provider;
  final ServiceType service;

  const BookingSlotScreen({
    super.key,
    required this.provider,
    required this.service,
  });

  @override
  ConsumerState<BookingSlotScreen> createState() => _BookingSlotScreenState();
}

class _BookingSlotScreenState extends ConsumerState<BookingSlotScreen> {
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
      final repo = ref.read(bookingRepositoryProvider);
      final result = await repo.fetchSlots(
        providerId: widget.provider.id,
        selectedDate: _selectedDate,
        serviceDurationMin: widget.service.durationMin,
      );

      final rawSlots = result['allSlots'] as List<DateTime>;
      final unavailableDateTimes = result['unavailableSlots'] as Set<DateTime>;

      final formatter = DateFormat('h:mm a');
      List<String> formattedSlots = [];
      Set<String> unavailableFormatted = {};

      for (var slotTime in rawSlots) {
        final slotStr = formatter.format(slotTime);
        formattedSlots.add(slotStr);

        if (unavailableDateTimes.contains(slotTime)) {
          unavailableFormatted.add(slotStr);
        }
      }

      if (mounted) {
        setState(() {
          _allSlots = formattedSlots;
          _unavailableSlots = unavailableFormatted;
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


// ── Step indicator helpers ────────────────────────────────────

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
