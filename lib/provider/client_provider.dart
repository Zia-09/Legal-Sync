import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import '../model/client_Model.dart';
import '../services/client_services.dart';

// ===============================
// Client Service Provider
// ===============================
final clientServiceProvider = Provider((ref) => ClientService());

// ===============================
// Current Client Provider
// ===============================
final currentClientProvider = StreamProvider<ClientModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(null);

  // We need a stream for a single client. Let's add it if not exists.
  // For now we can use snapshots directly or add it to service.
  return FirebaseFirestore.instance
      .collection('clients')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return ClientModel.fromJson({...doc.data()!, 'clientId': doc.id});
      });
});

// ===============================
// All Clients Provider
// ===============================
final allClientsProvider = StreamProvider<List<ClientModel>>((ref) {
  final service = ref.watch(clientServiceProvider);
  return service.getAllClients();
});

// ===============================
// Get Client by ID Provider
// ===============================
final getClientByIdProvider = FutureProvider.family<ClientModel?, String>((
  ref,
  clientId,
) async {
  final service = ref.watch(clientServiceProvider);
  return service.getClientById(clientId);
});

// ===============================
// Verified Clients Provider
// ===============================
final verifiedClientsProvider = StreamProvider<List<ClientModel>>((ref) {
  final service = ref.watch(clientServiceProvider);
  return service.getAllClients().map(
    (clients) => clients.where((client) => client.isVerified).toList(),
  );
});

// ===============================
// Active Clients Provider
// ===============================
final activeClientsProvider = StreamProvider<List<ClientModel>>((ref) {
  final service = ref.watch(clientServiceProvider);
  return service.getAllClients().map(
    (clients) => clients
        .where((client) => client.status.toLowerCase() == 'active')
        .toList(),
  );
});

// ===============================
// Clients with Pending Payment Provider
// ===============================
final clientsWithPendingPaymentProvider = StreamProvider<List<ClientModel>>((
  ref,
) {
  final service = ref.watch(clientServiceProvider);
  return service.getAllClients().map(
    (clients) => clients.where((client) => client.hasPendingPayment).toList(),
  );
});

// ===============================
// Client Cases Count Provider
// ===============================
final clientCasesCountProvider = FutureProvider.family<int, String>((
  ref,
  clientId,
) async {
  final service = ref.watch(clientServiceProvider);
  final client = await service.getClientById(clientId);
  return client?.caseIds.length ?? 0;
});

// ===============================
// Client Wallet Balance Provider
// ===============================
final clientWalletBalanceProvider = FutureProvider.family<double, String>((
  ref,
  clientId,
) async {
  final service = ref.watch(clientServiceProvider);
  final client = await service.getClientById(clientId);
  return client?.walletBalance ?? 0.0;
});

// ===============================
// Client Notifier
// ===============================
class ClientNotifier extends StateNotifier<ClientModel?> {
  final ClientService _service;

  ClientNotifier(this._service) : super(null);

  Future<String> createClient(ClientModel client) async {
    await _service.addOrUpdateClient(client);
    state = client;
    return client.clientId;
  }

  Future<void> updateClient(ClientModel client) async {
    await _service.updateClient(
      clientId: client.clientId,
      data: client.toJson(),
    );
    state = client;
  }

  Future<void> deleteClient(String clientId) async {
    await _service.deleteClient(clientId);
    state = null;
  }

  Future<void> loadClient(String clientId) async {
    final client = await _service.getClientById(clientId);
    state = client;
  }

  Future<void> approveClient(String clientId) async {
    await _service.updateClient(
      clientId: clientId,
      data: {'isApproved': true, 'status': 'active'},
    );
    await loadClient(clientId);
  }

  Future<void> suspendClient(String clientId) async {
    await _service.updateClient(
      clientId: clientId,
      data: {'status': 'suspended'},
    );
    await loadClient(clientId);
  }

  Future<void> addWallet(String clientId, double amount) async {
    final client = await _service.getClientById(clientId);
    if (client == null) return;

    await _service.updateClient(
      clientId: clientId,
      data: {'walletBalance': client.walletBalance + amount},
    );
    await loadClient(clientId);
  }

  Future<void> deductWallet(String clientId, double amount) async {
    final client = await _service.getClientById(clientId);
    if (client == null) return;
    final updatedBalance = client.walletBalance - amount;

    await _service.updateClient(
      clientId: clientId,
      data: {'walletBalance': updatedBalance < 0 ? 0.0 : updatedBalance},
    );
    await loadClient(clientId);
  }

  Future<void> bookLawyer(String clientId, String lawyerId) async {
    await _service.bookLawyer(clientId: clientId, lawyerId: lawyerId);
    await loadClient(clientId);
  }
}

// ===============================
// Client State Notifier Provider
// ===============================
final clientStateNotifierProvider =
    StateNotifierProvider<ClientNotifier, ClientModel?>((ref) {
      final service = ref.watch(clientServiceProvider);
      return ClientNotifier(service);
    });

// ===============================
// Selected Client Provider
// ===============================
final selectedClientProvider = StateProvider<ClientModel?>((ref) => null);

// ===============================
// Lawyer's Clients Provider
// ===============================
final myClientsProvider = StreamProvider<List<ClientModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  final service = ref.watch(clientServiceProvider);
  return service.getAllClients().map((clients) {
    if (user.uid.isEmpty) return [];
    return clients
        .where((client) => client.bookedLawyers.contains(user.uid))
        .toList();
  });
});
