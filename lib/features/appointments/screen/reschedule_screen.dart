import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_theme.dart';
import '../../../domain/models/models.dart';
import '../../../providers/repository_providers.dart';

class RescheduleScreen extends ConsumerStatefulWidget {
  final Appointment appointment;
  const RescheduleScreen({super.key, required this.appointment});

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  bool _isLoadingSlots = false;
  bool _isSaving = false;

  final List<DateTime> _dates = List.generate(
    14,
    (index) => DateTime.now().add(Duration(days: index)),
  );
  List<String> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchSlotsForDate(_selectedDate);
  }

  Future<void> _fetchSlotsForDate(DateTime date) async {
    setState(() => _isLoadingSlots = true);
    try {
      // Fetch available slots from BookingRepository
      final duration = widget.appointment.durationMin + widget.appointment.bufferMin;
      final slotsData = await ref.read(bookingRepositoryProvider).fetchSlots(
            providerId: widget.appointment.providerId,
            selectedDate: date,
            serviceDurationMin: duration,
            intervalMin: duration,
          );

      final allSlots = slotsData['allSlots'] as List<DateTime>;
      final unavailable = slotsData['unavailableSlots'] as Set<DateTime>;

      final validSlots = allSlots
          .where((t) => !unavailable.contains(t))
          .map((t) => DateFormat('h:mm a').format(t))
          .toList();

      if (mounted) {
        setState(() {
          _availableSlots = validSlots;
          _isLoadingSlots = false;
          if (_availableSlots.isNotEmpty) {
             _selectedSlot = _availableSlots.first;
          } else {
             _selectedSlot = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
        debugPrint('Error fetching slots for reschedule: $e');
      }
    }
  }

  Future<void> _attemptReschedule() async {
    if (_selectedSlot == null) return;
    setState(() => _isSaving = true);

    try {
      final parsedTime = DateFormat('h:mm a').parse(_selectedSlot!);

      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        parsedTime.hour,
        parsedTime.minute,
      ).toUtc().toIso8601String();

      await ref.read(appointmentRepositoryProvider).rescheduleAppointment(
            widget.appointment.id,
            finalDateTime,
          );

      if (mounted) {
         context.pop(true); // Pop back to appointments list, perhaps passing true to trigger a reload
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Appointment successfully rescheduled!')),
         );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reschedule: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Reschedule'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a new date and time for your ${widget.appointment.serviceName} with ${widget.appointment.providerName}.',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Select Date',
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dates.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final date = _dates[i];
                        final isSelected = DateUtils.isSameDay(date, _selectedDate);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                              _selectedSlot = null;
                            });
                            _fetchSlotsForDate(date);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 56,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.sage : AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.sage : AppColors.line,
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
                                    color: isSelected ? Colors.white : AppColors.ink,
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
                  const SizedBox(height: 32),
                  Text(
                    'Available Times',
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingSlots)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.sage),
                      ),
                    )
                  else if (_availableSlots.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Text('🙈', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            Text(
                              'No slots available',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try checking another date.',
                              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableSlots.map((slot) {
                        final isSel = _selectedSlot == slot;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSlot = slot),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: (MediaQuery.of(context).size.width - 40 - 12) / 2, // 2 columns
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.sage : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? AppColors.sage : AppColors.line,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                slot,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                                  color: isSel ? Colors.white : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: _isSaving
              ? const SizedBox(
                  height: 56,
                  child: Center(child: CircularProgressIndicator(color: AppColors.sage)),
                )
              : FilledButton(
                  onPressed: _selectedSlot == null ? null : _attemptReschedule,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    disabledBackgroundColor: AppColors.line,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Confirm Reschedule',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
