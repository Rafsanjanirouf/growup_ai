import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/backup_preference_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/local_db_service.dart';

/// Shown once after onboarding (goal selection) before the first camera scan.
/// Lets the user explicitly choose whether to enable cloud backup.
class BackupConsentScreen extends StatefulWidget {
  const BackupConsentScreen({super.key});

  @override
  State<BackupConsentScreen> createState() => _BackupConsentScreenState();
}

class _BackupConsentScreenState extends State<BackupConsentScreen>
    with SingleTickerProviderStateMixin {
  // null = no selection yet, true = backup on, false = backup off
  bool? _selected;
  bool _saving = false;

  late final AnimationController _anim;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _saving = true);

    final svc = BackupPreferenceService();
    await svc.setBackupEnabled(_selected!);
    await svc.markConsentShown();

    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final localScans = await LocalDbService().getAllScans(user.uid);
        if (localScans.isNotEmpty) {
          final lastScanDate = DateTime.parse(localScans.first['date'] as String);
          if (DateTime.now().difference(lastScanDate).inDays < 7) {
            if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
            return;
          }
        }
      }
      if (mounted) Navigator.of(context).pushReplacementNamed('/camera-scan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back navigation — user MUST make a choice
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────────────
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(80),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.shield_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DATA & PRIVACY',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              'Choose Your Backup',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose where your face scan data, AI results, habits and history are stored.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Option A: Backup OFF ─────────────────────────────────────
                    _OptionCard(
                      selected: _selected == false,
                      onTap: () => setState(() => _selected = false),
                      icon: Icons.phone_android_rounded,
                      iconColor: AppTheme.secondary,
                      glowColor: AppTheme.secondary,
                      badge: 'RECOMMENDED',
                      badgeColor: AppTheme.secondary,
                      title: 'Local Only',
                      subtitle: 'Maximum Privacy',
                      description:
                          'All your scan data stays only on this device. Nothing is uploaded to any server.',
                      isCloud: false,
                    ),
                    const SizedBox(height: 16),

                    // ── Option B: Backup ON ──────────────────────────────────────
                    _OptionCard(
                      selected: _selected == true,
                      onTap: () => setState(() => _selected = true),
                      icon: Icons.cloud_sync_rounded,
                      iconColor: AppTheme.primary,
                      glowColor: AppTheme.primary,
                      badge: 'MULTI-DEVICE',
                      badgeColor: AppTheme.primary,
                      title: 'Cloud Backup',
                      subtitle: 'Sync Across Devices',
                      description:
                          'Data is encrypted and securely backed up. Restore everything instantly on a new device.',
                      isCloud: true,
                    ),
                    const SizedBox(height: 12),

                    // ── Fine print ───────────────────────────────────────────────
                    _buildFinePrint(),
                    const SizedBox(height: 32),

                    // ── Confirm Button ───────────────────────────────────────────
                    AnimatedOpacity(
                      opacity: _selected != null ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _selected != null
                              ? AppTheme.primaryGradient
                              : const LinearGradient(
                                  colors: [Colors.white12, Colors.white12]),
                          boxShadow: _selected != null
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withAlpha(100),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  )
                                ]
                              : null,
                        ),
                        child: ElevatedButton(
                          onPressed: (_selected != null && !_saving) ? _confirm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _selected == null
                                          ? 'SELECT AN OPTION'
                                          : _selected == false
                                              ? 'CONTINUE WITH LOCAL ONLY'
                                              : 'CONTINUE WITH BACKUP',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_selected != null) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded,
                                          color: Colors.white, size: 20),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Note: can be changed later
                    Center(
                      child: Text(
                        'You can change this anytime in Profile → Data & Backup',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinePrint() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.white38, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'We use end-to-end encryption for all cloud data. We never sell your data or share it with third parties. Face photos are only used for AI analysis and deleted from processing servers immediately after.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white38,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Option Card ──────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final Color glowColor;
  final String badge;
  final Color badgeColor;
  final String title;
  final String subtitle;
  final String description;
  final bool isCloud;

  const _OptionCard({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.glowColor,
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isCloud,
  });

  static const _items = [
    ('📸', 'Face Scan Image'),
    ('🧠', 'AI Scan Results'),
    ('📋', 'Daily Habits & Tasks'),
    ('📊', 'Scan History'),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? glowColor.withAlpha(20)
              : Colors.white.withAlpha(6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? glowColor : Colors.white.withAlpha(20),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: glowColor.withAlpha(60),
                    blurRadius: 24,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? glowColor.withAlpha(40)
                        : Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: glowColor.withAlpha(80),
                              blurRadius: 12,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(icon,
                      color: selected ? iconColor : Colors.white38, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: selected ? Colors.white : Colors.white70,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: selected ? iconColor : Colors.white38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? badgeColor.withAlpha(40)
                        : Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? badgeColor.withAlpha(120)
                          : Colors.white.withAlpha(15),
                    ),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: selected ? badgeColor : Colors.white30,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? iconColor : Colors.transparent,
                    border: Border.all(
                      color: selected ? iconColor : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 13)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Description
            Text(
              description,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: selected ? Colors.white70 : Colors.white38,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Data items list — 4 items only
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            ..._items.map((item) => _buildRow(
                  item.$1,
                  item.$2,
                  isCloud,
                  selected,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
      String emoji, String label, bool cloud, bool cardSelected) {
    final chipColor = cloud ? AppTheme.primary : AppTheme.secondary;
    final chipLabel = cloud ? '☁️ Server' : '📱 Local Device';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cardSelected ? Colors.white : Colors.white54,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: chipColor.withAlpha(80)),
            ),
            child: Text(
              chipLabel,
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: chipColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


