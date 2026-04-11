import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../face_scan/face_scan_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      body: ListView(
        padding: const EdgeInsets.only(top: 20, bottom: 140),
        physics: const BouncingScrollPhysics(),
        children: [
          // ===== PAGE TITLE =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Dashboard',
              style: AppTypography.displaySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),


          // ===== SCAN HISTORY SECTION =====
          _buildScanHistorySection(context),

          const SizedBox(height: 24),

          // ===== QUICK ACTIONS =====
          _buildQuickActions(context),

          const SizedBox(height: 24),

          // ===== TREE PROGRESS OVERVIEW =====
          _buildTreeProgressOverview(context),

          const SizedBox(height: 24),

          // ===== AI TOOLS HUB =====
          _buildAiToolsSection(context),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ===== SCAN HISTORY SECTION =====
  Widget _buildScanHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Scan History',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) {
              return _buildHistoryCard(
                score: 85 - index,
                date: index == 0 ? 'Today' : 'Apr ${11 - index}',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard({required int score, required String date}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.face, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'Score: $score',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            date,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ===== QUICK ACTIONS =====
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              title: 'Next Scan',
              subtitle: '6 Days',
              icon: Icons.timer_outlined,
              color: AppColors.success,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionCard(
              title: 'New Analysis',
              subtitle: 'Start Scan',
              icon: Icons.add_a_photo_outlined,
              color: Colors.white,
              isGradient: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FaceScanScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isGradient = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isGradient ? null : AppColors.surfaceLow,
          gradient: isGradient ? AppColors.kineticGradient : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isGradient ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isGradient ? Colors.black : color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: isGradient ? Colors.black87 : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.labelLarge.copyWith(
                    color: isGradient ? Colors.black : color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== TREE OVERVIEW =====
  Widget _buildTreeProgressOverview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.park_rounded, color: AppColors.success, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grow Your Tree',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete today\'s missions to level up.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  // ===== AI TOOLS =====
  Widget _buildAiToolsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Tools Hub',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'View All →',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              final tools = [
                {'name': 'Hairstyle AI', 'icon': Icons.content_cut},
                {'name': 'Glass AI', 'icon': Icons.add_a_photo},
                {'name': 'Aging Pro', 'icon': Icons.help_outline},
              ];
              return _buildToolCard(
                name: tools[index]['name'] as String,
                icon: tools[index]['icon'] as IconData,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard({required String name, required IconData icon}) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.warning, size: 24),
          const SizedBox(height: 8),
          Text(
            name,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
