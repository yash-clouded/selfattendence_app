import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance_model.dart';
import 'analysis_sheet.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final subjects = provider.subjects;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            floating: true,
            title: Row(
              children: [
                const Text('My Classes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.white)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${subjects.length}', style: const TextStyle(fontSize: 14)),
                )
              ],
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A84FF), // iOS Blue
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.add, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pushNamed(context, '/add'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            sliver: subjects.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.square_list, size: 60, color: Colors.grey[800]),
                          const SizedBox(height: 16),
                          Text('No subjects yet', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final subject = subjects[index];
                        final percentage = subject.currentPercentage;
                        final streak = subject.currentStreak;


                        // Unique styling
                        return Dismissible(
                          key: Key(subject.id),
                          direction: DismissDirection.horizontal,
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              // Left Swipe -> Delete
                              return await showCupertinoDialog(
                                context: context, 
                                builder: (ctx) => CupertinoAlertDialog(
                                  title: const Text('Delete Subject?'),
                                  content: Text('Are you sure you want to delete ${subject.name}?'),
                                  actions: [
                                    CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx, false)),
                                    CupertinoDialogAction(isDestructiveAction: true, child: const Text('Delete'), onPressed: () => Navigator.pop(ctx, true)),
                                  ],
                                )
                              );
                            } else if (direction == DismissDirection.startToEnd) {
                              // Right Swipe -> Analysis
                              // Show Bottom Sheet
                              showModalBottomSheet(
                                context: context, 
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => AnalysisScreen(subject: subject)
                              );
                              return false; // Don't dismiss
                            }
                            return false;
                          },
                          onDismissed: (direction) {
                             if (direction == DismissDirection.endToStart) {
                               Provider.of<AttendanceProvider>(context, listen: false).deleteSubject(subject.id);
                             }
                          },
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            color: const Color(0xFF0A84FF), // Analysis Blue
                            child: const Icon(CupertinoIcons.chart_pie_fill, color: Colors.white, size: 30),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: const Color(0xFFFF453A), // Delete Red
                            child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 30),
                          ),
                          child: _buildUniqueSubjectCard(context, subject, percentage, streak),
                        );
                      },
                      childCount: subjects.length,
                    ),

                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniqueSubjectCard(BuildContext context, Subject subject, double percentage, int streak) {
    final bool isGood = percentage >= subject.targetAttendance; // Use Target
    // Fallback if target is default: 65% is standard pass.
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/details', arguments: subject.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 140, // Fixed height for consistent look
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.5),
               offset: const Offset(0, 4),
               blurRadius: 10,
             )
          ],
        ),
        child: Stack(
          children: [
            // Background decor (optional subtle gradient or shape)
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isGood ? const Color(0xFF32D74B) : const Color(0xFFFF453A)).withValues(alpha: 0.1),
                  border: Border.all(
                    color: (isGood ? const Color(0xFF32D74B) : const Color(0xFFFF453A)).withValues(alpha: 0.1),
                    width: 1
                  )
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Name and Percentage bubble
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subject.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isGood ? const Color(0xFF32D74B).withValues(alpha: 0.2) : const Color(0xFFFF453A).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isGood ? const Color(0xFF32D74B) : const Color(0xFFFF453A),
                            width: 1.5
                          )
                        ),
                        child: Text(
                          '${percentage.toInt()}%',
                          style: TextStyle(
                            color: isGood ? const Color(0xFF32D74B) : const Color(0xFFFF453A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Bottom Row: Stats & Streak
                  Row(
                    children: [
                      _buildStatBadge(
                         icon: CupertinoIcons.checkmark_alt_circle_fill,
                         text: '${subject.attendedClasses}/${subject.totalClasses}',
                         color: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      
                      // STREAK BADGE - The "Unique" Snap-like feature
                      if (streak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9500).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department, size: 16, color: Colors.white), // The Fire Icon
                              const SizedBox(width: 4),
                              Text(
                                '$streak', 
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                       ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({required IconData icon, required String text, required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
