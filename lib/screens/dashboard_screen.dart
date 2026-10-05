import 'package:flutter/material.dart';
import 'package:agent_doctor/services/dashboard_service.dart';
import 'package:fl_chart/fl_chart.dart'; // Tambahkan fl_chart

class DashboardScreen extends StatefulWidget {
  final String userUid;

  const DashboardScreen({super.key, required this.userUid});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Palet warna yang disamakan dengan tema utama aplikasi
  static const Color scaffoldBg = Colors.white;
  static const Color primaryDark = Color(0xFF1A1A8C);
  static const Color accentBlue = Color(0xFF29B6D8);
  static const Color textSub = Color(0xFF888888);

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String get _formattedDate {
    return "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await DashboardService.getDashboardData(
      widget.userUid,
      _formattedDate,
    );
    if (mounted) {
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryDark,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // HEADER CUSTOM (TEMA APLIKASI)
            // ==========================================
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: primaryDark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        'Report Summary',
                        style: const TextStyle(
                          color: accentBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // KONTEN BAWAH
            // ==========================================
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: accentBlue),
                    )
                  : _dashboardData == null
                  ? const Center(child: Text('Gagal mengambil data dashboard'))
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final int smokeTotal =
        (_dashboardData!['smoke_count_total'] as num?)?.toInt() ?? 0;
    final int actTotal =
        (_dashboardData!['daily_activities_done_total'] as num?)?.toInt() ?? 0;
    final int chatTotal = (_dashboardData!['chat_total'] as num?)?.toInt() ?? 0;

    final List<dynamic> hourlyGraphRaw =
        _dashboardData!['smoke_hourly_graph'] ?? [];
    final List<dynamic> activitiesRaw =
        _dashboardData!['activities_done_list'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: textSub, size: 20),
              const SizedBox(width: 8),
              Text(
                'Data Tanggal: $_formattedDate',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // SUMMARY CARDS
          Row(
            children: [
              _buildSummaryCard(
                'Rokok',
                smokeTotal.toString(),
                Icons.whatshot,
                accentBlue,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                'Aktivitas',
                actTotal.toString(),
                Icons.local_activity,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                'Chat',
                chatTotal.toString(),
                Icons.chat_bubble_outline,
                primaryDark,
              ),
            ],
          ),
          const SizedBox(height: 32),

          const Text(
            'Grafik Merokok Per Jam',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildHourlyChart(hourlyGraphRaw),
          const SizedBox(height: 32),

          const Text(
            'Aktivitas Diselesaikan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (activitiesRaw.isEmpty)
            const Text(
              'Belum ada aktivitas yang diselesaikan pada tanggal ini.',
              style: TextStyle(color: textSub, fontSize: 14),
            )
          else
            ...activitiesRaw.map((act) => _buildActivityItem(act.toString())),

          const SizedBox(height: 40),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: textSub),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // GRAFIK MENGGUNAKAN FL_CHART
  Widget _buildHourlyChart(List<dynamic> rawData) {
    if (rawData.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'Data grafik tidak tersedia.',
            style: TextStyle(color: textSub),
          ),
        ),
      );
    }

    double maxCount = 1;
    List<BarChartGroupData> barGroups = [];

    // Safety parsing tipe data agar grafik konsisten naik
    for (int i = 0; i < rawData.length; i++) {
      final item = rawData[i];
      final double count = (item['count'] as num?)?.toDouble() ?? 0.0;
      if (count > maxCount) maxCount = count;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              color: count > 0 ? accentBlue : Colors.grey.shade300,
              width: 12,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxCount < 5
                    ? 5
                    : maxCount + 2, // Background batas atas dinamis
                color: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Dibungkus scroll horizontal agar 24 data tidak tergencet/menumpuk
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width:
              rawData.length * 36.0, // Memberi ruang proporsional untuk 24 jam
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxCount < 5 ? 5 : maxCount + 2, // Jarak batas atas grafik
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
                    getTitlesWidget: (double value, TitleMeta meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < rawData.length) {
                        String hourStr = rawData[index]['hour'] ?? '';
                        String hourOnly = hourStr
                            .split(':')
                            .first; // Ambil jam saja ("00", "12")
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            hourOnly,
                            style: const TextStyle(
                              fontSize: 10,
                              color: textSub,
                            ),
                          ),
                        );
                      }
                      return const Text('');
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
    );
  }

  Widget _buildActivityItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
