import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/attendance_model.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final String subjectId;
  const SubjectDetailsScreen({super.key, required this.subjectId});

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    // Find subject safely
    Subject? subject;
    try {
      subject = provider.subjects.firstWhere((s) => s.id == widget.subjectId);
    } catch (e) {
      return const Scaffold(body: Center(child: Text("Subject not found")));
    }

    final percentage = subject.currentPercentage;
    final bool isGreen = percentage >= 65; 
    
    final toAttend = subject.classesToAttend;
    final toBunk = subject.classesToBunk;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        leading: IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.trash, color: Color(0xFFFF453A)),
            onPressed: () {
              _confirmDelete(context, provider, subject!.id);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Card
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    subject.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 48, 
                      fontWeight: FontWeight.bold,
                      color: isGreen ? const Color(0xFF32D74B) : const Color(0xFFFF453A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Target: ${subject.targetAttendance.toStringAsFixed(0)}%',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                  


                ],
              ),
            ),

            // Advice Card
            // Advice Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF132235), // Dark blueish
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0A84FF).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                   // Icon based on status
                   if (subject.currentStreak > 0)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                           gradient: LinearGradient(colors: [Color(0xFFFF9500), Color(0xFFFFCC00)]),
                           shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                      )
                   else
                      const Icon(CupertinoIcons.graph_circle, color: Colors.white, size: 28),

                   const SizedBox(width: 16),
                   
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         if (subject.currentStreak > 0)
                            Text(
                              '${subject.currentStreak} Day Streak!',
                              style: const TextStyle(color: Color(0xFFFFCC00), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                         if (subject.currentStreak > 0) const SizedBox(height: 4),
                         Text(
                           toAttend > 0 
                             ? 'Attend next $toAttend classes to reach target.'
                             : 'On track! You can bunk $toBunk classes.',
                           style: const TextStyle(color: Colors.white, fontSize: 15),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),


            const SizedBox(height: 24),

            // Calendar Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFF1C1C1E),
                 borderRadius: BorderRadius.circular(20),
               ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mark Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                   const SizedBox(height: 10),
                   TableCalendar(
                     firstDay: DateTime.utc(2020, 10, 16),
                     lastDay: DateTime.utc(2030, 3, 14),
                     focusedDay: _focusedDay,
                     calendarFormat: _calendarFormat,
                     selectedDayPredicate: (day) {
                       return isSameDay(_selectedDay, day);
                     },
                     onDaySelected: (selectedDay, focusedDay) {
                       setState(() {
                         _selectedDay = selectedDay;
                         _focusedDay = focusedDay;
                       });
                       
                       String dateKey = selectedDay.toIso8601String().split('T')[0];
                       bool? currentState = subject!.attendance[dateKey];
                       
                       bool? newState;
                       if (currentState == null) {
                         newState = true; // Present
                       } else if (currentState == true) {
                         newState = false; // Absent
                       } else {
                         newState = null; // Unmark
                       }
                       
                       provider.markAttendance(subject.id, selectedDay, newState);
                     },
                     onFormatChanged: (format) {
                       setState(() {
                         _calendarFormat = format;
                       });
                     },
                     onPageChanged: (focusedDay) {
                       _focusedDay = focusedDay;
                     },
                     calendarStyle: CalendarStyle(
                       defaultTextStyle: const TextStyle(color: Colors.white),
                       weekendTextStyle: const TextStyle(color: Colors.grey),
                       todayDecoration: BoxDecoration(
                         color: Colors.white.withValues(alpha: 0.1),
                         shape: BoxShape.circle,
                       ),
                       selectedDecoration: const BoxDecoration(
                         color: Colors.transparent, 
                         shape: BoxShape.circle,
                         border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1)),
                       ),
                     ),
                     headerStyle: const HeaderStyle(
                       titleCentered: false,
                       formatButtonVisible: false,
                       leftChevronIcon: Icon(CupertinoIcons.left_chevron, color: Color(0xFF0A84FF)),
                       rightChevronIcon: Icon(CupertinoIcons.right_chevron, color: Color(0xFF0A84FF)),
                     ),
                     calendarBuilders: CalendarBuilders(
                       defaultBuilder: (context, day, focusedDay) {
                           return _buildDateCell(day, subject!.attendance, subject.classDays);
                       },
                       selectedBuilder: (context, day, focusedDay) {
                           return Container(
                             margin: const EdgeInsets.all(6.0),
                             alignment: Alignment.center,
                             decoration: BoxDecoration(
                               border: Border.all(color: Colors.white),
                               shape: BoxShape.circle,
                             ),
                             child: _buildDateCell(day, subject!.attendance, subject.classDays, isSelected: true),
                           );
                       },
                       todayBuilder: (context, day, focusedDay) {
                           return _buildDateCell(day, subject!.attendance, subject.classDays);
                       },
                     ),
                   ),
                   const SizedBox(height: 20),
                   Row(
                     children: [
                       const Text('Marked: ', style: TextStyle(color: Colors.grey)),
                       // Status indicators
                       Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF32D74B), shape: BoxShape.circle)),
                       const SizedBox(width: 4),
                       const Text('Present  ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                       Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF453A), shape: BoxShape.circle)),
                       const SizedBox(width: 4),
                       const Text('Absent', style: TextStyle(color: Colors.grey, fontSize: 12)),
                       const Spacer(),
                       // Dot indicator explanation
                       Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF0A84FF), shape: BoxShape.circle)),
                       const SizedBox(width: 4),
                       const Text('Class Day', style: TextStyle(color: Colors.grey, fontSize: 12)),
                     ],
                   )
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCell(DateTime day, Map<String, bool> attendance, List<int> classDays, {bool isSelected = false}) {
     String dateKey = day.toIso8601String().split('T')[0];
     bool? status = attendance[dateKey];
     bool isClassDay = classDays.contains(day.weekday);
     
     Color? bgColor;
     Color textColor = Colors.white;
     
     if (status == true) {
       bgColor = const Color(0xFF32D74B); // Green
     } else if (status == false) {
       bgColor = const Color(0xFFFF453A); // Red
     }
     
     return Container(
       margin: const EdgeInsets.all(6.0),
       alignment: Alignment.center,
       decoration: bgColor != null ? BoxDecoration(
         color: bgColor,
         shape: BoxShape.circle,
       ) : null,
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Text(
             '${day.day}',
             style: TextStyle(color: textColor, fontWeight: isClassDay ? FontWeight.bold : FontWeight.normal),
           ),
           if (isClassDay && bgColor == null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A84FF), // Blue dot for class day
                  shape: BoxShape.circle,
                ),
              )
         ],
       ),
     );
  }

  void _confirmDelete(BuildContext context, AttendanceProvider provider, String subjectId) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Subject?'),
        content: const Text('This cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              provider.deleteSubject(subjectId);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back to home
            },
          ),
        ],
      ),
    );
  }
}

