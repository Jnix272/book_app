import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import '../../domain/models/models.dart';

class ScheduleRepository {
  final SupabaseClient _client;

  ScheduleRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ─────────────────────────────────────────────
  // Working Hours (provider_schedules)
  // ─────────────────────────────────────────────

  Future<List<WorkingHours>> getWorkingHours(String providerId) async {
    try {
      final res = await _client
          .from('provider_schedules')
          .select()
          .eq('provider_id', providerId)
          .order('day_of_week', ascending: true);
      
      return (res as List).map((row) {
        final st = (row['start_time'] as String).split(':');
        final et = (row['end_time'] as String).split(':');
        
        return WorkingHours(
          day: DayOfWeek.values.firstWhere((d) => d.dbIndex == row['day_of_week']),
          isOpen: row['is_open'] as bool,
          startTime: TimeOfDay(hour: int.parse(st[0]), minute: int.parse(st[1])),
          endTime: TimeOfDay(hour: int.parse(et[0]), minute: int.parse(et[1])),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching working hours: $e');
      return [];
    }
  }

  Future<void> updateWorkingHours(
      String providerId, List<WorkingHours> days) async {
    for (final d in days) {
      await _client.from('provider_schedules').upsert({
        'provider_id': providerId,
        'day_of_week': d.day.dbIndex,
        'start_time': '${d.startTime.hour.toString().padLeft(2, '0')}:${d.startTime.minute.toString().padLeft(2, '0')}:00',
        'end_time': '${d.endTime.hour.toString().padLeft(2, '0')}:${d.endTime.minute.toString().padLeft(2, '0')}:00',
        'is_open': d.isOpen,
      });
    }
  }

  // ─────────────────────────────────────────────
  // Time Offs (provider_time_off)
  // ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBlockedTimeOffsets(
      String providerId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final rows = await _client
          .from('provider_time_off')
          .select()
          .eq('provider_id', providerId)
          .gte('end_datetime', now)
          .order('start_datetime', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('Error fetching time_offs: $e');
      return [];
    }
  }

  Future<bool> addBlockedTime(
    String providerId,
    DateTime startDateTime,
    DateTime endDateTime,
    String? reason,
  ) async {
    try {
      await _client.from('provider_time_off').insert({
        'provider_id': providerId,
        'start_datetime': startDateTime.toUtc().toIso8601String(),
        'end_datetime': endDateTime.toUtc().toIso8601String(),
        if (reason != null && reason.isNotEmpty) 'reason': reason.trim(),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding time_off block: $e');
      return false;
    }
  }

  Future<bool> deleteBlockedTime(String blockId) async {
    try {
      await _client.from('provider_time_off').delete().eq('id', blockId);
      return true;
    } catch (e) {
      debugPrint('Error deleting time_off block: $e');
      return false;
    }
  }
}
