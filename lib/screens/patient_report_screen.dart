import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lungs_assistant_agent/services/auth_service.dart';
import 'package:lungs_assistant_agent/screens/edit_screen.dart';

class PatientReportScreen extends StatefulWidget {
  final String patientUid;
  final String patientName;
  final String currentUserRole;
  final DateTime? initialDate;
  const PatientReportScreen({
    super.key,
    required this.patientUid,
    required this.patientName,
    required this.currentUserRole,
    this.initialDate,
  });

  @override
  State<PatientReportScreen> createState() => _PatientReportScreenState();
}

class _PatientReportScreenState extends State<PatientReportScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  late DateTime _selectedDate;
  Map<String, dynamic>? _reportData;
  String _errorMessage = '';

  static const Color primaryBlue = Color(0xFF2F60CC);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _fetchReport();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final dateStr = _formatDate(_selectedDate);
    final result = await _authService.getPatientDailyReport(
      widget.patientUid,
      dateStr,
    );

    if (mounted) {
      if (result['status'] == 'success') {
        setState(() {
          _reportData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat laporan.';
          _isLoading = false;
        });
      }
    }
  }

  void _changeDate(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    _fetchReport();
  }

  void _navigateToEditProfile() async {
    final profileData = _reportData?['patient_data'];
    if (profileData == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          uid: widget.patientUid,
          userData: profileData,
          currentUserRole: widget.currentUserRole,
        ),
      ),
    );

    // Refresh laporan saat kembali dari EditProfileScreen
    if (mounted) {
      _fetchReport();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: primaryBlue)),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchReport();
    }
  }

  // ==============================
  // FUNGSI CRUD AKTIVITAS (UI)
  // ==============================
  void _showActivityDialog({String? activityId, String? currentActivity}) {
    final TextEditingController actController = TextEditingController(
      text: currentActivity ?? '',
    );
    final bool isEdit = activityId != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Aktivitas' : 'Tambah Aktivitas'),
          content: TextField(
            controller: actController,
            decoration: const InputDecoration(
              hintText: 'Misal: Olahraga lari 10 menit',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = actController.text.trim();
                if (val.isEmpty) return;
                Navigator.pop(context); // Tutup dialog

                setState(() => _isLoading = true);

                final dateStr = _formatDate(_selectedDate);
                if (isEdit) {
                  await _authService.editActivity(
                    widget.patientUid,
                    activityId,
                    dateStr,
                    val,
                  );
                } else {
                  await _authService.addActivity(
                    widget.patientUid,
                    dateStr,
                    val,
                  );
                }
                _fetchReport(); // Refresh layar setelah simpan
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String activityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Aktivitas?'),
        content: const Text('Aktivitas ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              await _authService.deleteActivity(
                widget.patientUid,
                activityId,
                _formatDate(_selectedDate),
              );
              _fetchReport();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.patientName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  )
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _buildReportContent(),
          ),
        ],
      ),
      // Tombol Mengambang (Floating Action Button) untuk Menambah Aktivitas
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActivityDialog(),
        backgroundColor: primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Aktivitas', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black87),
            onPressed: () => _changeDate(-1),
          ),
          GestureDetector(
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: primaryBlue),
                const SizedBox(width: 8),
                Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.black87),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    if (_reportData == null) return const SizedBox();

    final profile = _reportData!['patient_data'] ?? {};
    final activities = _reportData!['activities_list'] as List<dynamic>? ?? [];
    final List<dynamic> hourlyGraph = _reportData!['smoke_hourly_graph'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        80,
      ), // Tambah padding bawah untuk menghindari FAB
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profil Medis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _navigateToEditProfile,
                icon: const Icon(Icons.edit_note, color: primaryBlue, size: 26),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildInfoRow('Email', profile['email'] ?? '-'),
                _buildInfoRow('Gender', profile['gender'] ?? '-'),
                _buildInfoRow('Gol. Darah', profile['bloodType'] ?? '-'),
                _buildInfoRow(
                  'Tinggi / Berat',
                  '${profile['height'] ?? '-'} cm / ${profile['weight'] ?? '-'} kg',
                ),
                _buildInfoRow('Riwayat Sakit', profile['history'] ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Ringkasan Harian',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Rokok',
                  '${_reportData!['total_smoke']} Batang',
                  Icons.smoking_rooms,
                  Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Aktivitas',
                  '${_reportData!['total_activity_done']} / ${_reportData!['total_activity']} Selesai',
                  Icons.directions_run,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ==========================================
          // GRAFIK MEROKOK PER JAM
          // ==========================================
          const Text(
            'Grafik Merokok Per Jam',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildHourlyChart(hourlyGraph, primaryBlue),
          const SizedBox(height: 20),

          const Text(
            'Daftar Aktivitas Harian',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          activities.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Belum ada aktivitas di tanggal ini.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final act = activities[index];
                    final isDone = act['done'] == true;
                    final actId = act['id'] ?? ''; // Ambil ID dari backend

                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isDone
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isDone ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          act['activity'] ?? '',
                          style: TextStyle(
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone ? Colors.grey : Colors.black87,
                          ),
                        ),
                        // Tambahkan fitur aksi menggunakan PopupMenuButton
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showActivityDialog(
                                activityId: actId,
                                currentActivity: act['activity'],
                              );
                            } else if (value == 'delete') {
                              _confirmDelete(actId);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ============================================================
  // GRAFIK MEROKOK PER JAM (PATIENT REPORT)
  // ============================================================
  Widget _buildHourlyChart(List<dynamic> rawData, Color barColor) {
    if (rawData.isEmpty ||
        rawData.every((e) => ((e['count'] as num?) ?? 0) == 0)) {
      return Container(
        height: 240, // Tinggi dibuat sama persis dengan saat ada data
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'Data grafik tidak tersedia pada tanggal ini.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    double maxCount = 1;
    for (int i = 0; i < rawData.length; i++) {
      final double count = (rawData[i]['count'] as num?)?.toDouble() ?? 0.0;
      if (count > maxCount) maxCount = count;
    }

    // Kunci nilai max Y agar proporsi background abu-abu konsisten
    final double maxYValue = maxCount < 5 ? 5.0 : maxCount + 2.0;

    final List<BarChartGroupData> barGroups = List.generate(rawData.length, (
      i,
    ) {
      final double count = (rawData[i]['count'] as num?)?.toDouble() ?? 0.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: count,
            color: count > 0 ? barColor : Colors.grey.shade300,
            width: 16, // Ketebalan bar dikunci
            borderRadius: BorderRadius.circular(8),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxYValue, // Pastikan background penuh sampai atas
              color: Colors.grey.shade100,
            ),
          ),
        ],
      );
    });

    return Container(
      height: 240, // Kunci tinggi statis
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Container(
            width:
                rawData.length *
                46.0, // Jarak antar batang dikunci secara matematis
            padding: const EdgeInsets.only(
              top: 24,
              bottom: 8,
              left: 16,
              right: 16,
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment
                    .spaceEvenly, // Jarak dibagikan secara merata
                maxY: maxYValue,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} batang',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize:
                          30, // KUNCI AREA TEKS agar batang tidak mengecil/memanjang sendiri
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.toInt();
                        if (index >= 0 && index < rawData.length) {
                          final String hourStr =
                              rawData[index]['hour'] as String? ?? '';
                          final String hourOnly = hourStr.split(':').first;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              hourOnly,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
