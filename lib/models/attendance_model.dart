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
  String? classTime; // Format "HH:mm"

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
    this.classTime,
  });


  // ... (getters)

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
    DateTime checkLimit = startDate.isAfter(current.subtract(const Duration(days: 730))) 
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
      
      // If we are past the end date (if set), technically it's not a class day effectively for streak? 
      // But we iterate backwards from Today. If today > endDate, then streak might be frozen?
      // Let's simple ignore endDate for streak calculation or assume current date is valid.

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
      'classTime': classTime,
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      targetAttendance: json['targetAttendance'].toDouble(),
      classDays: List<int>.from(json['classDays'] ?? []),
      attendance: Map<String, bool>.from(json['attendance'] ?? {}),
      notes: Map<String, String>.from(json['notes'] ?? {}),
      isWeekly: json['isWeekly'] ?? true,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now().subtract(const Duration(days: 30)), 
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      classTime: json['classTime'],
    );
  }

}

class AttendanceProvider with ChangeNotifier {
  List<Subject> _subjects = [];
  
  List<Subject> get subjects => _subjects;

  AttendanceProvider() {
    _loadSubjects();
  }

  Future<void> addSubject(String name, double target, List<int> days, {bool isWeekly = true, DateTime? startDate, DateTime? endDate, String? classTime}) async {
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
      classTime: classTime,
    );
    _subjects.add(newSubject);
    _saveSubjects();
    notifyListeners();
    
    // Attempt to add to Device Calendar if time is provided
    if (classTime != null) {
       await _addToDeviceCalendar(newSubject);
    }
  }

  Future<void> _addToDeviceCalendar(Subject subject) async {
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
    var calendar = calendarsResult.data!.firstWhere((c) => c.isDefault ?? false, orElse: () => calendarsResult.data!.first);
    // Ensure writable?
    if (calendar.isReadOnly == true) {
         try {
           calendar = calendarsResult.data!.firstWhere((c) => c.isReadOnly == false);
         } catch(e) { return; }
    }

    // Parse Time
    if (subject.classTime == null) return;
    final parts = subject.classTime!.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Construct Event
    // We need to establish the "Next" occurrence(s).
    // If Weekly: Add event for each day in classDays.
    
    // For weekly, we can use RecurrenceRule.
    // RRULE:FREQ=WEEKLY;BYDAY=MO,TU...
    
    // device_calendar supports recurrence.
    
    // We iterate through selected classDays to create potentially multiple events if they have different start times, 
    // but here we assume same start time for all days.
    // BUT, RRULE BYDAY needs a single start date.
    // If "Monday and Wednesday at 10 AM", we can create one event starting on the *next* Monday (or Wednesday) and Set Recurrence.
    
    // Finding the first occurrence relative to StartDate
    DateTime firstInstance = subject.startDate; 
    // Adjust firstInstance to match the classTime
    firstInstance = DateTime(firstInstance.year, firstInstance.month, firstInstance.day, hour, minute);
    
    if (firstInstance.isBefore(DateTime.now())) {
       // If start date was in past, we still use it as anchor but maybe calendar handles it.
       // Or we start from today.
       // Let's stick to subject.startDate as anchor if possible, or today.
       DateTime now = DateTime.now();
       firstInstance = DateTime(now.year, now.month, now.day, hour, minute);
    }
    
    if (subject.isWeekly) {
         // Map int days to Recurrence Day
         List<DayOfWeek> daysOfWeek = [];
         Map<int, DayOfWeek> map = {
           1: DayOfWeek.Monday, 2: DayOfWeek.Tuesday, 3: DayOfWeek.Wednesday,
           4: DayOfWeek.Thursday, 5: DayOfWeek.Friday, 6: DayOfWeek.Saturday, 7: DayOfWeek.Sunday
         };
         
         for (var d in subject.classDays) {
           if (map.containsKey(d)) daysOfWeek.add(map[d]!);
         }
         
         final recurrenceRule = RecurrenceRule(RecurrenceFrequency.Weekly, daysOfWeek: daysOfWeek);
         
         if (subject.endDate != null) {
            recurrenceRule.endDate = subject.endDate;
         }
         
         final event = Event(
           calendar.id,
           title: subject.name,
           description: 'Class for ${subject.name}',
           start: tz.TZDateTime.from(firstInstance, tz.local),
           end: tz.TZDateTime.from(firstInstance.add(const Duration(minutes: 60)), tz.local), // Assume 1 hr
           recurrenceRule: recurrenceRule,
         );
         
         // 10 Min Reminder
         event.reminders = [Reminder(minutes: 10)];
         
         await deviceCalendarPlugin.createOrUpdateEvent(event);
    } else {
        // Monthly or Specific dates logic is harder with simple RRULE without BYMONTHDAY support in plugin fully?
        // device_calendar supports Monthly.
        // But our "Monthly Dates" feature stores integers: 1 (1st), 15 (15th).
        // RecurrenceRule(RecurrenceFrequency.Monthly, daysOfMonth: [1, 15]) ?
        // Checking plugin source/docs: supports daysOfMonth.
        

        // final recurrenceRule = RecurrenceRule(RecurrenceFrequency.Monthly);
        // recurrenceRule.daysOfMonth = daysOfMonth; // Not supported in this version
        final recurrenceRule = null; // Fallback to single event for now
        
        if (subject.endDate != null && recurrenceRule != null) {
           recurrenceRule.endDate = subject.endDate;
        }

        final event = Event(
           calendar.id,
           title: subject.name,
           description: 'Class for ${subject.name}',
           start: tz.TZDateTime.from(firstInstance, tz.local),
           end: tz.TZDateTime.from(firstInstance.add(const Duration(minutes: 60)), tz.local),
           recurrenceRule: recurrenceRule,
         );
         event.reminders = [Reminder(minutes: 10)];
         await deviceCalendarPlugin.createOrUpdateEvent(event);
    }
  }




  void deleteSubject(String id) {
    _subjects.removeWhere((s) => s.id == id);
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
    final String encoded = jsonEncode(_subjects.map((s) => s.toJson()).toList());
    prefs.setString('subjects', encoded);
  }
}
