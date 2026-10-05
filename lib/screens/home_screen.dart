import 'dart:math';
import 'package:agent_doctor/services/news_service.dart';
import 'package:agent_doctor/services/oxygen_service.dart';
import 'package:agent_doctor/services/youtube_service.dart';
import 'package:agent_doctor/services/smoke_service.dart';
import 'package:agent_doctor/services/activity_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  final String name;
  final String userUid;

  const HomeScreen({super.key, required this.name, required this.userUid});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  // State untuk Smoke
  int _smokeCount = 0;
  bool _smokeLoading = true;

  // State untuk Smoke Report (Grafik)
  List<dynamic> _weeklySmokeReport = [];
  bool _reportLoading = true;

  // State untuk Activity Report (Grafik Kanan)
  List<dynamic> _weeklyActivityReport = [];
  bool _activityReportLoading = true;

  // State untuk Oxygen
  double _oxygenLevel = 0.0;
  bool _oxygenLoading = true;

  int _currentStreak = 0;
  bool _streakLoading = true;

  // State untuk Activities (Diubah dari FutureBuilder ke local state agar mendukung UI real-time)
  bool _activitiesLoading = true;
  String? _dailyActivityId;
  List<dynamic> _activityList = [];

  // Future untuk News dan Video
  Future<List<dynamic>>? _newsFuture;
  Future<List<dynamic>>? _videoFuture;

  static const Color scaffoldBg = Colors.white;
  static const Color primaryDark = Color(0xFF1A1A8C);
  static const Color accentBlue = Color(0xFF29B6D8);
  static const Color accentGreen = Colors.green;
  static const Color textSub = Color(0xFF888888);

  String get _todayTimestamp {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  String get _todayTimestampForReport {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
  }

  @override
  void initState() {
    super.initState();
    _loadActivities(); // Load Activities pertama kali
    _loadOxygenLevel();
    _loadSmokeCount();
    _loadWeeklyReport();
    _loadWeeklyActivityReport();
    _loadStreak();
  }

  // --- FETCH DATA ACTIVITIES ---
  Future<void> _loadActivities() async {
    setState(() => _activitiesLoading = true);
    final data = await ActivityService.getDailyActivity(
      widget.userUid,
      _todayTimestamp,
    );

    if (mounted) {
      setState(() {
        if (data != null) {
          _dailyActivityId = data['id'];
          _activityList = data['activities'] ?? [];
        }
        _activitiesLoading = false;
      });
    }
  }

  Future<void> _loadStreak() async {
    setState(() => _streakLoading = true);
    final streak = await ActivityService.getActivityStreak(
      widget.userUid,
      _todayTimestampForReport,
    );
    if (mounted) {
      setState(() {
        _currentStreak = streak;
        _streakLoading = false;
      });
    }
  }

  Future<void> _loadWeeklyReport() async {
    setState(() => _reportLoading = true);
    final report = await SmokeService.getWeeklyReport(
      widget.userUid,
      _todayTimestampForReport,
    );
    if (mounted) {
      setState(() {
        _weeklySmokeReport = report;
        _reportLoading = false;
      });
    }
  }

  Future<void> _loadWeeklyActivityReport() async {
    setState(() => _activityReportLoading = true);
    final report = await ActivityService.getWeeklyActivityReport(
      widget.userUid,
      _todayTimestampForReport,
    );
    if (mounted) {
      setState(() {
        _weeklyActivityReport = report;
        _activityReportLoading = false;
      });
    }
  }

  // --- FUNGSI UPDATE CHECKLIST (OPTIMISTIC UI) ---
  Future<void> _toggleActivityChecklist(int index) async {
    if (_dailyActivityId == null) return;

    final activity = _activityList[index];
    final activityId = activity['id'];
    final currentStatus = activity['done'] ?? false;
    final newStatus = !currentStatus;

    // 1. Optimistic UI Update: Ubah UI duluan agar terasa cepat
    setState(() {
      _activityList[index]['done'] = newStatus;
    });

    // 2. Kirim request ke backend
    final success = await ActivityService.updateActivityChecklist(
      _dailyActivityId!,
      activityId,
      newStatus,
    );

    // 3. Jika gagal, kembalikan ke status awal dan tampilkan error
    if (!success && mounted) {
      setState(() {
        _activityList[index]['done'] = currentStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status aktivitas'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Jika berhasil, refresh grafik aktivitas DAN hitungan streak
      _loadWeeklyActivityReport();
      _loadStreak();
    }
  }

  // --- FUNGSI SMOKE & OXYGEN ---
  Future<void> _loadOxygenLevel() async {
    setState(() => _oxygenLoading = true);
    await OxygenService.requestPermission();
    final level = await OxygenService.getLatestOxygenLevel();
    if (mounted) {
      setState(() {
        _oxygenLevel = level;
        _oxygenLoading = false;
      });
    }
  }

  Future<void> _loadSmokeCount() async {
    setState(() => _smokeLoading = true);
    final count = await SmokeService.getSmokeCount(
      widget.userUid,
      _todayTimestamp,
    );
    if (mounted) {
      setState(() {
        _smokeCount = count;
        _smokeLoading = false;
      });
    }
  }

  Future<void> _updateSmokeCount(int newCount) async {
    final oldCount = _smokeCount;
    setState(() => _smokeCount = newCount);

    final success = await SmokeService.postSmokeCount(
      widget.userUid,
      _todayTimestamp,
      newCount,
    );

    if (!success && mounted) {
      setState(() => _smokeCount = oldCount);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan jumlah rokok ke server')),
      );
    } else {
      _loadWeeklyReport();
    }
  }

  Color _oxygenColor(double value) {
    if (value == 0) return Colors.grey.shade300;
    if (value >= 95) return const Color(0xFF2F60CC);
    if (value >= 90) return Colors.orange;
    return Colors.red;
  }

  String _oxygenStatus(double value) {
    if (value == 0) return 'No Data';
    if (value >= 95) return 'Normal';
    if (value >= 90) return 'Rendah';
    return 'Berbahaya';
  }

  // --- GRAFIK GABUNGAN: SMOKE & ACTIVITY ---
  Widget _buildCombinedChart() {
    // Tunggu sampai kedua API selesai
    if (_reportLoading || _activityReportLoading) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_weeklySmokeReport.isEmpty || _weeklyActivityReport.isEmpty) {
      return const SizedBox.shrink();
    }

    List<BarChartGroupData> barGroups = [];
    // Asumsi kedua data selalu memiliki panjang 7 (7 hari terakhir)
    for (int i = 0; i < 7; i++) {
      final double smokeCount = (_weeklySmokeReport[i]['count'] as num)
          .toDouble();
      final double activityCount = (_weeklyActivityReport[i]['count'] as num)
          .toDouble();

      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4, // Jarak antara batang biru dan hijau
          barRods: [
            // Bar Rokok (Biru)
            BarChartRodData(
              toY: smokeCount,
              color: accentBlue,
              width: 10,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 20, // Batas background abu-abu
                color: Colors.grey.shade100,
              ),
            ),
            // Bar Aktivitas (Hijau)
            BarChartRodData(
              toY: activityCount,
              color: accentGreen,
              width: 10,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 20,
                color: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      height: 175, // Sedikit ditinggikan agar legenda muat
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legenda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  _buildLegend(accentBlue, 'Smoke'),
                  const SizedBox(width: 12),
                  _buildLegend(accentGreen, 'Activities'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String label = rodIndex == 0 ? 'Rokok' : 'Aktivitas';
                      return BarTooltipItem(
                        '${rod.toY.toInt()} $label',
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
                        if (index >= 0 && index < _weeklySmokeReport.length) {
                          String date = _weeklySmokeReport[index]['timestamp'];
                          String dayMonth = date.substring(0, 5);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dayMonth,
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
        ],
      ),
    );
  }

  // Widget Bantuan untuk menampilkan Legenda Warna
  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: textSub,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // Menyamakan dengan tema card lain
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_streakLoading)
            const SizedBox(
              height: 50,
              child: Center(
                child: CircularProgressIndicator(color: accentBlue),
              ),
            )
          else ...[
            Text(
              '$_currentStreak',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87, // Warna teks diubah ke gelap
              ),
            ),
            const Text(
              'Current streak',
              style: TextStyle(
                fontSize: 14,
                color: textSub, // Menggunakan warna abu-abu tema
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Days timeline
          if (!_activityReportLoading && _weeklyActivityReport.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_weeklyActivityReport.length, (index) {
                final data = _weeklyActivityReport[index];
                final bool isDone = (data['count'] as num) > 0;
                final bool isToday = index == _weeklyActivityReport.length - 1;

                final parts = data['timestamp'].split('/');
                final date = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
                final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final weekdayLetter = weekdays[date.weekday - 1];

                return Column(
                  children: [
                    if (isToday && !isDone)
                      const Icon(
                        Icons.arrow_drop_down,
                        color: accentBlue, // Menyesuaikan warna panah
                        size: 24,
                      )
                    else
                      const SizedBox(height: 10),

                    isToday && !isDone
                        ? CustomPaint(
                            painter: _DashedCirclePainter(
                              color: accentBlue,
                            ), // Garis putus-putus
                            child: const SizedBox(width: 36, height: 36),
                          )
                        : Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? accentBlue
                                  : Colors.transparent, // Warna lingkaran aktif
                              border: isDone
                                  ? null
                                  : Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ), // Warna lingkaran kosong
                            ),
                            child: isDone
                                ? const Icon(
                                    Icons.whatshot,
                                    color: Colors.white, // Ikon api putih
                                    size: 20,
                                  )
                                : null,
                          ),
                    const SizedBox(height: 10),
                    Text(
                      weekdayLetter,
                      style: TextStyle(
                        color: isToday
                            ? Colors.black87
                            : Colors.grey, // Teks hari
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }),
            )
          else
            const Center(child: CircularProgressIndicator(color: accentBlue)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
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
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: accentBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        '${widget.name} !',
                        style: const TextStyle(
                          color: accentBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // SMOKE COUNT
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                        child: Column(
                          children: [
                            const Text(
                              'Smoke Count',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _smokeLoading
                                ? const SizedBox(
                                    height: 36,
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (_smokeCount > 0) {
                                            _updateSmokeCount(_smokeCount - 1);
                                          }
                                        },
                                        child: _smallCircleButton(Icons.remove),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        '$_smokeCount',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: () {
                                          // 1. Hapus snackbar sebelumnya (jika user tap berkali-kali dengan cepat)
                                          ScaffoldMessenger.of(
                                            context,
                                          ).clearSnackBars();

                                          // 2. Tampilkan warning
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Row(
                                                children: [
                                                  Icon(
                                                    Icons.warning_amber_rounded,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      'Tunggu dulu! Coba selesaikan daily activities-mu untuk mengalihkan rasa ingin merokok.',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors
                                                  .orange, // Warna peringatan
                                              duration: Duration(seconds: 3),
                                              behavior: SnackBarBehavior
                                                  .floating, // Membuatnya melayang agar lebih terlihat
                                            ),
                                          );

                                          // 3. Smoke count tetap bertambah ke server dan UI
                                          _updateSmokeCount(_smokeCount + 1);
                                        },
                                        child: _smallCircleButton(Icons.add),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // STREAK CARD
                    _buildStreakCard(),

                    const SizedBox(height: 10),

                    // GRAFIK GABUNGAN
                    _buildCombinedChart(),

                    const SizedBox(height: 10),

                    // TAB
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildTab('Activities', 0),
                          const SizedBox(width: 8),
                          _buildTab('News', 1),
                          const SizedBox(width: 8),
                          _buildTab('Videos', 2),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CONTENT TAB
                    _selectedTab == 0
                        ? _buildActivitiesSection()
                        : _selectedTab == 1
                        ? _buildNewsSection()
                        : _buildVideoSection(),

                    const SizedBox(
                      height: 30,
                    ), // Padding bawah agar konten paling bawah tidak tertutup mentok
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallCircleButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: accentBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          if (index == 0 && _activityList.isEmpty && !_activitiesLoading) {
            _loadActivities();
          }
          if (index == 1 && _newsFuture == null) {
            _newsFuture = NewsService.fetchTopHeadlines();
          }
          if (index == 2 && _videoFuture == null) {
            _videoFuture = YouTubeService.fetchVideos();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : textSub),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // --- UI ACTIVITIES ---
  Widget _buildActivitiesSection() {
    if (_activitiesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activityList.isEmpty) {
      return const Center(child: Text("Belum ada aktivitas hari ini."));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _activityList.length,
      itemBuilder: (context, index) {
        final activity = _activityList[index];
        final actText = activity['activity'] ?? 'Aktivitas';
        final isDone = activity['done'] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDone
                    ? Colors.green.withOpacity(0.1)
                    : accentBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check_circle : Icons.local_activity,
                color: isDone ? Colors.green : accentBlue,
              ),
            ),
            title: Text(
              actText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: Checkbox(
              value: isDone,
              activeColor: Colors.green,
              onChanged: (bool? value) {
                // Panggil fungsi toggle yang akan mengurus UI & Request Backend
                _toggleActivityChecklist(index);
              },
            ),
          ),
        );
      },
    );
  }

  // --- UI NEWS ---
  Widget _buildNewsSection() {
    if (_newsFuture == null)
      return const Center(child: Text("Tap News to load data"));

    return FutureBuilder<List<dynamic>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final newsList = snapshot.data ?? [];
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: newsList.length,
          itemBuilder: (context, index) {
            final article = newsList[index];
            return GestureDetector(
              onTap: () {
                if (article['url'] != null) _openUrl(article['url']);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          article['urlToImage'] != null &&
                              article['urlToImage'].toString().isNotEmpty
                          ? Image.network(
                              article['urlToImage'],
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 160,
                                  width: double.infinity,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 160,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 50,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI VIDEOS ---
  Widget _buildVideoSection() {
    if (_videoFuture == null)
      return const Center(child: Text("Tap Videos to load data"));

    return FutureBuilder<List<dynamic>>(
      future: _videoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final videoList = snapshot.data ?? [];
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: videoList.length,
          itemBuilder: (context, index) {
            final video = videoList[index];
            final snippet = video['snippet'];
            final videoId = video['id']['videoId'];
            return GestureDetector(
              onTap: () => _openUrl('https://www.youtube.com/watch?v=$videoId'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (snippet['thumbnails']?['high']?['url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          snippet['thumbnails']['high']['url'],
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      snippet['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snippet['channelTitle'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Custom painter untuk gauge setengah lingkaran
class _OxygenGaugePainter extends CustomPainter {
  final double value; // 0 - 100
  final Color color;

  _OxygenGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.9;
    final radius = size.width * 0.42;
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Background arc (setengah lingkaran)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Foreground arc (berdasarkan nilai)
    final sweep = pi * (value / 100).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      pi,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_OxygenGaugePainter old) =>
      old.value != value || old.color != color;
}

// Custom painter untuk membuat lingkaran putus-putus (dashed outline)
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double dashWidth = 5, dashSpace = 4;
    double circumference = 2 * pi * (size.width / 2);
    int dashCount = (circumference / (dashWidth + dashSpace)).floor();

    double angle = 0;
    double sweepAngle = (dashWidth / circumference) * 2 * pi;
    double spaceAngle = (dashSpace / circumference) * 2 * pi;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        angle,
        sweepAngle,
        false,
        paint,
      );
      angle += sweepAngle + spaceAngle;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
