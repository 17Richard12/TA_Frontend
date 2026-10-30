import 'package:flutter/material.dart';
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
      HospitalScreen(
        key: ValueKey('hospital_$_hospitalRefreshKey'),
      ),
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
