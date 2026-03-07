import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/provider/notification_provider.dart';
import 'package:legal_sync/model/notification_model.dart';
import 'package:intl/intl.dart';

class ClientNotificationsScreen extends ConsumerStatefulWidget {
  const ClientNotificationsScreen({super.key});

  @override
  ConsumerState<ClientNotificationsScreen> createState() =>
      _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState
    extends ConsumerState<ClientNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final notificationsAsync = ref.watch(userNotificationsProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFFFF6B00)),
            onPressed: () {
              ref
                  .read(notificationStateNotifierProvider.notifier)
                  .markAllAsRead(user.uid);
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    color: Colors.grey.shade800,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final today = notifications.where((n) {
            final now = DateTime.now();
            return n.createdAt.day == now.day &&
                n.createdAt.month == now.month &&
                n.createdAt.year == now.year;
          }).toList();

          final earlier = notifications.where((n) {
            final now = DateTime.now();
            return !(n.createdAt.day == now.day &&
                n.createdAt.month == now.month &&
                n.createdAt.year == now.year);
          }).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            physics: const BouncingScrollPhysics(),
            children: [
              if (today.isNotEmpty) ...[
                _buildSectionHeader('TODAY'),
                ...today.map((n) => _buildNotificationCard(n)),
              ],
              if (earlier.isNotEmpty) ...[
                _buildSectionHeader('EARLIER'),
                ...earlier.map((n) => _buildNotificationCard(n)),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
        error: (e, st) => Center(
          child: Text('Error: $e', style: TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B6B6B),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n) {
    bool isUrgent = n.type == 'urgent' || n.type == 'URGENT';
    IconData icon;
    Color color;

    switch (n.type.toLowerCase()) {
      case 'urgent':
        icon = Icons.priority_high;
        color = Colors.red;
        break;
      case 'litigation':
      case 'case':
        icon = Icons.description_outlined;
        color = Colors.blue;
        break;
      case 'message':
      case 'chat':
        icon = Icons.chat_bubble_outline;
        color = Colors.green;
        break;
      case 'calendar':
      case 'hearing':
        icon = Icons.calendar_today_outlined;
        color = Colors.orange;
        break;
      case 'payment':
        icon = Icons.monetization_on_outlined;
        color = Colors.teal;
        break;
      default:
        icon = Icons.notifications_none;
        color = const Color(0xFFFF6B00);
    }

    return GestureDetector(
      onTap: () {
        if (!n.isRead) {
          ref
              .read(notificationStateNotifierProvider.notifier)
              .markAsRead(n.notificationId);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead ? const Color(0xFF252525) : const Color(0xFF333333),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (!n.isRead)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B00),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1A1A1A),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: n.isRead
                                ? Colors.grey.shade400
                                : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(n.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: n.isRead
                          ? Colors.grey.shade500
                          : Colors.grey.shade400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isUrgent) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'URGENT',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          n.type.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFF333333), size: 20),
          ],
        ),
      ),
    );
  }
}
