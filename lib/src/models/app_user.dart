import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.joinDate,
    required this.goals,
    required this.fitnessLevel,
    this.daysPerWeek = 3,
    this.isPro = false,
  });

  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime joinDate;
  final String goals;
  final String fitnessLevel;
  final int daysPerWeek;
  final bool isPro;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'] as String? ?? 'GymPro Athlete',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      joinDate: _dateFrom(data['joinDate']) ?? DateTime.now(),
      goals: data['goals'] as String? ?? 'Build strength',
      fitnessLevel: data['fitnessLevel'] as String? ?? 'Beginner',
      daysPerWeek: (data['daysPerWeek'] as num? ?? 3).toInt(),
      isPro: data['isPro'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'joinDate': Timestamp.fromDate(joinDate),
      'goals': goals,
      'fitnessLevel': fitnessLevel,
      'daysPerWeek': daysPerWeek,
      'isPro': isPro,
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    DateTime? joinDate,
    String? goals,
    String? fitnessLevel,
    int? daysPerWeek,
    bool? isPro,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      joinDate: joinDate ?? this.joinDate,
      goals: goals ?? this.goals,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      isPro: isPro ?? this.isPro,
    );
  }
}

DateTime? _dateFrom(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
