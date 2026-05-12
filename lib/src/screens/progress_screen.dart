import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../providers/subscription_provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_tile.dart';
import '../widgets/upgrade_prompt.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const route = '/progress';

  @override
  Widget build(BuildContext context) {
    final workouts = context.watch<WorkoutProvider>().workouts;
    final isPro = context.watch<SubscriptionProvider>().isPro;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: workouts.isEmpty
          ? const EmptyState(
              icon: Icons.insights,
              title: 'No progress yet',
              message: 'Finish workouts to unlock charts, frequency trends, and PR tracking.',
            )
          : !isPro
              ? _FreeProgressSummary(workouts: workouts)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Weight lifted over time', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    SizedBox(height: 220, child: _VolumeLineChart(workouts: workouts)),
                    const SizedBox(height: 24),
                    Text('Workout frequency', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    SizedBox(height: 220, child: _FrequencyChart(workouts: workouts)),
                    const SizedBox(height: 24),
                    Text('Personal records', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    ..._prs(workouts).map((record) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.emoji_events, color: AppTheme.accent),
                            title: Text(record.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(DateFormat.yMMMd().format(record.date)),
                            trailing: Text('${record.weight.toStringAsFixed(0)} kg x ${record.reps}'),
                          ),
                        )),
                  ],
                ),
    );
  }
}

class _FreeProgressSummary extends StatelessWidget {
  const _FreeProgressSummary({required this.workouts});

  final List<Workout> workouts;

  @override
  Widget build(BuildContext context) {
    final totalVolume = workouts.fold<double>(0, (sum, item) => sum + item.totalVolume);
    final totalSets = workouts.fold<int>(0, (sum, item) => sum + item.totalSets);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: ListTile(
            leading: const Icon(Icons.workspace_premium, color: AppTheme.accent),
            title: const Text('Advanced progress is Pro'),
            subtitle: const Text('Unlock charts, PR insights, frequency trends, and exports. No ads.'),
            trailing: TextButton(onPressed: () => UpgradePrompt.show(context), child: const Text('Upgrade')),
          ),
        ),
        Row(
          children: [
            Expanded(child: StatTile(label: 'Workouts', value: workouts.length.toString(), icon: Icons.event_available)),
            const SizedBox(width: 10),
            Expanded(child: StatTile(label: 'Volume', value: totalVolume.toStringAsFixed(0), icon: Icons.monitor_weight)),
            const SizedBox(width: 10),
            Expanded(child: StatTile(label: 'Sets', value: totalSets.toString(), icon: Icons.repeat)),
          ],
        ),
        const SizedBox(height: 18),
        Text('Locked Pro tools', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const _LockedTool(icon: Icons.show_chart, title: 'Weight lifted over time'),
        const _LockedTool(icon: Icons.bar_chart, title: 'Workout frequency chart'),
        const _LockedTool(icon: Icons.emoji_events, title: 'Personal record list'),
        const _LockedTool(icon: Icons.ios_share, title: 'CSV/PDF export'),
      ],
    );
  }
}

class _LockedTool extends StatelessWidget {
  const _LockedTool({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.accent),
        title: Text(title),
        trailing: const Icon(Icons.lock),
      ),
    );
  }
}

class _VolumeLineChart extends StatelessWidget {
  const _VolumeLineChart({required this.workouts});

  final List<Workout> workouts;

  @override
  Widget build(BuildContext context) {
    final ordered = [...workouts]..sort((a, b) => a.date.compareTo(b.date));
    final spots = List.generate(
      ordered.length,
      (index) => FlSpot(index.toDouble(), ordered[index].totalVolume),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 16, 8),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: AppTheme.accent,
                barWidth: 4,
                isCurved: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: AppTheme.accent.withOpacity(0.18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyChart extends StatelessWidget {
  const _FrequencyChart({required this.workouts});

  final List<Workout> workouts;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final groups = List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
      final count = workouts.where((item) => item.date.year == day.year && item.date.month == day.month && item.date.day == day.day).length;
      return BarChartGroupData(
        x: index,
        barRods: [BarChartRodData(toY: count.toDouble(), color: AppTheme.accent, width: 16, borderRadius: BorderRadius.circular(4))],
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
        child: BarChart(
          BarChartData(
            maxY: 4,
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
            barGroups: groups,
          ),
        ),
      ),
    );
  }
}

class _Record {
  const _Record({required this.name, required this.weight, required this.reps, required this.date});

  final String name;
  final double weight;
  final int reps;
  final DateTime date;
}

List<_Record> _prs(List<Workout> workouts) {
  final best = <String, _Record>{};
  for (final workout in workouts) {
    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        final current = best[exercise.exercise.id];
        if (current == null || set.weight > current.weight) {
          best[exercise.exercise.id] = _Record(
            name: exercise.exercise.name,
            weight: set.weight,
            reps: set.reps,
            date: set.date,
          );
        }
      }
    }
  }
  final records = best.values.toList()..sort((a, b) => b.weight.compareTo(a.weight));
  return records.take(10).toList();
}
