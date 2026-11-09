import 'package:flutter/material.dart';
import 'package:lungs_assistant_agent/services/session_service.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'hospital_screen.dart';
import 'history_screen.dart';
import 'dashboard_screen.dart';
import 'account_screen.dart';

class MainScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String role; // Parameter role

  const MainScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.role, // Wajib diisi dari layar Login
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late String _name;

  String? _chatSessionId;
  String _chatSessionName = 'New Chat';

  // Counter refresh per tab agar memicu fetch data ulang saat tab dibuka
  int _homeRefreshKey = 0;
  int _hospitalRefreshKey = 0;
  int _historyRefreshKey = 0;
  int _reportRefreshKey = 0;
  int _accountRefreshKey = 0;

  static const Color primaryBlue = Color(0xFF2F60CC);

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowAppTour();
    });
  }

  Future<void> _checkAndShowAppTour({bool force = false}) async {
    final seen = await SessionService.hasSeenAppTour(widget.uid);
    if (!seen || force) {
      await SessionService.setAppTourSeen(widget.uid);
      if (!mounted) return;
      _showAppTourBottomSheet();
    }
  }

  void _showAppTourBottomSheet() {
    int stepIndex = 0;

    final steps = [
      {
        'icon': Icons.home_rounded,
        'badge': 'Langkah 1 dari 3 • Tab Home',
        'title': 'Pantau Kesehatan & Smoke Count di Home',
        'desc':
            'Di halaman Home, kamu bisa mencatat jumlah rokok harian, memantau batas rendah & batas tinggi merokok, melihat grafik mingguan, serta menjaga streak harianmu.',
        'tabIndex': 0,
      },
      {
        'icon': Icons.task_alt_rounded,
        'badge': 'Langkah 2 dari 3 • Tab Activities',
        'title': 'Selesaikan Daily Activities Pengalih Rokok',
        'desc':
            'Pada sub-tab "Activities" di bagian bawah halaman Home, centang rutinitas sehat yang direkomendasikan AI & Dokter setiap hari untuk mengalihkan keinginan merokok.',
        'tabIndex': 0,
      },
      {
        'icon': Icons.medical_information_rounded,
        'badge': 'Langkah 3 dari 3 • Perbandingan MRI/CT Scan & X-Ray',
        'title': 'Analisis Perbandingan X-Ray & CT Scan',
        'desc':
            'Buka tab Account lalu pilih menu "Perbandingan X-Ray" atau "Perbandingan CT Scan". Klik area gambar untuk mengunggah citra medis, lalu tekan tombol "Start Analysis" untuk melihat hasil analisis AI.',
        'tabIndex': 5,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final step = steps[stepIndex];
            final isLast = stepIndex == steps.length - 1;

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      step['badge'] as String,
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A8C).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      size: 38,
                      color: const Color(0xFF1A1A8C),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    step['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    step['desc'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      steps.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == stepIndex ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == stepIndex
                              ? primaryBlue
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _onTabTapped(0);
                        },
                        child: const Text(
                          'Lewati',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (stepIndex > 0)
                        OutlinedButton(
                          onPressed: () {
                            final prevIdx = stepIndex - 1;
                            final targetTab = steps[prevIdx]['tabIndex'] as int;
                            _onTabTapped(targetTab);
                            setModalState(() => stepIndex = prevIdx);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryBlue,
                            side: const BorderSide(color: primaryBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Kembali'),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (isLast) {
                            Navigator.pop(ctx);
                            _onTabTapped(0);
                          } else {
                            final nextIdx = stepIndex + 1;
                            final targetTab = steps[nextIdx]['tabIndex'] as int;
                            _onTabTapped(targetTab);
                            setModalState(() => stepIndex = nextIdx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A8C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isLast ? 'Mulai Gunakan' : 'Selanjutnya',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onNameUpdated(String newName) {
    setState(() => _name = newName);
  }

  void _onSelectHistory(String sessionId, String sessionName) {
    setState(() {
      _chatSessionId = sessionId;
      _chatSessionName = sessionName;
      _currentIndex = 1;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) _homeRefreshKey++;
      if (index == 2) _hospitalRefreshKey++;
      if (index == 3) _historyRefreshKey++;
      if (index == 4) _reportRefreshKey++;
      if (index == 5) _accountRefreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Menu Utama (Selalu ada untuk semua role)
    final List<Widget> screens = [
      HomeScreen(
        key: ValueKey('home_$_homeRefreshKey'),
        name: _name,
        userUid: widget.uid,
        onShowAppTour: () => _checkAndShowAppTour(force: true),
      ),
      ChatScreen(
        key: ValueKey(_chatSessionId ?? 'new_chat'),
        userUid: widget.uid,
        sessionId: _chatSessionId,
        sessionName: _chatSessionName,
        onNewSession: () {
          setState(() {
            _chatSessionId = null;
            _chatSessionName = 'New Chat';
          });
        },
      ),
      HospitalScreen(key: ValueKey('hospital_$_hospitalRefreshKey')),
      HistoryScreen(
        key: ValueKey('history_$_historyRefreshKey'),
        userUid: widget.uid,
        onSelectHistory: _onSelectHistory,
      ),
      DashboardScreen(
        key: ValueKey('report_$_reportRefreshKey'),
        userUid: widget.uid,
      ),
      AccountScreen(
        key: ValueKey('account_$_accountRefreshKey'),
        uid: widget.uid,
        name: _name,
        role: widget.role,
        onNameUpdated: _onNameUpdated,
      ),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: 'Chat',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.local_hospital_outlined),
        activeIcon: Icon(Icons.local_hospital),
        label: 'Hospital',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        activeIcon: Icon(Icons.history),
        label: 'History',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        activeIcon: Icon(Icons.bar_chart),
        label: 'Report',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Account',
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Jika sedang di tab selain Home, kembali ke Home dan refresh data
        if (_currentIndex != 0) {
          _onTabTapped(0);
        }
        // Jika sudah di Home, tahan agar tidak pop kembali ke login
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.black45,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          backgroundColor: Colors.white,
          elevation: 8,
          items: navItems,
        ),
      ),
    );
  }
}
