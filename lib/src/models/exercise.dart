import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseSet {
  const ExerciseSet({
    required this.weight,
    required this.reps,
    required this.date,
    this.isPr = false,
  });

  final double weight;
  final int reps;
  final DateTime date;
  final bool isPr;

  double get volume => weight * reps;

  factory ExerciseSet.fromMap(Map<String, dynamic> data) {
    return ExerciseSet(
      weight: (data['weight'] as num? ?? 0).toDouble(),
      reps: (data['reps'] as num? ?? 0).toInt(),
      date: _dateFrom(data['date']) ?? DateTime.now(),
      isPr: data['isPr'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'reps': reps,
      'date': Timestamp.fromDate(date),
      'isPr': isPr,
    };
  }
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    this.sets = const [],
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String category;
  final String muscleGroup;
  final List<ExerciseSet> sets;
  final bool isCustom;

  factory Exercise.fromMap(String id, Map<String, dynamic> data) {
    return Exercise(
      id: id,
      name: data['name'] as String? ?? 'Exercise',
      category: data['category'] as String? ?? 'Strength',
      muscleGroup: data['muscleGroup'] as String? ?? 'Full body',
      sets: (data['sets'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ExerciseSet.fromMap)
          .toList(),
      isCustom: data['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'muscleGroup': muscleGroup,
      'sets': sets.map((set) => set.toMap()).toList(),
      'isCustom': isCustom,
    };
  }

  Exercise copyWith({List<ExerciseSet>? sets}) {
    return Exercise(
      id: id,
      name: name,
      category: category,
      muscleGroup: muscleGroup,
      sets: sets ?? this.sets,
      isCustom: isCustom,
    );
  }
}

DateTime? _dateFrom(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
