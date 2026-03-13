import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/auth_provider.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  double _strength = 0.0;
  String _strengthText = '';
  Color _strengthColor = Colors.grey;

  void _checkStrength(String value) {
    double strength = 0;
    if (value.length >= 8) strength += 0.25;
    if (value.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (value.contains(RegExp(r'[a-z]'))) strength += 0.25;
    if (value.contains(RegExp(r'[0-9!@#\$&*~]'))) strength += 0.25;

    setState(() {
      _strength = strength;
      if (strength <= 0.25) {
        _strengthText = 'WEAK';
        _strengthColor = Colors.red;
      } else if (strength <= 0.5) {
        _strengthText = 'FAIR';
        _strengthColor = Colors.orange;
      } else if (strength <= 0.75) {
        _strengthText = 'GOOD';
        _strengthColor = Colors.blue;
      } else {
        _strengthText = 'STRONG';
        _strengthColor = Colors.green;
      }
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade600;

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
          'Security Settings',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authNotifierProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset, color: Color(0xFFDC2626), size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Update Password',
                    style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ensure your account stays secure by using a strong password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtitleColor, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDark? null : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Current Password', textColor),
                        _buildTextField(
                          controller: _currentPasswordController,
                          hint: 'Enter current password',
                          obscure: _obscureCurrent,
                          toggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('New Password', textColor),
                        _buildTextField(
                          controller: _newPasswordController,
                          hint: 'Enter new password',
                          obscure: _obscureNew,
                          onChanged: _checkStrength,
                          toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: _strength,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'STRENGTH: $_strengthText',
                              style: TextStyle(
                                color: _strengthColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Confirm New Password', textColor),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: 'Confirm new password',
                          obscure: _obscureConfirm,
                          toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleUpdatePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: authState.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Save New Password',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildRequirements(subtitleColor, textColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback toggleObscure,
    required bool isDark,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 20),
          onPressed: toggleObscure,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'This field is required';
        return null;
      },
    );
  }

  Widget _buildRequirements(Color subtitleColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 18),
            const SizedBox(width: 8),
            Text('Password Requirements', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        _buildRequirementItem('Minimum 8 characters long', _newPasswordController.text.length >= 8),
        _buildRequirementItem('One uppercase & one lowercase character', 
          _newPasswordController.text.contains(RegExp(r'[A-Z]')) && _newPasswordController.text.contains(RegExp(r'[a-z]'))),
        _buildRequirementItem('At least one number or special symbol', 
          _newPasswordController.text.contains(RegExp(r'[0-9!@#\$&*~]'))),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? Colors.green : Colors.grey.shade400,
            size: 16,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    if (_strength < 0.75) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please use a stronger password')));
      return;
    }

    try {
      final container = ProviderScope.containerOf(context);
      await container.read(authNotifierProvider.notifier).updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }
}
