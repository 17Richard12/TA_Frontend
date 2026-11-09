import 'package:lungs_assistant_agent/firebase_options.dart';
import 'package:lungs_assistant_agent/screens/auth_screen.dart';
import 'package:lungs_assistant_agent/screens/main_screen.dart';
import 'package:lungs_assistant_agent/screens/onboarding_screen.dart';
import 'package:lungs_assistant_agent/services/auth_service.dart';
import 'package:lungs_assistant_agent/services/notification_service.dart';
import 'package:lungs_assistant_agent/services/session_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  // Check session
  final uid = await SessionService.getUid();
  final name = await SessionService.getName();
  final role = await SessionService.getRole() ?? 'user';
  final token = await SessionService.getToken();

  Widget initialScreen = AuthScreen();
  if (uid != null && name != null && token != null && token.isNotEmpty) {
    bool? profileCompleted = await SessionService.getProfileCompleted();
    final userRes = await AuthService().getUser(uid);
    if (userRes['status'] == 'success') {
      final userData = userRes['data'] as Map<String, dynamic>?;
      final serverRole = (userData?['role']?.toString() ?? role)
          .trim()
          .toLowerCase();
      if (serverRole != role) {
        await SessionService.setRole(serverRole);
      }
      profileCompleted = SessionService.isProfileDataComplete(
        userData,
        roleFallback: serverRole,
      );
      await SessionService.setProfileCompleted(profileCompleted);
      initialScreen = profileCompleted
          ? MainScreen(uid: uid, name: name, role: serverRole)
          : OnboardingScreen(uid: uid, name: name, role: serverRole);
    } else if (userRes['unauthorized'] == true) {
      // Sesi kedaluwarsa / tidak valid -> bersihkan sesi dan arahkan ke halaman login
      await SessionService.clearSession();
      initialScreen = AuthScreen();
    } else {
      profileCompleted ??= SessionService.isProfileDataComplete(
        null,
        roleFallback: role,
      );
      initialScreen = profileCompleted
          ? MainScreen(uid: uid, name: name, role: role)
          : OnboardingScreen(uid: uid, name: name, role: role);
    }
  } else if (uid != null || name != null) {
    // Sesi lama tanpa token autentikasi -> minta login ulang
    await SessionService.clearSession();
    initialScreen = AuthScreen();
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}
