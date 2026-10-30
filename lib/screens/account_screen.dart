import 'package:lungs_assistant_agent/screens/mri_screen.dart';
import 'package:lungs_assistant_agent/screens/auth_screen.dart';
import 'package:lungs_assistant_agent/screens/edit_screen.dart';
import 'package:lungs_assistant_agent/screens/password_screen.dart';
import 'package:lungs_assistant_agent/screens/xray_screen.dart';
import 'package:lungs_assistant_agent/screens/patient_list_screen.dart';
import 'package:lungs_assistant_agent/screens/master_user_list_screen.dart';
import 'package:lungs_assistant_agent/services/auth_service.dart';
import 'package:lungs_assistant_agent/services/session_service.dart';
import 'package:flutter/material.dart';

class AccountScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String role;
  final void Function(String newName)? onNameUpdated;

  const AccountScreen({
    super.key,
    required this.uid,
    required this.name,
    this.role = 'user',
    this.onNameUpdated,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const Color primaryBlue = Color(0xFF2F60CC);

  late String _name;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final authService = AuthService();
    final result = await authService.getUser(widget.uid);
    if (mounted && result['status'] == 'success') {
      final data = result['data'];
      if (data != null && data['name'] != null) {
        final newName = data['name'] as String;
        setState(() => _name = newName);
        widget.onNameUpdated?.call(newName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String cleanRole = widget.role.trim().toLowerCase();
    final bool isMaster = cleanRole == 'master';
    final bool isDokter = cleanRole == 'dokter' || cleanRole == 'doctor';
    final bool canViewPatients = isMaster || isDokter;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black87, width: 5),
                ),
                child: const Icon(
                  Icons.person,
                  size: 110,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              // Nama
              Text(
                _name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 36),

              // Change Password
              _buildButton(
                label: 'Change Password',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordScreen(uid: widget.uid),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Perbandingan CT Scan
              _buildButton(
                label: 'Perbandingan CT Scan',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MriScreen(userUid: widget.uid),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              _buildButton(
                label: 'Perbandingan X-Ray',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => XrayScreen(userUid: widget.uid),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Edit Profile
              _buildButton(
                label: 'Edit Profile',
                onPressed: () async {
                  // Fetch data terbaru sebelum buka edit screen
                  final authService = AuthService();
                  final result = await authService.getUser(widget.uid);
                  if (!mounted) return;

                  if (result['status'] == 'success') {
                    final updatedData =
                        await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          uid: widget.uid,
                          userData: result['data'],
                          // Pass 'user' so master can edit their own full profile.
                          // EditUserRoleScreen is used separately for editing other users' roles.
                          currentUserRole: 'user',
                        ),
                      ),
                    );
                    if (!mounted) return;
                    await _fetchUserData();
                    if (updatedData != null &&
                        updatedData['name'] != null) {
                      final newName = updatedData['name'] as String;
                      setState(() => _name = newName);
                      // Update name in session
                      await SessionService.updateName(newName);
                      widget.onNameUpdated?.call(
                        newName,
                      ); // propagate ke MainScreen
                    }
                  }
                },
              ),

              // List Pasien (Dokter & Master)
              if (canViewPatients) ...[
                const SizedBox(height: 14),
                _buildButton(
                  label: 'List Pasien',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientListScreen(
                          currentUserRole: widget.role,
                        ),
                      ),
                    );
                    if (mounted) {
                      _fetchUserData();
                    }
                  },
                ),
              ],

              // Master User List (Master)
              if (isMaster) ...[
                const SizedBox(height: 14),
                _buildButton(
                  label: 'Master User List',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MasterUserListScreen(
                          currentUserRole: widget.role,
                        ),
                      ),
                    );
                    if (mounted) {
                      _fetchUserData();
                    }
                  },
                ),
              ],

              const SizedBox(height: 14),

              // Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(
                          color: primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await SessionService.clearSession();
              if (context.mounted) {
                Navigator.pop(ctx); // Close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
