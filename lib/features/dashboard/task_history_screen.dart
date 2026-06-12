import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/daily_progress_provider.dart';

class TaskHistoryScreen extends ConsumerStatefulWidget {
  const TaskHistoryScreen({super.key});

  @override
  ConsumerState<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends ConsumerState<TaskHistoryScreen> {
  DateTimeRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final allProgress = ref.watch(dailyProgressProvider);

    // Determine the date range
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime endDate = today;
    DateTime startDate = today.subtract(const Duration(days: 6));

    if (_selectedRange != null) {
      startDate = DateTime(_selectedRange!.start.year, _selectedRange!.start.month, _selectedRange!.start.day);
      endDate = DateTime(_selectedRange!.end.year, _selectedRange!.end.month, _selectedRange!.end.day);
    }

    // Generate a continuous list of days from endDate down to startDate
    final daysCount = endDate.difference(startDate).inDays + 1;
    var sorted = List.generate(daysCount, (i) {
      final d = endDate.subtract(Duration(days: i));
      final dateKey = DailyProgress.keyFor(d);
      return allProgress.firstWhere(
        (p) => p.dateKey == dateKey,
        orElse: () => DailyProgress(
          dateKey: dateKey,
          date: d,
          completed: 0,
          total: 0,
        ),
      );
    });

    // Compute overall stats
    final totalDays = sorted.length;
    final activeDays = sorted.where((d) => d.total > 0).toList();
    final perfectDays = activeDays.where((d) => d.percentage >= 1.0).length;
    final avgPct = activeDays.isNotEmpty
        ? activeDays.map((d) => d.percentage).reduce((a, b) => a + b) / activeDays.length
        : 0.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'TASK HISTORY',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedRange != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedRange = null),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white70, size: 16),
                        ),
                      ),
                    GestureDetector(
                      onTap: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                          initialDateRange: _selectedRange,
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.primary,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E1E24),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (range != null) {
                          setState(() => _selectedRange = range);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedRange != null ? AppTheme.primary.withAlpha(30) : Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedRange != null ? AppTheme.primary.withAlpha(80) : Colors.white24,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.date_range_rounded, 
                                color: _selectedRange != null ? AppTheme.primary : Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _selectedRange != null ? 'Filtered' : 'Filter',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _selectedRange != null ? AppTheme.primary : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Stats Strip ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildStatCard('🎯 Avg Daily', '${(avgPct * 100).toStringAsFixed(0)}%',
                        AppTheme.secondary),
                    const SizedBox(width: 10),
                    _buildStatCard('🏆 Perfect', '$perfectDays days', AppTheme.success),
                    const SizedBox(width: 10),
                    _buildStatCard('📅 Tracked', '$totalDays days', AppTheme.warning),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── List ─────────────────────────────────────────────────
              Expanded(
                child: sorted.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: sorted.length,
                        itemBuilder: (context, i) {
                          return _buildDayCard(sorted[i], i == 0 && _selectedRange == null);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.outfit(fontSize: 9, color: Colors.white54)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(DailyProgress dp, bool isToday) {
    final pct = dp.percentage;
    final color = _barColor(pct);
    final isFullDay = pct >= 1.0 && dp.total > 0;
    final isEmptyDay = dp.total == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday
            ? AppTheme.primary.withAlpha(18)
            : Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isToday
              ? AppTheme.primary.withAlpha(80)
              : Colors.white.withAlpha(15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Day icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Center(
                  child: Text(
                    isFullDay ? '🔥' : _percentEmoji(pct),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isToday
                              ? 'Today'
                              : DateFormat('EEE, d MMM').format(dp.date),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isFullDay)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppTheme.success.withAlpha(80)),
                            ),
                            child: Text(
                              'PERFECT',
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.success,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        if (isToday)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(40),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'TODAY',
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEmptyDay ? 'No tasks tracked' : '${dp.completed} of ${dp.total} tasks completed',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: isEmptyDay ? Colors.white24 : Colors.white54),
                    ),
                  ],
                ),
              ),

              // Percentage badge
              Text(
                '${(pct * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'NO HISTORY YET',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete tasks in the Today tab\nto start tracking your daily progress!',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.outfit(fontSize: 13, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Color _barColor(double pct) {
    if (pct == 0.0) return Colors.white38;
    if (pct >= 1.0) return AppTheme.success.withAlpha(200);
    return AppTheme.primary.withAlpha(180);
  }

  String _percentEmoji(double pct) {
    if (pct == 0.0) return '💤';
    if (pct >= 0.66) return '⚡';
    if (pct >= 0.33) return '📈';
    return '🌱';
  }
}
