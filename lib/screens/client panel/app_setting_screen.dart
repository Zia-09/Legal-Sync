import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/theme_provider.dart';
import 'package:legal_sync/screens/client%20panel/case_status_view.dart';
import 'home_screen.dart';

import 'messages_screen.dart';
import 'legal_categories_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legal_sync/services/supabase_service.dart';
import 'dart:io';
import 'login_screen.dart';
import 'update_password_screen.dart';
import 'client_edit_profile_screen.dart';
import 'payment_methods_screen.dart';
import 'billing_history_screen.dart';
import 'recent_activity_screen.dart';

class AppSettingScreen extends StatefulWidget {
  const AppSettingScreen({super.key});

  @override
  State<AppSettingScreen> createState() => _AppSettingScreenState();
}

class _AppSettingScreenState extends State<AppSettingScreen> {
  bool _twoFactorAuth = true;
  bool _caseNotifications = true;
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(WidgetRef ref, String clientId) async {
    // ... existing implementation remains mostly the same, just ensured context.mounted checks
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final imageUrl = await supabaseService.uploadFile(
        file: File(image.path),
        path: 'client_profiles/$clientId',
      );

      await ref
          .read(clientServiceProvider)
          .updateClient(clientId: clientId, data: {'profileImage': imageUrl});

      ref.invalidate(currentClientProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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

    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: textColor,
                            size: 16,
                          ),
                        ),
                      ),
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Profile Section
                        Consumer(
                          builder: (context, ref, child) {
                            final clientAsync = ref.watch(
                              currentClientProvider,
                            );
                            return clientAsync.when(
                              data: (client) => Column(
                                children: [
                                  Center(
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFFFF6B00),
                                              width: 2,
                                            ),
                                            image: DecorationImage(
                                              image:
                                                  (client?.profileImage !=
                                                          null &&
                                                      client!
                                                          .profileImage!
                                                          .isNotEmpty)
                                                  ? NetworkImage(
                                                      client.profileImage!,
                                                    )
                                                  : const AssetImage(
                                                          'images/profile.jpg',
                                                        )
                                                        as ImageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: _isUploading
                                                ? null
                                                : () => _pickAndUploadImage(
                                                    ref,
                                                    client!.clientId,
                                                  ),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF6B00),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: scaffoldBg,
                                                  width: 3,
                                                ),
                                              ),
                                              child: _isUploading
                                                  ? const Padding(
                                                      padding: EdgeInsets.all(
                                                        6.0,
                                                      ),
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.edit,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    client?.name ?? 'Loading...',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    client?.email ?? 'Loading...',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              loading: () => const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF6B00),
                                ),
                              ),
                              error: (e, st) => const Text(
                                'Error loading profile',
                                style: TextStyle(color: Colors.red),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 200,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ClientEditProfileScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B00),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // APPEARANCE
                        _buildSectionHeader('APPEARANCE', subtitleColor),
                        const SizedBox(height: 12),
                        _SettingRow(
                          icon: isDark ? Icons.dark_mode : Icons.light_mode,
                          iconBgColor: isDark
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFFFFB800),
                          title: 'Dark Mode',
                          subtitle: isDark
                              ? 'Enable Dark theme'
                              : 'Enable Light theme',
                          cardColor: cardColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          trailing: Switch(
                            value: isDark,
                            onChanged: (isDark) {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .toggleTheme(isDark);
                            },
                            activeThumbColor: const Color(0xFFFF6B00),
                            activeTrackColor: const Color(
                              0xFFFF6B00,
                            ).withValues(alpha: 0.3),
                            inactiveThumbColor: const Color(0xFF9E9E9E),
                            inactiveTrackColor: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // CASE & ACCOUNT
                        _buildSectionHeader('CASE & ACCOUNT', subtitleColor),
                        const SizedBox(height: 12),
                        _SettingRow(
                          icon: Icons.notifications_active_outlined,
                          iconBgColor: const Color(0xFF2563EB),
                          title: 'Case Notifications',
                          subtitle: 'Alerts for case updates and hearings',
                          cardColor: cardColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          trailing: Switch(
                            value: _caseNotifications,
                            onChanged: (val) =>
                                setState(() => _caseNotifications = val),
                            activeThumbColor: const Color(0xFFFF6B00),
                            activeTrackColor: const Color(
                              0xFFFF6B00,
                            ).withValues(alpha: 0.3),
                            inactiveThumbColor: const Color(0xFF9E9E9E),
                            inactiveTrackColor: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        _SettingRow(
                          icon: Icons.description_outlined,
                          iconBgColor: const Color(0xFFFF6B00),
                          title: 'Legal Documents',
                          subtitle: 'Manage your shared files and e-signs',
                          cardColor: cardColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RecentActivityScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // BILLING & PAYMENTS
                        _buildSectionHeader(
                          'BILLING & PAYMENTS',
                          subtitleColor,
                        ),
                        const SizedBox(height: 12),
                        _SettingRow(
                          icon: Icons.credit_card_outlined,
                          iconBgColor: const Color(0xFF7C3AED),
                          title: 'Payment Methods',
                          subtitle: 'Visa ending in **** 4242',
                          cardColor: cardColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
                            );
                          },
                        ),
                        _SettingRow(
                          icon: Icons.receipt_long_outlined,
                          iconBgColor: const Color(0xFF0891B2),
                          title: 'Billing History',
                          subtitle: 'View and download past invoices',
                          cardColor: cardColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BillingHistoryScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // SECURITY
                        _buildSectionHeader('SECURITY', subtitleColor),
                        const SizedBox(height: 12),
                        _SettingRow(
                          icon: Icons.lock_outline,
                          iconBgColor: const Color(0xFFDC2626),
                          title: 'Change Password',
                          subtitle: 'Last updated 3 months ago',
                          cardColor: cardColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
                            );
                          },
                        ),
                        _SettingRow(
                          icon: Icons.security_outlined,
                          iconBgColor: const Color(0xFF059669),
                          title: 'Two-Factor Auth',
                          subtitle: 'Add extra security to your account',
                          cardColor: cardColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          trailing: Switch(
                            value: _twoFactorAuth,
                            onChanged: (val) =>
                                setState(() => _twoFactorAuth = val),
                            activeThumbColor: const Color(0xFFFF6B00),
                            activeTrackColor: const Color(
                              0xFFFF6B00,
                            ).withValues(alpha: 0.3),
                            inactiveThumbColor: const Color(0xFF9E9E9E),
                            inactiveTrackColor: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // LOG OUT
                        GestureDetector(
                          onTap: () async {
                            await ref
                                .read(authNotifierProvider.notifier)
                                .logout();
                            if (!context.mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF6B00,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFFFF6B00,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: Color(0xFFFF6B00),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Log Out',
                                  style: TextStyle(
                                    color: Color(0xFFFF6B00),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color subtitleColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: subtitleColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final navBg = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor;

    const items = ['Home', 'Lawyer', 'Cases', 'Chat', 'Setting'];
    const icons = [
      Icons.home_outlined,
      Icons.balance_outlined,
      Icons.folder_outlined,
      Icons.chat_bubble_outline,
      Icons.settings_outlined,
    ];
    const activeIcons = [
      Icons.home,
      Icons.balance,
      Icons.folder,
      Icons.chat_bubble,
      Icons.settings,
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          final isActive = index == 4;
          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalCategoriesScreen(),
                  ),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CaseStatusScreen()),
                );
              } else if (index == 3) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MessagesScreen()),
                );
              }
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? activeIcons[index] : icons[index],
                    color: isActive
                        ? const Color(0xFFFF6B00)
                        : const Color(0xFF5A5A5A),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[index],
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFFF6B00)
                          : const Color(0xFF5A5A5A),
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;

  const _SettingRow({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconBgColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  color: subtitleColor.withValues(alpha: 0.5),
                  size: 16,
                ),
          ],
        ),
      ),
    );
  }
}
