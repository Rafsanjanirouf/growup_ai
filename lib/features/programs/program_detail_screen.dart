import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/programs_provider.dart';
import '../../core/providers/user_stats_provider.dart';
import '../monetization/premium_paywall_screen.dart';
import '../monetization/coin_shop_screen.dart';
import 'program_task_screen.dart';

class ProgramDetailScreen extends ConsumerWidget {
  final Program program;
  const ProgramDetailScreen({super.key, required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsState = ref.watch(programsProvider);
    // Find the latest state for this specific program
    final currentProgramState = programsState.programs.firstWhere((p) => p.id == program.id, orElse: () => program);
    final userStats = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ===== HERO HEADER =====
              SliverAppBar(
                expandedHeight: 300,
                backgroundColor: AppColors.surfaceLowest,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (currentProgramState.thumbnailUrl != null)
                        Image.network(currentProgramState.thumbnailUrl!, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.surfaceLowest.withValues(alpha: 0.8),
                              AppColors.surfaceLowest,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTypeBadge(currentProgramState),
                            const SizedBox(height: 12),
                            Text(
                              currentProgramState.title,
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentProgramState.description,
                              style: const TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== STATS ROW =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      _buildHeaderStat(Icons.schedule, currentProgramState.duration, 'DURATION'),
                      _buildHeaderStat(Icons.stairs, currentProgramState.difficulty.name.toUpperCase(), 'LEVEL'),
                      _buildHeaderStat(Icons.checklist_rtl_rounded, '${currentProgramState.tasksCompletedToday}/${currentProgramState.totalTasksToday}', 'TASKS'),
                    ],
                  ),
                ),
              ),

              // ===== ROADMAP TITLE =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Transformation Roadmap'.toUpperCase(),
                    style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                ),
              ),

              // ===== DAY LIST =====
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final day = index + 1;
                    final isLocked = !currentProgramState.isUnlocked;
                    final isCompleted = day < currentProgramState.currentDay && currentProgramState.isUnlocked;
                    final isToday = day == currentProgramState.currentDay && currentProgramState.isUnlocked;

                    return _buildDayCard(day, isLocked, isCompleted, isToday);
                  },
                  childCount: currentProgramState.totalDays,
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
            ],
          ),

          // ===== SMART BOTTOM BUTTON =====
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              top: false,
              bottom: true,
              child: _buildActionButton(context, ref, currentProgramState, userStats.coins),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(Program p) {
    if (p.isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.diamond_rounded, color: Colors.black, size: 14),
            SizedBox(width: 6),
            Text('PREMIUM ACCESS', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
      child: const Text('COIN BASE PROGRAM', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(int day, bool isLocked, bool isCompleted, bool isToday) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked ? Colors.white.withValues(alpha: 0.02) : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isToday ? AppColors.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.withValues(alpha: 0.1) : (isLocked ? Colors.white.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.1)),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isCompleted 
              ? const Icon(Icons.check, color: Colors.green, size: 20)
              : (isLocked ? const Icon(Icons.lock, color: Colors.white10, size: 18) : Text('$day', style: TextStyle(color: isToday ? AppColors.primary : Colors.white60, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day $day: Mission Name',
                  style: TextStyle(color: isLocked ? Colors.white24 : Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  isLocked ? 'Locked until program starts' : 'Specialized face-training activities.',
                  style: const TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              child: const Text('ACTIVE', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, Program p, int userCoins) {
    String label = '';
    IconData icon = Icons.play_arrow;
    Color color = AppColors.primary;
    VoidCallback? action;

    if (!p.isUnlocked) {
      if (p.isPremium) {
        label = 'UNLOCK WITH PREMIUM';
        icon = Icons.diamond_rounded;
        color = const Color(0xFFFFD700);
        action = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()));
      } else {
        label = 'UNLOCK FOR ${p.coinCost} COINS';
        icon = Icons.monetization_on;
        color = Colors.amber;
        action = () => _handleCoinUnlock(context, ref, p, userCoins);
      }
    } else {
      if (p.isCurrent) {
        label = 'CONTINUE DAY ${p.currentDay}';
        icon = Icons.bolt;
        action = () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramTaskScreen(program: p)));
      } else {
        label = 'START PROGRAM';
        icon = Icons.rocket_launch;
        action = () {
          ref.read(programsProvider.notifier).setAsCurrent(p.id);
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramTaskScreen(program: p)));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.title} is now your active program!')));
        };
      }
    }

    return GestureDetector(
      onTap: action,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCoinUnlock(BuildContext context, WidgetRef ref, Program p, int userCoins) async {
    if (userCoins < p.coinCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient coins! Opening shop...')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CoinShopScreen()),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: Colors.white10)),
          title: const Text('Confirm Purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: Text('Do you want to use ${p.coinCost} coins to unlock permanent access to ${p.title}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white24))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref.read(programsProvider.notifier).unlockProgram(p.id);
                if (success && context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Program unlocked successfully!')));
                }
              },
              child: const Text('UNLOCK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
