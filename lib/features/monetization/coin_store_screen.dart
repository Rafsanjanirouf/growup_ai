import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_stats_provider.dart';
import 'payment_screen.dart';

class CoinStoreScreen extends ConsumerWidget {
  const CoinStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStats = ref.watch(userStatsProvider);

    final coinPackages = [
      CoinPackage(
        id: 'starter',
        coins: 100,
        price: 0.99,
        priceString: '\$0.99',
        bonus: 0,
        isPopular: false,
      ),
      CoinPackage(
        id: 'standard',
        coins: 500,
        price: 3.99,
        priceString: '\$3.99',
        bonus: 50,
        isPopular: true,
      ),
      CoinPackage(
        id: 'premium',
        coins: 1200,
        price: 7.99,
        priceString: '\$7.99',
        bonus: 200,
        isPopular: false,
      ),
      CoinPackage(
        id: 'elite',
        coins: 2500,
        price: 14.99,
        priceString: '\$14.99',
        bonus: 500,
        isPopular: false,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Coin Store',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Current Balance Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.8),
                    AppColors.primary.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Balance',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${userStats.coins}',
                            style: AppTypography.displaySmall.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      Icons.redeem,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Coin Packages
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: coinPackages.length,
              itemBuilder: (context, index) {
                final package = coinPackages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _CoinPackageCard(
                    package: package,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(package: package),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Info Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coin Benefits',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BenefitRow(
                    icon: Icons.lock_open,
                    text: 'Unlock Premium Features',
                  ),
                  const SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.trending_up,
                    text: 'Get Detailed Analysis',
                  ),
                  const SizedBox(height: 12),
                  _BenefitRow(
                    icon: Icons.card_travel,
                    text: 'Access Advanced Tools',
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

class CoinPackage {
  final String id;
  final int coins;
  final double price;
  final String priceString;
  final int bonus;
  final bool isPopular;

  CoinPackage({
    required this.id,
    required this.coins,
    required this.price,
    required this.priceString,
    required this.bonus,
    required this.isPopular,
  });
}

class _CoinPackageCard extends StatelessWidget {
  final CoinPackage package;
  final VoidCallback onTap;

  const _CoinPackageCard({
    required this.package,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: package.isPopular
                    ? AppColors.primary
                    : AppColors.outline.withValues(alpha: 0.3),
                width: package.isPopular ? 2 : 1,
              ),
              boxShadow: package.isPopular
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Coins info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${package.coins}',
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Coins',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (package.bonus > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${package.bonus} Bonus',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Right side - Price & Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      package.priceString,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Buy',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Popular Badge
          if (package.isPopular)
            Positioned(
              top: -10,
              right:20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'POPULAR',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
