import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lungs_assistant_agent/firebase_options.dart';
import 'package:lungs_assistant_agent/main.dart';
import 'package:lungs_assistant_agent/screens/auth_screen.dart';
import 'package:lungs_assistant_agent/screens/login_screen.dart';
import 'package:lungs_assistant_agent/screens/main_screen.dart';
import 'package:lungs_assistant_agent/screens/home_screen.dart';
import 'package:lungs_assistant_agent/screens/chat_screen.dart';
import 'package:lungs_assistant_agent/screens/history_screen.dart';
import 'package:lungs_assistant_agent/screens/dashboard_screen.dart';
import 'package:lungs_assistant_agent/screens/account_screen.dart';
import 'package:lungs_assistant_agent/screens/mri_screen.dart';
import 'package:lungs_assistant_agent/screens/xray_screen.dart';
import 'package:lungs_assistant_agent/screens/edit_screen.dart';
import 'package:lungs_assistant_agent/screens/password_screen.dart';
import 'package:lungs_assistant_agent/screens/patient_list_screen.dart';
import 'package:lungs_assistant_agent/screens/monthly_report_screen.dart';
import 'package:lungs_assistant_agent/screens/master_user_list_screen.dart';
import 'package:lungs_assistant_agent/screens/edit_role_screen.dart';
import 'package:lungs_assistant_agent/services/session_service.dart';

// Credentials are provided via untracked --dart-define flags at test runtime
// (never hardcoded in source code):
// flutter test integration_test/app_test.dart \
//   --dart-define=TEST_USER_EMAIL=... --dart-define=TEST_USER_PASSWORD=... \
//   --dart-define=TEST_DOCTOR_EMAIL=... --dart-define=TEST_DOCTOR_PASSWORD=... \
//   --dart-define=TEST_ADMIN_EMAIL=... --dart-define=TEST_ADMIN_PASSWORD=...
const String _testUserEmail = String.fromEnvironment('TEST_USER_EMAIL');
const String _testUserPassword = String.fromEnvironment('TEST_USER_PASSWORD');
const String _testDoctorEmail = String.fromEnvironment('TEST_DOCTOR_EMAIL');
const String _testDoctorPassword = String.fromEnvironment(
  'TEST_DOCTOR_PASSWORD',
);
const String _testAdminEmail = String.fromEnvironment('TEST_ADMIN_EMAIL');
const String _testAdminPassword = String.fromEnvironment('TEST_ADMIN_PASSWORD');

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final steps = (duration.inMilliseconds / 100).ceil();
  for (int i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<bool> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}

Future<void> _dismissAppTourIfShown(WidgetTester tester) async {
  await _pumpFor(tester, const Duration(seconds: 1));
  final lewatiFinder = find.text('Lewati');
  if (lewatiFinder.evaluate().isNotEmpty) {
    await tester.tap(lewatiFinder.first);
    await _pumpFor(tester, const Duration(milliseconds: 800));
  }
}

Future<void> _loginWithCredentials(
  WidgetTester tester,
  String email,
  String password,
) async {
  expect(find.byType(AuthScreen), findsOneWidget);
  final loginBtnOnAuth = find.widgetWithText(ElevatedButton, 'LOGIN');
  await tester.ensureVisible(loginBtnOnAuth);
  await tester.tap(loginBtnOnAuth);
  await _pumpFor(tester, const Duration(milliseconds: 800));

  expect(find.byType(LoginScreen), findsOneWidget);
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await _pumpFor(tester, const Duration(milliseconds: 300));

  final submitBtn = find.widgetWithText(ElevatedButton, 'LOGIN');
  await tester.ensureVisible(submitBtn);
  await tester.tap(submitBtn);

  final reachedMain = await _waitForFinder(
    tester,
    find.byType(MainScreen),
    timeout: const Duration(seconds: 20),
  );
  expect(
    reachedMain,
    isTrue,
    reason: 'Harus masuk ke MainScreen setelah login',
  );
  await _dismissAppTourIfShown(tester);
}

Future<void> _logoutFromAccountTab(WidgetTester tester) async {
  final accountTab = find.text('Account');
  await tester.tap(accountTab.last);
  await _pumpFor(tester, const Duration(seconds: 1));

  final logoutBtn = find.widgetWithText(ElevatedButton, 'Logout');
  await tester.scrollUntilVisible(
    logoutBtn,
    150,
    scrollable: find.descendant(
      of: find.byType(AccountScreen),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.tap(logoutBtn);
  await _pumpFor(tester, const Duration(milliseconds: 600));

  final confirmLogout = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(ElevatedButton, 'Logout'),
  );
  expect(confirmLogout, findsOneWidget);
  await tester.tap(confirmLogout);

  final backToAuth = await _waitForFinder(
    tester,
    find.byType(AuthScreen),
    timeout: const Duration(seconds: 10),
  );
  expect(
    backToAuth,
    isTrue,
    reason: 'Harus kembali ke AuthScreen setelah Logout',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}
  });

  testWidgets('Full E2E Test: User, Dokter, and Admin/Master Flows', (
    WidgetTester tester,
  ) async {
    await SessionService.clearSession();
    await tester.pumpWidget(const MyApp(initialScreen: AuthScreen()));
    await _pumpFor(tester, const Duration(seconds: 1));

    expect(find.byType(AuthScreen), findsOneWidget);

    if (_testUserEmail.isEmpty || _testUserPassword.isEmpty) {
      debugPrint(
        'Skipping live E2E login steps because TEST_USER_EMAIL / TEST_USER_PASSWORD '
        'were not provided via --dart-define.',
      );
      return;
    }

    // =========================================================================
    // SCENARIO 1: ROLE USER
    // =========================================================================
    await _loginWithCredentials(tester, _testUserEmail, _testUserPassword);
    expect(find.byType(HomeScreen), findsOneWidget);

    await _pumpFor(tester, const Duration(seconds: 3));
    expect(find.text('Smoke Count'), findsOneWidget);
    expect(find.text('Current Daily Activities Streak'), findsOneWidget);

    final addSmokeIcon = find.byIcon(Icons.add);
    if (addSmokeIcon.evaluate().isNotEmpty) {
      await tester.tap(addSmokeIcon.first);
      await _pumpFor(tester, const Duration(milliseconds: 800));
      expect(find.text('BATAL'), findsOneWidget);
      await tester.tap(find.text('BATAL'));
      await _pumpFor(tester, const Duration(milliseconds: 600));
    }

    await tester.tap(find.text('News').last);
    await _pumpFor(tester, const Duration(seconds: 2));
    await tester.tap(find.text('Videos').last);
    await _pumpFor(tester, const Duration(seconds: 2));
    await tester.tap(find.text('Activities').last);
    await _pumpFor(tester, const Duration(seconds: 1));

    await tester.tap(find.text('Chat').last);
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('New Chat'), findsOneWidget);

    await tester.tap(find.text('History').last);
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('History Chat'), findsOneWidget);

    await tester.tap(find.text('Report').last);
    await _pumpFor(tester, const Duration(seconds: 3));
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Report Summary'), findsOneWidget);

    await tester.tap(find.text('Account').last);
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text('List Pasien'), findsNothing);
    expect(find.text('Master User List'), findsNothing);

    await tester.tap(find.text('Perbandingan CT Scan'));
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(find.byType(MriScreen), findsOneWidget);
    expect(find.text('Hasil CT Scan Terbaru'), findsOneWidget);
    await tester.pageBack();
    await _pumpFor(tester, const Duration(seconds: 1));

    await tester.tap(find.text('Perbandingan X-Ray'));
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(find.byType(XrayScreen), findsOneWidget);
    expect(find.text('Hasil X-Ray Terbaru'), findsOneWidget);
    await tester.pageBack();
    await _pumpFor(tester, const Duration(seconds: 1));

    await tester.tap(find.text('Change Password'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await _pumpFor(tester, const Duration(seconds: 1));

    await tester.tap(find.text('Edit Profile'));
    final editLoaded = await _waitForFinder(
      tester,
      find.byType(EditProfileScreen),
    );
    expect(editLoaded, isTrue);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await _pumpFor(tester, const Duration(seconds: 1));

    await _logoutFromAccountTab(tester);

    // =========================================================================
    // SCENARIO 2: ROLE DOKTER
    // =========================================================================
    if (_testDoctorEmail.isNotEmpty && _testDoctorPassword.isNotEmpty) {
      await _loginWithCredentials(
        tester,
        _testDoctorEmail,
        _testDoctorPassword,
      );

      await tester.tap(find.text('Account').last);
      await _pumpFor(tester, const Duration(seconds: 2));
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text('List Pasien'), findsOneWidget);
      expect(find.text('Master User List'), findsNothing);

      await tester.tap(find.text('List Pasien'));
      await _pumpFor(tester, const Duration(seconds: 3));
      expect(find.byType(PatientListScreen), findsOneWidget);
      expect(find.text('Daftar Pasien'), findsOneWidget);

      final patientTile = find.byType(ListTile);
      if (patientTile.evaluate().isNotEmpty) {
        await tester.tap(patientTile.first);
        await _pumpFor(tester, const Duration(seconds: 3));
        expect(find.byType(MonthlyReportScreen), findsOneWidget);
        expect(find.text('Kalender Laporan'), findsOneWidget);
        await tester.pageBack();
        await _pumpFor(tester, const Duration(seconds: 1));
      }

      await tester.pageBack();
      await _pumpFor(tester, const Duration(seconds: 1));
      await _logoutFromAccountTab(tester);
    }

    // =========================================================================
    // SCENARIO 3: ROLE ADMIN / MASTER
    // =========================================================================
    if (_testAdminEmail.isNotEmpty && _testAdminPassword.isNotEmpty) {
      await _loginWithCredentials(tester, _testAdminEmail, _testAdminPassword);

      await tester.tap(find.text('Account').last);
      await _pumpFor(tester, const Duration(seconds: 2));
      expect(find.byType(AccountScreen), findsOneWidget);

      final masterListBtn = find.text('Master User List');
      await tester.scrollUntilVisible(
        masterListBtn,
        150,
        scrollable: find.descendant(
          of: find.byType(AccountScreen),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('List Pasien'), findsOneWidget);
      expect(masterListBtn, findsOneWidget);

      await tester.tap(masterListBtn);
      await _pumpFor(tester, const Duration(seconds: 3));
      expect(find.byType(MasterUserListScreen), findsOneWidget);
      expect(find.text('Manage Users'), findsOneWidget);

      final userTiles = find.byType(ListTile);
      if (userTiles.evaluate().isNotEmpty) {
        await tester.tap(userTiles.first);
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.byType(EditUserRoleScreen), findsOneWidget);
        expect(find.text('Edit User Role'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await _pumpFor(tester, const Duration(seconds: 1));
      }

      await tester.pageBack();
      await _pumpFor(tester, const Duration(seconds: 1));
      await _logoutFromAccountTab(tester);
    }
  });
}
