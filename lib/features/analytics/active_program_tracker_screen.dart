import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class ActiveProgramTrackerScreen extends StatefulWidget {
  final String programName;
  final int totalDays;
  final int currentDay;

  const ActiveProgramTrackerScreen({
    super.key,
    required this.programName,
    required this.totalDays,
    required this.currentDay,
  });

  @override
  State<ActiveProgramTrackerScreen> createState() => _ActiveProgramTrackerScreenState();
}

class _ActiveProgramTrackerScreenState extends State<ActiveProgramTrackerScreen> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  List<AnalysisStep> steps = [];
  Timer? animationTimer;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(duration: const Duration(seconds: 3), vsync: this);
    animationController.repeat();

    // Initialize steps
    steps = [
      AnalysisStep('Detecting Jawline Landmarks...', 'Symmetry mapping complete', true, true),
      AnalysisStep('Analyzing Skin Texture...', 'Scanning dermal layers 84%', true, false),
      AnalysisStep('Calculating Potential Score...', 'Pending geometric cross-check', false, false),
    ];

    // Simulate progress updates
    animationTimer = Timer.periodic(Duration(seconds: 2 + (steps.length * 2)), (timer) {
      if (mounted) {
        setState(() {
          if (steps[0].completed == false) {
            steps[0] = steps[0].copyWith(completed: true, inProgress: false);
            steps[1] = steps[1].copyWith(inProgress: true);
          } else if (steps[1].completed == false && steps[1].inProgress == true) {
            steps[1] = steps[1].copyWith(completed: true, inProgress: false);
            steps[2] = steps[2].copyWith(inProgress: true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Program Analysis',
        showBackButton: true,
      ),
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -200,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.05),
                    AppColors.secondary.withValues(alpha: 0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Content
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32).copyWith(bottom: 120),
            children: [
              const SizedBox(height: 32),

              // Central Visualization
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating outer rings
                      RotationTransition(
                        turns: animationController,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      RotationTransition(
                        turns: Tween<double>(begin: 1, end: 0).animate(animationController),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                        ),
                      ),

                      // Face visualization
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.kineticGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.face, color: AppColors.scrimLight, size: 60),
                        ),
                      ),

                      // Scanning line
                      Positioned(
                        top: 40,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                            CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
                          ),
                          child: Container(
                            width: 120,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: AppColors.kineticGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Title & Subtitle
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Analyzing Your',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'Features...',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Progress Bar
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: steps.where((s) => s.completed).length / steps.length,
                      minHeight: 16,
                      backgroundColor: AppColors.surfaceLowest,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Steps Status
              Container(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: List.generate(
                    steps.length,
                    (index) => _buildStepItem(steps[index], index),
                  ).expand((widget) => [widget, const SizedBox(height: 12)]).toList()
                    ..removeLast(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(AnalysisStep step, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: step.completed
                ? AppColors.secondary
                : (step.inProgress ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.2)),
            width: 3,
          ),
          top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
          right: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.completed
                  ? AppColors.secondary.withValues(alpha: 0.2)
                  : (step.inProgress ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceHighest),
            ),
            child: Center(
              child: step.completed
                  ? Icon(Icons.check_circle, color: AppColors.secondary, size: 24)
                  : (step.inProgress
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : Icon(Icons.radio_button_unchecked, color: AppColors.onSurfaceVariant, size: 24)),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisStep {
  final String title;
  final String subtitle;
  final bool completed;
  final bool inProgress;

  AnalysisStep(this.title, this.subtitle, this.completed, this.inProgress);

  AnalysisStep copyWith({
    String? title,
    String? subtitle,
    bool? completed,
    bool? inProgress,
  }) {
    return AnalysisStep(
      title ?? this.title,
      subtitle ?? this.subtitle,
      completed ?? this.completed,
      inProgress ?? this.inProgress,
    );
  }
}
