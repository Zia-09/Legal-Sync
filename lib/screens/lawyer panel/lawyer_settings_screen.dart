import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/provider/theme_provider.dart';
import 'package:legal_sync/screens/lawyer%20panel/all_client_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_edit_profile_screen.dart';
import 'package:legal_sync/screens/lawyer%20panel/lawyer_login_screen.dart';

class LawyerSettingsScreen extends ConsumerStatefulWidget {
  const LawyerSettingsScreen({super.key});

  @override
  ConsumerState<LawyerSettingsScreen> createState() =>
      _LawyerSettingsScreenState();
}

class _LawyerSettingsScreenState extends ConsumerState<LawyerSettingsScreen> {
  bool _emailNotifications = true;

  @override
  Widget build(BuildContext context) {
    final themeModeVal = ref.watch(themeModeProvider);
    final isDark = themeModeVal == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    final user = ref.watch(authStateProvider).value;
    final lawyerAsync = user != null
        ? ref.watch(getLawyerByIdProvider(user.uid))
        : null;
    final lawyer = lawyerAsync?.valueOrNull;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(
              context,
              lawyer,
              cardColor,
              textColor,
              subtitleColor,
            ),
            _buildSectionHeader('ACCOUNT & SECURITY', subtitleColor),
            _buildSettingItem(
              icon: Icons.lock_outline,
              iconBg: Colors.orange.shade50,
              iconColor: Colors.orange.shade700,
              title: 'Login & Security',
              subtitle: 'Manage password and 2FA settings',
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.credit_card_outlined,
              iconBg: Colors.blue.shade50,
              iconColor: Colors.blue.shade700,
              title: 'Billing & Subscriptions',
              subtitle: 'Manage payment methods and invoices',
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.verified_user_outlined,
              iconBg: Colors.green.shade50,
              iconColor: Colors.green.shade700,
              title: 'Credentials & Bar ID',
              subtitle: 'Verified status and license info',
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              onTap: () {},
            ),
            _buildSectionHeader('PREFERENCES', subtitleColor),
            _buildToggleItem(
              icon: Icons.dark_mode_outlined,
              iconBg: Colors.purple.shade50,
              iconColor: Colors.purple.shade700,
              title: 'Dark Mode',
              value: isDark,
              cardColor: cardColor,
              textColor: textColor,
              onChanged: (val) {
                ref.read(themeModeProvider.notifier).toggleTheme(val);
              },
            ),
            _buildToggleItem(
              icon: Icons.notifications_none_outlined,
              iconBg: Colors.amber.shade50,
              iconColor: Colors.amber.shade700,
              title: 'Email Notifications',
              value: _emailNotifications,
              cardColor: cardColor,
              textColor: textColor,
              onChanged: (val) => setState(() => _emailNotifications = val),
            ),
            _buildSectionHeader('SUPPORT', subtitleColor),
            _buildSettingItem(
              icon: Icons.help_outline,
              iconBg: Colors.indigo.shade50,
              iconColor: Colors.indigo.shade700,
              title: 'Help Center',
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.headset_mic_outlined,
              iconBg: Colors.pink.shade50,
              iconColor: Colors.pink.shade700,
              title: 'Contact Support',
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              onTap: () {},
            ),
            const SizedBox(height: 30),
            _buildLogoutButton(context),
            _buildLogoutAllDevicesButton(context),
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 12.0, bottom: 40),
                child: Text(
                  'App Version 2.4.1 (Build 890)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    dynamic lawyer,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final profileImage = lawyer?.profileImage;
    final name = lawyer?.name ?? 'Loading...';
    final specialization = lawyer?.specialization ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFFF6B00),
                backgroundImage:
                    (profileImage != null && profileImage.isNotEmpty)
                    ? NetworkImage(profileImage)
                    : null,
                child: (profileImage == null || profileImage.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LawyerEditProfileScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            specialization,
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LawyerEditProfileScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllClientScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View All Clients',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: textColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: subtitleColor),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: subtitleColor),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required bool value,
    required Color cardColor,
    required Color textColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: textColor,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: const Color(0xFFFF6B00),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          final confirmed = await _showConfirmDialog(
            context,
            title: 'Logout',
            content: 'Are you sure you want to log out?',
          );
          if (confirmed == true && context.mounted) {
            await ref.read(authNotifierProvider.notifier).logout();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LawyerLoginScreen()),
                (route) => false,
              );
            }
          }
        },
        icon: const Icon(Icons.logout, color: Color(0xFFFF6B00), size: 18),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFFF6B00),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutAllDevicesButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          final confirmed = await _showConfirmDialog(
            context,
            title: 'Log out from all devices',
            content:
                'This will invalidate your session on all other devices. You will remain logged in here. Continue?',
          );
          if (confirmed != true) return;

          final user = ref.read(authStateProvider).value;
          if (user == null) return;

          try {
            // Write a globalLogoutTimestamp to Firestore.
            // All other active sessions will detect this and log out.
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'globalLogoutAt': FieldValue.serverTimestamp()});

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All other sessions have been invalidated.'),
                  backgroundColor: Color(0xFFFF6B00),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.devices, color: Colors.red, size: 18),
        label: const Text(
          'Log out from all devices',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
