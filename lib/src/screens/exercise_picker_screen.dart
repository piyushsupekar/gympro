import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/exercise_catalog.dart';
import '../models/exercise.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/upgrade_prompt.dart';

class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  static const route = '/exercise-picker';

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  final _search = TextEditingController();
  final _uuid = const Uuid();
  String _group = 'All';
  List<Exercise> _customExercises = [];
  bool _loadingCustom = false;

  List<Exercise> get _filtered {
    final allExercises = [...exerciseCatalog, ..._customExercises];
    final query = _search.text.trim().toLowerCase();
    return allExercises.where((exercise) {
      final groupMatch = _group == 'All' || exercise.muscleGroup == _group;
      final queryMatch = query.isEmpty ||
          exercise.name.toLowerCase().contains(query) ||
          exercise.category.toLowerCase().contains(query) ||
          exercise.muscleGroup.toLowerCase().contains(query);
      return groupMatch && queryMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCustomExercises();
  }

  Future<void> _loadCustomExercises() async {
    final user = context.read<AuthProvider>().firebaseUser;
    if (user == null) return;
    setState(() => _loadingCustom = true);
    try {
      final exercises = await context.read<FirestoreService>().getUserExercises(user.uid);
      if (mounted) {
        _customExercises = exercises.where((exercise) => exercise.isCustom).toList();
      }
    } finally {
      if (mounted) setState(() => _loadingCustom = false);
    }
  }

  Future<void> _createCustomExercise() async {
    if (!context.read<SubscriptionProvider>().isPro) {
      await UpgradePrompt.show(context);
      return;
    }

    final created = await showDialog<Exercise>(
      context: context,
      builder: (context) => _CustomExerciseDialog(id: _uuid.v4()),
    );
    final user = context.read<AuthProvider>().firebaseUser;
    if (created == null || user == null) return;
    await context.read<FirestoreService>().saveExercise(user.uid, created);
    if (!mounted) return;
    setState(() => _customExercises = [..._customExercises, created]);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add exercise'),
        actions: [
          IconButton(
            tooltip: 'Create custom exercise',
            onPressed: _createCustomExercise,
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search exercises',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: muscleGroups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final group = muscleGroups[index];
                return ChoiceChip(
                  label: Text(group),
                  selected: _group == group,
                  onSelected: (_) => setState(() => _group = group),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _BodyWireframe(title: 'Front', group: _group)),
              const SizedBox(width: 12),
              Expanded(child: _BodyWireframe(title: 'Back', group: _group, back: true)),
            ],
          ),
          const SizedBox(height: 20),
          if (_loadingCustom)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No exercises found', style: TextStyle(color: AppTheme.textMuted))),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.08,
              ),
              itemBuilder: (_, index) => _ExerciseGridCard(exercise: filtered[index]),
            ),
        ],
      ),
    );
  }
}

class _CustomExerciseDialog extends StatefulWidget {
  const _CustomExerciseDialog({required this.id});

  final String id;

  @override
  State<_CustomExerciseDialog> createState() => _CustomExerciseDialogState();
}

class _CustomExerciseDialogState extends State<_CustomExerciseDialog> {
  final _name = TextEditingController();
  String _group = 'Chest';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom exercise'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Exercise name')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _group,
            items: muscleGroups.where((group) => group != 'All').map((group) => DropdownMenuItem(value: group, child: Text(group))).toList(),
            onChanged: (value) => setState(() => _group = value ?? _group),
            decoration: const InputDecoration(labelText: 'Muscle group'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              Exercise(
                id: widget.id,
                name: _name.text.trim(),
                category: 'Custom',
                muscleGroup: _group,
                isCustom: true,
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _ExerciseGridCard extends StatelessWidget {
  const _ExerciseGridCard({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.pop(context, exercise),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.fitness_center, color: AppTheme.accent),
              const Spacer(),
              Text(exercise.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('${exercise.category} • ${exercise.muscleGroup}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyWireframe extends StatelessWidget {
  const _BodyWireframe({required this.title, required this.group, this.back = false});

  final String title;
  final String group;
  final bool back;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            SvgPicture.string(_bodySvg(group, back: back), height: 160),
          ],
        ),
      ),
    );
  }
}

String _fill(String muscle, String selected) {
  if (selected == 'All') return '#303030';
  return selected == muscle ? '#ff6b35' : '#303030';
}

String _bodySvg(String selected, {required bool back}) {
  final chest = _fill('Chest', selected);
  final backFill = _fill('Back', selected);
  final shoulders = _fill('Shoulders', selected);
  final arms = _fill('Arms', selected);
  final legs = _fill('Legs', selected);
  final core = _fill('Core', selected);
  final torso = back ? backFill : chest;
  return '''
<svg width="130" height="210" viewBox="0 0 130 210" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="65" cy="18" r="14" stroke="#8a8a8a" stroke-width="3" fill="#242424"/>
  <path d="M47 38 C53 33 77 33 83 38 L92 92 C85 105 45 105 38 92 Z" fill="$torso" stroke="#8a8a8a" stroke-width="3"/>
  <path d="M51 65 C58 72 72 72 79 65 L77 100 C71 106 59 106 53 100 Z" fill="$core" stroke="#8a8a8a" stroke-width="2"/>
  <path d="M38 43 L20 62 L28 117 L42 111 L36 75 Z" fill="$shoulders" stroke="#8a8a8a" stroke-width="3"/>
  <path d="M92 43 L110 62 L102 117 L88 111 L94 75 Z" fill="$shoulders" stroke="#8a8a8a" stroke-width="3"/>
  <path d="M28 117 L22 160" stroke="$arms" stroke-width="13" stroke-linecap="round"/>
  <path d="M102 117 L108 160" stroke="$arms" stroke-width="13" stroke-linecap="round"/>
  <path d="M49 104 L43 188" stroke="$legs" stroke-width="18" stroke-linecap="round"/>
  <path d="M81 104 L87 188" stroke="$legs" stroke-width="18" stroke-linecap="round"/>
  <path d="M50 202 H36" stroke="#8a8a8a" stroke-width="8" stroke-linecap="round"/>
  <path d="M80 202 H94" stroke="#8a8a8a" stroke-width="8" stroke-linecap="round"/>
</svg>
''';
}
