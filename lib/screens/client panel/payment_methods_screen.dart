import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/payment_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'add_new_card_screen.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedMethod;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
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
    final clientAsync = ref.watch(currentClientProvider);

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
            // Send Money Section
            _buildSendMoneyCard(
              clientAsync,
              isDark,
              cardColor,
              textColor,
              subtitleColor,
              ref,
            ),
            const SizedBox(height: 32),
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

  Widget _buildSendMoneyCard(
    AsyncValue clientAsync,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.3),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.send_outlined,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Money to Lawyer',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pay for your case instantly',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Amount (Rs.)',
              labelStyle: TextStyle(color: subtitleColor),
              hintText: 'Enter amount',
              hintStyle: TextStyle(color: subtitleColor.withValues(alpha: 0.5)),
              prefixText: 'Rs. ',
              prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description Input (Optional)
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              labelStyle: TextStyle(color: subtitleColor),
              hintText: 'e.g., Case fee payment, retainer, etc.',
              hintStyle: TextStyle(color: subtitleColor.withValues(alpha: 0.5)),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Payment Method Selection
          Text(
            'Payment Method',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentMethodSelector(
            isDark,
            cardColor,
            textColor,
            subtitleColor,
          ),
          const SizedBox(height: 24),
          // Send Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () => _handleSendMoney(clientAsync, ref, isDark, textColor),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white : Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      'Send Payment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final methods = ['easypaisa', 'jazzcash', 'nayapay', 'card'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: methods
            .map((method) {
              final isSelected = _selectedMethod == method;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMethod = method),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFDC2626)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      method.replaceFirst(method[0], method[0].toUpperCase()),
                      style: TextStyle(
                        color: isSelected ? Colors.white : textColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }

  void _handleSendMoney(
    AsyncValue clientAsync,
    WidgetRef ref,
    bool isDark,
    Color textColor,
  ) async {
    if (_amountController.text.isEmpty || _selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter amount and select payment method'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);
      
      clientAsync.whenData((client) async {
        if (client == null) {
          throw Exception('User not found');
        }

        // For demo, we'll use a mock lawyer ID
        const lawyerId = 'demo_lawyer_id';
        const caseId = 'demo_case_id';

        // Create transaction
        final transaction = await ref.read(transactionNotifierProvider.notifier).createTransaction(
          clientId: client.clientId,
          lawyerId: lawyerId,
          caseId: caseId,
          amount: amount,
          paymentMethod: _selectedMethod ?? 'card',
          description: _descriptionController.text.isEmpty
              ? 'Payment to lawyer'
              : _descriptionController.text,
        );

        // Show confirmation
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outlined,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Payment Initiated',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs. ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Transaction ID: ${transaction.transactionId}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _amountController.clear();
                          _descriptionController.clear();
                          setState(() => _selectedMethod = null);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
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
