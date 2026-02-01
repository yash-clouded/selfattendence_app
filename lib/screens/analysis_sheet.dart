import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';

class AnalysisScreen extends StatefulWidget {
  final Subject subject;
  const AnalysisScreen({super.key, required this.subject});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Colors
    const presentColor = Color(0xFF32D74B); // Green
    const absentColor = Color(0xFFFF453A); // Red
    
    int present = widget.subject.attendedClasses;
    int absent = widget.subject.totalClasses - present;
    int total = widget.subject.totalClasses;

    return Container(
         height: 700,
         decoration: const BoxDecoration(
           color: Color(0xFF1C1C1E),
           borderRadius: BorderRadius.only(
             topLeft: Radius.circular(20),
             topRight: Radius.circular(20),
           )
         ),
         child: Column(
           children: [
             // Handle bar
             Container(
               margin: const EdgeInsets.symmetric(vertical: 12),
               width: 40,
               height: 5,
               decoration: BoxDecoration(
                 color: Colors.grey[700],
                 borderRadius: BorderRadius.circular(10),
               ),
             ),
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Container(width: 24), // Spacer
                   Text(
                     widget.subject.name, 
                     style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
                   ),
                   IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
                 ],
               ),
             ),
             
             // Pie Chart
             if (total == 0)
               const Expanded(child: Center(child: Text('No data yet', style: TextStyle(color: Colors.grey))))
             else
               SizedBox(
                 height: 220,
                 child: Stack(
                   alignment: Alignment.center,
                   children: [
                      PieChart(
                       PieChartData(
                         pieTouchData: PieTouchData(
                           touchCallback: (FlTouchEvent event, pieTouchResponse) {
                             setState(() {
                               if (!event.isInterestedForInteractions ||
                                   pieTouchResponse == null ||
                                   pieTouchResponse.touchedSection == null) {
                                 touchedIndex = -1;
                                 return;
                               }
                               touchedIndex = pieTouchResponse
                                   .touchedSection!.touchedSectionIndex;
                             });
                           },
                         ),
                         borderData: FlBorderData(show: false),
                         sectionsSpace: 0,
                         centerSpaceRadius: 50, // Donut
                         sections: [
                           PieChartSectionData(
                             color: presentColor,
                             value: present.toDouble(),
                             title: '${((present/total)*100).toInt()}%',
                             radius: touchedIndex == 0 ? 60 : 50,
                             titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                           ),
                           PieChartSectionData(
                             color: absentColor,
                             value: absent.toDouble(),
                             title: '${((absent/total)*100).toInt()}%',
                             radius: touchedIndex == 1 ? 60 : 50,
                             titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                           ),
                         ],
                       ),
                     ),
                     Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
                         Text('$total', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                       ],
                     )
                   ],
                 ),
               ),

             const Divider(color: Colors.grey),
             
             // List of days
             Expanded(
               child: ListView.builder(
                 itemCount: widget.subject.attendance.length,
                 itemBuilder: (context, index) {
                   // Sort by date descending
                   final sortedKeys = widget.subject.attendance.keys.toList()
                     ..sort((a, b) => b.compareTo(a));
                   final key = sortedKeys[index];
                   final date = DateTime.parse(key);
                   final status = widget.subject.attendance[key] == true;
                   final note = widget.subject.notes[key];
                   
                   return ListTile(
                     leading: Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: status ? presentColor.withValues(alpha: 0.2) : absentColor.withValues(alpha: 0.2),
                         shape: BoxShape.circle,
                       ),
                       child: Icon(
                         status ? Icons.check : Icons.close, 
                         color: status ? presentColor : absentColor,
                         size: 16,
                       ),
                     ),
                     title: Text(
                       DateFormat('EEEE, MMM d').format(date),
                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                     ),
                     subtitle: note != null && note.isNotEmpty 
                        ? Text(note, style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic))
                        : const Text('Add a note...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                     onTap: () {
                         _showNoteDialog(context, widget.subject.id, date, note);
                     },
                   );
                 },
               ),
             ),
           ],
         ),
    );
  }

  void _showNoteDialog(BuildContext context, String subjectId, DateTime date, String? currentNote) {
    final controller = TextEditingController(text: currentNote);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(DateFormat('MMM d').format(date), style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Reason for absense / note",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
             child: const Text('Cancel', style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () {
              Provider.of<AttendanceProvider>(context, listen: false).updateNote(subjectId, date, controller.text);
              Navigator.pop(ctx);
              // Force rebuild handled by parent consumer usually, but here we are in a sheet. 
              // The model updates, but this widget is stateful taking `subject` in constructor.
              // Wait, `subject` in constructor is static. We should use `Consumer` or refetch.
              // However, since we close the sheet usually or we want to see update instantly:
              setState(() {}); 
            },
             child: const Text('Save', style: TextStyle(color: Colors.blue))
          ),
        ],
      ),
    );
  }
}
