import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/config/admin_theme.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/screens/client%20panel/login_screen.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  int _selectedTabIndex = 0;
  bool _lawyerVerConfig = true;
  bool _publicReviews = true;
  bool _emailNotifs = true;
  bool _pushNotifs = false;
  bool _twoFactor = false;
  bool _isSaving = false;

  final _systemNameCtrl =
      TextEditingController(text: 'LegalSync Pakistan');
  final _supportEmailCtrl =
      TextEditingController(text: 'admin@legalsync.pk');

  @override
  void dispose() {
    _systemNameCtrl.dispose();
    _supportEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveGeneralSettings() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: AdminTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await ref.read(authNotifierProvider.notifier).logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to logout: $e'),
          backgroundColor: AdminTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AdminTheme.cardDark,
        elevation: 0,
        leading: null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AdminTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.settings,
                color: AdminTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'System Settings',
              style: TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Tab Row ─────────────────────────────────────────────────────
          Container(
            color: AdminTheme.cardDark,
            child: Row(
              children: [
                _buildTab(0, 'General', Icons.tune),
                _buildTab(1, 'Notifications', Icons.notifications_none),
                _buildTab(2, 'Security', Icons.lock_outline),
              ],
            ),
          ),
          const Divider(color: AdminTheme.accentDark, height: 1),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_selectedTabIndex == 0) _buildGeneralTab(),
                  if (_selectedTabIndex == 1) _buildNotificationTab(),
                  if (_selectedTabIndex == 2) _buildSecurityTab(),
                  const SizedBox(height: 24),
                  _buildLogoutButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AdminTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AdminTheme.primary : AdminTheme.textTertiary,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AdminTheme.primary : AdminTheme.textTertiary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── GENERAL TAB ─────────────────────────────────────────────────────────
  Widget _buildGeneralTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('APP CONFIGURATION'),
        const SizedBox(height: 16),
        _darkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('System Name'),
              const SizedBox(height: 8),
              _darkTextField(
                controller: _systemNameCtrl,
                hint: 'Enter system name',
                icon: Icons.business,
              ),
              const SizedBox(height: 16),
              _fieldLabel('Support Email'),
              const SizedBox(height: 8),
              _darkTextField(
                controller: _supportEmailCtrl,
                hint: 'Enter support email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveGeneralSettings,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_isSaving ? 'Saving…' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionLabel('FEATURE MANAGEMENT'),
        const SizedBox(height: 16),
        _darkCard(
          child: Column(
            children: [
              _settingToggle(
                title: 'Lawyer Verification',
                subtitle: 'Require Bar Council ID verification',
                value: _lawyerVerConfig,
                onChanged: (val) => setState(() => _lawyerVerConfig = val),
                icon: Icons.verified_user_outlined,
                iconColor: AdminTheme.info,
              ),
              Divider(color: AdminTheme.accentDark, height: 24),
              _settingToggle(
                title: 'Public Reviews',
                subtitle: 'Enable client feedback on profiles',
                value: _publicReviews,
                onChanged: (val) => setState(() => _publicReviews = val),
                icon: Icons.star_outline,
                iconColor: AdminTheme.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionLabel('DATA MANAGEMENT'),
        const SizedBox(height: 16),
        _darkCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AdminTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: AdminTheme.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Backup',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last backup: Yesterday at 11:45 PM',
                      style: const TextStyle(
                        color: AdminTheme.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _showSnack('Backup initiated'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTheme.success,
                  side: const BorderSide(color: AdminTheme.success),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Backup',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── NOTIFICATIONS TAB ────────────────────────────────────────────────────
  Widget _buildNotificationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('NOTIFICATION PREFERENCES'),
        const SizedBox(height: 16),
        _darkCard(
          child: Column(
            children: [
              _settingToggle(
                title: 'Email Notifications',
                subtitle: 'Receive daily activity summaries via email',
                value: _emailNotifs,
                onChanged: (val) {
                  setState(() => _emailNotifs = val);
                  _showSnack(
                    val ? 'Email notifications enabled' : 'Email notifications disabled',
                  );
                },
                icon: Icons.email_outlined,
                iconColor: AdminTheme.info,
              ),
              Divider(color: AdminTheme.accentDark, height: 24),
              _settingToggle(
                title: 'Push Notifications',
                subtitle: 'Receive immediate alerts on new cases',
                value: _pushNotifs,
                onChanged: (val) {
                  setState(() => _pushNotifs = val);
                  _showSnack(
                    val ? 'Push notifications enabled' : 'Push notifications disabled',
                  );
                },
                icon: Icons.notifications_active_outlined,
                iconColor: AdminTheme.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionLabel('ALERT TYPES'),
        const SizedBox(height: 16),
        _darkCard(
          child: Column(
            children: [
              _infoRow(
                Icons.person_add_outlined,
                AdminTheme.statBlue,
                'New User Registrations',
                'Notify when a new lawyer or client registers',
              ),
              Divider(color: AdminTheme.accentDark, height: 20),
              _infoRow(
                Icons.folder_open_outlined,
                AdminTheme.warning,
                'New Case Filed',
                'Notify when a client files a new case',
              ),
              Divider(color: AdminTheme.accentDark, height: 20),
              _infoRow(
                Icons.verified_user_outlined,
                AdminTheme.success,
                'Verification Requests',
                'Notify when a lawyer submits bar council ID',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── SECURITY TAB ─────────────────────────────────────────────────────────
  Widget _buildSecurityTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SECURITY & ACCESS'),
        const SizedBox(height: 16),
        _darkCard(
          child: Column(
            children: [
              _settingToggle(
                title: 'Two-Factor Authentication',
                subtitle: 'Require 2FA for all admin logins',
                value: _twoFactor,
                onChanged: (val) {
                  setState(() => _twoFactor = val);
                  _showSnack(val ? '2FA enabled' : '2FA disabled');
                },
                icon: Icons.security_outlined,
                iconColor: AdminTheme.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionLabel('PASSWORD MANAGEMENT'),
        const SizedBox(height: 16),
        _darkCard(
          child: Column(
            children: [
              _actionRow(
                icon: Icons.lock_reset_outlined,
                iconColor: AdminTheme.warning,
                title: 'Change Master Password',
                subtitle: 'Send reset link to admin email',
                onTap: () => _showSnack('Password reset link sent to your email'),
              ),
              Divider(color: AdminTheme.accentDark, height: 20),
              _actionRow(
                icon: Icons.history_outlined,
                iconColor: AdminTheme.info,
                title: 'Login Activity Log',
                subtitle: 'View recent admin login sessions',
                onTap: () => _showSnack('Login activity log coming soon'),
              ),
              Divider(color: AdminTheme.accentDark, height: 20),
              _actionRow(
                icon: Icons.devices_outlined,
                iconColor: AdminTheme.statPurple,
                title: 'Active Sessions',
                subtitle: 'Manage devices logged into admin panel',
                onTap: () => _showSnack('Active session manager coming soon'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionLabel('DANGER ZONE'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminTheme.danger.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AdminTheme.danger.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AdminTheme.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Irreversible Actions',
                    style: TextStyle(
                      color: AdminTheme.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSnack('System reset coming soon'),
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('Reset System Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.danger,
                    side: const BorderSide(color: AdminTheme.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── LOGOUT BUTTON ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, color: Colors.white, size: 18),
        label: const Text(
          'Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminTheme.danger,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ── SHARED HELPERS ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(text, style: AdminTheme.sectionHeaderStyle());
  }

  Widget _darkCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.accentDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AdminTheme.textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _darkTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AdminTheme.textTertiary, fontSize: 13),
        prefixIcon: Icon(icon, color: AdminTheme.primary, size: 18),
        filled: true,
        fillColor: AdminTheme.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminTheme.accentDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminTheme.accentDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminTheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _settingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AdminTheme.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AdminTheme.primary,
          inactiveThumbColor: AdminTheme.textTertiary,
          inactiveTrackColor: AdminTheme.accentDark,
        ),
      ],
    );
  }

  Widget _infoRow(
    IconData icon,
    Color iconColor,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AdminTheme.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle,
          color: AdminTheme.success,
          size: 18,
        ),
      ],
    );
  }

  Widget _actionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AdminTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AdminTheme.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AdminTheme.cardDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
