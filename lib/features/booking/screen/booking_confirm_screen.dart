import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_theme.dart';
import '../../../domain/models/models.dart';
import '../../../providers/repository_providers.dart';

// ─────────────────────────────────────────────
// STEP 2 — Confirm booking
// ─────────────────────────────────────────────

class BookingConfirmScreen extends ConsumerStatefulWidget {
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
  ConsumerState<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends ConsumerState<BookingConfirmScreen> {
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
      final parsedTime = DateFormat('h:mm a').parse(widget.slot);
      final appointmentStart = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      final repo = ref.read(bookingRepositoryProvider);
      final appointmentId = await repo.confirmBooking(
        providerId: widget.provider.id,
        serviceId: widget.service.id,
        appointmentStart: appointmentStart,
        durationMin: widget.service.durationMin,
        notes: _notesController.text,
      );

      if (mounted) {
        context.go(
          '/booking_confirmed',
          extra: {
            'provider': widget.provider,
            'service': widget.service,
            'slotDateTime': appointmentStart,
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

// ── Private helpers ──────────────────────────────────────────

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
