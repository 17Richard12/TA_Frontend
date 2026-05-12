import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'record_screen.dart';
import 'hospital_screen.dart';
import 'history_screen.dart';
import 'account_screen.dart';

class MainScreen extends StatefulWidget {
  final String uid;
  final String name;

  const MainScreen({super.key, required this.uid, required this.name});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late String _name;

  static const Color primaryBlue = Color(0xFF2F60CC);

  @override
  void initState() {
    super.initState();
    _name = widget.name;
  }

  // Dipanggil dari AccountScreen ketika nama berhasil diupdate
  void _onNameUpdated(String newName) {
    setState(() => _name = newName);
  }

  @override
  Widget build(BuildContext context) {
    // Dibuild ulang setiap kali _name berubah
    // sehingga HomeScreen dan AccountScreen selalu dapat nama terbaru
    final screens = [
      HomeScreen(name: _name),
      ChatScreen(userUid: widget.uid),
      const RecordScreen(),
      const HospitalScreen(),
      HistoryScreen(userUid: widget.uid),
      AccountScreen(
        uid: widget.uid,
        name: _name,
        onNameUpdated: _onNameUpdated,
      ),
    ];

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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none),
            activeIcon: Icon(Icons.mic),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_outlined),
            activeIcon: Icon(Icons.local_hospital),
            label: 'Hospital',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
