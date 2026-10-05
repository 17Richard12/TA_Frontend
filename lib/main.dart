import 'package:agent_doctor/firebase_options.dart';
import 'package:agent_doctor/screens/auth_screen.dart';
import 'package:agent_doctor/screens/main_screen.dart';
import 'package:agent_doctor/services/session_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Check session
  final uid = await SessionService.getUid();
  final name = await SessionService.getName();
  final role = await SessionService.getRole() ?? 'user';

  Widget initialScreen = AuthScreen();
  if (uid != null && name != null) {
    initialScreen = MainScreen(uid: uid, name: name, role: role);
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
