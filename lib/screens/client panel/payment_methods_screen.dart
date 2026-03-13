import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/payment_provider.dart';
import 'add_new_card_screen.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark
        ? const Color(0xFF9E9E9E)
        : Colors.grey.shade600;

    final paymentMethods = ref.watch(paymentProvider);

    final wallets = paymentMethods
        .where(
          (m) => !m.title.contains('Visa') && !m.title.contains('MasterCard'),
        )
        .toList();
    final cards = paymentMethods
        .where(
          (m) => m.title.contains('Visa') || m.title.contains('MasterCard'),
        )
        .toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 16),
            ),
          ),
        ),
        title: Text(
          'Payment Methods',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Add New Card Placeholder
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddNewCardScreen()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_card_outlined,
                        color: Color(0xFFDC2626),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add New Card',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Securely add a credit or debit card',
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('DIGITAL WALLETS', subtitleColor),
            const SizedBox(height: 16),
            ...wallets.map(
              (wallet) => _buildMethodRow(
                context,
                ref,
                wallet,
                cardColor,
                textColor,
                subtitleColor,
              ),
            ),

            if (cards.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSectionHeader('YOUR CARDS', subtitleColor),
              const SizedBox(height: 16),
              ...cards.map(
                (card) => _buildMethodRow(
                  context,
                  ref,
                  card,
                  cardColor,
                  textColor,
                  subtitleColor,
                ),
              ),
            ],

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proceeding to payment Gateway...'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Your payment details are encrypted and secure.',
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color subtitleColor) {
    return Text(
      title,
      style: TextStyle(
        color: subtitleColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildMethodRow(
    BuildContext context,
    WidgetRef ref,
    PaymentMethod method,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _getIconForMethod(method),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  method.subtitle,
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: method.isEnabled,
            onChanged: (val) =>
                ref.read(paymentProvider.notifier).toggleMethod(method.id, val),
            activeThumbColor: const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  Widget _getIconForMethod(PaymentMethod method) {
    if (method.title.contains('Visa')) {
      return const Icon(Icons.credit_card, color: Colors.blue);
    }
    if (method.title.contains('EasyPaisa')) {
      return const Icon(Icons.account_balance_wallet, color: Colors.green);
    }
    if (method.title.contains('JazzCash')) {
      return const Icon(Icons.account_balance_wallet, color: Colors.red);
    }
    return const Icon(Icons.account_balance_wallet, color: Colors.orange);
  }
}
