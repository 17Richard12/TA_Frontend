import 'dart:math';
import 'package:agent_doctor/services/news_service.dart';
import 'package:agent_doctor/services/oxygen_service.dart';
import 'package:agent_doctor/services/youtube_service.dart';
import 'package:agent_doctor/services/songs_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final String name;
  const HomeScreen({super.key, required this.name});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  int _smokeCount = 0;
  double _oxygenLevel = 0.0;
  bool _oxygenLoading = true;

  Future<List<dynamic>>? _newsFuture;
  Future<List<dynamic>>? _videoFuture;
  Future<List<dynamic>>? _songsFuture;

  static const Color scaffoldBg = Colors.white;
  static const Color primaryDark = Color(0xFF1A1A8C);
  static const Color accentBlue = Color(0xFF29B6D8);
  static const Color textSub = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _newsFuture = NewsService.fetchTopHeadlines();
    _loadOxygenLevel();
  }

  Future<void> _loadOxygenLevel() async {
    setState(() => _oxygenLoading = true);
    await OxygenService.requestPermission();
    final level = await OxygenService.getLatestOxygenLevel();
    if (mounted)
      setState(() {
        _oxygenLevel = level;
        _oxygenLoading = false;
      });
  }

  // Warna gauge berdasarkan nilai SpO2
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

            // SMOKE COUNT + OXYGEN LEVEL (side by side)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Smoke Count
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() {
                                  if (_smokeCount > 0) _smokeCount--;
                                }),
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
                                onTap: () => setState(() => _smokeCount++),
                                child: _smallCircleButton(Icons.add),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Oxygen Level
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
                            'Oxygen Level',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _oxygenLoading
                              ? const SizedBox(
                                  height: 80,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: _loadOxygenLevel,
                                  child: SizedBox(
                                    height: 80,
                                    child: CustomPaint(
                                      painter: _OxygenGaugePainter(
                                        value: _oxygenLevel,
                                        color: _oxygenColor(_oxygenLevel),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 32,
                                          ),
                                          child: Text(
                                            _oxygenLevel == 0
                                                ? '--'
                                                : '\${_oxygenLevel.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: _oxygenColor(_oxygenLevel),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          Text(
                            _oxygenStatus(_oxygenLevel),
                            style: TextStyle(
                              fontSize: 12,
                              color: _oxygenColor(_oxygenLevel),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_oxygenLevel == 0) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                await OxygenService.openHealthConnectSettings();
                                await Future.delayed(
                                  const Duration(seconds: 2),
                                );
                                _loadOxygenLevel();
                              },
                              child: const Text(
                                'Grant Permission',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2F60CC),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // TAB
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTab('News', 0),
                  const SizedBox(width: 8),
                  _buildTab('Videos', 1),
                  const SizedBox(width: 8),
                  _buildTab('Songs', 2),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CONTENT
            Expanded(
              child: _selectedTab == 0
                  ? _buildNewsSection()
                  : _selectedTab == 1
                  ? _buildVideoSection()
                  : _buildSongsSection(),
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
          if (index == 1 && _videoFuture == null)
            _videoFuture = YouTubeService.fetchVideos();
          if (index == 2 && _songsFuture == null)
            _songsFuture = SongsService.fetchSongs();
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

  Widget _buildNewsSection() {
    if (_newsFuture == null)
      return const Center(child: Text("Tap News to load data"));
    return FutureBuilder<List<dynamic>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
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

  Widget _buildVideoSection() {
    if (_videoFuture == null)
      return const Center(child: Text("Tap Videos to load data"));
    return FutureBuilder<List<dynamic>>(
      future: _videoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
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

  Widget _buildSongsSection() {
    if (_songsFuture == null)
      return const Center(child: Text("Tap Songs to load data"));
    return FutureBuilder<List<dynamic>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text(snapshot.error.toString()));
        final songsList = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: songsList.length,
          itemBuilder: (context, index) {
            final song = songsList[index];
            return GestureDetector(
              onTap: () {
                if (song['previewUrl'] != null) _openUrl(song['previewUrl']);
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
                child: Row(
                  children: [
                    if (song['artworkUrl100'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          song['artworkUrl100'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song['trackName'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song['artistName'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.play_circle_fill,
                      color: Colors.deepPurple,
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
