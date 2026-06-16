import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/backup_preference_service.dart';
import '../profile/backup_settings_screen.dart';
import '../share/glow_up_share_screen.dart';
import '../../core/providers/subscription_details_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/habit_provider.dart';
import '../../core/config/app_languages.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool isTab;
  const ProfileScreen({super.key, this.isTab = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Mock Support ticket state
  final TextEditingController _supportController = TextEditingController();

  String _getGoalName(String id) {
    switch (id) {
      case 'hair_growth': return 'Hair Growth 💇‍♂️';
      case 'better_sleep': return 'Better Sleep 😴';
      case 'lips_pink': return 'Pink Lips 👄';
      case 'skin_glow': return 'Skin Glow ✨';
      default: return id;
    }
  }

  void _showGoalChangeDialog() {
    final user = ref.read(userStateProvider);
    List<String> tempGoals = List.from(user.goals);

    final availableGoals = {
      'hair_growth': 'Hair Growth 💇‍♂️',
      'better_sleep': 'Better Sleep 😴',
      'lips_pink': 'Pink Lips 👄',
      'skin_glow': 'Skin Glow ✨',
    };

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Change Active Goals',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableGoals.entries.map((entry) {
                    final isSelected = tempGoals.contains(entry.key);
                    return CheckboxListTile(
                      title: Text(entry.value, style: GoogleFonts.outfit(color: Colors.white)),
                      value: isSelected,
                      activeColor: AppTheme.primary,
                      checkColor: Colors.white,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            tempGoals.add(entry.key);
                          } else {
                            tempGoals.remove(entry.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white30)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    ref.read(userStateProvider.notifier).updateGoals(tempGoals);
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      try {
                        await FirestoreService().updateUser(uid, {'goals': tempGoals});
                      } catch (_) {}
                    }
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Aura goals updated successfully!', style: GoogleFonts.outfit()),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                  child: Text('Save', style: GoogleFonts.outfit()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLegalDocument(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (_, controller) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.gavel_rounded, color: AppTheme.secondary),
                        const SizedBox(width: 10),
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        children: [
                          Text(
                            content,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSupportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                children: [
                  const Icon(Icons.support_agent_rounded, color: AppTheme.secondary),
                  const SizedBox(width: 10),
                  Text(
                    'Contact Aura Support',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Submit an issue ticket. Our लुकमैक्सिंग experts usually reply in 2-4 hours.',
                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _supportController,
                maxLines: 4,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Describe your issue (acne, Mewing queries, payment errors)...',
                  hintStyle: GoogleFonts.outfit(color: Colors.white30),
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
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppTheme.primaryGradient,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (_supportController.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    _supportController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Support Ticket Submitted! Ticket ID: #${DateTime.now().millisecond}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text('SUBMIT TICKET', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStateProvider);
    final subDetailsAsync = ref.watch(subscriptionDetailsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button Header (Conditionally shown)
                Row(
                  children: [
                    if (!widget.isTab)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    Text(
                      'YOUR PROFILE',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // User Bio Header Card
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.secondary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondary.withAlpha(50),
                              blurRadius: 16,
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/image/avater_image.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name.isEmpty ? 'Champ' : user.name,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.gender} • ${user.age} Years Old',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 1. Subscription Tier Status
                Text(
                  'MEMBERSHIP STATUS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  glowColor: AppTheme.success,
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppTheme.success, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AURA PRO UNLOCKED',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Premium features & AI routine scanning fully active.',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.isPro) ...[
                  const SizedBox(height: 16),
                  subDetailsAsync.when(
                    data: (details) {
                      if (details == null) return const SizedBox.shrink();
                      
                      IconData catIcon = Icons.card_giftcard_rounded;
                      Color catColor = AppTheme.primary;
                      if (details.category == 'Purchase') {
                        catIcon = Icons.credit_card_rounded;
                        catColor = AppTheme.secondary;
                      } else if (details.category == 'Trial') {
                        catIcon = Icons.timer_rounded;
                        catColor = Colors.orangeAccent;
                      }

                      String formatDate(DateTime d) => "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

                      return GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(catIcon, color: catColor, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${details.category.toUpperCase()} SUBSCRIPTION',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: catColor,
                                      letterSpacing: 1.0,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${details.ongoingDays} Days',
                                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('STARTED ON', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white54, letterSpacing: 1.0)),
                                      const SizedBox(height: 4),
                                      Text(formatDate(details.startDate), style: GoogleFonts.outfit(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(details.category == 'Purchase' ? 'RENEWS ON' : 'ENDS ON', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white54, letterSpacing: 1.0)),
                                      const SizedBox(height: 4),
                                      Text(formatDate(details.endDate), style: GoogleFonts.outfit(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
                const SizedBox(height: 28),

                // 2. Goal Management Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'YOUR CHISELED GOALS',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showGoalChangeDialog,
                      child: Text(
                        'EDIT',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.goals.isEmpty
                      ? [
                          Text(
                            'No goals chosen. Tap EDIT to add lookmaxxing targets.',
                            style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textSecondary),
                          )
                        ]
                      : user.goals.map((g) {
                          return Chip(
                            backgroundColor: Colors.white.withAlpha(12),
                            side: const BorderSide(color: Colors.white10),
                            label: Text(
                              _getGoalName(g),
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                ),
                const SizedBox(height: 28),

                // 3. Viral Share CTA
                _buildViralShareBanner(context),
                const SizedBox(height: 28),

                // 4. Settings & Options list
                Text(
                  'APP SETTINGS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSettingsTile(Icons.tune_rounded, 'Adjust Skin & Budget', 'Configure Oily/Dry and basic/premium routines', () {
                        _showGroomingSettingsDialog();
                      }),
                      const Divider(color: Colors.white12, height: 1),
                      _buildBackupTile(),
                      const Divider(color: Colors.white12, height: 1),
                      _buildCustomerCenterTile(),
                      const Divider(color: Colors.white12, height: 1),
                      _buildSettingsTile(Icons.support_agent_rounded, 'Live Help & Support', 'Submit queries to lookmaxxing coaches', () {
                        _showSupportModal();
                      }),
                      const Divider(color: Colors.white12, height: 1),
                      _buildSettingsTile(
                        Icons.language_rounded,
                        'Coach Language',
                        '${AppLanguages.flagFor(ref.watch(userStateProvider).coachLanguage)}  ${ref.watch(userStateProvider).coachLanguage.isEmpty ? 'Not set' : ref.watch(userStateProvider).coachLanguage}',
                        () => _showLanguageSettingsDialog(),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      _buildSettingsTile(Icons.notifications_active_rounded, 'Notification Times', 'Customize routine reminders', () {
                        _showNotificationTimesDialog();
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 4. Legal & Billing Documentation
                Text(
                  'LEGAL & BILLING DOCUMENTATION',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSettingsTile(Icons.verified_user_rounded, 'Privacy Policy', 'Data boundaries and face camera security protocols', () {
                        _showLegalDocument(
                          'Privacy Policy',
                          'Your facial privacy is our absolute priority.\n\n'
                              '1. Face Scan Data: All photos captured by your front camera inside the scanning oval frame are processed securely. The image is uploaded temporarily via high-security channels to process Lookmaxxing diagnostics.\n\n'
                              '2. Zero Persistent Logging: We do not compile, build, or sell visual databases of user face blueprints. Your baseline facial photos remain in your safe before/after vault which only you can access.\n\n'
                              '3. Third-party safeguards: Diagnostics sent to Gemini Vision API are stripped of user-identifiable metadata, safeguarding privacy completely.',
                        );
                      }),
                      const Divider(color: Colors.white12, height: 1),
                      _buildSettingsTile(Icons.gavel_rounded, 'Terms of Service', 'Subscription rules and usage terms for Lookmaxxing coaching', () {
                        _showLegalDocument(
                          'Terms of Service',
                          'Welcome to Aura Lookmaxxing Coach!\n\n'
                              'By subscribing to Aura weekly trial (₹49) or pro plans, you agree to: \n\n'
                              '1. Educational Guidance: Lookmaxxing, Mewing, and jaw fitness routines are for self-improvement educational purposes only. They do not constitute professional clinical medical advice.\n\n'
                              '2. Subscription Renewals: Subscription billing is managed securely through RevenueCat. You can cancel active auto-renewing subscriptions at any point within Play Store/App Store subscriptions manager.',
                        );
                      }),
                      const Divider(color: Colors.white12, height: 1),
                      _buildSettingsTile(Icons.currency_rupee_rounded, 'Refund Policy', 'Easy Razorpay UPI refunds, standard cancellation terms', () {
                        _showLegalDocument(
                          'Refund Policy',
                          'We support instant risk-free subscriptions!\n\n'
                              '1. Trial Period Refunds: If you purchased the Weekly Trial (₹49) and are not satisfied with your Day 1 face scan report or habit checklist, you are eligible for a full refund within 48 hours of subscription checkout.\n\n'
                              '2. Support Claims: To invoke a refund, simply open the Live Help Support section inside this profile page and submit a support ticket detailing your refund claim. Refund amounts are credited back to your original UPI app wallet instantly.',
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 5. Danger Zone Action
                Text(
                  'DANGER ZONE',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    // Confirm reset
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: Text('Delete Local Data?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                        content: Text('This will delete all local habit logs, streaks, and scanned score datasets on this device.', style: GoogleFonts.outfit(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white24))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('DELETE', style: GoogleFonts.outfit(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await LocalDbService().clearAllData();
                      await ref.read(userStateProvider.notifier).resetState();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.danger.withAlpha(100)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_forever_rounded, color: AppTheme.danger),
                          const SizedBox(width: 8),
                          Text(
                            'DELETE LOCAL DATA',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: Text('Logout?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                        content: Text('Are you sure you want to log out?', style: GoogleFonts.outfit(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white24))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('LOGOUT', style: GoogleFonts.outfit(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseAuth.instance.signOut();
                      await ref.read(userStateProvider.notifier).resetState();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(30)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'LOGOUT',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViralShareBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GlowUpShareScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5500CC), Color(0xFFD61CFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 SHARE YOUR GLOW-UP',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Flex your Aura Score to Instagram & Snapchat',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ios_share_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'FLEX',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupTile() {
    final isEnabled = BackupPreferenceService().isBackupEnabled;
    final statusColor = isEnabled ? AppTheme.success : AppTheme.secondary;
    final statusText  = isEnabled ? 'Cloud Backup ON' : 'Local Only';

    return ListTile(
      leading: Icon(
        isEnabled ? Icons.cloud_done_rounded : Icons.phone_android_rounded,
        color: statusColor,
      ),
      title: Text(
        'Data & Backup',
        style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        statusText,
        style: GoogleFonts.outfit(color: statusColor, fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withAlpha(80)),
            ),
            child: Text(
              isEnabled ? 'ON' : 'OFF',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white24, size: 12),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
      ).then((_) => setState(() {})), // refresh status on return
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.secondary),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
      onTap: onTap,
    );
  }

  /// Opens RevenueCat Customer Center — lets users manage/cancel subscriptions.
  Widget _buildCustomerCenterTile() {
    return ListTile(
      leading: const Icon(Icons.manage_accounts_rounded, color: AppTheme.primary),
      title: Text(
        'Manage Subscription',
        style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        'Upgrade, cancel or restore via RevenueCat',
        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          color: Colors.white24, size: 12),
      onTap: () async {
        await RevenueCatUI.presentCustomerCenter();
      },
    );
  }

  void _showGroomingSettingsDialog() {
    final user = ref.read(userStateProvider);
    String tempSkin = user.skinType;
    String tempBudget = user.budget;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Configure Setup Preferences',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Skin Type', style: GoogleFonts.outfit(color: Colors.white)),
                      DropdownButton<String>(
                        value: tempSkin,
                        dropdownColor: AppTheme.surface,
                        style: GoogleFonts.outfit(color: AppTheme.secondary),
                        underline: Container(),
                        items: ['Oily', 'Dry', 'Mixed'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => tempSkin = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Budget', style: GoogleFonts.outfit(color: Colors.white)),
                      DropdownButton<String>(
                        value: tempBudget,
                        dropdownColor: AppTheme.surface,
                        style: GoogleFonts.outfit(color: AppTheme.secondary),
                        underline: Container(),
                        items: ['Basic', 'Premium'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => tempBudget = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white30)),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(userStateProvider.notifier).updateLifestyle(skinType: tempSkin, budget: tempBudget);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Aura preferences updated successfully!', style: GoogleFonts.outfit()),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  },
                  child: Text('Save', style: GoogleFonts.outfit()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLanguageSettingsDialog() async {
    final userState = ref.read(userStateProvider);
    String currentLang = userState.coachLanguage;

    // If no language set yet, detect from device locale
    if (currentLang.isEmpty ||
        !AppLanguages.all.any((l) => l['name'] == currentLang)) {
      final deviceLocale =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      currentLang = AppLanguages.fromDeviceLocale(deviceLocale);
    }

    if (!mounted) return;

    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      builder: (ctx) => _ProfileLanguagePickerSheet(
        selectedLanguage: currentLang,
      ),
    );

    if (!mounted || chosen == null) return;

    await ref.read(userStateProvider.notifier).updateLanguage(chosen);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirestoreService().updateUser(uid, {
          'language': chosen,
          'languageLocale': AppLanguages.fullLocaleFor(chosen),
          'coach_language': chosen,
        });
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLanguages.flagFor(chosen)}  Language updated to $chosen!',
              style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.success,
        ),
      );
      setState(() {});
    }
  }

  void _showNotificationTimesDialog() {
    final userState = ref.read(userStateProvider);
    String tMorning = userState.effectiveMorningTime;
    String tNoon = userState.effectiveNoonTime;
    String tEvening = userState.effectiveEveningTime;
    String tNight = userState.effectiveNightTime;

    Future<void> pickTime(String initial, Function(String) onPicked) async {
      final parts = initial.split(':');
      final initTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      final picked = await showTimePicker(context: context, initialTime: initTime);
      if (picked != null) {
        final hh = picked.hour.toString().padLeft(2, '0');
        final mm = picked.minute.toString().padLeft(2, '0');
        onPicked('$hh:$mm');
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            Widget timeRow(String label, String timeStr, Function(String) onPicked) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: GoogleFonts.outfit(color: Colors.white)),
                  TextButton(
                    onPressed: () => pickTime(timeStr, (res) => setModalState(() => onPicked(res))),
                    child: Text(timeStr, style: GoogleFonts.outfit(color: AppTheme.secondary)),
                  ),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text('Notification Times', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  timeRow('Morning Routine', tMorning, (v) => tMorning = v),
                  timeRow('Noon Routine', tNoon, (v) => tNoon = v),
                  timeRow('Evening Routine', tEvening, (v) => tEvening = v),
                  timeRow('Night Routine', tNight, (v) => tNight = v),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white30)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref.read(userStateProvider.notifier).updateNotificationTimes(
                      morningTime: tMorning,
                      noonTime: tNoon,
                      eveningTime: tEvening,
                      nightTime: tNight,
                    );
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      await FirestoreService().updateUser(currentUser.uid, {
                        'aura_morning_time': tMorning,
                        'aura_noon_time': tNoon,
                        'aura_evening_time': tEvening,
                        'aura_night_time': tNight,
                      });
                    }
                    
                    // Immediately reschedule the reminders using the new times
                    await ref.read(habitProvider.notifier).rescheduleReminders();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notification times updated successfully!', style: GoogleFonts.outfit()),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  },
                  child: Text('Save', style: GoogleFonts.outfit()),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Reusable Language Picker Bottom Sheet (Profile Settings)
// ══════════════════════════════════════════════════════════════════════════════

class _ProfileLanguagePickerSheet extends StatefulWidget {
  final String selectedLanguage;
  const _ProfileLanguagePickerSheet({required this.selectedLanguage});

  @override
  State<_ProfileLanguagePickerSheet> createState() =>
      _ProfileLanguagePickerSheetState();
}

class _ProfileLanguagePickerSheetState
    extends State<_ProfileLanguagePickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.secondary.withAlpha(60)),
                ),
                child: const Icon(Icons.translate_rounded,
                    color: AppTheme.secondary, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coach Language',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'AI report & routine language',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Language Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppLanguages.all.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final lang = AppLanguages.all[index];
              final isSelected = _selected == lang['name'];
              return GestureDetector(
                onTap: () => setState(() => _selected = lang['name']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.secondary.withAlpha(35)
                        : Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.secondary
                          : Colors.white.withAlpha(20),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.secondary.withAlpha(40),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              lang['name']!,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppTheme.secondary : Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              lang['native']!,
                              style: GoogleFonts.outfit(
                                  fontSize: 10, color: Colors.white38),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.secondary, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Save Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppTheme.primaryGradient,
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SET LANGUAGE TO',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${AppLanguages.flagFor(_selected)} $_selected',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
