import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  static const _key = 'gympro_onboarding_complete';
  static const _goalKey = 'gympro_goal';
  static const _levelKey = 'gympro_level';
  static const _daysKey = 'gympro_days';

  bool _isComplete = false;
  bool _loaded = false;
  String _goal = 'Build strength';
  String _fitnessLevel = 'Beginner';
  int _daysPerWeek = 3;

  bool get isComplete => _isComplete;
  bool get loaded => _loaded;
  String get goal => _goal;
  String get fitnessLevel => _fitnessLevel;
  int get daysPerWeek => _daysPerWeek;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isComplete = prefs.getBool(_key) ?? false;
    _goal = prefs.getString(_goalKey) ?? _goal;
    _fitnessLevel = prefs.getString(_levelKey) ?? _fitnessLevel;
    _daysPerWeek = prefs.getInt(_daysKey) ?? _daysPerWeek;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setGoal(String value) async {
    _goal = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalKey, value);
    notifyListeners();
  }

  Future<void> setFitnessLevel(String value) async {
    _fitnessLevel = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_levelKey, value);
    notifyListeners();
  }

  Future<void> setDaysPerWeek(int value) async {
    _daysPerWeek = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_daysKey, value);
    notifyListeners();
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    _isComplete = true;
    notifyListeners();
  }
}
