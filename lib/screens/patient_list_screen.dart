import 'package:flutter/material.dart';
import 'package:lungs_assistant_agent/screens/monthly_report_screen.dart';
import 'package:lungs_assistant_agent/services/auth_service.dart';

class PatientListScreen extends StatefulWidget {
  final String currentUserRole;

  const PatientListScreen({super.key, required this.currentUserRole});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  List<dynamic> _allPatients = [];
  List<dynamic> _filteredPatients = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    final result = await _authService.getPatients();

    if (mounted) {
      if (result['status'] == 'success') {
        setState(() {
          _allPatients = result['data'] ?? [];
          _filterPatients();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal memuat pasien')),
        );
      }
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _allPatients.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  void _navigateToReport(Map<String, dynamic> user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonthlyReportScreen(
          userUid: user['uid'],
          patientName: user['name'] ?? 'No Name',
          currentUserRole: widget.currentUserRole,
        ),
      ),
    );

    // Akan selalu dijalankan saat user kembali ke layar ini
    if (mounted) {
      _fetchPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Daftar Pasien',
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
                hintText: 'Cari nama atau email pasien...',
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
                    onRefresh: _fetchPatients, // Panggil ulang saat di-pull
                    child: _filteredPatients.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(), // Agar selalu bisa di-pull
                                child: Container(
                                  height: constraints.maxHeight,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Tidak ada pasien ditemukan.',
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(), // Memaksa agar tetap bisa di-scroll meskpun item sedikit
                            itemCount: _filteredPatients.length,
                            itemBuilder: (context, index) {
                              final user = _filteredPatients[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green,
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
                                subtitle: Text(user['email'] ?? 'No Email'),
                                trailing: const Icon(
                                  Icons.edit,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onTap: () => _navigateToReport(user),
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
