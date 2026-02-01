import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

class Subject {
  String id;
  String name;
  double targetAttendance; // e.g., 75.0
  List<int> classDays; // 1 = Monday, 7 = Sunday
  Map<String, bool> attendance;
  Map<String, String> notes;
  bool isWeekly;
  DateTime startDate;
  DateTime? endDate;
  Map<int, String> dayTimings; // Maps day (1-7 or 1-31) to time "HH:mm"
  List<String> holidays; // List of holiday dates in ISO8601 format
  int reminderMinutes; // How many minutes before to show reminder
  Map<int, String> calendarEventIds; // Maps day to eventId in device calendar

  Subject({
    required this.id,
    required this.name,
    required this.targetAttendance,
    required this.classDays,
    required this.attendance,
    this.notes = const {},
    this.isWeekly = true,
    required this.startDate,
    this.endDate,
    this.dayTimings = const {},
    this.holidays = const [],
    this.reminderMinutes = 10,
    this.calendarEventIds = const {},
  });

  int get attendedClasses => attendance.values.where((v) => v).length;
  int get totalClasses => attendance.length;

  double get currentPercentage {
    if (totalClasses == 0) return 100.0;
    return (attendedClasses / totalClasses) * 100;
  }

  int get classesToAttend {
    double target = targetAttendance / 100.0;
    int currentAttended = attendedClasses;
    int currentTotal = totalClasses;

    if (currentPercentage >= targetAttendance) return 0;
    double numerator = (currentTotal * target) - currentAttended;
    double denominator = 1.0 - target;
    if (denominator == 0) return 0;
    double result = numerator / denominator;
    return result.ceil();
  }

  int get classesToBunk {
    if (currentPercentage < targetAttendance) return 0;
    double target = targetAttendance / 100.0;
    if (target == 0) return 999;

    double result = (attendedClasses - (totalClasses * target)) / target;
    return result.floor();
  }

  int get currentStreak {
    if (attendance.isEmpty) return 0;

    int streak = 0;
    DateTime current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);

    // Limit check to start date or 2 years
    DateTime checkLimit =
        startDate.isAfter(current.subtract(const Duration(days: 730)))
        ? startDate
        : current.subtract(const Duration(days: 730));

    // Normalize checkLimit
    checkLimit = DateTime(checkLimit.year, checkLimit.month, checkLimit.day);

    while (current.isAfter(checkLimit) || isSameDay(current, checkLimit)) {
      bool isClassDay = false;
      if (isWeekly) {
        isClassDay = classDays.contains(current.weekday);
      } else {
        isClassDay = classDays.contains(current.day);
      }

      if (isClassDay) {
        String dateKey = current.toIso8601String().split('T')[0];
        bool? status = attendance[dateKey];

        if (status == true) {
          streak++;
        } else if (status == false) {
          return streak;
        } else {
          if (!isSameDay(current, DateTime.now())) {
            return streak;
          }
        }
      }
      current = current.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAttendance': targetAttendance,
      'classDays': classDays,
      'attendance': attendance,
      'notes': notes,
      'isWeekly': isWeekly,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'dayTimings': dayTimings.map((k, v) => MapEntry(k.toString(), v)),
      'holidays': holidays,
      'reminderMinutes': reminderMinutes,
      'calendarEventIds': calendarEventIds.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    // Handle migration from old classTime format
    Map<int, String> parsedTimings = {};
    if (json['dayTimings'] != null) {
      final timingsMap = json['dayTimings'] as Map<String, dynamic>;
      parsedTimings = timingsMap.map(
        (k, v) => MapEntry(int.parse(k), v.toString()),
      );
    } else if (json['classTime'] != null) {
      // Migration: if old classTime exists, apply to all class days
      final oldTime = json['classTime'] as String;
      final days = List<int>.from(json['classDays'] ?? []);
      for (var day in days) {
        parsedTimings[day] = oldTime;
      }
    }

    return Subject(
      id: json['id'],
      name: json['name'],
      targetAttendance: json['targetAttendance'].toDouble(),
      classDays: List<int>.from(json['classDays'] ?? []),
      attendance: Map<String, bool>.from(json['attendance'] ?? {}),
      notes: Map<String, String>.from(json['notes'] ?? {}),
      isWeekly: json['isWeekly'] ?? true,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now().subtract(const Duration(days: 30)),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      dayTimings: parsedTimings,
      holidays: List<String>.from(json['holidays'] ?? []),
      reminderMinutes: json['reminderMinutes'] ?? 10,
      calendarEventIds:
          (json['calendarEventIds'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), v.toString()),
          ) ??
          {},
    );
  }
}

class AttendanceProvider with ChangeNotifier {
  List<Subject> _subjects = [];
  String? _userName;

  List<Subject> get subjects => _subjects;
  String? get userName => _userName;

  AttendanceProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadSubjects();
    await _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name');
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    _userName = name;
    notifyListeners();
  }

  Future<void> addSubject(
    String name,
    double target,
    List<int> days, {
    bool isWeekly = true,
    DateTime? startDate,
    DateTime? endDate,
    Map<int, String>? dayTimings,
    int? reminderMinutes,
  }) async {
    final newSubject = Subject(
      id: DateTime.now().toIso8601String(),
      name: name,
      targetAttendance: target,
      classDays: days,
      attendance: {},
      notes: {},
      isWeekly: isWeekly,
      startDate: startDate ?? DateTime.now(),
      endDate: endDate,
      dayTimings: dayTimings ?? {},
      holidays: [],
      reminderMinutes: reminderMinutes ?? 10,
    );
    _subjects.add(newSubject);
    _saveSubjects();
    notifyListeners();

    // Attempt to add to Device Calendar if timings provided
    if (dayTimings != null && dayTimings.isNotEmpty) {
      await _addToDeviceCalendar(newSubject);
    }
  }

  Future<void> _addToDeviceCalendar(Subject subject) async {
    // First, remove any existing events to avoid duplicates
    await _removeFromDeviceCalendar(subject);

    if (subject.dayTimings.isEmpty) return;

    final DeviceCalendarPlugin deviceCalendarPlugin = DeviceCalendarPlugin();

    // Check permissions
    var permissionsGranted = await deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await deviceCalendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        return; // Permission denied
      }
    }

    // Get calendars
    final calendarsResult = await deviceCalendarPlugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data!.isEmpty) return;

    // Select default or first calendar (writable)
    var calendar = calendarsResult.data!.firstWhere(
      (c) => c.isDefault ?? false,
      orElse: () => calendarsResult.data!.first,
    );
    if (calendar.isReadOnly == true) {
      try {
        calendar = calendarsResult.data!.firstWhere(
          (c) => c.isReadOnly == false,
        );
      } catch (e) {
        return;
      }
    }

    // Create events for each day with timing
    for (var entry in subject.dayTimings.entries) {
      final day = entry.key; // 1 = Mon, 7 = Sun
      final timeStr = entry.value;

      final parts = timeStr.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      // Find first occurrence on the correct day of week
      DateTime firstInstance = subject.startDate;

      if (subject.isWeekly) {
        // Adjust firstInstance to the next occurrence of 'day' (1=Mon)
        int currentWeekday = firstInstance.weekday;
        int daysToAdd = (day - currentWeekday + 7) % 7;
        firstInstance = firstInstance.add(Duration(days: daysToAdd));
      }

      firstInstance = DateTime(
        firstInstance.year,
        firstInstance.month,
        firstInstance.day,
        hour,
        minute,
      );

      // If that first instance is in the past, move it forward by 1 week
      if (firstInstance.isBefore(DateTime.now())) {
        if (subject.isWeekly) {
          firstInstance = firstInstance.add(const Duration(days: 7));
        } else {
          // Monthly case - move to next month same date
          firstInstance = DateTime(
            firstInstance.year,
            firstInstance.month + 1,
            firstInstance.day,
            hour,
            minute,
          );
        }
      }

      final event = Event(
        calendar.id,
        title: subject.name,
        description: 'Class for ${subject.name}',
        start: tz.TZDateTime.from(firstInstance, tz.local),
        end: tz.TZDateTime.from(
          firstInstance.add(const Duration(minutes: 60)),
          tz.local,
        ),
      );

      if (subject.isWeekly) {
        final dayOfWeek = _getDayOfWeek(day);
        if (dayOfWeek != null) {
          final recurrenceRule = RecurrenceRule(
            RecurrenceFrequency.Weekly,
            daysOfWeek: [dayOfWeek],
          );
          if (subject.endDate != null) {
            recurrenceRule.endDate = subject.endDate;
          }
          event.recurrenceRule = recurrenceRule;
        }
      }

      event.reminders = [Reminder(minutes: subject.reminderMinutes)];
      final result = await deviceCalendarPlugin.createOrUpdateEvent(event);
      if (result != null && result.isSuccess && result.data != null) {
        subject.calendarEventIds[day] = result.data!;
      }
    }
    _saveSubjects();
  }

  Future<void> _removeFromDeviceCalendar(Subject subject) async {
    if (subject.calendarEventIds.isEmpty) return;

    final DeviceCalendarPlugin deviceCalendarPlugin = DeviceCalendarPlugin();

    // Check permissions
    var permissionsGranted = await deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await deviceCalendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        return;
      }
    }

    // Get calendars to find the one that might contain these events
    final calendarsResult = await deviceCalendarPlugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data!.isEmpty) return;

    // Use the same logic as _addToDeviceCalendar to find the likely calendar
    var calendar = calendarsResult.data!.firstWhere(
      (c) => c.isDefault ?? false,
      orElse: () => calendarsResult.data!.first,
    );
    if (calendar.isReadOnly == true) {
      try {
        calendar = calendarsResult.data!.firstWhere(
          (c) => c.isReadOnly == false,
        );
      } catch (e) {
        return;
      }
    }

    for (var eventId in subject.calendarEventIds.values) {
      await deviceCalendarPlugin.deleteEvent(calendar.id, eventId);
    }

    subject.calendarEventIds.clear();
    _saveSubjects();
  }

  DayOfWeek? _getDayOfWeek(int day) {
    const map = {
      1: DayOfWeek.Monday,
      2: DayOfWeek.Tuesday,
      3: DayOfWeek.Wednesday,
      4: DayOfWeek.Thursday,
      5: DayOfWeek.Friday,
      6: DayOfWeek.Saturday,
      7: DayOfWeek.Sunday,
    };
    return map[day];
  }

  Future<void> updateSubject(
    String id, {
    String? name,
    double? targetAttendance,
    List<int>? classDays,
    bool? isWeekly,
    DateTime? startDate,
    DateTime? endDate,
    Map<int, String>? dayTimings,
    int? reminderMinutes,
  }) async {
    final index = _subjects.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final subject = _subjects[index];

    // Update fields
    if (name != null) subject.name = name;
    if (targetAttendance != null) subject.targetAttendance = targetAttendance;
    if (classDays != null) subject.classDays = classDays;
    if (isWeekly != null) subject.isWeekly = isWeekly;
    if (startDate != null) subject.startDate = startDate;
    subject.endDate = endDate; // Allow null to clear
    if (dayTimings != null) subject.dayTimings = dayTimings;
    if (reminderMinutes != null) subject.reminderMinutes = reminderMinutes;

    _saveSubjects();
    notifyListeners();

    // Update calendar events if timings changed
    if (dayTimings != null && dayTimings.isNotEmpty) {
      await _addToDeviceCalendar(subject);
    }
  }

  Future<void> deleteSubject(String id) async {
    final index = _subjects.indexWhere((s) => s.id == id);
    if (index != -1) {
      final subject = _subjects[index];
      await _removeFromDeviceCalendar(subject);
      _subjects.removeAt(index);
      _saveSubjects();
      notifyListeners();
    }
  }

  void addHoliday(String subjectId, DateTime date) {
    final index = _subjects.indexWhere((s) => s.id == subjectId);
    if (index == -1) return;

    final dateKey = date.toIso8601String().split('T')[0];
    if (!_subjects[index].holidays.contains(dateKey)) {
      _subjects[index].holidays = [..._subjects[index].holidays, dateKey];
      _saveSubjects();
      notifyListeners();
    }
  }

  void removeHoliday(String subjectId, DateTime date) {
    final index = _subjects.indexWhere((s) => s.id == subjectId);
    if (index == -1) return;

    final dateKey = date.toIso8601String().split('T')[0];
    _subjects[index].holidays = _subjects[index].holidays
        .where((h) => h != dateKey)
        .toList();
    _saveSubjects();
    notifyListeners();
  }

  void markAttendance(String subjectId, DateTime date, bool? isPresent) {
    final subjectIndex = _subjects.indexWhere((s) => s.id == subjectId);
    if (subjectIndex != -1) {
      final dateKey = date.toIso8601String().split('T')[0];
      if (isPresent == null) {
        _subjects[subjectIndex].attendance.remove(dateKey);
      } else {
        _subjects[subjectIndex].attendance[dateKey] = isPresent;
      }
      _saveSubjects();
      notifyListeners();
    }
  }

  void updateNote(String subjectId, DateTime date, String note) {
    final subjectIndex = _subjects.indexWhere((s) => s.id == subjectId);
    if (subjectIndex != -1) {
      final dateKey = date.toIso8601String().split('T')[0];
      if (note.isEmpty) {
        _subjects[subjectIndex].notes.remove(dateKey);
      } else {
        _subjects[subjectIndex].notes[dateKey] = note;
      }
      _saveSubjects();
      notifyListeners();
    }
  }

  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? subjectsJson = prefs.getString('subjects');
    if (subjectsJson != null) {
      final List<dynamic> decoded = jsonDecode(subjectsJson);
      _subjects = decoded.map((item) => Subject.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _subjects.map((s) => s.toJson()).toList(),
    );
    prefs.setString('subjects', encoded);
  }
}
