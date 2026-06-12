import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Paywall screen — 100% RevenueCat dashboard driven.
/// Shows RC's native PaywallView when offering is configured.
/// Shows a branded retry/loading screen while RC loads.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Offering? _offering;
  String? _errorMessage;
  int _retryCount = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _loadOffering();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Load RevenueCat offering ──────────────────────────────────────────────

  Future<void> _loadOffering() async {
    if (mounted) setState(() { _loading = true; _errorMessage = null; });
    try {
      final offering = await SubscriptionService().getCurrentOffering();
      debugPrint(offering == null
          ? '🔴 RC Paywall: offering is NULL'
          : '🟢 RC Paywall: "${offering.identifier}" — ${offering.availablePackages.length} packages');
      if (mounted) {
        setState(() {
          _offering = offering;
          _loading = false;
          _errorMessage = offering == null
              ? 'RevenueCat offering not configured yet.\nPlease check the RC dashboard.'
              : null;
        });
      }
    } catch (e) {
      debugPrint('🔴 RC Paywall error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load plans.\nTap retry to try again.';
        });
      }
    }
  }

  // ── Success handler ───────────────────────────────────────────────────────

  Future<void> _handleSuccess() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('paywall_pending', false);
    await ref.read(userStateProvider.notifier).setPro(true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirestoreService().updateUser(uid, {'is_pro': true});
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Welcome to Aura Pro!',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
    }
  }

  // ── Restore purchases ─────────────────────────────────────────────────────

  Future<void> _restorePurchases() async {
    setState(() => _loading = true);
    final info = await SubscriptionService().restorePurchases();
    if (!mounted) return;
    if (info != null && info.entitlements.active.containsKey(RCConfig.entitlement)) {
      await _handleSuccess();
    } else {
      setState(() {
        _loading = false;
        _errorMessage = 'No active subscription found to restore.';
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── Loading ──────────────────────────────────────────────────────────────
    if (_loading) return _buildLoading();

    // ── RC PaywallView — the main path ───────────────────────────────────────
    if (_offering != null) {
      return PaywallView(
        offering: _offering,
        onDismiss: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacementNamed('/camera-scan');
          }
        },
        onPurchaseCompleted: (customerInfo, storeTransaction) async {
          await _handleSuccess();
        },
        onRestoreCompleted: (customerInfo) async {
          if (customerInfo.entitlements.active.containsKey(RCConfig.entitlement)) {
            await _handleSuccess();
          }
        },
        onPurchaseError: (error) {
          if (mounted) setState(() => _errorMessage = error.message);
        },
      );
    }

    // ── RC offering not configured yet — branded wait screen ─────────────────
    return _buildWaitScreen();
  }

  // ── Loading spinner ───────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.secondary),
              SizedBox(height: 20),
              Text(
                'Loading subscription plans...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Branded wait/error screen (RC not configured yet) ────────────────────

  Widget _buildWaitScreen() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing logo
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) => Opacity(
                    opacity: _pulseAnim.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withAlpha(80),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'Aura Pro',
                  style: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  _errorMessage ?? 'Setting up subscription plans...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _retryCount++);
                      _loadOffering();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      _retryCount > 0 ? 'Retry Again ($_retryCount)' : 'Retry',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Restore button
                TextButton(
                  onPressed: _restorePurchases,
                  child: Text(
                    'Restore previous purchase',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white38,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Skip / back
                TextButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacementNamed('/camera-scan');
                    }
                  },
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white24,
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
}
