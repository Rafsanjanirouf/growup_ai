import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/backup_preference_service.dart';
import '../../core/services/firestore_service.dart';

/// Settings screen for managing cloud backup preferences.
/// Accessible from Profile → Data & Backup.
class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen>
    with SingleTickerProviderStateMixin {
  late bool _isEnabled;
  bool _isLoading = false;

  late final AnimationController _anim;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _isEnabled = BackupPreferenceService().isBackupEnabled;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _toggleBackup(bool value) async {
    setState(() => _isLoading = true);
    await BackupPreferenceService().setBackupEnabled(value);
    setState(() {
      _isEnabled = value;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '☁️ Cloud Backup Enabled — syncing your data...'
                : '📱 Switched to Local Only mode',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: value ? AppTheme.primary : AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteCloudData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: AppTheme.danger),
            const SizedBox(width: 10),
            Text(
              'Delete Cloud Data?',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all your scan results, habits, and face photos from our cloud servers.\n\nYour local data on this device will NOT be deleted.',
          style: GoogleFonts.outfit(
              fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: Colors.white30)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DELETE FROM CLOUD',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreService().deleteUserScanData(user.uid);
      }
      // Disable backup after deletion
      await BackupPreferenceService().setBackupEnabled(false);
      setState(() => _isEnabled = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cloud data deleted successfully',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting data: $e',
                style: GoogleFonts.outfit()),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'DATA & BACKUP',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Status Banner ──────────────────────────────────
                        _buildStatusBanner(),
                        const SizedBox(height: 28),

                        // ── Master Toggle ──────────────────────────────────
                        _sectionLabel('CLOUD BACKUP'),
                        const SizedBox(height: 12),
                        _buildToggleCard(),
                        const SizedBox(height: 28),

                        // ── What gets stored ──────────────────────────────
                        _sectionLabel('WHAT GETS STORED'),
                        const SizedBox(height: 12),
                        _buildDataBreakdown(),
                        const SizedBox(height: 28),

                        // ── Security info ─────────────────────────────────
                        _buildSecurityCard(),
                        const SizedBox(height: 28),

                        // ── Danger zone ───────────────────────────────────
                        if (_isEnabled) ...[
                          _sectionLabel('DANGER ZONE'),
                          const SizedBox(height: 12),
                          _buildDeleteCloudButton(),
                          const SizedBox(height: 40),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Status Banner ─────────────────────────────────────────────────────────

  Widget _buildStatusBanner() {
    final color = _isEnabled ? AppTheme.primary : AppTheme.secondary;
    final icon =
        _isEnabled ? Icons.cloud_done_rounded : Icons.phone_android_rounded;
    final title = _isEnabled ? 'Cloud Backup Active' : 'Local Only Mode';
    final sub = _isEnabled
        ? 'Your scan data syncs securely to cloud'
        : 'All data stays on this device only';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withAlpha(50), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withAlpha(100)),
            ),
            child: Text(
              _isEnabled ? 'ON' : 'OFF',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Toggle Card ───────────────────────────────────────────────────────────

  Widget _buildToggleCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_sync_rounded,
                  color: AppTheme.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Cloud Backup',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Scan results, habits & history synced securely',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              _isLoading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppTheme.primary),
                    )
                  : Switch.adaptive(
                      value: _isEnabled,
                      activeThumbColor: AppTheme.primary,
                      activeTrackColor: AppTheme.primary.withAlpha(80),
                      onChanged: _toggleBackup,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Data Breakdown ────────────────────────────────────────────────────────

  Widget _buildDataBreakdown() {
    final items = [
      ('📸', 'Face Scan Image', 'Before/after photos'),
      ('🧠', 'AI Scan Results', 'Aura scores, symmetry, ratings'),
      ('📋', 'Daily Habits & Tasks', 'Routine logs & streaks'),
      ('📊', 'Scan History', 'Progress timeline'),
    ];

    final color = _isEnabled ? AppTheme.success : AppTheme.secondary;
    final locationLabel = _isEnabled ? '☁️ Server' : '📱 Local Device';
    final groupTitle = _isEnabled ? 'Backed Up to Cloud' : 'Stored on Local Device';
    final groupIcon = _isEnabled ? Icons.cloud_done_rounded : Icons.phone_android_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(groupIcon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                groupTitle,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            item.$3,
                            style: GoogleFonts.outfit(
                                fontSize: 10, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withAlpha(80)),
                      ),
                      child: Text(
                        locationLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }


  // ── Security Card ─────────────────────────────────────────────────────────

  Widget _buildSecurityCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(12)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded,
                      color: AppTheme.success, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Our Security Promise',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...[
                '🔐 End-to-end encryption for all cloud data',
                '🚫 We never sell or share your personal data',
                '🗑️ Face photos deleted from AI servers immediately after analysis',
                '📋 GDPR & Data Protection compliant',
                '🔄 You can delete cloud data at any time below',
              ].map((text) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text.substring(0, 2),
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text.substring(2).trim(),
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete Cloud Button ───────────────────────────────────────────────────

  Widget _buildDeleteCloudButton() {
    return GestureDetector(
      onTap: _deleteCloudData,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.danger.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.danger.withAlpha(80)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: AppTheme.danger, size: 20),
              const SizedBox(width: 8),
              Text(
                'DELETE ALL CLOUD DATA',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.danger,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
