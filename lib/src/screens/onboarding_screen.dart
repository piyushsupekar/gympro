import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/onboarding_provider.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const route = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  static const _slideCount = 3;

  Future<void> _continue() async {
    if (_index < _slideCount - 1) {
      await _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
      return;
    }
    await context.read<OnboardingProvider>().complete();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AuthScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await context.read<OnboardingProvider>().complete();
                    if (context.mounted) Navigator.pushReplacementNamed(context, AuthScreen.route);
                  },
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slideCount,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, index) => _OnboardingSlide(index: index),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slideCount,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _index == index ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _index == index ? AppTheme.accent : Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _continue,
                child: Text(_index == _slideCount - 1 ? 'Start GymPro' : 'Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();
    final content = switch (index) {
      0 => (
          icon: Icons.flag,
          title: 'Choose your goal',
          subtitle: 'What should GymPro optimize around?',
          options: ['Build strength', 'Gain muscle', 'Lose fat', 'Stay consistent'],
          selected: onboarding.goal,
          onSelected: (String value) => onboarding.setGoal(value),
        ),
      1 => (
          icon: Icons.speed,
          title: 'Set your level',
          subtitle: 'Pick the level that feels honest today.',
          options: ['Beginner', 'Intermediate', 'Advanced'],
          selected: onboarding.fitnessLevel,
          onSelected: (String value) => onboarding.setFitnessLevel(value),
        ),
      _ => (
          icon: Icons.calendar_month,
          title: 'Pick training days',
          subtitle: 'Choose a weekly target you can actually hit.',
          options: ['2', '3', '4', '5', '6'],
          selected: onboarding.daysPerWeek.toString(),
          onSelected: (String value) => onboarding.setDaysPerWeek(int.parse(value)),
        ),
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(content.icon, color: AppTheme.accent, size: 70),
        ),
        const SizedBox(height: 32),
        Text(content.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Text(content.subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, height: 1.45)),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: content.options
              .map(
                (option) => ChoiceChip(
                  label: Text(index == 2 ? '$option days' : option),
                  selected: content.selected == option,
                  onSelected: (_) => content.onSelected(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
