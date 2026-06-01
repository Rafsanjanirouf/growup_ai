import '../../core/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../face_scan/face_scan_screen.dart';
import '../face_scan/scan_report_page.dart';
import '../face_scan/comparison_screen.dart';
import '../../core/utils/face_analyzer_engine.dart';
import '../../core/models/face_data_model.dart';
import '../ai_tools/hair_style_ai_tool_screen.dart';
import '../ai_tools/ai_try_on_tool_screen.dart';
import '../ai_tools/face_shape_analysis_tool_screen.dart';
import '../ai_tools/best_color_analysis_tool_screen.dart';
import '../ai_tools/beard_style_ai_tool_screen.dart';
import '../ai_tools/celebrity_face_match_tool_screen.dart';
import '../ai_tools/skin_analyzer_tool_screen.dart';
import '../ai_tools/outfit_style_ai_tool_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 140, top: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          // ===== SCAN HISTORY SECTION =====
          _buildScanHistorySection(context),

          const SizedBox(height: 16),
          
          // ===== COMPARISON ENTRY SECTION =====
          _buildComparisonEntry(context),

          const SizedBox(height: 24),

          // ===== QUICK ACTIONS =====
          _buildQuickActions(context),

          const SizedBox(height: 24),

          // ===== TREE PROGRESS OVERVIEW =====
          _buildTreeProgressOverview(context),

          const SizedBox(height: 24),

          // ===== AI TOOLS HUB =====
          _buildAiToolsSection(context),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ===== SCAN HISTORY SECTION =====
  Widget _buildScanHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Scan History',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            children: [
              // 1. Next Scan Countdown Card
              _buildNextScanCard(),
              
              // 2. Scan History Cards
              ..._getMockHistory().map((scan) => _buildHistoryCard(
                context: context,
                scanId: scan['id'],
                score: scan['score'],
                date: scan['date'],
                imageUrl: scan['image'],
              )),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getMockHistory() {
    return [
      {'id': 'SC-9821', 'score': 82, 'date': 'Apr 11, 2026', 'image': 'https://i.pravatar.cc/150?img=11'},
      {'id': 'SC-9745', 'score': 79, 'date': 'Apr 08, 2026', 'image': 'https://i.pravatar.cc/150?img=12'},
      {'id': 'SC-9612', 'score': 75, 'date': 'Apr 02, 2026', 'image': 'https://i.pravatar.cc/150?img=13'},
    ];
  }

  Widget _buildNextScanCard() {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: AppColors.secondary.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.secondary, size: 28),
          const SizedBox(height: 12),
          Text(
            'Next Scan'.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.secondary.withValues(alpha: 0.6),
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '2d 10h',
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '45m 12s',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.secondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required BuildContext context,
    required String scanId,
    required int score,
    required String date,
    required String imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        // Create a dummy FaceDataModel to satisfy the analyzer if needed, 
        // but it's better to manually create a result for history to ensure consistent scores
        final dummyData = FaceDataModel(
          boundingBox: Rect.zero,
          headEulerAngleX: 0,
          headEulerAngleY: 0,
          headEulerAngleZ: 0,
          landmarks: {},
          contours: {},
          imageSize: Size.zero,
          timestamp: DateTime.now(),
        );

        final mockResult = FaceAnalyzerEngine.analyze(dummyData);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanReportPage(
              result: mockResult,
              imagePath: imageUrl, // Use the history image URL
              isHistory: true,
            ),
          ),
        );
      },
      child: Container(
        width: 154,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: score >= 80 ? AppColors.secondary.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (score >= 80 ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          children: [
            // Image Frame with ID Badge
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const Center(child: Icon(Icons.face_unlock_rounded, color: Colors.white24)),
                    ),
                  ),
                  // ID Badge
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        '#${scanId.split('-').last}',
                        style: const TextStyle(color: Colors.white54, fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Data Rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date.toUpperCase(),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RATING',
                      style: TextStyle(color: (score >= 80 ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.5), fontSize: 7, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (score >= 80 ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$score',
                    style: TextStyle(
                      color: score >= 80 ? AppColors.secondary : AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== QUICK ACTIONS =====
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              title: 'Next Scan',
              subtitle: '6 Days',
              icon: Icons.timer_outlined,
              color: AppColors.success,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionCard(
              title: 'New Analysis',
              subtitle: 'Start Scan',
              icon: Icons.add_a_photo_outlined,
              color: Colors.white,
              isGradient: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FaceScanScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isGradient = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isGradient ? null : AppColors.surfaceLow,
          gradient: isGradient ? AppColors.kineticGradient : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isGradient ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isGradient ? Colors.black : color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: isGradient ? Colors.black87 : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.labelLarge.copyWith(
                    color: isGradient ? Colors.black : color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== TREE OVERVIEW =====
  Widget _buildTreeProgressOverview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          ref.read(navigationProvider.notifier).setTab(1);
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.success.withValues(alpha: 0.1), AppColors.success.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 10)
                  ],
                ),
                child: const Icon(Icons.park_rounded, color: Colors.black, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete today Task and Grow Tree',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to visit your daily mission center',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.success, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiToolsSection(BuildContext context) {
    final tools = [
      {'name': 'Hairstyle AI', 'icon': Icons.content_cut_rounded, 'results': 12, 'credits': 45, 'screen': const HairStyleAIToolScreen()},
      {'name': 'AI Try On', 'icon': Icons.checkroom_rounded, 'results': 8, 'credits': 20, 'screen': const AiTryOnToolScreen()},
      {'name': 'Face Shape', 'icon': Icons.face_rounded, 'results': 5, 'credits': 15, 'screen': const FaceShapeAnalysisToolScreen()},
      {'name': 'Dress Color', 'icon': Icons.palette_rounded, 'results': 14, 'credits': 30, 'screen': const BestColorAnalysisToolScreen()},
      {'name': 'Beard Style', 'icon': Icons.face_retouching_natural_rounded, 'results': 7, 'credits': 25, 'screen': const BeardStyleAIToolScreen()},
      {'name': 'Celeb Match', 'icon': Icons.stars_rounded, 'results': 3, 'credits': 35, 'screen': const CelebrityFaceMatchToolScreen()},
      {'name': 'Skin AI', 'icon': Icons.biotech_rounded, 'results': 21, 'credits': 40, 'screen': const SkinAnalyzerToolScreen()},
      {'name': 'Outfit AI', 'icon': Icons.checkroom_rounded, 'results': 9, 'credits': 15, 'screen': const OutfitStyleAIToolScreen()},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Tools Hub',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Explore All →',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              return _buildToolCard(
                name: tools[index]['name'] as String,
                icon: tools[index]['icon'] as IconData,
                resultsGenerated: tools[index]['results'] as int,
                creditsLeft: tools[index]['credits'] as int,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => tools[index]['screen'] as Widget),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required String name,
    required IconData icon,
    required int resultsGenerated,
    required int creditsLeft,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.warning, size: 24),
          ),
          const Spacer(),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 10, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                '$resultsGenerated REALS',
                style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.token_rounded, size: 10, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(
                '$creditsLeft CREDITS',
                style: const TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildComparisonEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          // Mock navigation with last two results from our history
          final dummyData = FaceDataModel(
            boundingBox: Rect.zero,
            headEulerAngleX: 0,
            headEulerAngleY: 0,
            headEulerAngleZ: 0,
            landmarks: {},
            contours: {},
            imageSize: Size.zero,
            timestamp: DateTime.now(),
          );

          final resultA = FaceAnalyzerEngine.analyze(dummyData);
          final resultB = FaceAnalyzerEngine.analyze(dummyData);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComparisonScreen(
                scanA: resultA,
                scanB: resultB,
                imageA: 'https://i.pravatar.cc/150?img=13',
                imageB: 'https://i.pravatar.cc/150?img=11',
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.8),
                AppColors.secondary.withValues(alpha: 0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SEE COMPARISON DETAILS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check your progress vs last scan',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
