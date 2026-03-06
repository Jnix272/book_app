import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app_theme.dart';
import '../../../models/models.dart';
import '../../../core/services/provider_session.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  List<WorkingHours> _hours = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchWorkingHours();
  }

  Future<void> _fetchWorkingHours() async {
    // ProviderSession caches the provider_id so subsequent calls are free.
    final providerId = await ProviderSession.instance.providerId;
    if (providerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final rows = await Supabase.instance.client
          .from('provider_schedules')
          .select()
          .eq('provider_id', providerId)
          .order('day_of_week');

      // DB uses 0=Sunday … 6=Saturday (PostgreSQL EXTRACT(DOW) convention).
      // DayOfWeek enum is ordered: monday(0) … sunday(6), so we map by dbIndex.
      if (rows.isEmpty) {
        _hours = List.generate(7, (i) {
          final day = DayOfWeek.values[i];
          // Default Mon–Fri open
          final isOpen = day != DayOfWeek.saturday && day != DayOfWeek.sunday;
          return WorkingHours(
            day: day,
            isOpen: isOpen,
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
          );
        });
      } else {
        _hours = List.generate(7, (i) {
          final day = DayOfWeek.values[i];
          // Match by dbIndex, NOT by list index.
          final row = (rows as List)
              .cast<Map<String, dynamic>>()
              .where((r) => r['day_of_week'] == day.dbIndex)
              .firstOrNull;

          if (row != null) {
            return WorkingHours(
              day: day,
              isOpen: row['is_active'] as bool,
              startTime: _parseTime(row['start_time'] as String),
              endTime: _parseTime(row['end_time'] as String),
            );
          }
          return WorkingHours(
            day: day,
            isOpen: false,
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
          );
        });
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching working hours: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _saveChanges() async {
    // ── Validate: end must be after start for all open days ──
    for (final h in _hours.where((h) => h.isOpen)) {
      if (_toMinutes(h.endTime) <= _toMinutes(h.startTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${h.day.fullLabel}: end time must be after start time.',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.amber,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final providerId = await ProviderSession.instance.providerId;
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

    setState(() => _isSaving = true);

    try {
      final upsertPayload = _hours
          .map(
            (h) => {
              'provider_id': providerId,
              'day_of_week': h.day.dbIndex, // use dbIndex, not enum index
              'start_time': _formatTime(h.startTime),
              'end_time': _formatTime(h.endTime),
              'is_active': h.isOpen,
            },
          )
          .toList();

      await Supabase.instance.client
          .from('provider_schedules')
          .upsert(upsertPayload, onConflict: 'provider_id,day_of_week');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Working hours saved ✓', style: GoogleFonts.dmSans()),
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving working hours: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e', style: GoogleFonts.dmSans()),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _hours[index].startTime : _hours[index].endTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.sage),
        ),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      setState(() {
        if (isStart) {
          _hours[index].startTime = picked;
        } else {
          _hours[index].endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'Working Hours',
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sage),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Working hours',
                          style: GoogleFonts.fraunces(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Set your regular weekly availability. Changes won't affect existing bookings.",
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Column(
                            children: List.generate(_hours.length, (i) {
                              final h = _hours[i];
                              final endBeforeStart =
                                  h.isOpen &&
                                  _toMinutes(h.endTime) <=
                                      _toMinutes(h.startTime);
                              return Column(
                                children: [
                                  if (i > 0) const AppDivider(),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 90,
                                              child: Text(
                                                h.day.fullLabel,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: h.isOpen
                                                      ? AppColors.ink
                                                      : AppColors.muted,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Switch.adaptive(
                                              value: h.isOpen,
                                              onChanged: (v) =>
                                                  setState(() => h.isOpen = v),
                                              activeTrackColor: AppColors.sage,
                                            ),
                                          ],
                                        ),
                                        if (h.isOpen) ...[
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: _TimePicker(
                                                  label: 'From',
                                                  time: h.startTime,
                                                  onTap: () =>
                                                      _pickTime(i, true),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward,
                                                size: 16,
                                                color: AppColors.muted,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: _TimePicker(
                                                  label: 'To',
                                                  time: h.endTime,
                                                  hasError: endBeforeStart,
                                                  onTap: () =>
                                                      _pickTime(i, false),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (endBeforeStart) ...[
                                            const SizedBox(height: 6),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'End must be after start',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 11,
                                                  color: AppColors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                        if (!h.isOpen)
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 4,
                                                top: 4,
                                              ),
                                              child: Text(
                                                'Closed',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 13,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // ── Sticky save button ────────────────────
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
                onPressed: _isLoading || _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sage,
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
                        'Save Changes',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  final bool hasError;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasError ? AppColors.redLight : AppColors.sageLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: hasError ? AppColors.red : AppColors.sageMid),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: hasError ? AppColors.red : AppColors.sage,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            time.format(context),
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: hasError ? AppColors.red : AppColors.sage,
            ),
          ),
        ],
      ),
    ),
  );
}
