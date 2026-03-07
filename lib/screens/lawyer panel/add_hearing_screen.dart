import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:legal_sync/model/hearing_Model.dart';
import 'package:legal_sync/model/case_Model.dart';
import 'package:legal_sync/provider/auth_provider.dart';
import 'package:legal_sync/provider/case_provider.dart';
import 'package:legal_sync/provider/hearing_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddHearingScreen extends ConsumerStatefulWidget {
  const AddHearingScreen({super.key});

  @override
  ConsumerState<AddHearingScreen> createState() => _AddHearingScreenState();
}

class _AddHearingScreenState extends ConsumerState<AddHearingScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCaseId;
  String? _selectedClientId;
  String _hearingType = 'Preliminary Hearing';
  String _modeOfConduct = 'Offline';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _courtRoomCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sendReminder = true;

  final List<String> _hearingTypes = [
    'Preliminary Hearing',
    'Trial',
    'Arraignment',
    'Sentencing',
    'Appeal',
    'Pre-trial Conference',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B00),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B00),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final casesAsync = ref.watch(casesByLawyerProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule Hearing',
          style: TextStyle(
            color: Color(0xFF131D31),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Case Information'),
                    casesAsync.when(
                      data: (cases) {
                        if (cases.isEmpty) {
                          return _buildEmptyCaseInfo();
                        }
                        return _buildCaseDropdown(cases);
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text(
                        'Error loading cases',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Hearing Details'),
                    _buildHearingTypeDropdown(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimePicker(
                            'Date',
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                            Icons.event,
                            () => _selectDate(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateTimePicker(
                            'Time',
                            _selectedTime.format(context),
                            Icons.schedule,
                            () => _selectTime(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Conduct & Location'),
                    _buildConductToggle(),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: _modeOfConduct == 'Offline'
                          ? 'Court Room / Location'
                          : 'Meeting Link (Optional)',
                      hint: _modeOfConduct == 'Offline'
                          ? 'e.g. Room 302, High Court'
                          : 'e.g. Zoom or Google Meet link',
                      controller: _courtRoomCtrl,
                      icon: _modeOfConduct == 'Offline'
                          ? Icons.location_on
                          : Icons.link,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Communication'),
                    _buildReminderSwitch(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Additional Information'),
                    _buildInputField(
                      label: 'Notes',
                      hint:
                          'Special instructions for the client or yourself...',
                      controller: _notesCtrl,
                      maxLines: 4,
                      icon: Icons.notes,
                    ),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitHearing() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    if (_selectedCaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a case first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw 'User not authenticated';

      final hearingDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final hearing = HearingModel(
        hearingId: FirebaseFirestore.instance.collection('dummy').doc().id,
        caseId: _selectedCaseId!,
        hearingDate: hearingDate,
        hearingType: _hearingType,
        courtName: _courtRoomCtrl.text.isNotEmpty ? _courtRoomCtrl.text : null,
        modeOfConduct: _modeOfConduct,
        notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        status: 'scheduled',
        createdBy: user.uid,
        clientId: _selectedClientId,
        createdAt: DateTime.now(),
      );

      if (_sendReminder &&
          _selectedClientId != null &&
          _selectedClientId!.isNotEmpty) {
        await ref
            .read(hearingServiceProvider)
            .createHearingWithReminder(
              hearing: hearing,
              recipientUserIds: [user.uid, _selectedClientId!],
              hoursBefore: 24,
            );
      } else {
        await ref
            .read(hearingStateNotifierProvider.notifier)
            .addHearing(hearing);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Hearing scheduled successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule hearing: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF8E99AF),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCaseDropdown(List<CaseModel> cases) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<CaseModel>(
          decoration: const InputDecoration(border: InputBorder.none),
          hint: const Text('Choose an active case'),
          isExpanded: true,
          validator: (val) => val == null ? 'Please select a case' : null,
          items: cases.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(
                '${c.caseNumber ?? 'No #'} - ${c.clientName ?? 'Unknown'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (CaseModel? val) {
            setState(() {
              _selectedCaseId = val?.caseId;
              _selectedClientId = val?.clientId;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCaseInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Text(
        'You don\'t have any active cases to schedule hearings for.',
        style: TextStyle(fontSize: 14, color: Colors.amber),
      ),
    );
  }

  Widget _buildHearingTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _hearingType,
          isExpanded: true,
          items: _hearingTypes.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(
                val,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) =>
              setState(() => _hearingType = val ?? _hearingTypes.first),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFFFF6B00)),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConductToggle() {
    return Row(
      children: [
        _buildToggleItem('Offline', Icons.location_on_outlined),
        const SizedBox(width: 12),
        _buildToggleItem('Online', Icons.video_camera_front_outlined),
      ],
    );
  }

  Widget _buildToggleItem(String label, IconData icon) {
    final bool isSelected = _modeOfConduct == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _modeOfConduct = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF6B00)
                  : Colors.grey.shade200,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF131D31),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: SwitchListTile(
        title: const Text(
          'Send Reminder to Client',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Notify the client 24 hours before the hearing',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        value: _sendReminder,
        activeColor: const Color(0xFFFF6B00),
        onChanged: (val) => setState(() => _sendReminder = val),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF6B00)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitHearing,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Schedule Hearing Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
