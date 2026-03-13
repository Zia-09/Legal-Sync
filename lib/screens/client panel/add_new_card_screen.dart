import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/payment_provider.dart';

class AddNewCardScreen extends StatefulWidget {
  const AddNewCardScreen({super.key});

  @override
  State<AddNewCardScreen> createState() => _AddNewCardScreenState();
}

class _AddNewCardScreenState extends State<AddNewCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _saveCard = true;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark
        ? const Color(0xFF9E9E9E)
        : Colors.grey.shade600;

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
          'Add New Card',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Visual Card Preview
              ValueListenableBuilder(
                valueListenable: _cardNumberController,
                builder: (context, cardNo, _) => ValueListenableBuilder(
                  valueListenable: _holderNameController,
                  builder: (context, holder, _) => ValueListenableBuilder(
                    valueListenable: _expiryDateController,
                    builder: (context, expiry, _) => _buildCardPreview(
                      cardNo.text,
                      holder.text,
                      expiry.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Card Information',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('CARDHOLDER NAME', subtitleColor),
              _buildTextField(
                controller: _holderNameController,
                hint: 'e.g. Alexander Sterling',
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _buildLabel('CARD NUMBER', subtitleColor),
              _buildTextField(
                controller: _cardNumberController,
                hint: '0000 0000 0000 0000',
                keyboardType: TextInputType.number,
                isDark: isDark,
                suffix: const Icon(
                  Icons.credit_card,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('EXPIRY DATE', subtitleColor),
                        _buildTextField(
                          controller: _expiryDateController,
                          hint: 'MM/YY',
                          keyboardType: TextInputType.datetime,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('CVV', subtitleColor),
                        _buildTextField(
                          controller: _cvvController,
                          hint: '***',
                          keyboardType: TextInputType.number,
                          isDark: isDark,
                          suffix: const Icon(
                            Icons.help_outline,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save Card',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remember for future legal payments',
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                    ],
                  ),
                  Switch(
                    value: _saveCard,
                    onChanged: (val) => setState(() => _saveCard = val),
                    activeThumbColor: const Color(0xFFFF6B00),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => _handleSaveCard(ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add Card',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Your card data is encrypted and secure. By adding a card, you agree to our Terms of Service.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subtitleColor.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPreview(String number, String holder, String expiry) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.contactless, color: Colors.white54, size: 32),
              Icon(Icons.credit_card, color: Colors.white, size: 32),
            ],
          ),
          const Spacer(),
          Text(
            number.isEmpty ? '•••• •••• •••• ••••' : number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CARD HOLDER',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    holder.isEmpty ? 'YOUR NAME' : holder.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPIRES',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expiry.isEmpty ? 'MM/YY' : expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        suffixIcon: suffix,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        return null;
      },
    );
  }

  void _handleSaveCard(WidgetRef ref) {
    if (!_formKey.currentState!.validate()) return;

    final last4 = _cardNumberController.text.length >= 4
        ? _cardNumberController.text.substring(
            _cardNumberController.text.length - 4,
          )
        : '0000';

    final newCard = PaymentMethod(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Visa ending in $last4',
      subtitle:
          'Added on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      iconPath: 'images/card_visa.png',
      isEnabled: true,
    );

    ref.read(paymentProvider.notifier).addCard(newCard);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}
