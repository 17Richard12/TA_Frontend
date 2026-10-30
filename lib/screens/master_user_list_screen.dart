import 'package:flutter/material.dart';
import 'package:lungs_assistant_agent/services/auth_service.dart';
import 'package:lungs_assistant_agent/screens/edit_role_screen.dart';

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
          _filterUsers(); // Pastikan _filterUsers dipanggil, jangan langsung overwrite _filteredUsers
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserRoleScreen(
          uid: user['uid'],
          userData: user,
          currentUserRole: widget.currentUserRole,
        ),
      ),
    );

    // Refresh daftar jika ada perubahan data
    if (mounted) {
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
        iconTheme: const IconThemeData(color: Colors.black87),
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
                // Tambahkan RefreshIndicator di sini
                : RefreshIndicator(
                    onRefresh: _fetchUsers,
                    child: _filteredUsers.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(), // Selalu bisa ditarik
                                child: Container(
                                  height: constraints.maxHeight,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Tidak ada pengguna ditemukan.',
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(), // Selalu bisa ditarik
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${user['email'] ?? 'No Email'}\nRole: ${user['role'] ?? 'user'}',
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
          ),
        ],
      ),
    );
  }
}
