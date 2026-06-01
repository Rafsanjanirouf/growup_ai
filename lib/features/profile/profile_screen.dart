import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/user_stats_provider.dart';
import '../monetization/coin_shop_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStats = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ===== CINEMATIC HEADER WITH PROFILE TITLE =====
          SliverToBoxAdapter(child: _buildHeroHeader(context)),

          // ===== BENTO STATS HUB (GROWTH DATA) =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CoinShopScreen(),
                          ),
                        );
                      },
                      child: _buildBentoStat(
                        'COINS',
                        '${userStats.coins}',
                        Icons.monetization_on,
                        Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoStat(
                      'STREAK',
                      '14D',
                      Icons.local_fire_department,
                      Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoStat(
                      'SCORE',
                      '78',
                      Icons.auto_awesome,
                      AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== IDENTITY & SETTINGS CLUSTERS =====
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('PERSONAL IDENTITY'),
                _buildSettingsCluster([
                  _buildIdentityInfoRow(
                    Icons.alternate_email_rounded,
                    'Email Address',
                    'alex.mercer@growth.ai',
                  ),
                  _buildIdentityInfoRow(
                    Icons.fingerprint_rounded,
                    'User ID',
                    '#ALPHA-8829',
                  ),
                  const Divider(
                    color: Colors.white12,
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  _buildMenuRow(
                    Icons.edit_note_rounded,
                    'Edit Personal Details',
                    'Update your name or credentials',
                    isAction: true,
                  ),
                ]),

                const SizedBox(height: 32),
                _buildSectionHeader('ACCOUNT HUB'),
                _buildSettingsCluster([
                  _buildMenuRow(
                    Icons.history_rounded,
                    'Scan History',
                    'View all previous analysis',
                  ),
                  _buildMenuRow(
                    Icons.analytics_outlined,
                    'Performance Reports',
                    'Detailed weekly breakdown',
                  ),
                  _buildMenuRow(
                    Icons.workspace_premium_rounded,
                    'Premium Subscription',
                    'Manage your pro plan',
                    isPremium: true,
                  ),
                ]),

                const SizedBox(height: 32),
                _buildSectionHeader('PREFERENCES'),
                _buildSettingsCluster([
                  _buildMenuRow(
                    Icons.notifications_active_outlined,
                    'Notifications',
                    'Alerts & Reminders',
                  ),
                  _buildMenuRow(
                    Icons.vibration_rounded,
                    'Haptic Feedback',
                    'Tactile interaction mode',
                  ),
                  _buildMenuRow(
                    Icons.privacy_tip_outlined,
                    'Privacy & Security',
                    'Manage your biometric data',
                  ),
                ]),

                const SizedBox(height: 32),
                _buildSectionHeader('SUPPORT'),
                _buildSettingsCluster([
                  _buildMenuRow(
                    Icons.help_center_outlined,
                    'Help Center',
                    'Tutorials & FAQ',
                  ),
                  _buildMenuRow(
                    Icons.logout_rounded,
                    'Sign Out',
                    'Safely disconnect account',
                    isDestructive: true,
                  ),
                ]),
              ]),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
        ],
      ),
    );
  }

  Widget _buildIdentityInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 18),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        children: [
          // Background Blur Effect
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.network(
                'https://images.unsplash.com/photo-1614728263952-84ea206f0c4c?q=80&w=800&auto=format&fit=crop',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.surfaceLowest],
              ),
            ),
          ),

          // ===== ADDED: PROFILE TITLE ON TOP LEFT =====
          const Positioned(
            top: 60,
            left: 24,
            child: Text(
              'PROFILE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                // Glowing Avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://i.pravatar.cc/150?img=33',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Alex Mercer'.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: AppColors.secondary,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ALPHA LEVEL 12'.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Icon with Subtle Glow
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  Icon(icon, color: color, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSettingsCluster(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuRow(
    IconData icon,
    String title,
    String subtitle, {
    bool isPremium = false,
    bool isDestructive = false,
    bool isAction = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : (isAction
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDestructive
              ? Colors.redAccent
              : (isPremium
                    ? AppColors.tertiary
                    : (isAction ? AppColors.primary : Colors.white70)),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? Colors.redAccent
              : (isAction ? AppColors.primary : Colors.white),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white24, fontSize: 12),
      ),
      trailing: isPremium
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  color: AppColors.tertiary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Icon(
              isAction
                  ? Icons.open_in_new_rounded
                  : Icons.chevron_right_rounded,
              color: Colors.white10,
            ),
      onTap: () {},
    );
  }
}
