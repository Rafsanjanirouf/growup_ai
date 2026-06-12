import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/backup_preference_service.dart';

class GoalSelectionScreen extends ConsumerStatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  ConsumerState<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends ConsumerState<GoalSelectionScreen> {
  final List<String> _selectedGoals = [];
  String _selectedSkinType = 'Oily';
  String _selectedBudget = 'Basic';

  final List<Map<String, String>> _availableGoals = [
    {'title': 'Sharp Jawline 📐', 'desc': 'Chisel structure & mewing'},
    {'title': 'Clear Skin 🧼', 'desc': 'Reduce acne & glow skin'},
    {'title': 'Fix Posture 🧍', 'desc': 'Align spine & stand tall'},
    {'title': 'Better Dressing 👔', 'desc': 'Aesthetics & style fits'},
  ];

  void _toggleGoal(String goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
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
          'skin_type': _selectedSkinType,
          'budget': _selectedBudget,
          'onboarding_completed': true,
        });
      } catch (e) {
        debugPrint('Error saving goals to Firestore: $e');
      }
    }

    // Route: show backup consent screen first time, then camera scan
    if (mounted) {
      final hasConsent = BackupPreferenceService().hasShownConsent;
      Navigator.of(context)
          .pushReplacementNamed(hasConsent ? '/camera-scan' : '/backup-consent');
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
                    final title = g['title']!;
                    final desc = g['desc']!;
                    final isSelected = _selectedGoals.contains(title);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () => _toggleGoal(title),
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
