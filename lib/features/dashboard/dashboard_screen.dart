import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/providers/daily_progress_provider.dart';
import '../../core/providers/scan_history_provider.dart';
import '../../core/services/sync_service.dart';

// Import sibling features to host them inside the persistent tabs
import '../analytics/analytics_screen.dart';
import '../profile/profile_screen.dart';
import '../coach/coach_screen.dart';
import '../share/glow_up_share_screen.dart';
import '../scan/scan_history_screen.dart';
import 'task_history_screen.dart';
import 'task_management_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _navIndex = 0; // 0=Today, 1=History, 2=Coach, 3=Analytics, 4=Profile
  String _activeTab = 'morning'; // 'morning' | 'afternoon' | 'night' inside Today's checklist

  @override
  void initState() {
    super.initState();
    // Fetch real data for the 7 days task graph from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDailyProgress();
    });
  }

  Future<void> _syncDailyProgress() async {
    final rawData = await SyncService().fetchRemoteDailyProgress();
    if (rawData.isNotEmpty) {
      final parsed = rawData.map((d) {
        final dt = DateTime.tryParse(d['date_key'] ?? '') ?? DateTime.now();
        return DailyProgress(
          dateKey: d['date_key'] ?? '',
          date: dt,
          completed: d['completed_count'] ?? 0,
          total: d['total_count'] ?? 0,
        );
      }).toList();
      ref.read(dailyProgressProvider.notifier).syncFromFirestore(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          // Tab 0: Daily habits Checklist
          _buildTodayHabitsView(),
          
          // Tab 1: Scan History (Persistent state)
          const ScanHistoryScreen(isTab: true),

          // Tab 2: AI Lookmaxxing Coach Console (Persistent state)
          const AICoachScreen(isTab: true),
          
          // Tab 3: AI Analytics View (Persistent state)
          const AnalyticsScreen(isTab: true),
          
          // Tab 4: Profile View (Persistent state)
          const ProfileScreen(isTab: true),
        ],
      ),
      floatingActionButton: _navIndex == 0 ? FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
      bottomNavigationBar: _buildBottomNavbar(),
    );
  }

  // 1. Today Habits Tab View
  Widget _buildTodayHabitsView() {
    final user = ref.watch(userStateProvider);
    final habits = ref.watch(habitStateProvider);
    final last7 = ref.watch(dailyProgressProvider.notifier).lastNDays(7);

    // Check for missing tasks
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // If no tasks exist for today, prompt generation
      if (habits.isEmpty) {
        _showGenerateTasksDialog(context, ref);
      }
    });

    // Filter habits by current tab
    final activeHabits = habits.where((h) => h.timeOfDay == _activeTab).toList();

    // Calculate overall completion percentage
    final totalHabits = habits.length;
    final completedHabits = habits.where((h) => h.isCompleted).length;
    final progress = totalHabits > 0 ? completedHabits / totalHabits : 0.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Dynamic HUD Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GrowUp AI',
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Hey, ',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                user.name.isEmpty
                                    ? 'Champ'
                                    : user.name.trim().split(' ').first,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.secondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Streak Flame + Share button row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.withAlpha(100)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              '${user.streak} STREAK',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick Share Button
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GlowUpShareScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.secondary],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondary.withAlpha(80),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.ios_share_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Glowing Score Ring & Overall Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GlassContainer(
                glowColor: AppTheme.primary,
                child: Row(
                  children: [
                    // Circular progress bar dynamically updates when checking tasks!
                    SizedBox(
                      width: 105,
                      height: 105,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Explicit sizing forces the indicator to fill the 105x105 region!
                          SizedBox(
                            width: 105,
                            height: 105,
                            child: CircularProgressIndicator(
                              value: (user.auraScore / 10.0).clamp(0.0, 1.0), // Represents aura score out of 10!
                              strokeWidth: 9,
                              backgroundColor: Colors.white10,
                              color: AppTheme.secondary,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.auraScore > 0 ? user.auraScore.toStringAsFixed(1) : '0.0',
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'AURA',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Progress Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "TODAY'S PROGRESS",
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.success.withAlpha(100)),
                                ),
                                child: Text(
                                  '${(progress * 100).toInt()}%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Linear progress tracker bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.white10,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$completedHabits of $totalHabits tasks done (${(progress * 100).toInt()}% Completed)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Segmented Tab Selector (Morning, Noon, Evening, Night)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    _buildTabButton('morning', '☀️ Morn'),
                    _buildTabButton('afternoon', '⚡ Noon'),
                    _buildTabButton('evening', '🌆 Eve'),
                    _buildTabButton('night', '🌙 Night'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Checklist Habit Items + Mini Chart in scrollable list
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Habit checklist
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    sliver: activeHabits.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  const Text('✅', style: TextStyle(fontSize: 36)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No tasks for this time slot',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, idx) {
                                final h = activeHabits[idx];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: h.isCompleted
                                            ? AppTheme.primary.withAlpha(18)
                                            : Colors.white.withAlpha(8),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: h.isCompleted
                                              ? AppTheme.primary.withAlpha(100)
                                              : Colors.white.withAlpha(15),
                                        ),
                                      ),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          children: [
                                            // Left accent bar
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              width: 4,
                                              color: h.isCompleted
                                                  ? AppTheme.primary
                                                  : Colors.transparent,
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
                                                child: Row(
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () => ref
                                                          .read(habitStateProvider.notifier)
                                                          .toggleHabit(h.id),
                                                      child: AnimatedContainer(
                                                        duration: const Duration(milliseconds: 300),
                                                        width: 30,
                                                        height: 30,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: h.isCompleted
                                                              ? AppTheme.primary
                                                              : Colors.transparent,
                                                          border: Border.all(
                                                            color: h.isCompleted
                                                                ? AppTheme.primary
                                                                : Colors.white30,
                                                            width: 2.0,
                                                          ),
                                                          boxShadow: h.isCompleted
                                                              ? [
                                                                  BoxShadow(
                                                                    color: AppTheme.primary
                                                                        .withAlpha(80),
                                                                    blurRadius: 8,
                                                                  )
                                                                ]
                                                              : [],
                                                        ),
                                                        child: Center(
                                                          child: h.isCompleted
                                                              ? const Icon(
                                                                  Icons.check_rounded,
                                                                  size: 16,
                                                                  color: Colors.white,
                                                                )
                                                              : Text(
                                                                  '${h.currentCount}/${h.targetCount}',
                                                                  style: GoogleFonts.outfit(
                                                                    fontSize: 9,
                                                                    color: Colors.white70,
                                                                  ),
                                                                ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            h.title,
                                                            style: GoogleFonts.outfit(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: h.isCompleted
                                                                  ? Colors.white54
                                                                  : Colors.white,
                                                              decoration: h.isCompleted
                                                                  ? TextDecoration.lineThrough
                                                                  : null,
                                                              decorationColor:
                                                                  Colors.white38,
                                                            ),
                                                          ),
                                                          if (h.description.isNotEmpty) ...
                                                            [
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                h.description,
                                                                style: GoogleFonts.outfit(
                                                                  fontSize: 11,
                                                                  color: AppTheme.textSecondary,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ],
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.more_vert,
                                                        color: Colors.white38,
                                                        size: 18,
                                                      ),
                                                      onPressed: () =>
                                                          _showEditTaskDialog(context, h),
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: activeHabits.length,
                            ),
                          ),
                  ),

                  // ── Last 7 Days Mini Chart ──────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildWeeklyMiniChart(context, last7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateTasksDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Daily Routine Required',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your AI Coach has analyzed your data. Generate today\'s personalized Lookmaxxing routine now.',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final scans = ref.read(scanHistoryProvider);
              final latest = scans.isNotEmpty ? scans.first : null;
              final fullData = latest?.fullData;
              await ref.read(habitStateProvider.notifier).generateTasksFromScan(fullData);
            },
            child: Text('Generate Routine', style: GoogleFonts.outfit(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, Habit habit) {
    // Basic stub for edit/delete dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E24),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (habit.isCustom)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete Task', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  ref.read(habitStateProvider.notifier).deleteTask(habit.id);
                  Navigator.pop(ctx);
                },
              )
            else
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'AI Generated tasks cannot be deleted.',
                  style: GoogleFonts.outfit(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    String timeOfDay = _activeTab;
    String frequency = 'daily';
    final titleCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E24),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Custom Task',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskManagementScreen()));
                      },
                      icon: const Icon(Icons.settings, size: 16, color: AppTheme.secondary),
                      label: Text('Manage', style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.secondary)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withAlpha(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Time of Day', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['morning', 'afternoon', 'evening', 'night'].map((t) {
                    final isSelected = timeOfDay == t;
                    return ChoiceChip(
                      label: Text(t.toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white54)),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: Colors.white10,
                      onSelected: (val) {
                        if (val) setModalState(() => timeOfDay = t);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Frequency', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['daily', 'weekly', 'monthly'].map((f) {
                    final isSelected = frequency == f;
                    return ChoiceChip(
                      label: Text(f.toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white54)),
                      selected: isSelected,
                      selectedColor: AppTheme.secondary,
                      backgroundColor: Colors.white10,
                      onSelected: (val) {
                        if (val) setModalState(() => frequency = f);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.isNotEmpty) {
                        ref.read(habitStateProvider.notifier).addCustomTask(
                          Habit(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleCtrl.text,
                            timeOfDay: timeOfDay,
                            frequency: frequency,
                            icon: 'star',
                            description: 'Custom Task',
                            isCustom: true,
                            targetCount: 1,
                          )
                        );
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save Task', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Last 7 Days Mini Bar Chart ──────────────────────────────────────────────
  Widget _buildWeeklyMiniChart(BuildContext context, List<DailyProgress> last7) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LAST 7 DAYS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TaskHistoryScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'SEE MORE',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.secondary, size: 11),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bar chart
            SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: last7.map((dp) {
                  final pct = dp.percentage;
                  final barH = (pct * 70).clamp(4.0, 70.0);
                  final isToday =
                      dp.dateKey == DailyProgress.keyFor(DateTime.now());
                  final barColor = _chartBarColor(pct);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Percentage label on top
                          Text(
                            pct > 0 ? '${(pct * 100).toInt()}%' : '',
                            style: GoogleFonts.outfit(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: isToday ? AppTheme.secondary : Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            height: barH,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors: isToday
                                    ? [AppTheme.secondary, AppTheme.primary]
                                    : [barColor, barColor.withAlpha(160)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: isToday
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.secondary.withAlpha(80),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : [],
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Day label
                          Text(
                            isToday ? 'Now' : dp.label,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? AppTheme.secondary : Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _chartBarColor(double pct) {
    if (pct >= 1.0) return AppTheme.success;
    if (pct >= 0.66) return AppTheme.primary;
    if (pct >= 0.33) return AppTheme.warning;
    return Colors.white24;
  }

  Widget _buildTabButton(String tabKey, String label) {
    final isSelected = _activeTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tabKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  )
                : null,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 2. Custom Persistent Bottom Navigation Bar
  Widget _buildBottomNavbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavbarItem(0, Icons.today_rounded, 'Today'),
            _buildNavbarItem(1, Icons.history_rounded, 'History'),
            _buildNavbarItem(2, Icons.smart_toy_rounded, 'Coach'),
            _buildNavbarItem(3, Icons.analytics_outlined, 'Analytics'),
            _buildNavbarItem(4, Icons.person_outline_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbarItem(int index, IconData icon, String label) {
    final isSelected = _navIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _navIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.secondary : AppTheme.textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.secondary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
