import '../models/exercise.dart';

const muscleGroups = [
  'All',
  'Chest',
  'Back',
  'Shoulders',
  'Arms',
  'Legs',
  'Core',
];

final exerciseCatalog = <Exercise>[
  const Exercise(id: 'bench_press', name: 'Bench Press', category: 'Push', muscleGroup: 'Chest'),
  const Exercise(id: 'incline_db_press', name: 'Incline DB Press', category: 'Push', muscleGroup: 'Chest'),
  const Exercise(id: 'deadlift', name: 'Deadlift', category: 'Pull', muscleGroup: 'Back'),
  const Exercise(id: 'lat_pulldown', name: 'Lat Pulldown', category: 'Pull', muscleGroup: 'Back'),
  const Exercise(id: 'overhead_press', name: 'Overhead Press', category: 'Push', muscleGroup: 'Shoulders'),
  const Exercise(id: 'lateral_raise', name: 'Lateral Raise', category: 'Accessory', muscleGroup: 'Shoulders'),
  const Exercise(id: 'barbell_curl', name: 'Barbell Curl', category: 'Accessory', muscleGroup: 'Arms'),
  const Exercise(id: 'triceps_pushdown', name: 'Triceps Pushdown', category: 'Accessory', muscleGroup: 'Arms'),
  const Exercise(id: 'squat', name: 'Back Squat', category: 'Legs', muscleGroup: 'Legs'),
  const Exercise(id: 'leg_press', name: 'Leg Press', category: 'Legs', muscleGroup: 'Legs'),
  const Exercise(id: 'plank', name: 'Weighted Plank', category: 'Core', muscleGroup: 'Core'),
  const Exercise(id: 'cable_crunch', name: 'Cable Crunch', category: 'Core', muscleGroup: 'Core'),
];
