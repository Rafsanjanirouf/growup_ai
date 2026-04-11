import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class WeeklyScanScreen extends StatefulWidget {
  const WeeklyScanScreen({super.key});

  @override
  State<WeeklyScanScreen> createState() => _WeeklyScanScreenState();
}

class _WeeklyScanScreenState extends State<WeeklyScanScreen> {
  final List<ScanRecord> scanRecords = [
    ScanRecord(
      date: 'Monday',
      score: 92,
      timestamp: '10:30 AM',
      improvement: 'jawline',
    ),
    ScanRecord(
      date: 'Wednesday',
      score: 94,
      timestamp: '2:15 PM',
      improvement: 'skin',
    ),
    ScanRecord(
      date: 'Friday',
      score: 96,
      timestamp: '9:45 AM',
      improvement: 'symmetry',
    ),
    ScanRecord(
      date: 'Sunday',
      score: 98,
      timestamp: '4:20 PM',
      improvement: 'overall',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Weekly Scans',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.8),
                    AppColors.primary.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '4',
                            style: AppTypography.displayMedium.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Scans Completed',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+6',
                            style: AppTypography.displayMedium.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Average Improvement',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Scan List Title
            Text(
              'Scan History',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Scan Records List
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: scanRecords.length,
              itemBuilder: (context, index) {
                final record = scanRecords[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ScanRecordCard(record: record),
                );
              },
            ),

            const SizedBox(height: 32),

            // Enhancement Tips
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Enhancement Tips',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _TipRow('Focus on jawline exercises for better definition'),
                  const SizedBox(height: 12),
                  _TipRow('Maintain consistent skincare routine'),
                  const SizedBox(height: 12),
                  _TipRow('Stay hydrated and get 7-8 hours of sleep'),
                  const SizedBox(height: 12),
                  _TipRow('Take scans under consistent lighting for accuracy'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanRecord {
  final String date;
  final int score;
  final String timestamp;
  final String improvement;

  ScanRecord({
    required this.date,
    required this.score,
    required this.timestamp,
    required this.improvement,
  });
}

class _ScanRecordCard extends StatelessWidget {
  final ScanRecord record;

  const _ScanRecordCard({required this.record});

  Color get improvementColor {
    switch (record.improvement) {
      case 'jawline':
        return AppColors.primary;
      case 'skin':
        return AppColors.secondary;
      case 'symmetry':
        return AppColors.tertiary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Date and time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.date,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.timestamp,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: improvementColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Improved: ${record.improvement}',
                  style: AppTypography.labelSmall.copyWith(
                    color: improvementColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Right side - Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: record.score / 100,
                      backgroundColor: AppColors.surfaceLowest,
                      valueColor: AlwaysStoppedAnimation(
                        improvementColor,
                      ),
                      strokeWidth: 4,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${record.score}',
                        style: AppTypography.displaySmall.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/100',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String text;

  const _TipRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle,
            color: AppColors.secondary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
