import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/client_Model.dart';
import '../services/client_services.dart';

// ===============================
// Client Service Provider
// ===============================
final clientServiceProvider = Provider((ref) => ClientService());

// ===============================
// All Clients Provider
// ===============================
final allClientsProvider = StreamProvider<List<ClientModel>>((ref) {
  final service = ref.watch(clientServiceProvider);
  return service.streamAllClients();
});

// ===============================
// Get Client by ID Provider
// ===============================
final getClientByIdProvider = FutureProvider.family<ClientModel?, String>((
  ref,
  clientId,
) async {
  final service = ref.watch(clientServiceProvider);
  return service.getClient(clientId);
});

// ===============================
// Verified Clients Provider
// ===============================
final verifiedClientsProvider = StreamProvider<List<ClientModel>>((ref) {
  final service = ref.watch(clientServiceProvider);
  return service.streamVerifiedClients();
});

// ===============================
// Active Clients Provider
// ===============================
final activeClientsProvider = StreamProvider<List<ClientModel>>((ref) {
  final service = ref.watch(clientServiceProvider);
  return service.streamActiveClients();
});

// ===============================
// Clients with Pending Payment Provider
// ===============================
final clientsWithPendingPaymentProvider = StreamProvider<List<ClientModel>>((
  ref,
) {
  final service = ref.watch(clientServiceProvider);
  return service.streamClientsWithPendingPayment();
});

// ===============================
// Client Cases Count Provider
// ===============================
final clientCasesCountProvider = FutureProvider.family<int, String>((
  ref,
  clientId,
) async {
  final service = ref.watch(clientServiceProvider);
  return service.getClientCasesCount(clientId);
});

// ===============================
// Client Wallet Balance Provider
// ===============================
final clientWalletBalanceProvider = FutureProvider.family<double, String>((
  ref,
  clientId,
) async {
  final service = ref.watch(clientServiceProvider);
  return service.getWalletBalance(clientId);
});

// ===============================
// Client Notifier
// ===============================
class ClientNotifier extends StateNotifier<ClientModel?> {
  final ClientService _service;

  ClientNotifier(this._service) : super(null);

  Future<String> createClient(ClientModel client) async {
    final id = await _service.createClient(client);
    state = client;
    return id;
  }

  Future<void> updateClient(ClientModel client) async {
    await _service.updateClient(client);
    state = client;
  }

  Future<void> deleteClient(String clientId) async {
    await _service.deleteClient(clientId);
    state = null;
  }

  Future<void> loadClient(String clientId) async {
    final client = await _service.getClient(clientId);
    state = client;
  }

  Future<void> approveClient(String clientId) async {
    await _service.approveClient(clientId);
  }

  Future<void> suspendClient(String clientId) async {
    await _service.suspendClient(clientId);
  }

  Future<void> addWallet(String clientId, double amount) async {
    await _service.addWalletBalance(clientId, amount);
  }

  Future<void> deductWallet(String clientId, double amount) async {
    await _service.deductWalletBalance(clientId, amount);
  }

  Future<void> bookLawyer(String clientId, String lawyerId) async {
    await _service.bookLawyer(clientId, lawyerId);
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
