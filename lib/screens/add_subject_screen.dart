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
  final DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final Map<int, TimeOfDay> _dayTimes = {}; // Per-day times
  int _reminderMinutes = 10;

  void _submit() {
    if (_nameController.text.isEmpty) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day.')),
      );
      return;
    }

    // Create dayTimings map
    Map<int, String> dayTimings = {};
    for (var entry in _dayTimes.entries) {
      final time = entry.value;
      dayTimings[entry.key] =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    Provider.of<AttendanceProvider>(context, listen: false).addSubject(
      _nameController.text,
      _targetAttendance,
      _selectedDays,
      isWeekly: _isWeekly,
      startDate: _startDate,
      endDate: _isTemporary ? _endDate : null,
      dayTimings: dayTimings,
      reminderMinutes: _reminderMinutes,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Target: ${_targetAttendance.toInt()}%',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() {
                                if (_targetAttendance > 0) {
                                  _targetAttendance -= 5;
                                }
                              }),
                              child: const Icon(Icons.remove),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() {
                                if (_targetAttendance < 100) {
                                  _targetAttendance += 5;
                                }
                              }),
                              child: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'SCHEDULE TYPE',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
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
                        _dayTimes.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isWeekly
                              ? const Color(0xFF2C2C2E)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Weekly',
                          style: TextStyle(
                            fontWeight: _isWeekly
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isWeekly = false;
                        _selectedDays.clear();
                        _dayTimes.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isWeekly
                              ? const Color(0xFF2C2C2E)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Monthly Dates',
                          style: TextStyle(
                            fontWeight: !_isWeekly
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              _isWeekly
                  ? 'WEEKLY SCHEDULE & TIMES'
                  : 'SELECT DATES & TIMES (1-31)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            // Day selector with time pickers
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isWeekly
                  ? Column(
                      children: [
                        for (int i = 1; i <= 7; i++)
                          _buildDayTimeRow(i, _getDayName(i)),
                      ],
                    )
                  : SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: 31,
                        itemBuilder: (context, index) {
                          int day = index + 1;
                          return _buildDayTimeRow(day, 'Day $day');
                        },
                      ),
                    ),
            ),

            const SizedBox(height: 30),
            Text(
              'DURATION',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
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
                      const Text(
                        'Is this for the current semester only?',
                        style: TextStyle(fontSize: 16),
                      ),
                      CupertinoSwitch(
                        value: _isTemporary,
                        onChanged: (val) {
                          setState(() {
                            _isTemporary = val;
                            if (!val) {
                              _endDate = null;
                            } else {
                              _endDate = DateTime.now().add(
                                const Duration(days: 30),
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isTemporary) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.grey),
                    ),
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
                                return Theme(
                                  data: ThemeData.dark(),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _endDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _endDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                  : 'Select Date',
                              style: const TextStyle(
                                color: Color(0xFF0A84FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),

            Text(
              'REMINDER',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Remind me before:',
                    style: TextStyle(fontSize: 16),
                  ),
                  DropdownButton<int>(
                    value: _reminderMinutes,
                    dropdownColor: const Color(0xFF1C1C1E),
                    style: const TextStyle(
                      color: Color(0xFF0A84FF),
                      fontWeight: FontWeight.bold,
                    ),
                    underline: Container(),
                    items: [-1, 0, 5, 10, 15, 30, 60].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(
                          value == -1
                              ? 'None'
                              : (value == 0 ? 'Exact time' : '$value mins'),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _reminderMinutes = val);
                    },
                  ),
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
                  backgroundColor: const Color(0xFF0A84FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Add Subject',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTimeRow(int day, String label) {
    final isSelected = _selectedDays.contains(day);
    final hasTime = _dayTimes.containsKey(day);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF0A84FF).withValues(alpha: 0.15)
            : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: const Color(0xFF0A84FF), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedDays.remove(day);
                  _dayTimes.remove(day);
                } else {
                  _selectedDays.add(day);
                }
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0A84FF)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0A84FF) : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ),
          if (isSelected)
            GestureDetector(
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _dayTimes[day] ?? TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFF0A84FF),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _dayTimes[day] = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hasTime
                      ? const Color(0xFF0A84FF)
                      : const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasTime ? _dayTimes[day]!.format(context) : 'Set Time',
                  style: TextStyle(
                    color: hasTime ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDayName(int i) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[i - 1];
  }
}
