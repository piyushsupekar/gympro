import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/subscription_provider.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';

class UpgradePrompt extends StatelessWidget {
  const UpgradePrompt({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const UpgradePrompt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Upgrade to GymPro Pro', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'No ads. Just serious training tools when you outgrow the free tier.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            const _PlanComparison(),
            const SizedBox(height: 18),
            _Benefit(icon: Icons.all_inclusive, text: 'Unlimited workout history'),
            _Benefit(icon: Icons.insights, text: 'Advanced progress charts'),
            _Benefit(icon: Icons.fitness_center, text: '500+ exercise library'),
            _Benefit(icon: Icons.edit_note, text: 'Custom exercises'),
            _Benefit(icon: Icons.ios_share, text: 'CSV/PDF export'),
            _Benefit(icon: Icons.auto_awesome, text: 'AI workout plans'),
            const SizedBox(height: 18),
            if (subscription.loading)
              const Center(child: CircularProgressIndicator())
            else if (!subscription.storeAvailable || subscription.products.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Store products are not available yet. Configure ₹199/month and ₹999/year products in Play Console/App Store Connect.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => subscription.setPro(true),
                    child: const Text('Enable Pro for testing'),
                  ),
                ],
              )
            else
              ...subscription.products.map((product) {
                final fallback = product.id == PurchaseService.monthlyId ? '₹199/month' : '₹999/year';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: () => subscription.buy(product),
                    child: Text('${product.title} - ${product.price.isEmpty ? fallback : product.price}'),
                  ),
                );
              }),
            TextButton(
              onPressed: subscription.restore,
              child: const Text('Restore purchase'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanComparison extends StatelessWidget {
  const _PlanComparison();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _PlanCard(
            title: 'Free',
            price: '₹0',
            subtitle: 'Forever',
            features: ['3 workouts saved', 'Basic stats', '50 exercises'],
            disabled: ['Progress charts', 'Custom exercises', 'Data export'],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _PlanCard(
            title: 'Pro',
            price: '₹199/mo',
            subtitle: '₹999/year saves 58%',
            highlighted: true,
            features: ['Unlimited workouts', 'Advanced charts', '500+ exercises', 'CSV/PDF export'],
            disabled: [],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.features,
    required this.disabled,
    this.highlighted = false,
  });

  final String title;
  final String price;
  final String subtitle;
  final List<String> features;
  final List<String> disabled;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlighted ? AppTheme.accent : Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 6),
          Text(price, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const Divider(height: 18),
          ...features.map((feature) => _FeatureLine(enabled: true, text: feature)),
          ...disabled.map((feature) => _FeatureLine(enabled: false, text: feature)),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.enabled, required this.text});

  final bool enabled;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(enabled ? Icons.check : Icons.close, size: 14, color: enabled ? AppTheme.accent : AppTheme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
