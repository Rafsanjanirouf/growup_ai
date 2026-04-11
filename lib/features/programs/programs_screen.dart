import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/bottom_action_button.dart';
import 'program_detail_screen.dart';
import '../monetization/premium_paywall_screen.dart';
import '../../core/widgets/app_cards.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 140, top: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              // ===== PAGE TITLE =====
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Programs',
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
          // Hero Active Program
          ProgressCard(
            title: 'Face Glow Program',
            subtitle: 'Day 12 of 30 - Actively improving',
            progress: 0.4,
            progressLabel: '40% Complete - 18 Days Left',
            progressColor: AppColors.secondary,
            borderRadius: 24,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Continue →',
                style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
              ),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.primary, width: 4))),
                padding: const EdgeInsets.only(left: 12),
                child: const Text('Recommended for You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
            ],
          ),
          const SizedBox(height: 24),

          // Program Cards
          _buildProgramRow(context, 'Jawline Sculptor', 'Master face yoga to define your facial profile.', '21 Days', 'Intermediate', 150, Icons.fitness_center),
          const SizedBox(height: 16),
          _buildProgramRow(context, 'Quit Bad Habits', 'Science-backed behavioral retraining to reclaim focus.', '30 Days', 'Advanced', 100, Icons.psychology),
          const SizedBox(height: 16),
          _buildProgramRow(context, 'Posture Perfection', 'Fix Tech Neck with 5-min micro-adjustments.', '14 Days', 'Essential', 0, Icons.self_improvement, isFree: true),
          const SizedBox(height: 40),

          // Premium Upsell
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.surfaceHigh, AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              border: Border(top: BorderSide(color: AppColors.primary, width: 4)),
            ),
            child: Column(
              children: [
                const Text('Unlock the Growth Lab', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                const Text('Get unlimited access to all premium programs, expert AI coaching, and exclusive daily quests.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPaywallScreen())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(gradient: AppColors.kineticGradient, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: const Text('Go Premium — \$9.99/mo', style: TextStyle(color: AppColors.surfaceLowest, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ],
            ),
          )
            ],
          ),
          // Bottom Action Button
          BottomActionButton(
            label: 'Start Program',
            icon: Icons.play_arrow,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgramDetailScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgramRow(BuildContext context, String title, String desc, String duration, String level, int price, IconData icon, {bool isFree = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgramDetailScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    if (isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Text('FREE', style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.tertiary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on, color: AppColors.tertiary, size: 12),
                            const SizedBox(width: 4),
                            Text('$price', style: const TextStyle(color: AppColors.tertiary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 8),
                Text(desc, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.onSurfaceVariant, size: 12),
                    const SizedBox(width: 4),
                    Text(duration.toUpperCase(), style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    const Icon(Icons.bolt, color: AppColors.onSurfaceVariant, size: 12),
                    const SizedBox(width: 4),
                    Text(level.toUpperCase(), style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    ),
  );
  }
}
