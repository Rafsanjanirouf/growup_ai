import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/backup_preference_service.dart';
import '../../core/services/local_db_service.dart';

class GoalSelectionScreen extends ConsumerStatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  ConsumerState<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends ConsumerState<GoalSelectionScreen> {
  final List<String> _selectedGoals = [];
  final List<String> _selectedProblems = [];
  String _selectedSkinType = 'Oily';
  String _selectedBudget = 'Basic';

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
    ref.read(userStateProvider.notifier).updateLifestyle(
          skinType: _selectedSkinType,
          budget: _selectedBudget,
        );
    ref.read(userStateProvider.notifier).completeOnboarding();

    // Save to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirestoreService().updateUser(user.uid, {
          'goals': _selectedGoals,
          'problems': _selectedProblems,
          'skinType': _selectedSkinType,
          'skin_type': _selectedSkinType, // fallback
          'budget': _selectedBudget,
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
      } else {
        if (mounted) Navigator.of(context).pushReplacementNamed('/backup-consent');
      }
    }
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
                Column(
                  children: _availableGoals.map((g) {
                    final id = g['id']!;
                    final title = g['title']!;
                    final desc = g['desc']!;
                    final isSelected = _selectedGoals.contains(id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () => _toggleGoal(id),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary.withAlpha(40) : Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : Colors.white.withAlpha(20),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      desc,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                color: isSelected ? AppTheme.primary : Colors.white24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                Column(
                  children: _availableProblems.map((p) {
                    final id = p['id']!;
                    final title = p['title']!;
                    final desc = p['desc']!;
                    final isSelected = _selectedProblems.contains(id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () => _toggleProblem(id),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.secondary.withAlpha(40) : Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.secondary : Colors.white.withAlpha(20),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      desc,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                color: isSelected ? AppTheme.secondary : Colors.white24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Step 2: Skin & Budget
                Text(
                  'YOUR DETAILS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  child: Column(
                    children: [
                      // Skin type dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Skin Type',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          DropdownButton<String>(
                            value: _selectedSkinType,
                            dropdownColor: AppTheme.surface,
                            underline: Container(),
                            style: GoogleFonts.outfit(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                            items: ['Oily', 'Dry', 'Mixed'].map((t) {
                              return DropdownMenuItem(value: t, child: Text(t));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSkinType = val);
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      // Budget Type
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monthly Budget',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          DropdownButton<String>(
                            value: _selectedBudget,
                            dropdownColor: AppTheme.surface,
                            underline: Container(),
                            style: GoogleFonts.outfit(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                            items: ['Basic', 'Premium'].map((b) {
                              return DropdownMenuItem(value: b, child: Text(b));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedBudget = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

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
