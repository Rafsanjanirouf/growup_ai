import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header_fixed.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  // Sample scan history data
  final List<ScanRecord> scanHistory = [
    ScanRecord(
      date: 'Today, 10:45 AM',
      overallScore: 87,
      skinAnalysis: 92,
      jawScore: 84,
      overallRating: 'Excellent',
      imageUrl: 'https://i.pravatar.cc/150?img=33',
    ),
    ScanRecord(
      date: 'Yesterday, 2:30 PM',
      overallScore: 85,
      skinAnalysis: 89,
      jawScore: 82,
      overallRating: 'Very Good',
      imageUrl: 'https://i.pravatar.cc/150?img=34',
    ),
    ScanRecord(
      date: 'Mar 28, 5:15 PM',
      overallScore: 82,
      skinAnalysis: 86,
      jawScore: 79,
      overallRating: 'Very Good',
      imageUrl: 'https://i.pravatar.cc/150?img=35',
    ),
    ScanRecord(
      date: 'Mar 27, 11:20 AM',
      overallScore: 80,
      skinAnalysis: 83,
      jawScore: 77,
      overallRating: 'Good',
      imageUrl: 'https://i.pravatar.cc/150?img=36',
    ),
    ScanRecord(
      date: 'Mar 26, 3:45 PM',
      overallScore: 78,
      skinAnalysis: 81,
      jawScore: 75,
      overallRating: 'Good',
      imageUrl: 'https://i.pravatar.cc/150?img=37',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppHeader(
        title: 'Scan History',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Header Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.kineticGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox('Total Scans', '${scanHistory.length}'),
                _buildStatBox('Avg Score', '84'),
                _buildStatBox('Progress', '+9'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Section Title
          Text(
            'All Scans',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Scan History List
          ...scanHistory.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildScanCard(entry.value),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildScanCard(ScanRecord scan) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing scan from ${scan.date}')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Scan Image Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.surface,
                  child: Image.network(
                    scan.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.lightAccent,
                      child: const Icon(Icons.person, color: AppColors.primary, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Scan Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Text(
                      scan.date,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Overall Score
                    Row(
                      children: [
                        Text(
                          'Score: ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '${scan.overallScore}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getRatingColor(scan.overallRating).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getRatingColor(scan.overallRating).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            scan.overallRating,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _getRatingColor(scan.overallRating),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Mini Stats Row
                    Row(
                      children: [
                        _buildMiniStat('Skin', '${scan.skinAnalysis}%'),
                        const SizedBox(width: 12),
                        _buildMiniStat('Jaw', '${scan.jawScore}%'),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.arrow_forward_ios, color: AppColors.onSurfaceVariant, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return AppColors.success;
      case 'very good':
        return AppColors.primary;
      case 'good':
        return AppColors.warning;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
}

class ScanRecord {
  final String date;
  final int overallScore;
  final int skinAnalysis;
  final int jawScore;
  final String overallRating;
  final String imageUrl;

  ScanRecord({
    required this.date,
    required this.overallScore,
    required this.skinAnalysis,
    required this.jawScore,
    required this.overallRating,
    required this.imageUrl,
  });
}
