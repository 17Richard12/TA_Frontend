import 'package:flutter/material.dart';
import 'package:lungs_assistant_agent/screens/main_screen.dart';
import 'package:lungs_assistant_agent/services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String role;

  const OnboardingScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.role,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _smokeController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _historyController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodType;
  bool _isLoading = false;

  @override
  void dispose() {
    _smokeController.dispose();
    _birthController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _phoneController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final payload = {
        "birth": _birthController.text,
        "bloodType": _selectedBloodType,
        "gender": _selectedGender,
        "height": double.tryParse(_heightController.text) ?? 0.0,
        "weight": double.tryParse(_weightController.text) ?? 0.0,
        "phone": _phoneController.text,
        "history": _historyController.text,
        "initial_smoke_count": int.tryParse(_smokeController.text) ?? 0,
      };

      final result = await _authService.submitOnboarding(widget.uid, payload);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['status'] == 'success') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(
                uid: widget.uid,
                name: widget.name,
                role: widget.role,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal menyimpan data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A8C),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lengkapi Profil 📝',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Data ini membantu AI merancang aktivitas harianmu.',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // SMOKE COUNT INITIAL
                      _buildLabel('Jumlah Rokok Hari Ini'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _smokeController,
                        hint: 'Contoh: 5',
                        icon: Icons.smoking_rooms,
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Wajib diisi (isi 0 jika tidak merokok)'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // MEDICAL HISTORY
                      _buildLabel('Riwayat Medis (Opsional)'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _historyController,
                        hint: 'Contoh: Asma, Hipertensi',
                        icon: Icons.medical_services_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // GENDER & BLOOD TYPE
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Gender'),
                                const SizedBox(height: 8),
                                _buildDropdown(
                                  value: _selectedGender,
                                  items: const ['Laki-laki', 'Perempuan'],
                                  hint: 'Pilih',
                                  icon: Icons.person_outline,
                                  onChanged: (v) => setState(
                                    () => _selectedGender = v as String?,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Gol. Darah'),
                                const SizedBox(height: 8),
                                _buildDropdown(
                                  value: _selectedBloodType,
                                  items: const ['A', 'B', 'AB', 'O'],
                                  hint: 'Pilih',
                                  icon: Icons.bloodtype_outlined,
                                  onChanged: (v) => setState(
                                    () => _selectedBloodType = v as String?,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // HEIGHT & WEIGHT
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Tinggi (cm)'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _heightController,
                                  hint: '170',
                                  icon: Icons.height,
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
                                _buildLabel('Berat (kg)'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _weightController,
                                  hint: '65',
                                  icon: Icons.monitor_weight_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E3192),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'MULAI SEKARANG',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF444444),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: const Color(0xFF2E3192), size: 20)
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F6FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required void Function(Object?) onChanged,
  }) {
    return DropdownButtonFormField(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
        prefixIcon: Icon(icon, color: const Color(0xFF2E3192), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F6FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
