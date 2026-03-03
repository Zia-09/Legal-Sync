import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legal_sync/provider/lawyer_provider.dart';
import 'package:legal_sync/services/supabase_service.dart';
import 'dart:io';

class LawyerEditProfileScreen extends ConsumerStatefulWidget {
  const LawyerEditProfileScreen({super.key});

  @override
  ConsumerState<LawyerEditProfileScreen> createState() =>
      _LawyerEditProfileScreenState();
}

class _LawyerEditProfileScreenState
    extends ConsumerState<LawyerEditProfileScreen> {
  bool _isUploading = false;
  final List<String> _specializations = [
    'Corporate Law',
    'Intellectual Property',
    'Litigation',
    'M&A',
    'Taxation',
  ];

  final List<String> _selectedSpecializations = [
    'Corporate Law',
    'Litigation',
    'M&A',
  ];

  Future<void> _pickAndUploadImage(String lawyerId) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Upload to Supabase
      final imageUrl = await supabaseService.uploadFile(
        file: File(image.path),
        path: 'lawyer_profiles/$lawyerId',
      );

      // Update Firestore
      await ref
          .read(lawyerServiceProvider)
          .updateLawyer(
            lawyerId: lawyerId,
            data: {'profileImageUrl': imageUrl},
          );

      // Refresh lawyer data
      ref.invalidate(currentLawyerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Professional photo updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lawyerAsync = ref.watch(currentLawyerProvider);
    return lawyerAsync.when(
      data: (lawyer) => _buildScaffold(lawyer),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      ),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildScaffold(dynamic lawyer) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        (lawyer != null && lawyer.profileImageUrl.isNotEmpty)
                        ? NetworkImage(lawyer.profileImageUrl)
                        : Image.network(
                                'https://i.pravatar.cc/150?img=12',
                              ).image
                              as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploading
                          ? null
                          : () => _pickAndUploadImage(lawyer!.lawyerId),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B00),
                          shape: BoxShape.circle,
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildInputField(
              label: 'FULL NAME',
              hint: 'e.g. Jonathan Sterling',
              controller: TextEditingController(text: lawyer?.name ?? ''),
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: 'EMAIL ADDRESS',
              hint: 'e.g. j.sterling@lawfirm.com',
              controller: TextEditingController(text: lawyer?.email ?? ''),
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: 'STATE BAR NUMBER',
              hint: 'CA-983241',
              controller: TextEditingController(text: 'CA-983241'),
              suffixIcon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'AREA OF SPECIALIZATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._specializations.map((spec) => _buildSpecChip(spec)),
                _buildAddSpecChip(),
              ],
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: 'MOBILE NUMBER',
              hint: '+1 (555) 012-3456',
              controller: TextEditingController(text: lawyer?.phone ?? ''),
            ),
            const SizedBox(height: 20),

            _buildInputField(
              label: 'OFFICE ADDRESS',
              hint: 'Enter your office address',
              controller: TextEditingController(text: lawyer?.location ?? ''),
              maxLines: 3,
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Professional Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B00)),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecChip(String spec) {
    bool isSelected = _selectedSpecializations.contains(spec);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSpecializations.remove(spec);
          } else {
            _selectedSpecializations.add(spec);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B00) : Colors.grey.shade200,
          ),
        ),
        child: Text(
          spec,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAddSpecChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFFF6B00),
          style: BorderStyle.solid,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, color: Color(0xFFFF6B00), size: 16),
          SizedBox(width: 4),
          Text(
            'Add',
            style: TextStyle(
              color: Color(0xFFFF6B00),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
