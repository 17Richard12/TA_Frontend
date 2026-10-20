import 'package:flutter/material.dart';
import 'package:agent_doctor/services/auth_service.dart';
import 'patient_report_screen.dart';

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
          _filterPatients(); // <--- Pastikan pakai fungsi filter ini, JANGAN _filteredPatients = _allPatients;
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
        builder: (context) => PatientReportScreen(
          patientUid: user['uid'],
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
                : _filteredPatients.isEmpty
                ? const Center(child: Text('Tidak ada pasien ditemukan.'))
                : ListView.builder(
                    itemCount: _filteredPatients.length,
                    itemBuilder: (context, index) {
                      final user = _filteredPatients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors
                              .green, // Bedakan warna avatar untuk tab pasien
                          child: Text(
                            (user['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          user['name'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
        ],
      ),
    );
  }
}
