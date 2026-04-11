import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/user_stats_provider.dart';
import 'coin_store_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final CoinPackage package;

  const PaymentScreen({super.key, required this.package});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'card';

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final statsNotifier = ref.read(userStatsProvider.notifier);
      await statsNotifier.addCoins(widget.package.coins + widget.package.bonus);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text(
            'Successfully purchased ${widget.package.coins + widget.package.bonus} coins!',
          ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Checkout',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
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
                    'Order Summary',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _OrderRow(
                    label: 'Coins',
                    value: '${widget.package.coins}',
                    color: AppColors.primary,
                  ),
                  if (widget.package.bonus > 0) ...[
                    const SizedBox(height: 12),
                    _OrderRow(
                      label: 'Bonus Coins',
                      value: '+${widget.package.bonus}',
                      color: AppColors.secondary,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Divider(
                    color: AppColors.outline.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.package.priceString,
                        style: AppTypography.displaySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Payment Method Selection
            Text(
              'Payment Method',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _PaymentMethodCard(
              title: 'Credit/Debit Card',
              subtitle: 'Visa, Mastercard',
              icon: Icons.credit_card,
              isSelected: _selectedPaymentMethod == 'card',
              onTap: () => setState(() => _selectedPaymentMethod = 'card'),
            ),
            const SizedBox(height: 12),

            _PaymentMethodCard(
              title: 'Google Pay',
              subtitle: 'Fast & Secure',
              icon: Icons.g_mobiledata,
              isSelected: _selectedPaymentMethod == 'gpay',
              onTap: () => setState(() => _selectedPaymentMethod = 'gpay'),
            ),
            const SizedBox(height: 12),

            _PaymentMethodCard(
              title: 'Apple Pay',
              subtitle: 'One-Touch Payment',
              icon: Icons.apple,
              isSelected: _selectedPaymentMethod == 'applepay',
              onTap: () => setState(() => _selectedPaymentMethod = 'applepay'),
            ),

            const SizedBox(height: 32),

            // Card Details (if card selected)
            if (_selectedPaymentMethod == 'card') ...[
              Text(
                'Card Details',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _CardInputField(
                label: 'Cardholder Name',
                hintText: 'Enter your name',
              ),
              const SizedBox(height: 16),
              _CardInputField(
                label: 'Card Number',
                hintText: '1234 5678 9012 3456',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _CardInputField(
                      label: 'Expiry',
                      hintText: 'MM/YY',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CardInputField(
                      label: 'CVV',
                      hintText: '123',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // Security Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment information is secure and encrypted',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Complete Payment Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.outline,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isProcessing
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.onPrimary,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Complete Payment',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Terms
            Center(
              child: Text(
                'By completing this purchase, you agree to our Terms of Service',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OrderRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _CardInputField extends StatelessWidget {
  final String label;
  final String hintText;

  const _CardInputField({
    required this.label,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: AppColors.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.outline.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
