import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/exercise_catalog.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/firestore_service.dart';

class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider({required this.firestoreService});

  final FirestoreService firestoreService;

  static const freeWorkoutLimit = 3;
  final _uuid = const Uuid();

  StreamSubscription<List<Workout>>? _subscription;
  List<Workout> _workouts = [];
  List<WorkoutExercise> _activeExercises = [];
  DateTime? _startedAt;
  String? _error;
  bool _loading = false;

  List<Workout> get workouts => _workouts;
  List<WorkoutExercise> get activeExercises => _activeExercises;
  DateTime? get startedAt => _startedAt;
  String? get error => _error;
  bool get loading => _loading;
  bool get hasActiveWorkout => _startedAt != null;

  int get totalSets => _activeExercises.fold(0, (sum, item) => sum + item.sets.length);
  double get totalVolume => _activeExercises.fold(0, (sum, item) => sum + item.volume);
  int get prCount => _activeExercises.fold(0, (sum, item) => sum + item.sets.where((set) => set.isPr).length);

  void bind(String uid) {
    _subscription?.cancel();
    if (!firestoreService.firebaseEnabled) {
      _workouts = _demoWorkouts();
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    _subscription = firestoreService.watchWorkouts(uid).listen(
      (workouts) {
        _workouts = workouts;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _loading = false;
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  void startWorkout() {
    _startedAt = DateTime.now();
    _activeExercises = [
      WorkoutExercise(
        exercise: exerciseCatalog.first,
        sets: [ExerciseSet(weight: 60, reps: 8, date: DateTime.now())],
      ),
    ];
    notifyListeners();
  }

  void addExercise(Exercise exercise) {
    if (_startedAt == null) startWorkout();
    if (_activeExercises.any((item) => item.exercise.id == exercise.id)) return;
    _activeExercises = [
      ..._activeExercises,
      WorkoutExercise(exercise: exercise, sets: [ExerciseSet(weight: 0, reps: 10, date: DateTime.now())]),
    ];
    notifyListeners();
  }

  void replaceExercise(String oldId, Exercise replacement) {
    _activeExercises = _activeExercises
        .map((item) => item.exercise.id == oldId ? WorkoutExercise(exercise: replacement, sets: item.sets) : item)
        .toList();
    notifyListeners();
  }

  void addSet(String exerciseId) {
    _activeExercises = _activeExercises.map((item) {
      if (item.exercise.id != exerciseId) return item;
      final last = item.sets.isEmpty ? ExerciseSet(weight: 0, reps: 10, date: DateTime.now()) : item.sets.last;
      return WorkoutExercise(
        exercise: item.exercise,
        note: item.note,
        sets: [
          ...item.sets,
          ExerciseSet(weight: last.weight, reps: last.reps, date: DateTime.now()),
        ],
      );
    }).toList();
    notifyListeners();
  }

  void updateSet(String exerciseId, int index, {double? weight, int? reps}) {
    _activeExercises = _activeExercises.map((item) {
      if (item.exercise.id != exerciseId || index >= item.sets.length) return item;
      final sets = [...item.sets];
      final current = sets[index];
      sets[index] = ExerciseSet(
        weight: weight ?? current.weight,
        reps: reps ?? current.reps,
        date: current.date,
        isPr: (weight ?? current.weight) > _bestWeightFor(item.exercise.id),
      );
      return WorkoutExercise(exercise: item.exercise, sets: sets, note: item.note);
    }).toList();
    notifyListeners();
  }

  void addNoteToFirstExercise(String note) {
    if (_activeExercises.isEmpty) return;
    final first = _activeExercises.first;
    _activeExercises = [
      WorkoutExercise(exercise: first.exercise, sets: first.sets, note: note),
      ..._activeExercises.skip(1),
    ];
    notifyListeners();
  }

  void discardWorkout() {
    _startedAt = null;
    _activeExercises = [];
    notifyListeners();
  }

  Future<bool> finishWorkout(String uid, {required bool isPro}) async {
    if (_startedAt == null || _activeExercises.isEmpty) return false;
    if (!isPro && _workouts.length >= freeWorkoutLimit) return false;

    final workout = Workout(
      id: _uuid.v4(),
      date: DateTime.now(),
      duration: DateTime.now().difference(_startedAt!),
      totalVolume: totalVolume,
      totalSets: totalSets,
      exercises: _activeExercises,
    );

    try {
      if (firestoreService.firebaseEnabled) {
        await firestoreService.saveWorkout(uid, workout);
      } else {
        _workouts = [workout, ..._workouts];
      }
      discardWorkout();
      return true;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  double _bestWeightFor(String exerciseId) {
    final weights = _workouts
        .expand((workout) => workout.exercises)
        .where((item) => item.exercise.id == exerciseId)
        .expand((item) => item.sets)
        .map((set) => set.weight);
    if (weights.isEmpty) return 0;
    return weights.reduce((a, b) => a > b ? a : b);
  }

  List<Workout> _demoWorkouts() {
    final now = DateTime.now();
    return List.generate(3, (index) {
      final sets = [
        ExerciseSet(weight: 50 + index * 5, reps: 8, date: now.subtract(Duration(days: index * 2))),
        ExerciseSet(weight: 55 + index * 5, reps: 6, date: now.subtract(Duration(days: index * 2))),
      ];
      return Workout(
        id: 'demo_$index',
        date: now.subtract(Duration(days: index * 2)),
        duration: Duration(minutes: 48 + index * 5),
        totalVolume: sets.fold(0, (sum, set) => sum + set.volume),
        totalSets: sets.length,
        exercises: [WorkoutExercise(exercise: exerciseCatalog[index], sets: sets)],
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
