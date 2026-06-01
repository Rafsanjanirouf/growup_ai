import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/navigation_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/daily_tasks_screen.dart';
import '../assistant/assistant_screen.dart';
import '../programs/programs_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/widgets/dashboard_stats_hud.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  final List<Widget> _screens = [
    const DashboardScreen(),
    const DailyTasksScreen(),
    const ProgramsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceHighest,
      extendBody: true,
      body: Column(
        children: [
          // Persistent Fixed Top Bar - Hidden on Profile
          if (currentIndex != 3) const DashboardStatsHud(),
          
          // Navigation Tab Content
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.8), // Glassmorphism
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavBarItem(
                      icon: Icons.home_rounded,
                      label: 'HOME',
                      isSelected: currentIndex == 0,
                      onTap: () => ref.read(navigationProvider.notifier).setTab(0),
                    ),
                    _NavBarItem(
                      icon: Icons.park_outlined,
                      label: 'TREE',
                      isSelected: currentIndex == 1,
                      onTap: () => ref.read(navigationProvider.notifier).setTab(1),
                    ),
                    _NavBarItem(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI HUB',
                      isSelected: false, // AI Hub is always independent now
                      isAi: true,
                      onTap: () {
                        // Navigate to AI as a standalone page (hides bottom navbar)
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const AssistantScreen())
                        );
                      },
                    ),
                    _NavBarItem(
                      icon: Icons.explore_outlined,
                      label: 'PLAN',
                      isSelected: currentIndex == 2,
                      onTap: () => ref.read(navigationProvider.notifier).setTab(2),
                    ),
                    _NavBarItem(
                      icon: Icons.person_outline_rounded,
                      label: 'ME',
                      isSelected: currentIndex == 3,
                      onTap: () => ref.read(navigationProvider.notifier).setTab(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAi;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isAi = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected
                  ? AppColors.kineticGradient
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? AppColors.onPrimary
                  : isAi 
                      ? AppColors.secondary 
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
          if (!isSelected) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isAi ? AppColors.secondary : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
