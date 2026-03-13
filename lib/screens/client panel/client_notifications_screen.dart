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
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade600;

    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final notificationsAsync = ref.watch(userNotificationsProvider(user.uid));

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
          'Notifications',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFFDC2626)),
            onPressed: () {
              ref
                  .read(notificationStateNotifierProvider.notifier)
                  .markAllAsRead(user.uid);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(isDark),
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) {
                final filteredNotifications = notifications.where((n) {
                  if (_selectedFilter == 'All') return true;
                  if (_selectedFilter == 'Unread') return !n.isRead;
                  if (_selectedFilter == 'Archived') return false; // Mocking archived for now
                  return true;
                }).toList();

                if (filteredNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          color: subtitleColor.withValues(alpha: 0.3),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications found',
                          style: TextStyle(color: subtitleColor, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final today = filteredNotifications.where((n) {
                  final now = DateTime.now();
                  return n.createdAt.day == now.day &&
                      n.createdAt.month == now.month &&
                      n.createdAt.year == now.year;
                }).toList();

                final earlier = filteredNotifications.where((n) {
                  final now = DateTime.now();
                  return !(n.createdAt.day == now.day &&
                      n.createdAt.month == now.month &&
                      n.createdAt.year == now.year);
                }).toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (today.isNotEmpty) ...[
                      _buildSectionHeader('TODAY', subtitleColor),
                      ...today.map((n) => _buildNotificationCard(n, cardColor, textColor, subtitleColor, isDark)),
                    ],
                    if (earlier.isNotEmpty) ...[
                      _buildSectionHeader('EARLIER', subtitleColor),
                      ...earlier.map((n) => _buildNotificationCard(n, cardColor, textColor, subtitleColor, isDark)),
                    ],
                    const SizedBox(height: 40),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFDC2626)),
              ),
              error: (e, st) => Center(
                child: Text('Error: $e', style: TextStyle(color: textColor.withValues(alpha: 0.7))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    final filters = ['All', 'Unread', 'Archived'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFDC2626) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.transparent : Theme.of(context).dividerColor),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: subtitleColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n, Color cardColor, Color textColor, Color subtitleColor, bool isDark) {
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
        color = const Color(0xFFDC2626);
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead ? Theme.of(context).dividerColor : const Color(0xFFDC2626).withValues(alpha: 0.2),
          ),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
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
                        color: const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cardColor,
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
                                ? subtitleColor
                                : textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(n.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: subtitleColor.withValues(alpha: 0.7),
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
                          ? subtitleColor.withValues(alpha: 0.7)
                          : subtitleColor,
                      height: 1.4,
                    ),
                  ),
                  if (isUrgent) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
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
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: subtitleColor.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }
}
