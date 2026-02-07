import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance_model.dart';
import '../widgets/today_schedule_widget.dart';
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HI! ${provider.userName ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF0A84FF),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (provider.isAnonymous)
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A84FF), Color(0xFF5AC8FA)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0A84FF,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: () => provider.signInWithGoogle(),
                            icon: const Icon(
                              Icons.cloud_upload,
                              size: 14,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Backup Data',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _showUserMenu(context, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: const Color(0xFF0A84FF),
                                  backgroundImage:
                                      provider.currentUser?.photoURL != null
                                      ? NetworkImage(
                                          provider.currentUser!.photoURL!,
                                        )
                                      : null,
                                  child: provider.currentUser?.photoURL == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 12,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  provider.currentUser?.displayName?.split(
                                        ' ',
                                      )[0] ??
                                      'Account',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverAppBar(
            backgroundColor: Colors.black,
            floating: true,
            title: Row(
              children: [
                const Text(
                  'My Classes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${subjects.length}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  CupertinoIcons.share,
                  color: Colors.white70,
                  size: 22,
                ),
                onPressed: () => _showShareDialog(context, provider),
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.square_grid_2x2,
                  color: Colors.white70,
                  size: 22,
                ),
                onPressed: () => _showImportDialog(context, provider),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A84FF), // iOS Blue
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, '/add'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Today's Schedule Widget
          SliverToBoxAdapter(child: const TodayScheduleWidget()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            sliver: subjects.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.square_list,
                            size: 60,
                            color: Colors.grey[800],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subjects yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
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
                                content: Text(
                                  'Are you sure you want to delete ${subject.name}?',
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('Cancel'),
                                    onPressed: () => Navigator.pop(ctx, false),
                                  ),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: const Text('Delete'),
                                    onPressed: () => Navigator.pop(ctx, true),
                                  ),
                                ],
                              ),
                            );
                          } else if (direction == DismissDirection.startToEnd) {
                            // Right Swipe -> Analysis
                            // Show Bottom Sheet
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) =>
                                  AnalysisScreen(subject: subject),
                            );
                            return false; // Don't dismiss
                          }
                          return false;
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            Provider.of<AttendanceProvider>(
                              context,
                              listen: false,
                            ).deleteSubject(subject.id);
                          }
                        },
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          color: const Color(0xFF0A84FF), // Analysis Blue
                          child: const Icon(
                            CupertinoIcons.chart_pie_fill,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: const Color(0xFFFF453A), // Delete Red
                          child: const Icon(
                            CupertinoIcons.trash,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        child: _buildUniqueSubjectCard(
                          context,
                          subject,
                          percentage,
                          streak,
                        ),
                      );
                    }, childCount: subjects.length),
                  ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 40),
              child: Center(
                child: Text(
                  'made by yash._clouded',
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context, AttendanceProvider provider) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(provider.currentUser?.email ?? 'Account'),
        message: const Text('Manage your account and synchronization'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Already synced, but can trigger manual sync
              provider.signInWithGoogle();
            },
            child: const Text('Sync Now'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
            provider.signOut();
          },
          child: const Text('Sign Out'),
        ),
      ),
    );
  }

  Widget _buildUniqueSubjectCard(
    BuildContext context,
    Subject subject,
    double percentage,
    int streak,
  ) {
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
            ),
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
                  color:
                      (isGood
                              ? const Color(0xFF32D74B)
                              : const Color(0xFFFF453A))
                          .withValues(alpha: 0.1),
                  border: Border.all(
                    color:
                        (isGood
                                ? const Color(0xFF32D74B)
                                : const Color(0xFFFF453A))
                            .withValues(alpha: 0.1),
                    width: 1,
                  ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isGood
                              ? const Color(0xFF32D74B).withValues(alpha: 0.2)
                              : const Color(0xFFFF453A).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isGood
                                ? const Color(0xFF32D74B)
                                : const Color(0xFFFF453A),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${percentage.toInt()}%',
                          style: TextStyle(
                            color: isGood
                                ? const Color(0xFF32D74B)
                                : const Color(0xFFFF453A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Bottom Row: Stats & Streak
                  Row(
                    children: [
                      _buildStatBadge(
                        icon: CupertinoIcons.checkmark_alt_circle_fill,
                        text:
                            '${subject.attendedClasses}/${subject.totalClasses}',
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12),

                      // STREAK BADGE - The "Unique" Snap-like feature
                      if (streak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF9500,
                                ).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: Colors.white,
                              ), // The Fire Icon
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

  void _showShareDialog(
    BuildContext context,
    AttendanceProvider provider,
  ) async {
    final code = await provider.generateShareCode();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Share Timetable",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Share this code with your friends to instantly import your class schedule.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF0A84FF), width: 1),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Color(0xFF0A84FF),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.check_mark_circled),
                label: const Text("Done"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, AttendanceProvider provider) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "Import Timetable",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Enter the 6-digit code to import a friend's schedule.",
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.black,
                  hintText: "000000",
                  hintStyle: TextStyle(
                    color: Colors.grey[800],
                    letterSpacing: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (controller.text.length == 6) {
                      final success = await provider.importByShareCode(
                        controller.text,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? "Timetable imported successfully!"
                                : "Invalid or expired code.",
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text("Import Schedule"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
