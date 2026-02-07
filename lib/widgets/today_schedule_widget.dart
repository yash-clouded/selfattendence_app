import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/attendance_model.dart';

class TodayScheduleWidget extends StatefulWidget {
  const TodayScheduleWidget({super.key});

  @override
  State<TodayScheduleWidget> createState() => _TodayScheduleWidgetState();
}

class _TodayScheduleWidgetState extends State<TodayScheduleWidget> {
  final PageController _pageController = PageController(initialPage: 0);
  int _focusedIndex = 0;

  List<Map<String, dynamic>> _getClassesForDate(
    DateTime date,
    AttendanceProvider provider,
  ) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final dayOfMonth = date.day; // 1-31
    final classes = <Map<String, dynamic>>[];

    for (var subject in provider.subjects) {
      bool isClassDay = false;
      String? classTime;

      if (subject.isWeekly) {
        if (subject.classDays.contains(weekday)) {
          isClassDay = true;
          classTime = subject.dayTimings[weekday];
        }
      } else {
        if (subject.classDays.contains(dayOfMonth)) {
          isClassDay = true;
          classTime = subject.dayTimings[dayOfMonth];
        }
      }

      final dateKey = date.toIso8601String().split('T')[0];
      if (subject.holidays.contains(dateKey)) {
        isClassDay = false;
      }

      if (isClassDay && classTime != null) {
        classes.add({'subject': subject, 'time': classTime});
      }
    }

    classes.sort((a, b) {
      final timeA = a['time'] as String;
      final timeB = b['time'] as String;
      return timeA.compareTo(timeB);
    });

    return classes;
  }

  String _getDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) return "Today's Schedule";
    if (difference == 1) return "Tomorrow's Schedule";
    if (difference == -1) return "Yesterday's Schedule";

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return "${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}";
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final now = DateTime.now();

    return Column(
      children: [
        SizedBox(
          height: 380, // Fixed height for swipeable area
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _focusedIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final date = now.add(Duration(days: index));
              final todaysClasses = _getClassesForDate(date, provider);
              final dateTitle = _getDateString(date);

              return _buildScheduleCard(
                date,
                todaysClasses,
                dateTitle,
                index == 0,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            7,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _focusedIndex == index
                    ? const Color(0xFF0A84FF)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(
    DateTime date,
    List<Map<String, dynamic>> todaysClasses,
    String title,
    bool isToday,
  ) {
    if (todaysClasses.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isToday
                    ? CupertinoIcons.calendar_today
                    : CupertinoIcons.calendar,
                color: const Color(0xFF0A84FF),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No Classes Scheduled',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              isToday ? 'Enjoy your day off!' : 'Take it easy!',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    int? nextClassIndex;
    if (isToday) {
      for (int i = 0; i < todaysClasses.length; i++) {
        if ((todaysClasses[i]['time'] as String).compareTo(currentTime) > 0) {
          nextClassIndex = i;
          break;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isToday
                    ? CupertinoIcons.calendar_today
                    : CupertinoIcons.calendar,
                color: const Color(0xFF0A84FF),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(10),
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
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: todaysClasses.length,
              itemBuilder: (context, index) {
                final classData = todaysClasses[index];
                final subject = classData['subject'] as Subject;
                final time = classData['time'] as String;
                final isNext = isToday && index == nextClassIndex;
                final isPast =
                    isToday && nextClassIndex != null && index < nextClassIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isNext
                        ? const Color(0xFF0A84FF).withValues(alpha: 0.1)
                        : const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                    border: isNext
                        ? Border.all(color: const Color(0xFF0A84FF), width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(vertical: 6),
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isNext ? Colors.white : Colors.grey[300],
                              ),
                            ),
                            Text(
                              time.split(':')[1],
                              style: TextStyle(
                                fontSize: 12,
                                color: isNext ? Colors.white : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isPast ? Colors.grey : Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${subject.currentPercentage.toStringAsFixed(1)}% attendance',
                              style: TextStyle(
                                fontSize: 11,
                                color: isPast
                                    ? Colors.grey.withValues(alpha: 0.5)
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isNext)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A84FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NOW',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      if (isPast)
                        const Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: Colors.grey,
                          size: 18,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
