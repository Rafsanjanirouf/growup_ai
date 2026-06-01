import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_stats_provider.dart';

enum ProgramDifficulty { essential, intermediate, advanced }
enum MissionType { standard, timer, aiGuided }
enum ProgramTimeOfDay { morning, noon, night }

class ProgramMission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final ProgramTimeOfDay time;
  final int durationSeconds;
  final bool isCompleted;

  ProgramMission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.time,
    this.durationSeconds = 0,
    this.isCompleted = false,
  });

  ProgramMission copyWith({bool? isCompleted}) {
    return ProgramMission(
      id: id,
      title: title,
      description: description,
      type: type,
      time: time,
      durationSeconds: durationSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Program {
  final String id;
  final String title;
  final String description;
  final String duration;
  final ProgramDifficulty difficulty;
  final int coinCost;
  final int enrolledCount;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isPremium;
  final String? thumbnailUrl;
  final int totalDays;
  final int currentDay;
  final List<ProgramMission> dailyMissions;

  Program({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.coinCost,
    required this.enrolledCount,
    this.isUnlocked = false,
    this.isCurrent = false,
    this.isPremium = false,
    this.thumbnailUrl,
    this.totalDays = 30,
    this.currentDay = 1,
    required this.dailyMissions,
  });

  int get tasksCompletedToday => dailyMissions.where((m) => m.isCompleted).length;
  int get totalTasksToday => dailyMissions.length;

  Program copyWith({
    bool? isUnlocked, 
    bool? isCurrent, 
    int? currentDay,
    List<ProgramMission>? dailyMissions,
  }) {
    return Program(
      id: id,
      title: title,
      description: description,
      duration: duration,
      difficulty: difficulty,
      coinCost: coinCost,
      enrolledCount: enrolledCount,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCurrent: isCurrent ?? this.isCurrent,
      isPremium: isPremium,
      thumbnailUrl: thumbnailUrl,
      totalDays: totalDays,
      currentDay: currentDay ?? this.currentDay,
      dailyMissions: dailyMissions ?? this.dailyMissions,
    );
  }
}

class ProgramsState {
  final List<Program> programs;
  final bool isLoading;

  ProgramsState({required this.programs, this.isLoading = false});

  Program? get currentProgram => programs.firstWhere((p) => p.isCurrent, orElse: () => programs.first);
}

class ProgramsNotifier extends StateNotifier<ProgramsState> {
  final Ref ref;

  ProgramsNotifier(this.ref) : super(ProgramsState(programs: [], isLoading: true)) {
    _init();
  }

  void _init() {
    final eliteMissions = [
      ProgramMission(id: 'm1', title: 'Hard Mewing Start', description: 'Applying maximum tongue pressure to the palate for 5 minutes.', type: MissionType.timer, durationSeconds: 300, time: ProgramTimeOfDay.morning),
      ProgramMission(id: 'm2', title: 'Face Yoga: Eye Lift', description: 'Resistance stretching around the ocular muscles to reduce sagging.', type: MissionType.standard, time: ProgramTimeOfDay.noon),
      ProgramMission(id: 'm3', title: 'AI Posture Check', description: 'Use the camera for a real-time head alignment check.', type: MissionType.aiGuided, time: ProgramTimeOfDay.night),
      ProgramMission(id: 'm4', title: 'Mouth Taping Setup', description: 'Applying breathing tape for forced nasal respiration during sleep.', type: MissionType.standard, time: ProgramTimeOfDay.night),
    ];

    final initialPrograms = [
      Program(
        id: 'p1',
        title: 'Elite Jawline Sculpting',
        description: 'Advanced mewing and resistance training to chisele your facial profile and enhance symmetry.',
        duration: '21 Days',
        difficulty: ProgramDifficulty.intermediate,
        coinCost: 500,
        enrolledCount: 15450,
        isUnlocked: true,
        isCurrent: true,
        isPremium: true,
        totalDays: 21,
        thumbnailUrl: 'https://images.unsplash.com/photo-1618077360395-f3068be8e001?q=80&w=800&auto=format&fit=crop',
        dailyMissions: eliteMissions,
      ),
      Program(
        id: 'p2',
        title: 'Natural Face Glow',
        description: 'Master specialized facial massage and lymphatic drainage for a healthy, radiant complexion.',
        duration: '30 Days',
        difficulty: ProgramDifficulty.essential,
        coinCost: 750,
        enrolledCount: 12920,
        isUnlocked: false,
        isPremium: false,
        totalDays: 30,
        thumbnailUrl: 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=800&auto=format&fit=crop',
        dailyMissions: eliteMissions.take(3).toList(),
      ),
      Program(
        id: 'p3',
        title: 'Posture & Alignment',
        description: 'Correction for tech-neck and rounded shoulders to naturally improve your head posture.',
        duration: '14 Days',
        difficulty: ProgramDifficulty.essential,
        coinCost: 300,
        enrolledCount: 22200,
        isUnlocked: true,
        isPremium: false,
        totalDays: 14,
        thumbnailUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=800&auto=format&fit=crop',
        dailyMissions: eliteMissions.skip(1).take(2).toList(),
      ),
      Program(
        id: 'p4',
        title: 'Bad Habits Reset',
        description: 'Identify and quit mouth breathing and improper swallowing habits that affect long-term growth.',
        duration: '30 Days',
        difficulty: ProgramDifficulty.advanced,
        coinCost: 1000,
        enrolledCount: 8600,
        isUnlocked: false,
        isPremium: true,
        totalDays: 30,
        thumbnailUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=800&auto=format&fit=crop',
        dailyMissions: eliteMissions,
      ),
    ];

    state = ProgramsState(programs: initialPrograms, isLoading: false);
  }

  Future<bool> unlockProgram(String programId) async {
    final program = state.programs.firstWhere((p) => p.id == programId);
    if (program.isUnlocked) return true;

    final success = await ref.read(userStatsProvider.notifier).deductCoins(program.coinCost);
    if (success) {
      state = ProgramsState(
        programs: state.programs.map((p) {
          if (p.id == programId) return p.copyWith(isUnlocked: true);
          return p;
        }).toList(),
      );
      return true;
    }
    return false;
  }

  void completeMission(String programId, String missionId) {
    state = ProgramsState(
      programs: state.programs.map((p) {
        if (p.id == programId) {
          final updatedMissions = p.dailyMissions.map((m) {
            if (m.id == missionId) return m.copyWith(isCompleted: true);
            return m;
          }).toList();
          return p.copyWith(dailyMissions: updatedMissions);
        }
        return p;
      }).toList(),
    );
  }

  void setAsCurrent(String programId) {
    state = ProgramsState(
      programs: state.programs.map((p) {
        if (p.id == programId) return p.copyWith(isCurrent: true, currentDay: 1);
        return p.copyWith(isCurrent: false);
      }).toList(),
    );
  }
}

final programsProvider = StateNotifierProvider<ProgramsNotifier, ProgramsState>((ref) {
  return ProgramsNotifier(ref);
});
