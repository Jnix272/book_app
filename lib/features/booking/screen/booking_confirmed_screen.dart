import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app_theme.dart';
import '../../../domain/models/models.dart';

class BookingConfirmedScreen extends StatelessWidget {
  final ServiceProvider provider;
  final ServiceType service;
  final DateTime slotDateTime;
  final String appointmentId;

  const BookingConfirmedScreen({
    super.key,
    required this.provider,
    required this.service,
    required this.slotDateTime,
    required this.appointmentId,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(slotDateTime);
    final timeStr = DateFormat('h:mm a').format(slotDateTime);
    final reference = '#BK-${appointmentId.substring(0, 6).toUpperCase()}';

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: Column(
            children: [
              // ── Success icon ──────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.sageLight,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "You're booked!",
                style: GoogleFonts.fraunces(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your appointment is confirmed. A reminder will be sent 24 hours before.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.muted,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Booking summary card ──────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _ConfirmRow(
                        icon: Icons.storefront_outlined,
                        label: 'Provider',
                        value: provider.name,
                      ),
                      const AppDivider(),
                      _ConfirmRow(
                        icon: Icons.content_cut,
                        label: 'Service',
                        value: service.name,
                      ),
                      const AppDivider(),
                      _ConfirmRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date & Time',
                        value: '$dateStr · $timeStr',
                      ),
                      const AppDivider(),
                      _ConfirmRow(
                        icon: Icons.schedule,
                        label: 'Duration',
                        value: '${service.durationMin} min',
                      ),
                      const AppDivider(),
                      _ConfirmRow(
                        icon: Icons.payments_outlined,
                        label: 'Total',
                        value: '\$${service.price.toStringAsFixed(2)}',
                      ),
                      const AppDivider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
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
                              ],
                            ),
                            Text(
                              reference,
                              style: GoogleFonts.dmMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sage,
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

              // ── Reminder info ─────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sageLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sageMid),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.sage,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reminders will be sent 24 hours and 2 hours before your appointment.',
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
              const SizedBox(height: 32),

              // ── Actions ───────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      // Navigate home (which has Appointments tab)
                      onPressed: () => context.go('/', extra: {'tab': 1}),
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
                        'My Bookings',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      // Navigate back home to potentially start another flow
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: AppColors.sage,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Book Another',
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

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    ),
  );
}
