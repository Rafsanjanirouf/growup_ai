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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditTaskDialog(context, ref, null),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Task', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
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
              color: Color(0xFF1E1E24),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existingTask == null ? 'New Task' : 'Edit Task',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withAlpha(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Time of Day', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['morning', 'noon', 'evening', 'night'].map((t) {
                    final isSelected = timeOfDay == t;
                    return ChoiceChip(
                      label: Text(t.toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white54)),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: Colors.white10,
                      onSelected: (val) {
                        if (val) setModalState(() => timeOfDay = t);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Frequency', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['daily', 'weekly', 'monthly'].map((f) {
                    final isSelected = frequency == f;
                    return ChoiceChip(
                      label: Text(f.toUpperCase(), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.white54)),
                      selected: isSelected,
                      selectedColor: AppTheme.secondary,
                      backgroundColor: Colors.white10,
                      onSelected: (val) {
                        if (val) setModalState(() => frequency = f);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save Task', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
