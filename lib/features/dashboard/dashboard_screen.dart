import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../ai_recommendations/ai_outfit_screen.dart';
import '../ai_recommendations/ai_hair_style_screen.dart';

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
    ref.listen<UserState>(userStateProvider, (previous, next) {
      if (next.hasLostStreak && (previous == null || !previous.hasLostStreak)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStreakLostDialog(context, next.lostStreakCount);
        });
      }
    });

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
      floatingActionButton: _navIndex == 0 ? Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddTaskDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
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

    // Define displayAura to always match the latest scan or normalized user score
    final scans = ref.watch(scanHistoryProvider);
    final latestScan = scans.isNotEmpty ? scans.first : null;
    final double rawAura = latestScan != null ? latestScan.auraScore : user.auraScore;
    final displayAura = rawAura > 10.0 ? rawAura / 10.0 : rawAura;

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
                              value: (displayAura / 10.0).clamp(0.0, 1.0), // Represents aura score out of 10!
                              strokeWidth: 9,
                              backgroundColor: Colors.white10,
                              color: AppTheme.secondary,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayAura > 0 ? displayAura.toStringAsFixed(1) : '0.0',
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
            const SizedBox(height: 16),

            // AI Recommendations Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAiRecommendationCard(
                      title: 'AI Outfits',
                      subtitle: 'Find your style',
                      imagePath: 'assets/image/t_shirt_icon.png',
                      gradientColors: [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiOutfitScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAiRecommendationCard(
                      title: 'AI Haircut',
                      subtitle: 'Perfect cuts',
                      imagePath: 'assets/image/short_hair_style.png',
                      gradientColors: [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiHairStyleScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                                                      onTap: () => _handleToggleHabit(h),
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
                                                      child: GestureDetector(
                                                        onTap: () => _showTaskDetailsDialog(context, h),
                                                        child: Container(
                                                          color: Colors.transparent,
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
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: Colors.white12)),
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
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: GoogleFonts.outfit(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black38,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Time of Day', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ['morning', 'afternoon', 'evening', 'night'].map((t) {
                    final isSelected = timeOfDay == t;
                    return ChoiceChip(
                      label: Text(t.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white70)),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: Colors.white.withAlpha(15),
                      side: BorderSide(color: isSelected ? AppTheme.primary : Colors.white10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val) setModalState(() => timeOfDay = t);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Frequency', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: ['daily', 'weekly', 'monthly'].map((f) {
                    final isSelected = frequency == f;
                    return ChoiceChip(
                      label: Text(f.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white70)),
                      selected: isSelected,
                      selectedColor: AppTheme.secondary,
                      backgroundColor: Colors.white.withAlpha(15),
                      side: BorderSide(color: isSelected ? AppTheme.secondary : Colors.white10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val) setModalState(() => frequency = f);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppTheme.primary.withAlpha(100),
                    ),
                    child: Text('SAVE TASK', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.0)),
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

  void _showTaskDetailsDialog(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(180),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(30),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Icon + Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: habit.isCompleted
                            ? AppTheme.success.withAlpha(30)
                            : AppTheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        habit.isCompleted ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
                        color: habit.isCompleted ? AppTheme.success : AppTheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        habit.title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (habit.description.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'DETAILS',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    habit.description,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                // Progress
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROGRESS',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${habit.currentCount} / ${habit.targetCount}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: habit.isCompleted ? AppTheme.success : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'CLOSE',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Toggle task
                          _handleToggleHabit(habit);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: habit.isCompleted ? Colors.white10 : AppTheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          habit.isCompleted ? 'UNDO' : 'DONE',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: habit.isCompleted ? Colors.white : Colors.black,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiRecommendationCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle background glow effect
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gradientColors[1].withAlpha(15),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[1].withAlpha(20),
                        blurRadius: 30,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withAlpha(80),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                        ),
                        Image.asset(
                          imagePath,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.white54),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleToggleHabit(Habit h) async {
    final didIncrement = await ref.read(habitStateProvider.notifier).toggleHabit(h.id);
    if (didIncrement && mounted) {
      HapticFeedback.heavyImpact();
      _showStreakCongratulationDialog(context);
    }
  }

  void _showStreakLostDialog(BuildContext context, int previousStreak) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(200),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.danger.withAlpha(100), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.danger.withAlpha(40),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sentiment_dissatisfied_rounded, color: AppTheme.danger, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Streak Lost!',
                  style: GoogleFonts.cinzel(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Oh no! You missed a day. Your $previousStreak day streak has been reset. Let\'s start fresh!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(userStateProvider.notifier).acknowledgeLostStreak();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'START FROM 0',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStreakCongratulationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200),
      builder: (ctx) {
        final streak = ref.watch(userStateProvider).streak;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.success.withAlpha(100), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.success.withAlpha(60),
                  blurRadius: 60,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.success.withAlpha(20),
                  ),
                  child: Icon(Icons.local_fire_department_rounded, color: AppTheme.success, size: 60),
                ),
                const SizedBox(height: 16),
                Text(
                  'Streak Increased!',
                  style: GoogleFonts.cinzel(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are on fire! You have hit a $streak day streak. Keep pushing towards your goals.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'AWESOME',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
