import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Subject {
  String id;
  String name;
  double targetAttendance; // e.g., 75.0
  List<int> classDays; // 1 = Monday, 7 = Sunday
  Map<String, bool> attendance; 
  Map<String, String> notes; 
  bool isWeekly; // true = Mon-Sun (1-7), false = Date of month (1-31)
  DateTime startDate;
  DateTime? endDate;

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
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now().subtract(const Duration(days: 30)), // Fallback
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }

}

class AttendanceProvider with ChangeNotifier {
  List<Subject> _subjects = [];
  
  List<Subject> get subjects => _subjects;

  AttendanceProvider() {
    _loadSubjects();
  }

  void addSubject(String name, double target, List<int> days, {bool isWeekly = true, DateTime? startDate, DateTime? endDate}) {
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
    );
    _subjects.add(newSubject);
    _saveSubjects();
    notifyListeners();
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
