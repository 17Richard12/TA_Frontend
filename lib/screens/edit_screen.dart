import 'package:agent_doctor/services/auth_service.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> userData;
  final String currentUserRole;

  const EditProfileScreen({
    super.key,
    required this.uid,
    required this.userData,
    required this.currentUserRole,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color primaryBlue = Color(0xFF2F60CC);

  final authService = AuthService();
  bool _isLoading = false;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bloodTypeController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _historySicknessController;

  DateTime? _dateOfBirth;
  String? _selectedGender;
  String? _selectedRole;

  final List<String> _genderOptions = ['male', 'female'];
  final List<String> _roleOptions = ['user', 'dokter'];

  @override
  void initState() {
    super.initState();
    final d = widget.userData;

    _nameController = TextEditingController(text: d['name'] ?? '');
    _phoneController = TextEditingController(text: d['phone'] ?? '');
    _bloodTypeController = TextEditingController(text: d['bloodType'] ?? '');
    _weightController = TextEditingController(
      text: d['weight'] != null && d['weight'] != 0 ? '${d['weight']}' : '',
    );
    _heightController = TextEditingController(
      text: d['height'] != null && d['height'] != 0 ? '${d['height']}' : '',
    );
    _historySicknessController = TextEditingController(
      text: d['history'] ?? '',
    );

    // Parse birth date jika ada
    if (d['birth'] != null && d['birth'].toString().isNotEmpty) {
      try {
        _dateOfBirth = DateTime.parse(d['birth']);
      } catch (_) {}
    }

    // Gender
    final g = d['gender']?.toString().toLowerCase();
    if (g == 'male' || g == 'female') _selectedGender = g;

    final r = d['role']?.toString().toLowerCase();
    if (_roleOptions.contains(r)) {
      _selectedRole = r;
    } else {
      _selectedRole = 'user'; // Fallback
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bloodTypeController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _historySicknessController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: primaryBlue)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Format ke YYYY-MM-DD untuk backend
  String? _toIsoDate(DateTime? date) {
    if (date == null) return null;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);
    try {
      final profileData = <String, dynamic>{};

      if (_nameController.text.trim().isNotEmpty)
        profileData['name'] = _nameController.text.trim();
      if (_phoneController.text.trim().isNotEmpty)
        profileData['phone'] = _phoneController.text.trim();
      if (_bloodTypeController.text.trim().isNotEmpty)
        profileData['bloodType'] = _bloodTypeController.text.trim();
      if (_weightController.text.trim().isNotEmpty)
        profileData['weight'] = double.tryParse(_weightController.text.trim());
      if (_heightController.text.trim().isNotEmpty)
        profileData['height'] = double.tryParse(_heightController.text.trim());
      if (_historySicknessController.text.trim().isNotEmpty)
        profileData['history'] = _historySicknessController.text.trim();
      if (_selectedGender != null) profileData['gender'] = _selectedGender;
      if (_dateOfBirth != null) profileData['birth'] = _toIsoDate(_dateOfBirth);
      if (_selectedRole != null && (widget.currentUserRole == 'master')) {
        profileData['role'] = _selectedRole;
      }

      final result = await authService.editAccount(widget.uid, profileData);

      if (mounted) {
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(
            context,
            result['data'],
          ); // return data terbaru ke screen sebelumnya
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update profile.'),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canEditRole = widget.currentUserRole == 'master';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Name'),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Enter your name',
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Phone'),
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'Enter your phone number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Date Of Birth'),
                    _buildDatePicker(
                      value: _formatDate(_dateOfBirth),
                      hint: 'Select date of birth',
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),

                    if (canEditRole) ...[
                      _buildLabel('Role'),
                      _buildRoleDropdown(),
                      const SizedBox(height: 16),
                    ],

                    // Gender & Blood Type
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [_buildLabel('Gender'), _buildDropdown()],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Blood Type'),
                              _buildTextField(
                                controller: _bloodTypeController,
                                hint: 'e.g. A',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weight & Height
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Weight'),
                              _buildTextField(
                                controller: _weightController,
                                hint: 'kg',
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Height'),
                              _buildTextField(
                                controller: _heightController,
                                hint: 'cm',
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('History Sickness'),
                    _buildTextField(
                      controller: _historySicknessController,
                      hint: 'Enter history of sickness',
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black87, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black87, width: 1.5),
        ),
        child: Text(
          value.isEmpty ? hint : value,
          style: TextStyle(
            fontSize: 15,
            color: value.isEmpty ? Colors.black45 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black87, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          hint: const Text(
            'Select',
            style: TextStyle(color: Colors.black45, fontSize: 15),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
          items: _genderOptions
              .map(
                (g) => DropdownMenuItem(
                  value: g,
                  child: Text(g, style: const TextStyle(fontSize: 15)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedGender = value),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black87, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          hint: const Text(
            'Select Role',
            style: TextStyle(color: Colors.black45, fontSize: 15),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
          items: _roleOptions
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(r, style: const TextStyle(fontSize: 15)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedRole = value),
        ),
      ),
    );
  }
}
