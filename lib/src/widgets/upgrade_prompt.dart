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
              'Unlock unlimited workouts, advanced charts, custom exercises, and export tools.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            _Benefit(icon: Icons.all_inclusive, text: 'Unlimited workout history'),
            _Benefit(icon: Icons.insights, text: 'Advanced progress charts'),
            _Benefit(icon: Icons.edit_note, text: 'Custom exercises'),
            _Benefit(icon: Icons.ios_share, text: 'Export training data'),
            const SizedBox(height: 18),
            if (subscription.loading)
              const Center(child: CircularProgressIndicator())
            else if (!subscription.storeAvailable || subscription.products.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Store products are not available yet. Configure product IDs in Play Console/App Store Connect.',
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
