import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_tile.dart';
import '../widgets/upgrade_prompt.dart';
import 'exercise_picker_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  static const route = '/active-workout';

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    final provider = context.read<WorkoutProvider>();
    if (!provider.hasActiveWorkout) provider.startWorkout();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final started = context.read<WorkoutProvider>().startedAt;
      if (started != null && mounted) {
        setState(() => _elapsed = DateTime.now().difference(started));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final exercise = await Navigator.pushNamed(context, ExercisePickerScreen.route);
    if (exercise is Exercise && mounted) {
      context.read<WorkoutProvider>().addExercise(exercise);
    }
  }

  Future<void> _finish() async {
    final auth = context.read<AuthProvider>();
    final user = auth.firebaseUser;
    if (user == null && auth.firebaseEnabled) return;
    final ok = await context.read<WorkoutProvider>().finishWorkout(
          user?.uid ?? 'demo',
          isPro: context.read<SubscriptionProvider>().isPro,
        );
    if (!mounted) return;
    if (!ok) {
      await UpgradePrompt.show(context);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDuration(_elapsed)),
        actions: [
          TextButton(onPressed: _finish, child: const Text('Finish')),
          IconButton(onPressed: () => _showMore(context), icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Row(
            children: [
              Expanded(child: StatTile(label: 'Volume', value: workout.totalVolume.toStringAsFixed(0), icon: Icons.monitor_weight)),
              const SizedBox(width: 10),
              Expanded(child: StatTile(label: 'Sets', value: workout.totalSets.toString(), icon: Icons.repeat)),
              const SizedBox(width: 10),
              Expanded(child: StatTile(label: 'PRs', value: workout.prCount.toString(), icon: Icons.emoji_events)),
            ],
          ),
          const SizedBox(height: 18),
          ...workout.activeExercises.map((item) => _ExerciseEditor(item: item)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showMore(context),
                icon: const Icon(Icons.tune),
                label: const Text('More'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _finish,
                icon: const Icon(Icons.check),
                label: const Text('Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.timer, color: AppTheme.accent),
                title: const Text('Set rest timer'),
                subtitle: const Text('90 seconds'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rest timer set for 90 seconds')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_add, color: AppTheme.accent),
                title: const Text('Add note'),
                onTap: () async {
                  Navigator.pop(context);
                  final note = await _askNote(context);
                  if (note != null && note.trim().isNotEmpty && mounted) {
                    context.read<WorkoutProvider>().addNoteToFirstExercise(note);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: AppTheme.accent),
                title: const Text('Replace exercise'),
                onTap: () async {
                  Navigator.pop(context);
                  final active = context.read<WorkoutProvider>().activeExercises;
                  if (active.isEmpty) return;
                  final replacement = await Navigator.pushNamed(context, ExercisePickerScreen.route);
                  if (replacement is Exercise && mounted) {
                    context.read<WorkoutProvider>().replaceExercise(active.first.exercise.id, replacement);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Discard workout'),
                onTap: () {
                  context.read<WorkoutProvider>().discardWorkout();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _askNote(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout note'),
        content: TextField(controller: controller, minLines: 3, maxLines: 5, decoration: const InputDecoration(hintText: 'How did this set feel?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
  }
}

class _ExerciseEditor extends StatelessWidget {
  const _ExerciseEditor({required this.item});

  final WorkoutExercise item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.exercise.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                Text(item.exercise.muscleGroup, style: const TextStyle(color: AppTheme.textMuted)),
              ],
            ),
            if (item.note != null) ...[
              const SizedBox(height: 8),
              Text(item.note!, style: const TextStyle(color: AppTheme.textMuted)),
            ],
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(width: 42, child: Text('Set', style: TextStyle(color: AppTheme.textMuted))),
                Expanded(child: Text('Kg', style: TextStyle(color: AppTheme.textMuted))),
                SizedBox(width: 12),
                Expanded(child: Text('Reps', style: TextStyle(color: AppTheme.textMuted))),
                SizedBox(width: 32),
              ],
            ),
            const SizedBox(height: 6),
            ...List.generate(item.sets.length, (index) => _SetRow(item: item, index: index)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.read<WorkoutProvider>().addSet(item.exercise.id),
              icon: const Icon(Icons.add),
              label: const Text('Add set'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.item, required this.index});

  final WorkoutExercise item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final set = item.sets[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 42, child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800))),
          Expanded(
            child: TextFormField(
              initialValue: set.weight == 0 ? '' : set.weight.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0'),
              onChanged: (value) => context.read<WorkoutProvider>().updateSet(item.exercise.id, index, weight: double.tryParse(value) ?? 0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: set.reps.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0'),
              onChanged: (value) => context.read<WorkoutProvider>().updateSet(item.exercise.id, index, reps: int.tryParse(value) ?? 0),
            ),
          ),
          SizedBox(width: 32, child: set.isPr ? const Icon(Icons.emoji_events, color: AppTheme.accent) : const SizedBox.shrink()),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${duration.inHours}:$minutes:$seconds';
}
