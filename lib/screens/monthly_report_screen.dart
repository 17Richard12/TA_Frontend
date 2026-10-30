import 'package:flutter/material.dart';
import 'package:lungs_assistant_agent/services/dashboard_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'patient_report_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  final String userUid;
  final String patientName;
  final String currentUserRole;

  const MonthlyReportScreen({
    super.key,
    required this.userUid,
    required this.patientName,
    required this.currentUserRole,
  });

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  static const Color primaryBlue = Color(0xFF2F60CC);
  bool _isLoading = true;

  DateTime _selectedMonth = DateTime.now();
  Map<String, dynamic>? _reportData;
  Set<String> _availableDatesSet = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Hindari set state loading jika widget sudah tidak aktif
    if (!mounted) return;
    setState(() => _isLoading = true);

    final result = await DashboardService.getMonthlyReport(
      widget.userUid,
      _selectedMonth.year,
      _selectedMonth.month,
    );

    if (mounted) {
      if (result['status'] == 'success') {
        setState(() {
          _reportData = result['data'] as Map<String, dynamic>?;

          // Masukkan array tanggal ke dalam Set agar pencarian di kalender lebih cepat
          final List<dynamic> dates = _reportData?['available_dates'] ?? [];
          _availableDatesSet = dates.map((e) => e.toString()).toSet();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memuat data'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);

    if (_availableDatesSet.contains(dateStr)) {
      // Jika ada data, arahkan ke laporan harian pasien
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientReportScreen(
            patientUid: widget.userUid,
            patientName: widget.patientName,
            currentUserRole: widget.currentUserRole,
            initialDate: selectedDay,
          ),
        ),
      );
      // Fetch ulang data setelah kembali dari PatientReportScreen
      if (mounted) {
        _fetchData();
      }
    } else {
      // Jika kosong, tampilkan pesan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak ada data laporan pada tanggal $dateStr'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedDay(DateTime day, bool isToday) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primaryBlue,
        shape: BoxShape.circle,
        // Berikan border khusus jika hari ini dan ada datanya
        border: isToday ? Border.all(color: Colors.orange, width: 2) : null,
      ),
      child: Text(
        '${day.day}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSmoke = _reportData?['total_smoke_count'] ?? 0;
    final totalActivities = _reportData?['total_activities'] ?? 0;
    final totalChats = _reportData?['total_chats'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Laporan: ${widget.patientName}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(color: primaryBlue),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              color: primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- RINGKASAN METRIK ---
                    Row(
                      children: [
                        _buildSummaryCard(
                          'Aktivitas Selesai',
                          '$totalActivities',
                          Icons.task_alt,
                          Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _buildSummaryCard(
                          'Batang Rokok',
                          '$totalSmoke',
                          Icons.smoking_rooms,
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSummaryCard(
                          'Total Sesi Chat',
                          '$totalChats',
                          Icons.chat_bubble_outline,
                          primaryBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Kalender Laporan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- KALENDER ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _selectedMonth,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        }, // Kunci hanya tampilan bulan
                        headerStyle: const HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                        ),
                        // Pemicu saat pengguna menggeser bulan ke kiri/kanan
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _selectedMonth = focusedDay;
                          });
                          _fetchData(); // Ambil data dari API untuk bulan baru
                        },
                        // Pemicu saat pengguna menekan tanggal
                        onDaySelected: _onDaySelected,
                        // Builder untuk menggambar UI khusus di dalam kalender
                        calendarBuilders: CalendarBuilders(
                          // Override UI default (hari biasa) jika ada datanya
                          defaultBuilder: (context, day, focusedDay) {
                            final dateStr = DateFormat(
                              'yyyy-MM-dd',
                            ).format(day);
                            if (_availableDatesSet.contains(dateStr)) {
                              return _buildHighlightedDay(day, false);
                            }
                            return null;
                          },
                          // Override UI hari ini jika ada datanya
                          todayBuilder: (context, day, focusedDay) {
                            final dateStr = DateFormat(
                              'yyyy-MM-dd',
                            ).format(day);
                            if (_availableDatesSet.contains(dateStr)) {
                              return _buildHighlightedDay(day, true);
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
