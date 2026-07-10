import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/backup_preference_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/subscription_service.dart';

class GoalSelectionScreen extends ConsumerStatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  ConsumerState<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends ConsumerState<GoalSelectionScreen> {
  final List<String> _selectedGoals = [];
  final List<String> _selectedProblems = [];

  final List<Map<String, String>> _availableGoals = [
    {'id': 'hair_growth', 'title': 'Hair Growth 💇‍♂️', 'desc': 'Stop hair fall & stimulate growth'},
    {'id': 'better_sleep', 'title': 'Better Sleep 😴', 'desc': 'Optimize sleep quality & energy'},
    {'id': 'lips_pink', 'title': 'Pink Lips 👄', 'desc': 'Reduce pigmentation & hydrate'},
    {'id': 'skin_glow', 'title': 'Skin Glow ✨', 'desc': 'Clear skin, reduce blemishes & glow'},
  ];

  final List<Map<String, String>> _availableProblems = [
    {'id': 'acne', 'title': 'Acne 🧼', 'desc': 'Pimples, whiteheads & blackheads'},
    {'id': 'dark_circles', 'title': 'Dark Circles 🐼', 'desc': 'Tired eyes & under-eye shadows'},
    {'id': 'hair_fall', 'title': 'Hair Fall 💇', 'desc': 'Thinning hairline & shedding'},
    {'id': 'weight', 'title': 'Weight Issues ⚖️', 'desc': 'Bulk, cut, or BMI management'},
    {'id': 'dull', 'title': 'Dull Skin 🌫️', 'desc': 'Dry, tired-looking complexion'},
    {'id': 'dark_spots', 'title': 'Dark Spots 🟤', 'desc': 'Hyperpigmentation & spots'},
  ];

  void _toggleGoal(String id) {
    setState(() {
      if (_selectedGoals.contains(id)) {
        _selectedGoals.remove(id);
      } else {
        _selectedGoals.add(id);
      }
    });
  }

  void _toggleProblem(String id) {
    setState(() {
      if (_selectedProblems.contains(id)) {
        _selectedProblems.remove(id);
      } else {
        _selectedProblems.add(id);
      }
    });
  }

  Future<void> _completeSelection() async {
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one goal.', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (_selectedProblems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one problem.', style: GoogleFonts.outfit()),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    // Save states to Riverpod
    ref.read(userStateProvider.notifier).updateGoals(_selectedGoals);
    ref.read(userStateProvider.notifier).completeOnboarding();

    // Save to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirestoreService().updateUser(user.uid, {
          'goals': _selectedGoals,
          'problems': _selectedProblems,
          'language': 'English',
          'languageLocale': 'en-US',
          'profileCompleted': true,
          'completedAt': DateTime.now().millisecondsSinceEpoch,
          'onboarding_completed': true,
        });
      } catch (e) {
        debugPrint('Error saving goals to Firestore: $e');
      }
    }

    // Route: show backup consent screen first time, then camera scan
    if (mounted) {
      final hasConsent = BackupPreferenceService().hasShownConsent;
      if (hasConsent) {
        if (user != null) {
          final localScans = await FirestoreService().getUserScans(user.uid);
          if (localScans.isNotEmpty) {
            final scanDateData = localScans.first['scan_date'];
            DateTime lastScanDate;
            if (scanDateData is Timestamp) {
              lastScanDate = scanDateData.toDate();
            } else {
              lastScanDate = DateTime.parse(scanDateData.toString());
            }
            if (DateTime.now().difference(lastScanDate).inDays < 7) {
              bool isPro = false;
              try {
                isPro = await SubscriptionService().isProEntitled();
              } catch (_) {}
              if (!mounted) return;
              if (isPro) {
                Navigator.of(context).pushReplacementNamed('/dashboard');
              } else {
                Navigator.of(context).pushReplacementNamed('/locked-report');
              }
              return;
            }
          }
        }
        if (mounted) Navigator.of(context).pushReplacementNamed('/camera-scan');
      } else {
        if (mounted) Navigator.of(context).pushReplacementNamed('/backup-consent');
      }
    }
  }

  Widget _buildGridSelection({
    required List<Map<String, String>> items,
    required List<String> selectedItems,
    required Function(String) onToggle,
    required Color activeColor,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['id']!;
        final title = item['title']!;
        final desc = item['desc']!;
        final isSelected = selectedItems.contains(id);

        return GestureDetector(
          onTap: () => onToggle(id),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withAlpha(40) : Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? activeColor : Colors.white.withAlpha(20),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: isSelected ? activeColor : Colors.white24,
                    size: 20,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Set Your Target',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose what you want to improve first.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Step 1: Goals
                Text(
                  'SELECT YOUR GOALS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGridSelection(
                  items: _availableGoals,
                  selectedItems: _selectedGoals,
                  onToggle: _toggleGoal,
                  activeColor: AppTheme.primary,
                ),
                const SizedBox(height: 24),

                // Step 1.5: Problems
                Text(
                  'SELECT YOUR PROBLEMS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGridSelection(
                  items: _availableProblems,
                  selectedItems: _selectedProblems,
                  onToggle: _toggleProblem,
                  activeColor: AppTheme.secondary,
                ),
                const SizedBox(height: 24),


                // Next Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: ElevatedButton(
                    onPressed: _completeSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'GENERATE AI SCANNER',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.bolt),
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
}
