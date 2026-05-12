import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise.dart';

class WorkoutExercise {
  const WorkoutExercise({
    required this.exercise,
    required this.sets,
    this.note,
  });

  final Exercise exercise;
  final List<ExerciseSet> sets;
  final String? note;

  double get volume => sets.fold(0, (sum, set) => sum + set.volume);

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exercise.id,
      'name': exercise.name,
      'category': exercise.category,
      'muscleGroup': exercise.muscleGroup,
      'note': note,
      'sets': sets.map((set) => set.toMap()).toList(),
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> data) {
    final exercise = Exercise(
      id: data['exerciseId'] as String? ?? data['name'] as String? ?? 'exercise',
      name: data['name'] as String? ?? 'Exercise',
      category: data['category'] as String? ?? 'Strength',
      muscleGroup: data['muscleGroup'] as String? ?? 'Full body',
    );

    return WorkoutExercise(
      exercise: exercise,
      note: data['note'] as String?,
      sets: (data['sets'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ExerciseSet.fromMap)
          .toList(),
    );
  }
}

class Workout {
  const Workout({
    required this.id,
    required this.date,
    required this.duration,
    required this.totalVolume,
    required this.totalSets,
    required this.exercises,
  });

  final String id;
  final DateTime date;
  final Duration duration;
  final double totalVolume;
  final int totalSets;
  final List<WorkoutExercise> exercises;

  factory Workout.fromMap(String id, Map<String, dynamic> data) {
    return Workout(
      id: id,
      date: _dateFrom(data['date']) ?? DateTime.now(),
      duration: Duration(seconds: (data['duration'] as num? ?? 0).toInt()),
      totalVolume: (data['totalVolume'] as num? ?? 0).toDouble(),
      totalSets: (data['totalSets'] as num? ?? 0).toInt(),
      exercises: (data['exercises'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WorkoutExercise.fromMap)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'duration': duration.inSeconds,
      'totalVolume': totalVolume,
      'totalSets': totalSets,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
    };
  }
}

DateTime? _dateFrom(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
