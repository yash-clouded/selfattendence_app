import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/attendance_model.dart';

class TodayScheduleWidget extends StatelessWidget {
  const TodayScheduleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final today = DateTime.now();
    final todayWeekday = today.weekday; // 1 = Monday, 7 = Sunday
    final todayDate = today.day; // 1-31

    // Get all classes for today
    final todaysClasses = <Map<String, dynamic>>[];

    for (var subject in provider.subjects) {
      // Check if today is a class day
      bool isClassDay = false;
      String? classTime;

      if (subject.isWeekly) {
        if (subject.classDays.contains(todayWeekday)) {
          isClassDay = true;
          classTime = subject.dayTimings[todayWeekday];
        }
      } else {
        if (subject.classDays.contains(todayDate)) {
          isClassDay = true;
          classTime = subject.dayTimings[todayDate];
        }
      }

      // Check if today is a holiday
      final todayKey = today.toIso8601String().split('T')[0];
      if (subject.holidays.contains(todayKey)) {
        isClassDay = false;
      }

      if (isClassDay && classTime != null) {
        todaysClasses.add({'subject': subject, 'time': classTime});
      }
    }

    // Sort by time
    todaysClasses.sort((a, b) {
      final timeA = a['time'] as String;
      final timeB = b['time'] as String;
      return timeA.compareTo(timeB);
    });

    if (todaysClasses.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.calendar_today,
                color: Color(0xFF0A84FF),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Classes Today',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Enjoy your day off!',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Find next class
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    int? nextClassIndex;
    for (int i = 0; i < todaysClasses.length; i++) {
      if ((todaysClasses[i]['time'] as String).compareTo(currentTime) > 0) {
        nextClassIndex = i;
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.calendar_today,
                color: Color(0xFF0A84FF),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                "Today's Schedule",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${todaysClasses.length} ${todaysClasses.length == 1 ? 'class' : 'classes'}',
                  style: const TextStyle(
                    color: Color(0xFF0A84FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...todaysClasses.asMap().entries.map((entry) {
            final index = entry.key;
            final classData = entry.value;
            final subject = classData['subject'] as Subject;
            final time = classData['time'] as String;
            final isNext = index == nextClassIndex;
            final isPast = nextClassIndex != null && index < nextClassIndex;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isNext
                    ? const Color(0xFF0A84FF).withValues(alpha: 0.15)
                    : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
                border: isNext
                    ? Border.all(color: const Color(0xFF0A84FF), width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isNext
                          ? const Color(0xFF0A84FF)
                          : const Color(0xFF3A3A3C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          time.split(':')[0],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isNext ? Colors.white : Colors.grey,
                          ),
                        ),
                        Text(
                          time.split(':')[1],
                          style: TextStyle(
                            fontSize: 14,
                            color: isNext ? Colors.white : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPast ? Colors.grey : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subject.currentPercentage.toStringAsFixed(1)}% attendance',
                          style: TextStyle(
                            fontSize: 12,
                            color: isPast
                                ? Colors.grey.withValues(alpha: 0.5)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isNext)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A84FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NEXT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  if (isPast)
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: Colors.grey,
                      size: 20,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
