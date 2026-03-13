import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/model/client_Model.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_chat_screen.dart';

class AllClientScreen extends ConsumerStatefulWidget {
  const AllClientScreen({super.key});

  @override
  ConsumerState<AllClientScreen> createState() => _AllClientScreenState();
}

class _AllClientScreenState extends ConsumerState<AllClientScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(myClientsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Clients',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(context, isDark),
          Expanded(
            child: clientsAsync.when(
              data: (clients) {
                final filteredClients = clients.where((c) {
                  final query = _searchQuery.toLowerCase();
                  return c.name.toLowerCase().contains(query) ||
                      c.clientId.toLowerCase().contains(query);
                }).toList();

                if (filteredClients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 60,
                          color: Theme.of(
                            context,
                          ).hintColor.withValues(alpha: 0.5),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No clients found'
                              : 'No clients matching "$_searchQuery"',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: filteredClients.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    return _buildContactCard(context, client);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action for adding new client logic if any
        },
        backgroundColor: const Color(0xFFFF6B00),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 14,
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey.shade500),
          hintText: 'Search clients by name or ID',
          hintStyle: TextStyle(
            color: Theme.of(context).hintColor.withValues(alpha: 0.5),
            fontSize: 14,
          ),

          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, ClientModel client) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LawyerChatScreen(
              clientName: client.name,
              avatarUrl: client.profileImage ?? '',
              receiverId: client.clientId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFFF6B00).withValues(alpha: 0.1),
              backgroundImage:
                  (client.profileImage != null &&
                      client.profileImage!.isNotEmpty)
                  ? NetworkImage(client.profileImage!)
                  : null,
              child:
                  (client.profileImage == null || client.profileImage!.isEmpty)
                  ? Text(
                      client.name.isNotEmpty
                          ? client.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFFFF6B00),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${client.clientId.substring(0, client.clientId.length > 8 ? 8 : client.clientId.length).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          client.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chat_bubble_outline,
              color: const Color(0xFFFF6B00),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
