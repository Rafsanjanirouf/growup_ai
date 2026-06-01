import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/programs_provider.dart';
import '../assistant/assistant_screen.dart';

class ProgramTaskScreen extends ConsumerStatefulWidget {
  final Program program;
  const ProgramTaskScreen({super.key, required this.program});

  @override
  ConsumerState<ProgramTaskScreen> createState() => _ProgramTaskScreenState();
}

class _ProgramTaskScreenState extends ConsumerState<ProgramTaskScreen> {
  @override
  Widget build(BuildContext context) {
    final programsState = ref.watch(programsProvider);
    final p = programsState.programs.firstWhere((prog) => prog.id == widget.program.id);
    final missions = p.dailyMissions;
    final completedCount = p.tasksCompletedToday;

    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ===== CINEMATIC HEADER =====
              SliverAppBar(
                expandedHeight: 220,
                backgroundColor: AppColors.surfaceLowest,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAY ${p.currentDay}'.toUpperCase(),
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.title,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                        const SizedBox(height: 16),
                        _buildProgressHud(completedCount, missions.length),
                      ],
                    ),
                  ),
                ),
              ),

              // ===== MISSION LIST =====
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _MissionCard(mission: missions[index], programId: p.id);
                    },
                    childCount: missions.length,
                  ),
                ),
              ),
            ],
          ),

          // ===== FLOATING AI SUPPORT =====
          Positioned(
            bottom: 30, right: 20,
            child: _buildAiFab(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHud(int completed, int total) {
    double progress = total > 0 ? completed / total : 0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Daily Goal'.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900)),
                   Text('$completed/$total DONE', style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  color: AppColors.primary,
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiFab() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistantScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.kineticGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20)],
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.black, size: 18),
            SizedBox(width: 8),
            Text('AI SUPPORT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends ConsumerStatefulWidget {
  final ProgramMission mission;
  final String programId;
  const _MissionCard({required this.mission, required this.programId});

  @override
  ConsumerState<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends ConsumerState<_MissionCard> {
  bool isExpanded = false;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.mission.durationSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (isTimerRunning) return;
    setState(() => isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _complete();
      }
    });
  }

  void _complete() {
    ref.read(programsProvider.notifier).completeMission(widget.programId, widget.mission.id);
    setState(() => isTimerRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    Color timeColor = _getTimeColor(m.time);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: m.isCompleted ? Colors.white.withValues(alpha: 0.02) : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: m.isCompleted ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
            onTap: () => setState(() => isExpanded = !isExpanded),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: timeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(_getMissionIcon(m.type), color: timeColor, size: 20),
            ),
            title: Text(
              m.title,
              style: TextStyle(
                color: m.isCompleted ? Colors.white24 : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                decoration: m.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              m.time.name.toUpperCase(),
              style: TextStyle(color: timeColor.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w900),
            ),
            trailing: m.isCompleted 
              ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
              : IconButton(
                  icon: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white24),
                  onPressed: () => setState(() => isExpanded = !isExpanded),
                ),
          ),
          
          if (isExpanded && !m.isCompleted)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  Text(m.description, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 20),
                  _buildActionArea(m),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionArea(ProgramMission m) {
    if (m.type == MissionType.timer) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isTimerRunning ? Colors.red.withValues(alpha: 0.1) : AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: isTimerRunning ? () {
                _timer?.cancel();
                setState(() => isTimerRunning = false);
              } : _startTimer,
              child: Text(
                isTimerRunning ? 'STOP TIMER' : 'START TIMER',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            _formatDuration(_remainingSeconds),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ],
      );
    }
    
    if (m.type == MissionType.aiGuided) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistantScreen()));
          },
          icon: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
          label: const Text('GET AI GUIDANCE', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _complete,
        child: const Text('MARK AS FINISHED', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  String _formatDuration(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Color _getTimeColor(ProgramTimeOfDay t) {
    switch (t) {
      case ProgramTimeOfDay.morning: return Colors.blueAccent;
      case ProgramTimeOfDay.noon: return Colors.orangeAccent;
      case ProgramTimeOfDay.night: return Colors.indigoAccent;
    }
  }

  IconData _getMissionIcon(MissionType t) {
    switch (t) {
      case MissionType.timer: return Icons.timer_outlined;
      case MissionType.standard: return Icons.task_alt_rounded;
      case MissionType.aiGuided: return Icons.auto_awesome;
    }
  }
}
