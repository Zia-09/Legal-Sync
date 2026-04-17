import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:legal_sync/screens/lawyer panel/lawyer_verification_pending_screen.dart';
import 'package:legal_sync/services/supabase_service.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/screens/lawyer panel/lawyer_login_screen.dart';
import 'package:legal_sync/services/verification_service.dart';
import 'package:legal_sync/services/email_service.dart';

class LawyerRegistrationScreen extends ConsumerStatefulWidget {
  const LawyerRegistrationScreen({super.key});

  @override
  ConsumerState<LawyerRegistrationScreen> createState() =>
      _LawyerRegistrationScreenState();
}

class _LawyerRegistrationScreenState
    extends ConsumerState<LawyerRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form Keys
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  // State Variables - Step 1
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // State Variables - Step 2
  final TextEditingController _barCouncilController = TextEditingController();
  String? _selectedExperience;
  String? _selectedSpecialization;
  final TextEditingController _addressController = TextEditingController();

  final List<String> _experienceOptions = [
    '0-2 years',
    '3-5 years',
    '6-10 years',
    '10+ years',
  ];

  final List<String> _specializationOptions = [
    'Criminal Law',
    'Civil Litigation',
    'Corporate Law',
    'Family Law',
    'Real Estate',
    'Other',
  ];

  final TextEditingController _consultationFeeController =
      TextEditingController();

  // State Variables - Step 3
  bool _isFileUploaded = false;
  String? _uploadedFileUrl;
  bool _isUploading = false;
  String? _fileName;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _barCouncilController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_step1FormKey.currentState!.validate()) {
        _goToNextPage();
      }
    } else if (_currentStep == 1) {
      if (_step2FormKey.currentState!.validate()) {
        if (_selectedExperience == null || _selectedSpecialization == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select experience and specialization'),
            ),
          );
          return;
        }
        _goToNextPage();
      }
    } else if (_currentStep == 2) {
      if (!_isFileUploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload an identity document')),
        );
        return;
      }
      // Finish Registration
      _completeRegistration();
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'png',
          'jpeg',
        ], // Removed PDF for OCR simplicity
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploading = true;
        _fileName = result.files.first.name;
      });

      final file = File(result.files.first.path!);

      // 🔹 Step 1: Verify the Card using OCR
      final isValid = await verificationService.verifyLawyerCard(file);

      if (!isValid) {
        setState(() => _isUploading = false);
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Invalid Document'),
              content: const Text(
                'The uploaded image does not appear to be a valid Lawyer Identity Card. '
                'Please ensure you upload a clear photo of your Bar Council membership card.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // 🔹 Step 2: Upload if valid
      final downloadUrl = await supabaseService.uploadFile(
        file: file,
        path: 'lawyer_documents',
      );

      setState(() {
        _uploadedFileUrl = downloadUrl;
        _isFileUploaded = true;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification card verified & uploaded!'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Process failed: $e')));
      }
    }
  }

  void _goToNextPage() {
    setState(() {
      _currentStep++;
    });
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _completeRegistration() async {
    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final name = '$firstName $lastName';
      final email = _emailController.text.trim();

      await ref
          .read(authNotifierProvider.notifier)
          .registerLawyer(
            name: name,
            phone: _phoneController.text.trim(),
            email: email,
            password: _passwordController.text,
            specialization: _selectedSpecialization!,
            experience: _selectedExperience!,
            consultationFee:
                double.tryParse(_consultationFeeController.text) ?? 0.0,
            idCardDocument: _uploadedFileUrl,
          );

      // ✅ Send welcome email via Resend
      await emailService.sendWelcomeEmail(
        email: email,
        name: name,
        role: 'lawyer',
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LawyerVerificationPendingScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isRegistering = authState is AsyncLoading;

    // Determine Appbar title based on step
    String appBarTitle = _currentStep == 0
        ? 'Lawyer Portal'
        : 'Lawyer Registration';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF7F9FC);
    final appBarBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: scaffoldBg, // Light background as in Figma
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: isRegistering ? null : _previousStep,
        ),
        title: Text(
          appBarTitle,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: appBarBg,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // If Step 0, display Hero Image Card
              if (_currentStep == 0) _buildHeroCard(),

              // Minimal padding for steppers
              const SizedBox(height: 16),

              // Stepper Header
              _buildHorizontalStepper(),

              const SizedBox(height: 16),

              // PageView for Forms
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable swipe
                  children: [_buildStep1(), _buildStep2(), _buildStep3()],
                ),
              ),
            ],
          ),
          if (isRegistering)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF131D31), // Dark blue/black as per Figma
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ONBOARDING',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Lawyer Registration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join our elite network of legal professionals and expand your practice.',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalStepper() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          _buildStepIndicator(0, 'Account'),
          _buildStepConnector(0),
          _buildStepIndicator(1, 'Practice'),
          _buildStepConnector(1),
          _buildStepIndicator(2, 'Verification'),
        ],
      ),
    ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    bool isCompleted = _currentStep > stepIndex;
    bool isActive = _currentStep == stepIndex;
    Color primaryColor = const Color(0xFFFF6B00);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive ? primaryColor : Colors.white,
            border: Border.all(
              color: isCompleted || isActive
                  ? primaryColor
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    bool isCompleted = _currentStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        color: isCompleted ? const Color(0xFFFF6B00) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF6B00)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator:
              validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF6B00)),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // --- STEP 1 ---
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Information Header
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'First Name',
              hint: 'e.g. Alexander',
              controller: _firstNameController,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Last Name',
              hint: 'e.g. Hamilton',
              controller: _lastNameController,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Email Address',
              hint: 'alexander@lawfirm.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Phone Number',
              hint: '+1 (555) 000-0000',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Security Header
            Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Create Password',
              hint: '••••••••',
              controller: _passwordController,
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password required';
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Confirm Password',
              hint: '••••••••',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                'Step 1 of 3: Account Creation',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next Step',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LawyerLoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        color: Color(0xFFFF6B00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- STEP 2 ---
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Professional Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide your professional credentials and office details to verify your account.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Bar Council Number',
              hint: 'e.g. BC/12345/2023',
              controller: _barCouncilController,
              suffixIcon: const Icon(Icons.shield_outlined, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Years of Experience',
              hint: 'Select experience',
              value: _selectedExperience,
              items: _experienceOptions,
              onChanged: (val) {
                setState(() {
                  _selectedExperience = val;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Primary Specialization',
              hint: 'Select your niche',
              value: _selectedSpecialization,
              items: _specializationOptions,
              onChanged: (val) {
                setState(() {
                  _selectedSpecialization = val;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Office Address',
              hint: 'Enter your full office address...',
              controller: _addressController,
              maxLines: 4,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      side: const BorderSide(color: Color(0xFFFF6B00)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFFF6B00),
                      size: 18,
                    ),
                    label: const Text(
                      'Back',
                      style: TextStyle(color: Color(0xFFFF6B00)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Next Step',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- STEP 3 ---
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF131D31),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identity Verification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please provide your professional identification to access the legal tech platform features.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Advocate Identity Card',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadFile,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isFileUploaded
                      ? const Color(0xFFFF6B00)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  if (_isUploading)
                    const CircularProgressIndicator(color: Color(0xFFFF6B00))
                  else
                    Icon(
                      _isFileUploaded
                          ? Icons.check_circle_outline
                          : Icons.cloud_upload_outlined,
                      color: const Color(0xFFFF6B00),
                      size: 48,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _isUploading
                        ? 'Uploading...'
                        : _isFileUploaded
                        ? 'File Uploaded'
                        : 'Select identity document',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload JPG, PNG, or PDF (Max 5MB)',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _pickAndUploadFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isFileUploaded ? 'Change File' : 'Choose File',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.insert_drive_file_outlined,
                    color: Color(0xFFFF6B00),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName ??
                            (_isFileUploaded
                                ? 'identity_document.pdf'
                                : 'No file selected yet'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isUploading
                            ? 'STATUS: UPLOADING...'
                            : _isFileUploaded
                            ? 'STATUS: READY TO UPLOAD'
                            : 'STATUS: WAITING FOR UPLOAD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isUploading
                              ? Colors.orange
                              : _isFileUploaded
                              ? Colors.green
                              : Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your advocate identity card will be verified by our admin team before account activation. This usually takes 24-48 hours.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    side: const BorderSide(color: Color(0xFFFF6B00)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFFFF6B00),
                    size: 18,
                  ),
                  label: const Text(
                    'Back',
                    style: TextStyle(color: Color(0xFFFF6B00)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Complete',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
