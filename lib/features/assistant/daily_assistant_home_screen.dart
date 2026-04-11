import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class DailyAssistantHomeScreen extends StatelessWidget {
  const DailyAssistantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'AI Assistant',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24).copyWith(bottom: 120),
        children: [
          // Hero Section: GrowUp Coach
          _buildHeroSection(),
          const SizedBox(height: 48),

          // Chat Preview with Quick Suggestions
          _buildChatPreviewSection(),
          const SizedBox(height: 48),

          // Message Limit Indicator
          _buildMessageLimitSection(),
          const SizedBox(height: 48),

          // Stats Grid
          _buildStatsGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Coach Avatar
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                gradient: AppColors.kineticGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.surface,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCUKIEmpSe7tlUSMNh9j-Vh_JwQIuHeBoYxsLFtWut1mqifXNB29fXWFAQr0cmouzjwl5BtE5wZGN1c9b5R_Hdh-uwnDxWSSnzSHs-ycGd_gMHGEYKkLCZn29WY-e075ltWliBlAK45JFZyj_zwKSGgIzuUI13ENM8pitn4XQPeOIQvNCgwOgCAtc3mGPKeOjvlwTnt3K5mY_ESsKwnr2uooHaSDTsKgUt5oOC0zTcc0x7h_V_cKiNcEX0_njGGk0EJbQ91-OCvrGs',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceHighest,
                      child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'DAILY COACH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ready to level up today?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatPreviewSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceBright.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Message
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppColors.kineticGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.scrimLight, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
                      ),
                      child: const Text(
                        'Good morning! I\'ve analyzed your progress. Your skin hydration is up by 12% this week. What shall we focus on today to keep the momentum going?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Suggestion Chips
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  _buildSuggestionChip('face', 'Skincare Advice', AppColors.primary),
                  _buildSuggestionChip('content_cut', 'Grooming Guide', AppColors.secondary),
                  _buildSuggestionChip('restaurant', 'Diet & Nutrition', AppColors.tertiary),
                  _buildSuggestionChip('fitness_center', 'Exercise Guide', AppColors.error),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String icon, String label, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                _getIconData(icon),
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'face':
        return Icons.face;
      case 'content_cut':
        return Icons.content_cut;
      case 'restaurant':
        return Icons.restaurant;
      case 'fitness_center':
        return Icons.fitness_center;
      default:
        return Icons.star;
    }
  }

  Widget _buildMessageLimitSection() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: 0.6,
            minHeight: 8,
            backgroundColor: AppColors.surfaceLowest,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.flash_on, color: AppColors.tertiary, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '3 FREE MESSAGES LEFT TODAY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'UPGRADE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceBright.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.05)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY STREAK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildStreakDay('M', true),
                          const SizedBox(width: 8),
                          _buildStreakDay('T', true),
                          const SizedBox(width: 8),
                          _buildStreakDay('W', true),
                          const SizedBox(width: 8),
                          _buildStreakDay('T', false),
                          const SizedBox(width: 8),
                          _buildStreakDay('F', false),
                        ],
                      ),
                      const Text(
                        '3 Days',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.insights, color: AppColors.primary, size: 32),
              const SizedBox(height: 16),
              const Text(
                'Smart Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Level 2 Analysis unlocked',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakDay(String day, bool completed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: completed ? AppColors.kineticGradient : null,
        color: completed ? null : AppColors.surfaceHighest,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: completed ? AppColors.scrimLight : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
