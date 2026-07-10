import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/habit_provider.dart';

class TaskManagementScreen extends ConsumerWidget {
  const TaskManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterTasks = ref.watch(masterHabitProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'TASK MANAGER',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: masterTasks.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: masterTasks.length,
                itemBuilder: (context, index) {
                  final task = masterTasks[index];
                  return _buildTaskCard(context, ref, task);
                },
              ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: AppTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showEditTaskDialog(context, ref, null),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('New Task', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'NO CUSTOM TASKS',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add recurring daily, weekly, or\nmonthly tasks here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, Habit task) {
    IconData getIcon() {
      switch (task.timeOfDay) {
        case 'morning': return Icons.wb_sunny;
        case 'noon': return Icons.wb_twilight;
        case 'evening': return Icons.wb_iridescent;
        case 'night': return Icons.nights_stay;
        default: return Icons.task;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(getIcon(), color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildChip(task.timeOfDay.toUpperCase(), AppTheme.secondary),
                    const SizedBox(width: 6),
                    _buildChip(task.frequency.toUpperCase(), AppTheme.warning),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
            onPressed: () => _showEditTaskDialog(context, ref, task),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
            onPressed: () {
              ref.read(masterHabitProvider.notifier).deleteTask(task.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, WidgetRef ref, Habit? existingTask) {
    final titleCtrl = TextEditingController(text: existingTask?.title ?? '');
    String timeOfDay = existingTask?.timeOfDay ?? 'morning';
    String frequency = existingTask?.frequency ?? 'daily';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existingTask == null ? 'New Custom Task' : 'Edit Task',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: GoogleFonts.outfit(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black38,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Time of Day', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ['morning', 'noon', 'evening', 'night'].map((t) {
                    final isSelected = timeOfDay == t;
                    return ChoiceChip(
                      label: Text(t.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white70)),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: Colors.white.withAlpha(15),
                      side: BorderSide(color: isSelected ? AppTheme.primary : Colors.white10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val) setModalState(() => timeOfDay = t);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Frequency', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: ['daily', 'weekly', 'monthly'].map((f) {
                    final isSelected = frequency == f;
                    return ChoiceChip(
                      label: Text(f.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white70)),
                      selected: isSelected,
                      selectedColor: AppTheme.secondary,
                      backgroundColor: Colors.white.withAlpha(15),
                      side: BorderSide(color: isSelected ? AppTheme.secondary : Colors.white10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val) setModalState(() => frequency = f);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.isEmpty) return;
                      final task = Habit(
                        id: existingTask?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleCtrl.text,
                        timeOfDay: timeOfDay,
                        frequency: frequency,
                        icon: 'star',
                        description: 'Custom task',
                        targetCount: 1,
                      );
                      if (existingTask == null) {
                        ref.read(masterHabitProvider.notifier).addTask(task);
                      } else {
                        ref.read(masterHabitProvider.notifier).updateTask(task);
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppTheme.primary.withAlpha(100),
                    ),
                    child: Text('SAVE TASK', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.0)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
