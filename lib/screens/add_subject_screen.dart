import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  double _targetAttendance = 75.0;
  final List<int> _selectedDays = []; 
  bool _isWeekly = true; // Weekly vs Monthly
  bool _isTemporary = false;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  void _submit() {
    if (_nameController.text.isEmpty) return;
    if (_selectedDays.isEmpty) {
        // Warning
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one day.')));
        return;
    }

    Provider.of<AttendanceProvider>(context, listen: false).addSubject(
      _nameController.text,
      _targetAttendance,
      _selectedDays,
      isWeekly: _isWeekly,
      startDate: _startDate,
      endDate: _isTemporary ? _endDate : null,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('New Subject', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.black,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.clear),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SUBJECT DETAILS',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Subject Name',
                      hintStyle: TextStyle(color: Colors.grey),
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target: ${_targetAttendance.toInt()}%',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Row(
                          children: [
                            GestureDetector(onTap: () => setState(() { if(_targetAttendance > 0) _targetAttendance -= 5; }), child: const Icon(Icons.remove)),
                            const SizedBox(width: 8),
                            GestureDetector(onTap: () => setState(() { if(_targetAttendance < 100) _targetAttendance += 5; }), child: const Icon(Icons.add)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Scheduling Mode Support
             Text(
              'SCHEDULE TYPE',
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 10),
            Container(
               width: double.infinity,
               padding: const EdgeInsets.all(4),
               decoration: BoxDecoration(
                 color: const Color(0xFF1C1C1E),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Row(
                 children: [
                   Expanded(
                     child: GestureDetector(
                       onTap: () => setState(() { 
                          _isWeekly = true; 
                          _selectedDays.clear();
                       }),
                       child: Container(
                         padding: const EdgeInsets.symmetric(vertical: 8),
                         decoration: BoxDecoration(
                           color: _isWeekly ? const Color(0xFF2C2C2E) : Colors.transparent,
                           borderRadius: BorderRadius.circular(8),
                         ),
                         alignment: Alignment.center,
                         child: Text('Weekly', style: TextStyle(fontWeight: _isWeekly ? FontWeight.bold : FontWeight.normal, color: Colors.white)),
                       ),
                     ),
                   ),
                   Expanded(
                     child: GestureDetector(
                       onTap: () => setState(() { 
                          _isWeekly = false; 
                          _selectedDays.clear();
                       }),
                       child: Container(
                         padding: const EdgeInsets.symmetric(vertical: 8),
                         decoration: BoxDecoration(
                           color: !_isWeekly ? const Color(0xFF2C2C2E) : Colors.transparent,
                           borderRadius: BorderRadius.circular(8),
                         ),
                         alignment: Alignment.center,
                         child: Text('Monthly Dates', style: TextStyle(fontWeight: !_isWeekly ? FontWeight.bold : FontWeight.normal, color: Colors.white)),
                       ),
                     ),
                   ),
                 ],
               ),
            ),

            const SizedBox(height: 20),
            Text(
              _isWeekly ? 'WEEKLY SCHEDULE' : 'SELECT DATES (1-31)',
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
             const SizedBox(height: 10),
             
             // Dynamic Selector
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFF1C1C1E),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: _isWeekly 
                  ? Wrap(
                     spacing: 12,
                     runSpacing: 12,
                     children: [
                       for (int i = 1; i <= 7; i++)
                         _buildDaySelector(i, _getDayName(i))
                     ],
                   )
                  : SizedBox(
                      height: 200,
                      child: GridView.builder(
                        itemCount: 31,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 8, mainAxisSpacing: 8),
                        itemBuilder: (context, index) {
                           int day = index + 1;
                           return GestureDetector(
                             onTap: () {
                               setState(() {
                                 if (_selectedDays.contains(day)) {
                                   _selectedDays.remove(day);
                                 } else {
                                   _selectedDays.add(day);
                                 }
                               });
                             },
                             child: Container(
                               decoration: BoxDecoration(
                                 color: _selectedDays.contains(day) ? const Color(0xFF0A84FF) : const Color(0xFF2C2C2E),
                                 shape: BoxShape.circle,
                               ),
                               alignment: Alignment.center,
                               child: Text('$day', style: TextStyle(color: _selectedDays.contains(day) ? Colors.white : Colors.grey)),
                             ),
                           );
                        },
                      ),
                  ),
             ),

            const SizedBox(height: 30),
            Text(
              'DURATION',
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Is this a temporary class?', style: TextStyle(fontSize: 16)),
                      CupertinoSwitch(
                        value: _isTemporary, 
                        onChanged: (val) {
                          setState(() {
                             _isTemporary = val;
                             if (!val) _endDate = null;
                             else _endDate = DateTime.now().add(const Duration(days: 30));
                          });
                        }
                      )
                    ],
                  ),
                  if (_isTemporary) ...[
                     const Divider(color: Colors.grey),
                     const SizedBox(height: 8),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text('End Date', style: TextStyle(fontSize: 16)),
                         GestureDetector(
                           onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                                builder: (context, child) {
                                  return Theme(data: ThemeData.dark(), child: child!);
                                }
                              );
                              if (picked != null) {
                                setState(() => _endDate = picked);
                              }
                           },
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                             decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(8)),
                             child: Text(
                               _endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Select Date',
                               style: const TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold),
                             ),
                           ),
                         )
                       ],
                     )
                  ]
                ],
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Subject', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDaySelector(int i, String title) {
    return GestureDetector(
       onTap: () {
         setState(() {
           if (_selectedDays.contains(i)) {
             _selectedDays.remove(i);
           } else {
             _selectedDays.add(i);
           }
         });
       },
       child: Container(
         width: 40,
         height: 40,
         decoration: BoxDecoration(
           color: _selectedDays.contains(i) ? const Color(0xFF0A84FF) : const Color(0xFF2C2C2E),
           shape: BoxShape.circle,
         ),
         alignment: Alignment.center,
         child: Text(
           title,
           style: TextStyle(
             fontWeight: FontWeight.bold,
             color: _selectedDays.contains(i) ? Colors.white : Colors.grey,
           ),
         ),
       ),
    );
  }

  String _getDayName(int i) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[i - 1];
  }
}

