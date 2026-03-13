import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentMethod {
  final String id;
  final String title;
  final String subtitle;
  final String iconPath;
  final bool isEnabled;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    this.isEnabled = false,
    this.isDefault = false,
  });

  PaymentMethod copyWith({bool? isEnabled, bool? isDefault}) {
    return PaymentMethod(
      id: id,
      title: title,
      subtitle: subtitle,
      iconPath: iconPath,
      isEnabled: isEnabled ?? this.isEnabled,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class PaymentNotifier extends StateNotifier<List<PaymentMethod>> {
  PaymentNotifier() : super([
    PaymentMethod(
      id: 'easypaisa',
      title: 'EasyPaisa',
      subtitle: 'Fast & Secure',
      iconPath: 'images/easypaisa.png',
      isEnabled: false,
    ),
    PaymentMethod(
      id: 'jazzcash',
      title: 'JazzCash',
      subtitle: 'Instant Transfer',
      iconPath: 'images/jazzcash.png',
      isEnabled: false,
    ),
    PaymentMethod(
      id: 'nayapay',
      title: 'NayaPay',
      subtitle: 'Digital Payments',
      iconPath: 'images/nayapay.png',
      isEnabled: true,
    ),
  ]);

  void toggleMethod(String id, bool enabled) {
    state = [
      for (final method in state)
        if (method.id == id) method.copyWith(isEnabled: enabled) else method
    ];
  }

  void addCard(PaymentMethod card) {
    state = [...state, card];
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, List<PaymentMethod>>((ref) {
  return PaymentNotifier();
});
