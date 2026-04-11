import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_stats_provider.dart';
import '../../core/widgets/app_header_fixed.dart';

class CoinShopScreen extends ConsumerStatefulWidget {
  const CoinShopScreen({super.key});

  @override
  ConsumerState<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends ConsumerState<CoinShopScreen> {
  final List<CoinPackage> packages = [
    CoinPackage(
      id: 1,
      coins: 100,
      price: '\$0.99',
      bonus: 0,
      popular: false,
    ),
    CoinPackage(
      id: 2,
      coins: 550,
      price: '\$4.99',
      bonus: 50,
      popular: true,
    ),
    CoinPackage(
      id: 3,
      coins: 1200,
      price: '\$9.99',
      bonus: 200,
      popular: false,
    ),
    CoinPackage(
      id: 4,
      coins: 2600,
      price: '\$19.99',
      bonus: 600,
      popular: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final userStats = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLowest,
      appBar: AppHeader(
        title: 'Coin Shop',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Coins Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Balance',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${userStats.coins}',
                        style: AppTypography.displayMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '💰',
                    style: TextStyle(fontSize: 56),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Available Packages
            Text(
              'Choose Your Package',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Coin Packages Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final package = packages[index];
                return _CoinPackageCard(
                  package: package,
                  onTap: () => _handlePurchase(package),
                  isPopular: package.popular,
                );
              },
            ),
            const SizedBox(height: 32),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _FAQItem(
              question: 'How are coins used?',
              answer:
                  'Coins are used to unlock premium features, special programs, and exclusive content.',
            ),
            _FAQItem(
              question: 'Can I get refunds?',
              answer: 'Refunds are available within 24 hours of purchase.',
            ),
            _FAQItem(
              question: 'Do coins expire?',
              answer: 'No, your coins never expire. Use them anytime!',
            ),
          ],
        ),
      ),
    );
  }

  void _handlePurchase(CoinPackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLow,
        title: Text(
          'Confirm Purchase',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          'Purchase ${package.coins} coins for ${package.price}?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () {
              // Handle actual purchase here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Purchase successful!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }
}

class CoinPackage {
  final int id;
  final int coins;
  final String price;
  final int bonus;
  final bool popular;

  CoinPackage({
    required this.id,
    required this.coins,
    required this.price,
    required this.bonus,
    required this.popular,
  });
}

class _CoinPackageCard extends StatelessWidget {
  final CoinPackage package;
  final VoidCallback onTap;
  final bool isPopular;

  const _CoinPackageCard({
    required this.package,
    required this.onTap,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          border: Border.all(
            color: isPopular ? AppColors.primary : AppColors.outline.withValues(alpha: 0.2),
            width: isPopular ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPopular
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Popular Badge
            if (isPopular)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.kineticGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    '⭐ Popular',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPopular) const SizedBox(height: 20),
                  Text(
                    '💰',
                    style: TextStyle(fontSize: isPopular ? 36 : 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${package.coins}',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (package.bonus > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${package.bonus} bonus',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.kineticGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      package.price,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          widget.question,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.answer,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
