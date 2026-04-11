import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/bottom_action_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  'My Profile',
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        image: const DecorationImage(
                          image: NetworkImage('https://i.pravatar.cc/150?img=33'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: AppColors.surfaceLowest, size: 16),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Alex Mercer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Level 12 Alpha', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Stats
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: const [
                      Text('1,240', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.tertiary)),
                      SizedBox(height: 4),
                      Text('COINS', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: const [
                      Text('14', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.secondary)),
                      SizedBox(height: 4),
                      Text('DAY STREAK', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: const [
                      Text('67', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      SizedBox(height: 4),
                      Text('AVG SCORE', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Badges
          const Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBadgeNode('Early Bloomer', Icons.stars, AppColors.tertiary),
                const SizedBox(width: 16),
                _buildBadgeNode('Iron Jaw', Icons.architecture, AppColors.primary),
                const SizedBox(width: 16),
                _buildBadgeNode('Zen Master', Icons.self_improvement, AppColors.secondary),
                const SizedBox(width: 16),
                _buildBadgeNode('Streak x14', Icons.local_fire_department, AppColors.tertiary),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Menu
          _buildMenuRow(Icons.history, 'Scan History'),
          _buildMenuRow(Icons.bar_chart, 'Weekly Progress Reports'),
          _buildMenuRow(Icons.card_membership, 'Premium Subscription', color: AppColors.tertiary),
          _buildMenuRow(Icons.help_outline, 'Help & Support'),
            ],
          ),
          
          // Bottom Action Button
          BottomActionButton(
            label: 'Edit Profile',
            icon: Icons.edit,
            onTap: () {
              // Show profile edit screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeNode(String title, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1), border: Border.all(color: color.withValues(alpha: 0.3), width: 2)),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
      ],
    );
  }

  Widget _buildMenuRow(IconData icon, String title, {Color color = AppColors.onSurface}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: color))),
          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
