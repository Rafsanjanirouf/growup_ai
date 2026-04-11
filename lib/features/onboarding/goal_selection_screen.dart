import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/voice_guide_provider.dart';
import '../../shared/widgets/voice_guide_toggle.dart';

class GoalSelectionScreen extends ConsumerStatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  ConsumerState<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends ConsumerState<GoalSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger AI Guide narration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceGuideProvider.notifier).speak(
        "Start your journey by choosing your evolution goals. We'll tailor your daily missions based on these selections."
      );
    });
  }

  final List<Goal> goals = [
    Goal(
      id: 'jawline',
      emoji: '✨',
      title: 'Sculpted Jawline',
      description: 'Sharpen your jawline and improve facial definition',
      color: AppColors.primary,
    ),
    Goal(
      id: 'skin',
      emoji: '🌟',
      title: 'Clear Glowing Skin',
      description: 'Achieve a radiant complexion with expert skincare',
      color: AppColors.secondary,
    ),
    Goal(
      id: 'symmetry',
      emoji: '⚖️',
      title: 'Facial Symmetry',
      description: 'Balance your features and improve proportions',
      color: AppColors.tertiary,
    ),
    Goal(
      id: 'posture',
      emoji: '🧘',
      title: 'Elite Posture',
      description: 'Stand tall with professional body alignment correction',
      color: Colors.blue,
    ),
    Goal(
      id: 'style',
      emoji: '👔',
      title: 'Style Elevation',
      description: 'Curate a high-status wardrobe and fashion sense',
      color: Colors.deepPurple,
    ),
    Goal(
      id: 'hair',
      emoji: '💇',
      title: 'Hair Vitality',
      description: 'Optimize growth and thickness with expert routines',
      color: Colors.orange,
    ),
    Goal(
      id: 'muscle',
      emoji: '💪',
      title: 'Muscle Definition',
      description: 'Tone your physique for a sharper, athletic silhouette',
      color: AppColors.warning,
    ),
    Goal(
      id: 'mindset',
      emoji: '🧠',
      title: 'Iron Mindset',
      description: 'Develop discipline and unbreakable self-confidence',
      color: Colors.redAccent,
    ),
    Goal(
      id: 'discipline',
      emoji: '📈',
      title: 'Daily Discipline',
      description: 'Master consistency and track your long-term evolution',
      color: const Color(0xFF10B981),
    ),
  ];

  Set<String> selectedGoals = {};
  bool _isLoading = false;

  void _toggleGoal(String goalId) {
    setState(() {
      if (selectedGoals.contains(goalId)) {
        selectedGoals.remove(goalId);
      } else {
        selectedGoals.add(goalId);
      }
    });
  }

  void _handleContinue() {
    if (selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one goal'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Save goals and complete onboarding
    _saveGoalsAndNavigate();
  }

  Future<void> _saveGoalsAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save selected goals as comma-separated string
      await prefs.setString('selectedGoals', selectedGoals.join(','));
      
      // Mark onboarding as complete (if not already done by auth screen)
      await prefs.setBool('isOnboardingComplete', true);
      
      // Wait a bit to simulate saving
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/face-scan');
      }
    } catch (e) {
      debugPrint('Error saving goals: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving your goals. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Lock navigation
      child: Scaffold(
        backgroundColor: AppColors.surfaceLowest,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceLowest,
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          title: Text(
            'STEP 2/2',
            style: AppTypography.eyebrow.copyWith(color: AppColors.primary),
          ),
          centerTitle: true,
        ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Choose Your Goals',
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select what you want to improve. You can change this later.',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Goals Grid
                      ...goals.map((goal) {
                        final isSelected = selectedGoals.contains(goal.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildGoalCard(goal, isSelected),
                        );
                      }),

                      const SizedBox(height: 24),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You\'ll receive daily missions and expert guidance specific to your goals.',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom button section
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          selectedGoals.isEmpty || _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.5),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Setting up your journey...',
                                  style: AppTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Continue',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const VoiceGuideToggle(),
        ],
      ),
    ),
  );
}

  Widget _buildGoalCard(Goal goal, bool isSelected) {
    return InkWell(
      onTap: () => _toggleGoal(goal.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? goal.color : AppColors.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: goal.color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? goal.color : AppColors.outline.withValues(alpha: 0.1),
                border: Border.all(
                  color: isSelected ? goal.color : AppColors.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        goal.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        goal.title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal.description,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isSelected ? goal.color : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class Goal {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final Color color;

  Goal({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
  });
}
