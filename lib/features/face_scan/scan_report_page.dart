import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../home/main_navigation_screen.dart';

class ScanReportPage extends ConsumerWidget {
  final int faceScore;
  
  const ScanReportPage({super.key, required this.faceScore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.scanReportBlack,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Status Bar Space
            SizedBox(height: MediaQuery.of(context).padding.top + 16),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get Detailed',
                    style: AppTypography.displayLarge.copyWith(
                      color: AppColors.scanReportWhite,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    'Face Rating',
                    style: AppTypography.displayLarge.copyWith(
                      color: AppColors.scanReportGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Main Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.scanReportDarkGray,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.scanReportGold.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Profile Image Placeholder
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.scanReportGold,
                          width: 3,
                        ),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://i.pravatar.cc/150?img=33',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Overall Score Row
                    _ScoreRow(
                      label: 'Overall',
                      score: faceScore.toString(),
                      color: AppColors.scanReportGold,
                    ),
                    const SizedBox(height: 20),
                    
                    // Potential Score Row
                    _ScoreRow(
                      label: 'Potential',
                      score: '${faceScore + 10}',
                      color: AppColors.scanReportGold,
                    ),
                    
                    const SizedBox(height: 32),
                    Divider(
                      color: AppColors.scanReportGold.withValues(alpha: 0.2),
                      height: 1,
                    ),
                    const SizedBox(height: 32),
                    
                    // Masculinity & Skin Quality
                    Row(
                      children: [
                        Expanded(
                          child: _ScoreColumn(
                            label: 'Masculinity',
                            score: '91',
                            color: AppColors.scanReportGold,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _ScoreColumn(
                            label: 'Skin Quality',
                            score: '74',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Jawline & Cheekbones
                    Row(
                      children: [
                        Expanded(
                          child: _ScoreColumn(
                            label: 'Jawline',
                            score: '98',
                            color: AppColors.scanReportGold,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _ScoreColumn(
                            label: 'Cheekbones',
                            score: '90',
                            color: AppColors.scanReportGold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // View PSL Scores Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _showPslScores(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.scanReportGold,
                        foregroundColor: AppColors.scanReportBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'View PSL Scores',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.scanReportBlack,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Back to Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const MainNavigationScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.scanReportGold,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.scanReportGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
  
  void _showPslScores(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const PslScoresModal(),
    );
  }
}

// Score Row Widget (for Overall/Potential)
class _ScoreRow extends StatelessWidget {
  final String label;
  final String score;
  final Color color;
  
  const _ScoreRow({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.scanReportLightGray,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              score,
              style: AppTypography.displayMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Score Column Widget (for metrics grid)
class _ScoreColumn extends StatelessWidget {
  final String label;
  final String score;
  final Color color;
  
  const _ScoreColumn({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.scanReportLightGray,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          score,
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.scanReportWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// PSL Scores Modal
class PslScoresModal extends StatelessWidget {
  const PslScoresModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scanReportBlack,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.scanReportGold.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.scanReportGold.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PSL Scores',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.scanReportGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Maxxing',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.scanReportWhite,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Genetic Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.scanReportDarkGray,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.scanReportGold.withValues(alpha: 0.2),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _GeneticInfoRow('Genetic Ceiling', 'High'),
                    const Divider(
                      color: Color(0xFF333333),
                      height: 16,
                    ),
                    _GeneticInfoRow('Primary Strength', 'Skin Quality'),
                    const Divider(
                      color: Color(0xFF333333),
                      height: 16,
                    ),
                    _GeneticInfoRow('Primary Bottleneck', 'Eye Area'),
                    const Divider(
                      color: Color(0xFF333333),
                      height: 16,
                    ),
                    _GeneticInfoRow('Looksmax Priority', 'Structure-Limited'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // PSL Scores Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _PslScoreCard(
                    label: 'PSL Score',
                    value: '6.0',
                    subtitle: 'Top 15%',
                    color: AppColors.secondary,
                  ),
                  _PslScoreCard(
                    label: 'Cheekbones',
                    value: '6.0',
                    subtitle: 'Top 15%',
                    color: AppColors.secondary,
                  ),
                  _PslScoreCard(
                    label: 'Eye Area',
                    value: '5.0',
                    subtitle: 'Top 25%',
                    color: Colors.orange,
                  ),
                  _PslScoreCard(
                    label: 'Skin Quality',
                    value: '7.0',
                    subtitle: 'Top 5%',
                    color: AppColors.secondary,
                  ),
                  _PslScoreCard(
                    label: 'Hair Quality',
                    value: '7.0',
                    subtitle: 'Top 5%',
                    color: AppColors.secondary,
                  ),
                  _PslScoreCard(
                    label: 'Symmetry',
                    value: '6.0',
                    subtitle: 'Top 15%',
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.scanReportGold,
                    foregroundColor: AppColors.scanReportBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.scanReportBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Genetic Info Row
class _GeneticInfoRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _GeneticInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.scanReportLightGray,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.scanReportWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// PSL Score Card
class _PslScoreCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  
  const _PslScoreCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scanReportDarkGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.scanReportLightGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: double.parse(value) / 10,
                  backgroundColor: AppColors.scanReportDarkGray,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeWidth: 6,
                ),
              ),
              Column(
                children: [
                  Text(
                    value,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.scanReportWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'High',
                      style: AppTypography.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.scanReportLightGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
