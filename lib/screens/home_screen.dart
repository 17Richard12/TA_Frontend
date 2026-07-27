import 'dart:math';
import 'package:agent_doctor/services/news_service.dart';
import 'package:agent_doctor/services/oxygen_service.dart';
import 'package:agent_doctor/services/youtube_service.dart';
import 'package:agent_doctor/services/smoke_service.dart';
import 'package:agent_doctor/services/activity_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // State untuk Oxygen
  double _oxygenLevel = 0.0;
  bool _oxygenLoading = true;

  Future<List<dynamic>>? _activitiesFuture;
  Future<List<dynamic>>? _newsFuture;
  Future<List<dynamic>>? _videoFuture;

  static const Color scaffoldBg = Colors.white;
  static const Color primaryDark = Color(0xFF1A1A8C);
  static const Color accentBlue = Color(0xFF29B6D8);
  static const Color textSub = Color(0xFF888888);

  String get _todayTimestamp {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    // Memuat Activities pertama kali karena index 0
    _activitiesFuture = ActivityService.getActivities(
      widget.userUid,
      _todayTimestamp,
    );

    _loadOxygenLevel();
    _loadSmokeCount();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
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

            const SizedBox(height: 20),

            // SMOKE COUNT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
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
                                        if (_smokeCount > 0)
                                          _updateSmokeCount(_smokeCount - 1);
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
                                      onTap: () =>
                                          _updateSmokeCount(_smokeCount + 1),
                                      child: _smallCircleButton(Icons.add),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),

            const SizedBox(height: 20),

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

            // CONTENT
            Expanded(
              child: _selectedTab == 0
                  ? _buildActivitiesSection()
                  : _selectedTab == 1
                  ? _buildNewsSection()
                  : _buildVideoSection(),
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
          if (index == 0 && _activitiesFuture == null) {
            _activitiesFuture = ActivityService.getActivities(
              widget.userUid,
              _todayTimestamp,
            );
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
    if (_activitiesFuture == null)
      return const Center(child: Text("Tap Activities to load data"));

    return FutureBuilder<List<dynamic>>(
      future: _activitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError)
          return Center(child: Text(snapshot.error.toString()));

        final activityList = snapshot.data ?? [];

        if (activityList.isEmpty) {
          return const Center(child: Text("Belum ada aktivitas hari ini."));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: activityList.length,
          itemBuilder: (context, index) {
            final activity = activityList[index];
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
                    // TODO: Jika Anda sudah membuat fungsi update status (done/not done) di backend
                    // Silakan panggil fungsinya di sini.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur checklist akan segera tersedia!'),
                      ),
                    );
                  },
                ),
              ),
            );
          },
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
        if (snapshot.hasError)
          return Center(child: Text(snapshot.error.toString()));
        final newsList = snapshot.data ?? [];
        return ListView.builder(
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
                    if (article['urlToImage'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          article['urlToImage'],
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
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
        if (snapshot.hasError)
          return Center(child: Text(snapshot.error.toString()));
        final videoList = snapshot.data ?? [];
        return ListView.builder(
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
