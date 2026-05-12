import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/workout_provider.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_tile.dart';
import '../widgets/upgrade_prompt.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const route = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  Future<void> _pickAvatar(AppUser user) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 900);
    if (image == null) return;
    setState(() => _uploading = true);
    try {
      final url = await context.read<StorageService>().uploadProfilePicture(user.uid, image);
      await context.read<FirestoreService>().updatePhoto(user.uid, url);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AuthScreen.route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.firebaseUser;
    final store = context.read<FirestoreService>();
    final workouts = context.watch<WorkoutProvider>().workouts;
    final subscription = context.watch<SubscriptionProvider>();

    if (user == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.person_off,
          title: 'No profile loaded',
          message: 'Sign in to manage your GymPro profile.',
        ),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: store.watchUser(user.uid),
      builder: (context, snapshot) {
        final appUser = snapshot.data ??
            AppUser(
              uid: user.uid,
              name: user.displayName ?? 'GymPro Athlete',
              email: user.email ?? '',
              photoUrl: user.photoURL,
              joinDate: DateTime.now(),
              goals: 'Build strength',
              fitnessLevel: 'Beginner',
              daysPerWeek: 3,
              isPro: subscription.isPro,
            );

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: AppTheme.surfaceAlt,
                      backgroundImage: appUser.photoUrl == null ? null : NetworkImage(appUser.photoUrl!),
                      child: appUser.photoUrl == null ? const Icon(Icons.person, size: 54, color: AppTheme.accent) : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton.filled(
                        onPressed: _uploading ? null : () => _pickAvatar(appUser),
                        icon: _uploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(appUser.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(appUser.email, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  avatar: Icon(subscription.isPro ? Icons.workspace_premium : Icons.lock_open, color: AppTheme.accent, size: 18),
                  label: Text(subscription.isPro ? 'Pro member' : 'Free tier'),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: StatTile(label: 'Workouts', value: workouts.length.toString(), icon: Icons.event_available)),
                  const SizedBox(width: 10),
                  Expanded(child: StatTile(label: 'Volume', value: workouts.fold<double>(0, (sum, item) => sum + item.totalVolume).toStringAsFixed(0), icon: Icons.monitor_weight)),
                  const SizedBox(width: 10),
                  Expanded(child: StatTile(label: 'Sets', value: workouts.fold<int>(0, (sum, item) => sum + item.totalSets).toString(), icon: Icons.repeat)),
                ],
              ),
              const SizedBox(height: 22),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.flag, color: AppTheme.accent),
                      title: const Text('Goal'),
                      subtitle: Text(appUser.goals),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.speed, color: AppTheme.accent),
                      title: const Text('Fitness level'),
                      subtitle: Text(appUser.fitnessLevel),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.calendar_month, color: AppTheme.accent),
                      title: const Text('Training days'),
                      subtitle: Text('${appUser.daysPerWeek} days per week'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications, color: AppTheme.accent),
                      title: const Text('Workout reminders'),
                      subtitle: const Text('Stay consistent'),
                      value: true,
                      onChanged: (_) {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.ios_share, color: AppTheme.accent),
                      title: const Text('CSV/PDF export'),
                      subtitle: const Text('Pro members can export workout history'),
                      onTap: () {
                        if (!subscription.isPro) {
                          UpgradePrompt.show(context);
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Prepared ${workouts.length} workouts for export.')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.auto_awesome, color: AppTheme.accent),
                      title: const Text('AI workout plans'),
                      subtitle: const Text('Included with Pro'),
                      onTap: () {
                        if (!subscription.isPro) {
                          UpgradePrompt.show(context);
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('AI workout plans module is ready for your training preferences.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!subscription.isPro)
                OutlinedButton.icon(
                  onPressed: () => UpgradePrompt.show(context),
                  icon: const Icon(Icons.workspace_premium),
                  label: const Text('Upgrade to Pro'),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        );
      },
    );
  }
}
