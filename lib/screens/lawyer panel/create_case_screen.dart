import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/model/client_Model.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/document_provider.dart';
import 'package:legal_sync/provider/appointment_provider.dart';

class CreateCaseScreen extends ConsumerStatefulWidget {
  const CreateCaseScreen({super.key});

  @override
  ConsumerState<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends ConsumerState<CreateCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _refIdController = TextEditingController();
  final _feeController = TextEditingController(text: '350.00');

  String _billingType = 'Hourly Rate';
  String _estimatedDuration = '1-3 Months';
  String _selectedCaseType = 'Select case type';
  ClientModel? _selectedClient;
  File? _engagementLetter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refIdController.text = _generateReferenceId();
  }

  String _generateReferenceId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    final shortHash = timestamp.substring(timestamp.length - 4);
    return 'REF-${now.year}-$shortHash';
  }

  Future<void> _pickEngagementLetter() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _engagementLetter = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _handleCreateCase() async {
    if (!_formKey.currentState!.validate() || _selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and select a client'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw 'User not authenticated';

      // 1. Generate Case ID upfront
      final caseId = FirebaseFirestore.instance.collection('cases').doc().id;

      String? documentUrl;
      if (_engagementLetter != null) {
        // 2. Upload and Save Document Metadata
        final doc = await ref
            .read(documentServiceProvider)
            .uploadAndSaveDocument(
              file: _engagementLetter!,
              caseId: caseId,
              lawyerId: user.uid,
              uploadedBy: user.uid,
              fileType: _engagementLetter!.path.split('.').last,
              description:
                  'Engagement Letter for Case ${_refIdController.text}',
              tags: ['engagement_letter'],
            );
        documentUrl = doc.fileUrl;
      }

      final newCase = CaseModel(
        caseId: caseId,
        clientId: _selectedClient!.clientId,
        lawyerId: user.uid,
        title: _titleController.text,
        description: _descriptionController.text,
        caseNumber: _refIdController.text,
        caseType: _selectedCaseType != 'Select case type'
            ? _selectedCaseType
            : 'General',
        caseFee: double.tryParse(_feeController.text),
        createdAt: DateTime.now(),
        documentUrls: documentUrl != null ? [documentUrl] : [],
        clientName: _selectedClient!.name,
        status: 'pending',
        isApproved: false,
      );

      await ref.read(caseStateNotifierProvider.notifier).createCase(newCase);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Case created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating case: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF7F9FC);
    final appBarBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Case',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildSection(
                    header: 'Client Name',
                    child: _buildClientSelector(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              header: 'Case Type',
              child: _buildDropdownField(
                value: _selectedCaseType,
                items: [
                  'Select case type',
                  'Divorce Law',
                  'Criminal Law',
                  'Corporate Litigation',
                  'Real Estate Law',
                  'Intellectual Property',
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedCaseType = val!;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              header: 'Case Title / Reference',
              child: _buildInputField(
                hint: 'e.g. Smith v. Johnson Real Estate Dispute',
                controller: _titleController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Title is required' : null,
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader(Icons.description_outlined, 'Case Details'),
            const SizedBox(height: 12),
            _buildSection(
              header: 'Description of Matter',
              child: _buildInputField(
                hint: 'Briefly describe the legal matter and objectives...',
                controller: _descriptionController,
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty
                    ? 'Description is required'
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              header: 'Internal Reference ID',
              child: _buildInputField(
                hint: 'REF-2024-001',
                controller: _refIdController,
                validator: (val) => val == null || val.isEmpty
                    ? 'Reference ID is required'
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              header: 'Estimated Duration',
              child: _buildDropdownField(
                value: _estimatedDuration,
                items: ['1-3 Months', '3-6 Months', '6-12 Months', '1 Year+'],
                onChanged: (val) {
                  setState(() {
                    _estimatedDuration = val!;
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader(Icons.receipt_long_outlined, 'Fee & Agreement'),
            const SizedBox(height: 12),
            _buildSection(
              header: 'Billing Type',
              child: Row(
                children: [
                  _buildBillingButton('Hourly Rate'),
                  const SizedBox(width: 12),
                  _buildBillingButton('Flat Fee'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_billingType == 'Hourly Rate')
              _buildSection(
                header: 'Hourly Rate (USD)',
                child: _buildInputField(
                  hint: '0.00',
                  prefixIcon: Icons.attach_money,
                  controller: _feeController,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Fee is required';
                    if (double.tryParse(val) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 20),
            _buildSection(
              header: 'Engagement Letter',
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.grey.shade400,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload Engagement Letter',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PDF, Word, or Scanned Document',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: OutlinedButton(
                          onPressed: _pickEngagementLetter,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFFF6B00)),
                          ),
                          child: Text(
                            _engagementLetter != null
                                ? _engagementLetter!.path.split('/').last
                                : 'Browse Files',
                            style: const TextStyle(color: Color(0xFFFF6B00)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save as Draft',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateCase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Next Step',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFF6B00), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String header, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.grey.shade400, size: 20)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildClientSelector() {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // ✅ Get only clients with ACCEPTED consultations
    final clientsAsync = ref.watch(
      clientsWithAcceptedConsultationsProvider(user.uid),
    );

    return clientsAsync.when(
      data: (clients) {
        if (clients.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'No accepted consultations yet',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Accept client consultation requests first to create cases.',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return _buildDropdown(clients);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Text(
          'Error loading clients: $err',
          style: TextStyle(color: Colors.red.shade700),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<ClientModel> clients) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClientModel>(
          value: _selectedClient,
          hint: const Text('Select Client'),
          isExpanded: true,
          items: clients.map((client) {
            return DropdownMenuItem<ClientModel>(
              value: client,
              child: Text(client.name),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedClient = val);
          },
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(
                val,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBillingButton(String label) {
    bool isSelected = _billingType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _billingType = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF6B00)
                  : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
