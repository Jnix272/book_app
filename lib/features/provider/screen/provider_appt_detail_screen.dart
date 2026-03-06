import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app_theme.dart';
import '../../../models/models.dart';

class ProviderApptDetailScreen extends StatefulWidget {
  final ProviderAppointment appt;
  final VoidCallback? onStatusChanged;

  const ProviderApptDetailScreen({
    super.key,
    required this.appt,
    this.onStatusChanged,
  });

  @override
  State<ProviderApptDetailScreen> createState() =>
      _ProviderApptDetailScreenState();
}

class _ProviderApptDetailScreenState extends State<ProviderApptDetailScreen> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.appt.status;
  }

  Future<void> _updateStatus(String newStatus, {String? reason}) async {
    final dbStatus = switch (newStatus) {
      'Confirmed' => 'confirmed',
      'Cancelled' => 'cancelled',
      'Completed' => 'completed',
      'No Show' => 'no_show',
      'Pending' => 'pending',
      _ => throw ArgumentError('Unknown appointment status: $newStatus'),
    };

    final updates = <String, dynamic>{'status': dbStatus};
    if (reason != null && reason.isNotEmpty) {
      updates['cancellation_reason'] = reason;
    }

    try {
      await Supabase.instance.client
          .from('appointments')
          .update(updates)
          .eq('appointment_id', widget.appt.id);

      if (mounted) {
        setState(() => _status = newStatus);
        widget.onStatusChanged?.call();
      }
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update status',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool get _isActionable => _status == 'Confirmed' || _status == 'Pending';

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${DateFormat('h:mm a').format(widget.appt.startsAt)} – ${DateFormat('h:mm a').format(widget.appt.endsAt)}';
    final dateStr = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(widget.appt.startsAt);
    final durationMin = widget.appt.endsAt
        .difference(widget.appt.startsAt)
        .inMinutes;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(''),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusBadge(_status),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Text(
              widget.appt.serviceName,
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // Using ID if reference not available on Provider model
              widget.appt.id.substring(0, 8).toUpperCase(),
              style: GoogleFonts.dmMono(
                fontSize: 13,
                color: AppColors.sage,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // ── Customer card ─────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.amberLight,
                      child: Text(
                        widget.appt.customerName.isNotEmpty
                            ? widget.appt.customerName[0]
                            : '?',
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          color: AppColors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.appt.customerName,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Phone hidden', // TODO: Add to model if needed
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.sage,
                        size: 20,
                      ),
                      tooltip: 'Call customer',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Appointment details card ──────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
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
                      icon: Icons.timer_outlined,
                      label: 'Duration',
                      value: '$durationMin min',
                    ),
                    const AppDivider(),
                    _DetailRow(
                      icon: Icons.payments_outlined,
                      label: 'Price',
                      value: '\$${widget.appt.price.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Notes card ────────────────────────
            if (widget.appt.notes != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notes,
                            size: 16,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Customer notes',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.amberLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF0CDB0)),
                        ),
                        child: Text(
                          widget.appt.notes!,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.ink2,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Status history ────────────────────
            if (!_isActionable) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status == 'Completed'
                      ? AppColors.sageLight
                      : _status == 'No Show'
                      ? AppColors.amberLight
                      : AppColors.redLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _status == 'Completed'
                        ? AppColors.sageMid
                        : _status == 'No Show'
                        ? const Color(0xFFF0CDB0)
                        : const Color(0xFFF5C6C1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _status == 'Completed'
                          ? Icons.check_circle_outline
                          : _status == 'No Show'
                          ? Icons.person_off_outlined
                          : Icons.cancel_outlined,
                      color: _status == 'Completed'
                          ? AppColors.sage
                          : _status == 'No Show'
                          ? AppColors.amber
                          : AppColors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _status == 'Completed'
                          ? 'Appointment marked as completed.'
                          : _status == 'No Show'
                          ? 'Customer marked as no-show.'
                          : 'Appointment has been cancelled.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: _status == 'Completed'
                            ? AppColors.sage
                            : _status == 'No Show'
                            ? AppColors.amber
                            : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Action buttons ────────────────────
            if (_isActionable) ...[
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.check_circle_outline,
                label: 'Mark as Completed',
                bgColor: AppColors.sageLight,
                fgColor: AppColors.sage,
                borderColor: AppColors.sageMid,
                onTap: () => _confirmAction(
                  context,
                  title: 'Mark as completed?',
                  message:
                      'This will update the appointment status to Completed.',
                  confirmLabel: 'Mark Complete',
                  confirmColor: AppColors.sage,
                  onConfirm: () => _updateStatus('Completed'),
                ),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.person_off_outlined,
                label: 'Mark as No Show',
                bgColor: AppColors.amberLight,
                fgColor: AppColors.amber,
                borderColor: const Color(0xFFF0CDB0),
                onTap: () => _confirmAction(
                  context,
                  title: 'Mark as no-show?',
                  message:
                      'This will flag the customer as a no-show for this appointment.',
                  confirmLabel: 'Mark No Show',
                  confirmColor: AppColors.amber,
                  onConfirm: () => _updateStatus('No Show'),
                ),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.cancel_outlined,
                label: 'Cancel Appointment',
                bgColor: AppColors.redLight,
                fgColor: AppColors.red,
                borderColor: const Color(0xFFF5C6C1),
                onTap: () => _showCancelSheet(context),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
        content: Text(
          message,
          style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await onConfirm();
              // Show success only after the async DB call completes successfully.
              // _updateStatus handles its own error snackbar on failure.
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$confirmLabel successful',
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
            },
            child: Text(
              confirmLabel,
              style: GoogleFonts.dmSans(
                color: confirmColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelSheet(BuildContext context) {
    String selectedReason = 'Scheduling conflict';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
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
              Text(
                'The customer will be notified. A refund may be required based on your cancellation policy.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.muted,
                  height: 1.6,
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
              for (final r in [
                'Scheduling conflict',
                'Provider unavailable',
                'Emergency',
                'Other',
              ])
                // ignore: deprecated_member_use
                RadioListTile<String>(
                  value: r,
                  // ignore: deprecated_member_use
                  groupValue: selectedReason,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setModalState(() => selectedReason = v!),
                  title: Text(r, style: GoogleFonts.dmSans(fontSize: 14)),
                  activeColor: AppColors.amber,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
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
                        Navigator.pop(ctx); // close sheet
                        await _updateStatus(
                          'Cancelled',
                          reason: selectedReason,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Appointment cancelled. Customer notified.',
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
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: AppColors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel Appointment',
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: fgColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    ),
  );
}
