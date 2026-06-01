import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/programs_provider.dart';
import 'program_detail_screen.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsState = ref.watch(programsProvider);

    if (programsState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentProgram = programsState.currentProgram;
    final otherPrograms = programsState.programs.where((p) => p.id != currentProgram?.id).toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ===== TOP SPACING (SAFE AREA REPLACEMENT) =====
          const SliverToBoxAdapter(child: SizedBox(height: 60)),

          // ===== CURRENT PROGRAM HERO =====
          if (currentProgram != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: _buildCurrentProgramHero(context, currentProgram, ref),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                'Ready to start?'.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _ProgramListItem(program: otherPrograms[index]),
                );
              },
              childCount: otherPrograms.length,
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildCurrentProgramHero(BuildContext context, Program program, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramDetailScreen(program: program))),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          image: program.thumbnailUrl != null 
            ? DecorationImage(
                image: NetworkImage(program.thumbnailUrl!), 
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
              )
            : null,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 10)),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [Colors.black.withValues(alpha: 0.54), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                child: const Text('CURRENTLY ACTIVE', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
              const SizedBox(height: 12),
              Text(
                program.title,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
              ),
              const SizedBox(height: 12),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: program.currentDay / program.totalDays,
                  backgroundColor: Colors.white10,
                  color: AppColors.primary,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on, color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text('DAY ${program.currentDay} OF ${program.totalDays}', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 10)),
                    ],
                  ),
                  Text(
                    '${program.tasksCompletedToday}/${program.totalTasksToday} TASKS DONE',
                    style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramListItem extends ConsumerWidget {
  final Program program;
  const _ProgramListItem({required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramDetailScreen(program: program))),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Cinematic Thumbnail
            Container(
              width: 110,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
                image: program.thumbnailUrl != null
                  ? DecorationImage(image: NetworkImage(program.thumbnailUrl!), fit: BoxFit.cover)
                  : null,
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: program.thumbnailUrl == null ? const Icon(Icons.image, color: Colors.white10) : null,
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            program.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      program.description,
                      style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '${program.enrolledCount ~/ 1000}K+ ENROLLED',
                          style: const TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        _buildAccessBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessBadge() {
    if (program.isUnlocked) {
      return _badge('UNLOCKED', Colors.green);
    }
    
    if (program.isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.diamond_rounded, color: Colors.black, size: 10),
            SizedBox(width: 4),
            Text('PREMIUM', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    // Default badge for all other programs - no coin mention
    return _badge('ENROLL', AppColors.primary.withValues(alpha: 0.5));
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }
}
