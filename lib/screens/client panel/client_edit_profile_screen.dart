import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legal_sync/model/client_Model.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/services/supabase_service.dart';
import 'dart:io';

class ClientEditProfileScreen extends ConsumerStatefulWidget {
  const ClientEditProfileScreen({super.key});

  @override
  ConsumerState<ClientEditProfileScreen> createState() => _ClientEditProfileScreenState();
}

class _ClientEditProfileScreenState extends ConsumerState<ClientEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isUploading = false;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _selectedGender;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initializeControllers(ClientModel client) {
    if (_isInitialized) return;
    _nameController.text = client.name;
    _emailController.text = client.email;
    _phoneController.text = client.phone;
    _addressController.text = client.address ?? '';
    _selectedGender = client.gender;
    _isInitialized = true;
  }

  Future<void> _pickAndUploadImage(String clientId) async {
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

      await ref.read(clientServiceProvider).updateClient(
        clientId: clientId,
        data: {'profileImage': imageUrl},
      );

      ref.invalidate(currentClientProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile(ClientModel client) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(clientServiceProvider).updateClient(
        clientId: client.clientId,
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'gender': _selectedGender,
        },
      );

      ref.invalidate(currentClientProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFFFF6B00),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(currentClientProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC);
    final textColor = isDark ? Colors.white : Colors.black87;

    return clientAsync.when(
      data: (client) {
        if (client != null) _initializeControllers(client);
        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: _buildAppBar(context, textColor, appBarBg: isDark ? const Color(0xFF1A1A1A) : Colors.white),
          body: client == null 
              ? const Center(child: Text('Client data not found')) 
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileImage(client, scaffoldBg),
                        const SizedBox(height: 32),
                        _buildTextField(
                          label: 'FULL NAME',
                          controller: _nameController,
                          hint: 'Enter your name',
                          isDark: isDark,
                          validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'EMAIL ADDRESS',
                          controller: _emailController,
                          hint: 'Enter your email',
                          isDark: isDark,
                          readOnly: true, // Typically email is not editable
                          validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'PHONE NUMBER',
                          controller: _phoneController,
                          hint: 'Enter your phone number',
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.isEmpty ? 'Phone is required' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildGenderDropdown(isDark, textColor),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'RESIDENTIAL ADDRESS',
                          controller: _addressController,
                          hint: 'Enter your address',
                          isDark: isDark,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 40),
                        _buildSaveButton(client),
                      ],
                    ),
                  ),
                ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: scaffoldBg,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(child: Text('Error loading profile: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color textColor, {required Color appBarBg}) {
    return AppBar(
      backgroundColor: appBarBg,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Edit Profile',
        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProfileImage(ClientModel client, Color scaffoldBg) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF6B00), width: 2),
              image: DecorationImage(
                image: (client.profileImage != null && client.profileImage!.isNotEmpty)
                    ? NetworkImage(client.profileImage!)
                    : const AssetImage('images/profile.jpg') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: _isUploading ? null : () => _pickAndUploadImage(client.clientId),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00),
                  shape: BoxShape.circle,
                  border: Border.all(color: scaffoldBg, width: 3),
                ),
                child: _isUploading
                    ? const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9E9E9E),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B00)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GENDER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9E9E9E),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              isExpanded: true,
              hint: Text('Select Gender', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400)),
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              items: ['Male', 'Female', 'Other'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedGender = newValue);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ClientModel client) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _saveProfile(client),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
