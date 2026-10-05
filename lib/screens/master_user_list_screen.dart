import 'package:flutter/material.dart';
import 'package:agent_doctor/services/auth_service.dart';
import 'package:agent_doctor/screens/edit_screen.dart'; // Sesuaikan path jika berbeda

class MasterUserListScreen extends StatefulWidget {
  final String currentUserRole;

  const MasterUserListScreen({super.key, required this.currentUserRole});

  @override
  State<MasterUserListScreen> createState() => _MasterUserListScreenState();
}

class _MasterUserListScreenState extends State<MasterUserListScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final result = await _authService.getAllUsers();

    if (mounted) {
      if (result['status'] == 'success') {
        setState(() {
          _allUsers = result['data'] ?? [];
          _filteredUsers = _allUsers;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal memuat pengguna')),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  void _navigateToEdit(Map<String, dynamic> user) async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          uid: user['uid'],
          userData: user,
          currentUserRole: widget.currentUserRole,
        ),
      ),
    );

    // Refresh daftar jika ada perubahan data
    if (updatedData != null) {
      _fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? const Center(child: Text('Tidak ada pengguna ditemukan.'))
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2F60CC),
                          child: Text(
                            (user['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          user['name'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${user['email'] ?? 'No Email'} • Role: ${user['role'] ?? 'user'}',
                        ),
                        trailing: const Icon(
                          Icons.edit,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onTap: () => _navigateToEdit(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
