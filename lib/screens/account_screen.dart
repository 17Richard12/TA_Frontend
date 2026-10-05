import 'package:agent_doctor/screens/mri_screen.dart';
import 'package:agent_doctor/screens/auth_screen.dart';
import 'package:agent_doctor/screens/edit_screen.dart';
import 'package:agent_doctor/screens/password_screen.dart';
import 'package:agent_doctor/services/auth_service.dart';
import 'package:agent_doctor/services/session_service.dart';
import 'package:flutter/material.dart';

class AccountScreen extends StatefulWidget {
  final String uid;
  final String name;
  final void Function(String newName)? onNameUpdated;

  const AccountScreen({
    super.key,
    required this.uid,
    required this.name,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black87, width: 5),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 120,
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

                  const SizedBox(height: 60),

                  // Change Password
                  _buildButton(
                    label: 'Change Password',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangePasswordScreen(uid: widget.uid),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Perbandingan MRI
                  _buildButton(
                    label: 'Perbandingan MRI',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MriScreen(userUid: widget.uid),
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
                                  currentUserRole: result['data']['role'],
                                ),
                              ),
                            );
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
          ],
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
