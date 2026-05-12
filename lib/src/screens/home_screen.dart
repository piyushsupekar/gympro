import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_tile.dart';
import '../widgets/upgrade_prompt.dart';
import 'active_workout_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const route = '/home';

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final today = DateTime.now();
    final todaysWorkouts = workout.workouts.where((item) =>
        item.date.year == today.year && item.date.month == today.month && item.date.day == today.day);
    final todayVolume = todaysWorkouts.fold<double>(0, (sum, item) => sum + item.totalVolume);
    final todaySets = todaysWorkouts.fold<int>(0, (sum, item) => sum + item.totalSets);
    final streak = _streakDays(workout.workouts);

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.fitness_center, color: AppTheme.accent),
                title: Text('GymPro', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                selected: true,
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () => Navigator.pushNamed(context, ProfileScreen.route),
              ),
              ListTile(
                leading: const Icon(Icons.show_chart),
                title: const Text('Progress'),
                onTap: () => Navigator.pushNamed(context, ProgressScreen.route),
              ),
              const Spacer(),
              if (!subscription.isPro)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                    onPressed: () => UpgradePrompt.show(context),
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Upgrade Pro'),
                  ),
                ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('GymPro'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Chip(
              avatar: const Icon(Icons.local_fire_department, color: AppTheme.accent, size: 18),
              label: Text('$streak'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        onPressed: () {
          if (!subscription.isPro && workout.workouts.length >= WorkoutProvider.freeWorkoutLimit) {
            UpgradePrompt.show(context);
            return;
          }
          workout.startWorkout();
          Navigator.pushNamed(context, ActiveWorkoutScreen.route);
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start workout'),
      ),
      body: workout.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final user = context.read<AuthProvider>().firebaseUser;
                if (user != null) workout.bind(user.uid);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  if (!subscription.isPro && workout.workouts.length >= WorkoutProvider.freeWorkoutLimit)
                    _LimitBanner(onUpgrade: () => UpgradePrompt.show(context)),
                  Row(
                    children: [
                      Expanded(child: StatTile(label: 'Workouts', value: todaysWorkouts.length.toString(), icon: Icons.event_available)),
                      const SizedBox(width: 10),
                      Expanded(child: StatTile(label: 'Volume', value: todayVolume.toStringAsFixed(0), icon: Icons.monitor_weight)),
                      const SizedBox(width: 10),
                      Expanded(child: StatTile(label: 'Sets', value: todaySets.toString(), icon: Icons.repeat)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Weekly summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  SizedBox(height: 210, child: _WeeklyChart(workouts: workout.workouts)),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text('Recent exercises', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const Spacer(),
                      TextButton(onPressed: () => Navigator.pushNamed(context, ProgressScreen.route), child: const Text('Progress')),
                    ],
                  ),
                  if (workout.workouts.isEmpty)
                    const EmptyState(
                      icon: Icons.add_chart,
                      title: 'No workouts yet',
                      message: 'Start your first session to see exercise history and weekly stats here.',
                    )
                  else
                    ...workout.workouts.take(6).expand((item) => item.exercises.take(2)).map((item) => _ExerciseCard(item: item)),
                ],
              ),
            ),
    );
  }
}

class _LimitBanner extends StatelessWidget {
  const _LimitBanner({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.lock, color: AppTheme.accent),
          const SizedBox(width: 10),
          const Expanded(child: Text('Free tier limit reached: 3 stored workouts.')),
          TextButton(onPressed: onUpgrade, child: const Text('Upgrade')),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.workouts});

  final List<Workout> workouts;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bars = List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
      final volume = workouts
          .where((item) => item.date.year == day.year && item.date.month == day.month && item.date.day == day.day)
          .fold<double>(0, (sum, item) => sum + item.totalVolume);
      return BarChartGroupData(
        x: index,
        barRods: [BarChartRodData(toY: volume, color: AppTheme.accent, width: 16, borderRadius: BorderRadius.circular(4))],
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
        child: BarChart(
          BarChartData(
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(drawVerticalLine: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final day = now.subtract(Duration(days: 6 - value.toInt()));
                    return Text(DateFormat.E().format(day)[0], style: const TextStyle(color: AppTheme.textMuted, fontSize: 11));
                  },
                ),
              ),
            ),
            barGroups: bars,
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.item});

  final WorkoutExercise item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: AppTheme.surfaceAlt, child: Icon(Icons.fitness_center, color: AppTheme.accent)),
        title: Text(item.exercise.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${item.exercise.muscleGroup} • ${item.sets.length} sets • ${item.volume.toStringAsFixed(0)} kg'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

int _streakDays(List<Workout> workouts) {
  if (workouts.isEmpty) return 0;
  final days = workouts.map((item) => DateTime(item.date.year, item.date.month, item.date.day)).toSet();
  var streak = 0;
  var cursor = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
