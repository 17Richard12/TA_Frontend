import 'package:lungs_assistant_agent/services/auth_service.dart';
import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String uid;

  const ChangePasswordScreen({super.key, required this.uid});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const Color primaryBlue = Color(0xFF2F60CC);

  final authService = AuthService();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateStrongPassword(String password) {
    if (password.length < 8) {
      return 'Password minimal 8 karakter.';
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(password)) {
      return 'Password harus mengandung minimal 1 huruf besar.';
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(password)) {
      return 'Password harus mengandung minimal 1 huruf kecil.';
    }
    if (!RegExp(r'(?=.*[0-9])').hasMatch(password)) {
      return 'Password harus mengandung minimal 1 angka.';
    }
    return null;
  }

  Future<void> _onSave() async {
    final currentPassword = _currentPasswordController.text;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (currentPassword.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnackbar('Harap isi semua kolom password.');
      return;
    }
    if (password != confirm) {
      _showSnackbar('Konfirmasi password baru tidak cocok.');
      return;
    }
    final validationError = _validateStrongPassword(password);
    if (validationError != null) {
      _showSnackbar(validationError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await authService.changePassword(
        widget.uid,
        currentPassword,
        password,
      );
      if (mounted) {
        if (result['status'] == 'success') {
          _showSnackbar('Password berhasil diubah.');
          Navigator.pop(context);
        } else {
          _showSnackbar(result['message'] ?? 'Gagal mengubah password.');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                'Change Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // Form
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Current Password'),
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      hint: 'Masukkan password saat ini',
                      obscure: _obscureCurrent,
                      onToggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('New Password'),
                    _buildPasswordField(
                      controller: _passwordController,
                      hint: 'Min 8 karakter, huruf besar, kecil & angka',
                      obscure: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Confirm Password'),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      hint: 'Ulangi password baru',
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),

                    const Spacer(),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black87, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          border: InputBorder.none,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.black45,
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ),
    );
  }
}
