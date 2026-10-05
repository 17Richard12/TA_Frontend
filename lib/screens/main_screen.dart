import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'hospital_screen.dart';
import 'history_screen.dart';
import 'dashboard_screen.dart';
import 'account_screen.dart';
import 'master_user_list_screen.dart'; // Import screen baru
import 'patient_list_screen.dart'; // Import screen baru

class MainScreen extends StatefulWidget {
  final String uid;
  final String name;
  final String role; // Tambahkan parameter role

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

  @override
  Widget build(BuildContext context) {
    // Tentukan role untuk validasi tab
    final bool isMaster = widget.role.toLowerCase() == 'master';
    final bool isDokter =
        widget.role.toLowerCase() == 'dokter' ||
        widget.role.toLowerCase() == 'doctor';
    final bool canViewPatients = isMaster || isDokter;

    // 1. Menu Utama (Selalu ada untuk semua role)
    final List<Widget> screens = [
      HomeScreen(name: _name, userUid: widget.uid),
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
      const HospitalScreen(),
      HistoryScreen(userUid: widget.uid, onSelectHistory: _onSelectHistory),
      DashboardScreen(userUid: widget.uid),
      AccountScreen(
        uid: widget.uid,
        name: _name,
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

    // 2. Jika Dokter atau Master, tambahkan Patients secara BERPAHAMAN (Screens & NavItems berurutan)
    if (canViewPatients) {
      screens.add(PatientListScreen(currentUserRole: widget.role));
      navItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Patients',
        ),
      );
    }

    // 3. Jika Master, tambahkan All Users di urutan paling akhir
    if (isMaster) {
      screens.add(MasterUserListScreen(currentUserRole: widget.role));
      navItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.manage_accounts_outlined),
          activeIcon: Icon(Icons.manage_accounts),
          label:
              'All Users', // Diubah dari 'Users' agar lebih jelas perbedaannya dengan Patients
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
    );
  }
}
