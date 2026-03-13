import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_theme.dart';
import '../../../providers/provider_dashboard_providers.dart';
import '../../../providers/repository_providers.dart';

class BlockTimeScreen extends ConsumerStatefulWidget {
  const BlockTimeScreen({super.key});

  @override
  ConsumerState<BlockTimeScreen> createState() => _BlockTimeScreenState();
}

class _BlockTimeScreenState extends ConsumerState<BlockTimeScreen> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  String _reason = 'Holiday / Vacation';
  final _noteController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Removed _loadExistingBlocks since we'll use providerTimeOffsProvider inside build

  Future<void> _deleteBlock(String timeOffId) async {
    try {
      final success = await ref.read(scheduleRepositoryProvider).deleteBlockedTime(timeOffId);
      if (!success) throw Exception('Deletion failed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Block removed ✓', style: GoogleFonts.dmSans()),
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        ref.invalidate(providerTimeOffsProvider);
      }
    } catch (e) {
      debugPrint('Error deleting block: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to remove block',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Save new block ────────────────────────────────────────

  Future<void> _saveBlock() async {
    final providerId = ref.read(currentProviderIdProvider);
    if (providerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Provider account not found.',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final startDt = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDt = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (!endDt.isAfter(startDt)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'End must be after start',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.amber,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final note = _noteController.text.trim();
      final reason = note.isNotEmpty ? '$_reason — $note' : _reason;

      final success = await ref.read(scheduleRepositoryProvider).addBlockedTime(providerId, startDt, endDt, reason);
      if (!success) throw Exception('Creation failed');

      if (mounted) {
        _noteController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time blocked ✓', style: GoogleFonts.dmSans()),
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        ref.invalidate(providerTimeOffsProvider);
      }
    } catch (e) {
      debugPrint('Error saving block time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block time', style: GoogleFonts.dmSans()),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Date / time pickers ───────────────────────────────────

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.amber),
        ),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.amber),
        ),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'Block Time',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Block off time',
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Customers won't be able to book during blocked periods.",
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 28),

            // ── Date / time pickers ───────────────────
            Card(
              child: Column(
                children: [
                  _DateTimeTile(
                    label: 'Start',
                    date: _startDate,
                    time: _startTime,
                    onDateTap: () => _pickDate(true),
                    onTimeTap: () => _pickTime(true),
                  ),
                  const AppDivider(),
                  _DateTimeTile(
                    label: 'End',
                    date: _endDate,
                    time: _endTime,
                    onDateTap: () => _pickDate(false),
                    onTimeTap: () => _pickTime(false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Reason ───────────────────────────────
            const SectionLabel('REASON'),
            Card(
              child: Column(
                children: [
                  for (final r in [
                    'Holiday / Vacation',
                    'Personal',
                    'Training',
                    'Maintenance',
                    'Other',
                  ])
                    _ReasonTile(
                      label: r,
                      selected: _reason == r,
                      onTap: () => setState(() => _reason = r),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Notes ────────────────────────────────
            const SectionLabel('NOTES (OPTIONAL)'),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Spring holiday, back on the 15th',
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
                    color: AppColors.amber,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            // ── Save button ──────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveBlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Block',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 36),

            // ── Existing blocks ──────────────────────
            const SectionLabel('UPCOMING BLOCKS'),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final blocksAsync = ref.watch(providerTimeOffsProvider);
                
                return blocksAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  ),
                  error: (err, stack) => Center(
                    child: Text('Error loading blocks', style: GoogleFonts.dmSans()),
                  ),
                  data: (blocks) {
                    if (blocks.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Text(
                          'No upcoming blocks',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: blocks
                          .map(
                            (block) => _ExistingBlockTile(
                              block: block,
                              onDelete: () => _deleteBlock(block['time_off_id'] as String),
                            ),
                          )
                          .toList(),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────

class _ExistingBlockTile extends StatelessWidget {
  final Map<String, dynamic> block;
  final VoidCallback onDelete;

  const _ExistingBlockTile({required this.block, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final start = DateTime.parse(block['start_datetime'] as String).toLocal();
    final end = DateTime.parse(block['end_datetime'] as String).toLocal();
    final reason = block['reason'] as String? ?? '';

    final sameDay = DateUtils.isSameDay(start, end);
    final dateStr = sameDay
        ? DateFormat('EEE, MMM d').format(start)
        : '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
    final timeStr =
        '${DateFormat('h:mm a').format(start)} – ${DateFormat('h:mm a').format(end)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.block_outlined,
              size: 18,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.red,
            ),
            onPressed: onDelete,
            tooltip: 'Remove block',
          ),
        ],
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  const _DateTimeTile({
    required this.label,
    required this.date,
    required this.time,
    required this.onDateTap,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.ink2,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onDateTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF0CDB0)),
            ),
            child: Text(
              DateFormat('MMM d, yyyy').format(date),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.amber,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onTimeTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              time.format(context),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: selected ? AppColors.amber : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.amber : AppColors.line,
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.ink),
          ),
        ],
      ),
    ),
  );
}
