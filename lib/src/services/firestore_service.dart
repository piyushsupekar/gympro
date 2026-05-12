import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/exercise.dart';
import '../models/workout.dart';

class FirestoreService {
  FirestoreService({required this.firebaseEnabled});

  final bool firebaseEnabled;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _users() => _db.collection('users');

  Future<AppUser?> getUser(String uid) async {
    if (!firebaseEnabled) return null;
    final snapshot = await _users().doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AppUser.fromMap(uid, snapshot.data()!);
  }

  Stream<AppUser?> watchUser(String uid) {
    if (!firebaseEnabled) return const Stream.empty();
    return _users().doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return AppUser.fromMap(snapshot.id, data);
    });
  }

  Future<void> upsertUser(AppUser user) {
    if (!firebaseEnabled) return Future.value();
    return _users().doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Stream<List<Workout>> watchWorkouts(String uid) {
    if (!firebaseEnabled) return const Stream.empty();
    return _users()
        .doc(uid)
        .collection('workouts')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Workout.fromMap(doc.id, doc.data())).toList());
  }

  Future<List<Workout>> getWorkouts(String uid) async {
    if (!firebaseEnabled) return [];
    final snapshot = await _users()
        .doc(uid)
        .collection('workouts')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => Workout.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> saveWorkout(String uid, Workout workout) async {
    if (!firebaseEnabled) return;
    final userRef = _users().doc(uid);
    final batch = _db.batch();
    batch.set(userRef.collection('workouts').doc(workout.id), workout.toMap());

    for (final item in workout.exercises) {
      final exerciseRef = userRef.collection('exercises').doc(item.exercise.id);
      batch.set(
        exerciseRef,
        {
          'name': item.exercise.name,
          'category': item.exercise.category,
          'muscleGroup': item.exercise.muscleGroup,
          'isCustom': item.exercise.isCustom,
          'sets': FieldValue.arrayUnion(item.sets.map((set) => set.toMap()).toList()),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<List<Exercise>> getUserExercises(String uid) async {
    if (!firebaseEnabled) return [];
    final snapshot = await _users().doc(uid).collection('exercises').get();
    return snapshot.docs.map((doc) => Exercise.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> saveExercise(String uid, Exercise exercise) {
    if (!firebaseEnabled) return Future.value();
    return _users().doc(uid).collection('exercises').doc(exercise.id).set(
          exercise.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<int> workoutCount(String uid) async {
    if (!firebaseEnabled) return 0;
    final snapshot = await _users().doc(uid).collection('workouts').count().get();
    return snapshot.count ?? 0;
  }

  Future<void> updatePhoto(String uid, String photoUrl) {
    if (!firebaseEnabled) return Future.value();
    return _users().doc(uid).set({'photoUrl': photoUrl}, SetOptions(merge: true));
  }

  Future<void> setProStatus(String uid, bool isPro) {
    if (!firebaseEnabled) return Future.value();
    return _users().doc(uid).set({'isPro': isPro}, SetOptions(merge: true));
  }
}
