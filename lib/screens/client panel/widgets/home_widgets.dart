import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/model/lawyer_Model.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/screens/client panel/lawyer_profile_screen.dart';
import 'package:legal_sync/screens/client panel/client_notifications_screen.dart';

// ─── Lawyer Card Widget ───────────────────────────────────────────────────────

class LawyerCard extends StatelessWidget {
  final LawyerModel lawyer;
  const LawyerCard({super.key, required this.lawyer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LawyerProfileScreen(lawyer: lawyer),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child:
                    (lawyer.profileImage != null &&
                        lawyer.profileImage!.isNotEmpty)
                    ? Image.network(
                        lawyer.profileImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Theme.of(context).dividerColor,
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFFFF6B00),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF2A2A2A),
                        child: Center(
                          child: Text(
                            lawyer.name
                                .split(' ')
                                .map((e) => e.isNotEmpty ? e[0] : '')
                                .take(2)
                                .join(),
                            style: const TextStyle(
                              color: Color(0xFFFF6B00),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lawyer.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lawyer.specialization,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFB800),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${lawyer.rating} (${lawyer.totalReviews} reviews)',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.payments_outlined,
                        color: Color(0xFF6B6B6B),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '\$${lawyer.consultationFee.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFFFF6B00),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF6B6B6B),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lawyer.location ?? 'N/A',
                          style: const TextStyle(
                            color: Color(0xFF6B6B6B),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

// ─── Home Drawer Widget ───────────────────────────────────────────────────────

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildDrawerHeader(context, ref),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClientNotificationsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bookmark_border,
                  label: 'Saved Lawyers',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history,
                  label: 'Past Consultations',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.wallet_outlined,
                  label: 'Wallet & Payments',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  onTap: () {},
                ),
                const Divider(height: 32),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  label: 'Logout',
                  color: Colors.redAccent,
                  onTap: () async {
                    // 🔓 Show confirmation dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Exit Application'),
                        content: const Text(
                          'Are you sure you want to logout and exit the app?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      // ✅ Logout and clear data
                      await ref.read(authNotifierProvider.notifier).logout();

                      if (context.mounted) {
                        // 🚪 Exit app
                        SystemNavigator.pop();
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(currentClientProvider);
    return clientAsync.when(
      data: (client) => Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        color: Theme.of(context).cardColor,
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  (client?.profileImage != null &&
                      client!.profileImage!.isNotEmpty)
                  ? NetworkImage(client.profileImage!)
                  : const AssetImage('images/profile.jpg') as ImageProvider,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    client?.name ?? 'Client Name',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    client?.email ?? 'client@example.com',
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 140),
      error: (_, _) => const SizedBox(height: 140),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor =
        color ?? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    return ListTile(
      leading: Icon(
        icon,
        color: color == Colors.white ? const Color(0xFFFF6B00) : color,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
