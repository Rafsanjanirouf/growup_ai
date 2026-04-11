import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/bottom_action_button.dart';
import '../monetization/premium_paywall_screen.dart';

class ProgramDetailScreen extends StatelessWidget {
  const ProgramDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 120),
            physics: const BouncingScrollPhysics(),
            children: [
              // Hero Image
              SizedBox(
                height: 350,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network('https://images.unsplash.com/photo-1618077360395-f3068be8e001?q=80&w=800&auto=format&fit=crop', fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.surface.withValues(alpha: 0.8), AppColors.surface.withValues(alpha: 0), AppColors.surface],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24, left: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('AESTHETIC EVOLUTION', style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          SizedBox(height: 4),
                          Text('21-Day Elite\nTransformation', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1)),
                        ],
                      ),
                    ),
                     Positioned(
                      top: 48, left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      top: 48, right: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.surfaceHigh.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: const [
                            Icon(Icons.stars, color: AppColors.tertiary, size: 16),
                            SizedBox(width: 4),
                            Text('PREMIUM', style: TextStyle(color: AppColors.surfaceLowest, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Bento
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('GROWTH ROADMAP', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: const LinearProgressIndicator(value: 0.33, backgroundColor: AppColors.surfaceLowest, color: AppColors.secondary, minHeight: 6),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStat('07', 'DAYS DONE'),
                                    _buildStat('21', 'TOTAL'),
                                    _buildStat('33%', 'PROGRESS', color: AppColors.primary),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(color: AppColors.surfaceHighest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1))),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  const Text('TODAY', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  const Icon(Icons.architecture, color: AppColors.secondary),
                                  const SizedBox(height: 8),
                                  const Text('Mewing\nBasics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
                               ],
                             ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    const Text('Curriculum', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    _buildCurriculumItem('01', 'Face Yoga Fundamentals', 'Waking up the dormant muscles.', isCompleted: true),
                    _buildCurriculumItem('02', 'Mewing: The Tongue Anchor', 'Mastering the correct resting position.', isActive: true),
                    _buildCurriculumItem('03', 'Resistance Stretching', 'Applying dynamic tension.', isLocked: true),
                    _buildCurriculumItem('04', 'Gua Sha Sculpting', 'Lymphatic drainage techniques.', isLocked: true),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              )
            ],
          ),
          
          // Bottom Action Button
          BottomActionButton(
            label: 'Unlock Full Program',
            icon: Icons.lock_open,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPaywallScreen()));
            },
            bottomOffset: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String val, String label, {Color color = AppColors.onSurface}) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 8, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
      ],
    );
  }
  
  Widget _buildCurriculumItem(String num, String title, String subtitle, {bool isCompleted = false, bool isActive = false, bool isLocked = false}) {
    Color outlineColor = AppColors.outlineVariant.withValues(alpha: 0.3);
    if(isActive) outlineColor = AppColors.secondary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked ? AppColors.surfaceLow.withValues(alpha: 0.5) : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: outlineColor, width: isActive ? 4 : 2)),
      ),
      child: Row(
        children: [
          Text(num, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isActive ? AppColors.secondary : AppColors.outlineVariant.withValues(alpha: 0.3))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLocked ? AppColors.onSurfaceVariant : AppColors.onSurface)),
                 Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
               ],
            ),
          ),
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppColors.secondary)
          else if (isActive)
             const Icon(Icons.play_circle, color: AppColors.onSurface)
          else if (isLocked)
             const Icon(Icons.lock, color: AppColors.outlineVariant)
        ],
      ),
    );
  }
}
