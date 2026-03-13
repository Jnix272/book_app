import 'package:flutter/material.dart';

enum DayOfWeek {
  monday('Mon', 'Monday', 1),
  tuesday('Tue', 'Tuesday', 2),
  wednesday('Wed', 'Wednesday', 3),
  thursday('Thu', 'Thursday', 4),
  friday('Fri', 'Friday', 5),
  saturday('Sat', 'Saturday', 6),
  sunday('Sun', 'Sunday', 0); // Sunday = 0 in PostgreSQL DOW

  final String label;
  final String fullLabel;

  /// The value stored in `provider_schedules.day_of_week` (PostgreSQL DOW).
  final int dbIndex;

  const DayOfWeek(this.label, this.fullLabel, this.dbIndex);

  static DayOfWeek fromDbIndex(int index) =>
      DayOfWeek.values.firstWhere((d) => d.dbIndex == index);
}

class WorkingHours {
  DayOfWeek day;
  bool isOpen;
  TimeOfDay startTime;
  TimeOfDay endTime;

  WorkingHours({
    required this.day,
    required this.isOpen,
    required this.startTime,
    required this.endTime,
  });
}
