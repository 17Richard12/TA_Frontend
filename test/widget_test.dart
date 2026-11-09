import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lungs_assistant_agent/main.dart';
import 'package:lungs_assistant_agent/screens/auth_screen.dart';
import 'package:lungs_assistant_agent/screens/login_screen.dart';
import 'package:lungs_assistant_agent/screens/register_screen.dart';
import 'package:lungs_assistant_agent/screens/terms_and_about_screen.dart';
import 'package:lungs_assistant_agent/screens/onboarding_screen.dart';
import 'package:lungs_assistant_agent/screens/account_screen.dart';
import 'package:lungs_assistant_agent/screens/password_screen.dart';
import 'package:lungs_assistant_agent/screens/edit_screen.dart';
import 'package:lungs_assistant_agent/screens/edit_role_screen.dart';
import 'package:lungs_assistant_agent/services/session_service.dart';
import 'package:lungs_assistant_agent/state/smoke_sync.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SmokeSync.instance.reset();
  });

  group('1. SessionService & Profile Completeness Tests', () {
    test(
      'isProfileDataComplete returns true for dokter, master, and admin roles regardless of profile fields',
      () {
        expect(
          SessionService.isProfileDataComplete(null, roleFallback: 'dokter'),
          isTrue,
        );
        expect(
          SessionService.isProfileDataComplete(null, roleFallback: 'doctor'),
          isTrue,
        );
        expect(
          SessionService.isProfileDataComplete(null, roleFallback: 'master'),
          isTrue,
        );
        expect(
          SessionService.isProfileDataComplete(null, roleFallback: 'admin'),
          isTrue,
        );
      },
    );

    test('isProfileDataComplete evaluates user profile fields accurately', () {
      expect(
        SessionService.isProfileDataComplete(null, roleFallback: 'user'),
        isFalse,
      );
      expect(
        SessionService.isProfileDataComplete({
          'role': 'user',
          'gender': 'Laki-laki',
          'bloodType': 'O',
          'height': 170,
          'weight': 65,
        }),
        isTrue,
      );
      expect(
        SessionService.isProfileDataComplete({
          'role': 'user',
          'gender': '',
          'bloodType': 'O',
          'height': 170,
          'weight': 65,
        }),
        isFalse,
      );
      expect(
        SessionService.isProfileDataComplete({
          'role': 'user',
          'profile_completed': true,
        }),
        isTrue,
      );
    });

    test(
      'saveSession, getters, token, updateName, AppTour, and clearSession work properly',
      () async {
        await SessionService.saveSession(
          'uid_123',
          'Test Patient',
          'user',
          profileCompleted: true,
          token: 'jwt_test_token',
        );
        expect(await SessionService.getUid(), equals('uid_123'));
        expect(await SessionService.getName(), equals('Test Patient'));
        expect(await SessionService.getRole(), equals('user'));
        expect(await SessionService.getProfileCompleted(), isTrue);
        expect(await SessionService.getToken(), equals('jwt_test_token'));

        final headers = await SessionService.getAuthHeaders();
        expect(headers['Authorization'], equals('Bearer jwt_test_token'));

        await SessionService.updateName('Updated Patient');
        expect(await SessionService.getName(), equals('Updated Patient'));

        expect(await SessionService.hasSeenAppTour('uid_123'), isFalse);
        await SessionService.setAppTourSeen('uid_123');
        expect(await SessionService.hasSeenAppTour('uid_123'), isTrue);

        await SessionService.clearSession();
        expect(await SessionService.getUid(), isNull);
        expect(await SessionService.getName(), isNull);
        expect(await SessionService.getRole(), isNull);
        expect(await SessionService.getToken(), isNull);
        expect(await SessionService.getProfileCompleted(), isNull);
      },
    );
  });

  group('2. SmokeSync State Management Tests', () {
    test(
      'seed and reset manage confirmedCountFor and clamp negative counts',
      () {
        SmokeSync.instance.seed('user_1', '2026-11-06', 4);
        expect(
          SmokeSync.instance.confirmedCountFor('user_1', '2026-11-06'),
          equals(4),
        );
        expect(
          SmokeSync.instance.confirmedCountFor('user_1', '2026-11-05'),
          isNull,
        );
        expect(
          SmokeSync.instance.confirmedCountFor('user_2', '2026-11-06'),
          isNull,
        );

        SmokeSync.instance.seed('user_1', '2026-11-07', -5);
        expect(
          SmokeSync.instance.confirmedCountFor('user_1', '2026-11-07'),
          equals(0),
        );

        SmokeSync.instance.reset();
        expect(
          SmokeSync.instance.confirmedCountFor('user_1', '2026-11-07'),
          isNull,
        );
      },
    );
  });

  group('3. Auth, Login & Register Widget Tests', () {
    testWidgets(
      'AuthScreen renders and navigates to Login & Register screens',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp(initialScreen: AuthScreen()));
        expect(find.text('Lungs Assistant Agent'), findsOneWidget);
        expect(find.text('LOGIN'), findsOneWidget);
        expect(find.text('CREATE ACCOUNT'), findsOneWidget);

        await tester.ensureVisible(find.text('LOGIN'));
        await tester.tap(find.text('LOGIN'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pumpAndSettle();
        expect(find.byType(AuthScreen), findsOneWidget);

        await tester.ensureVisible(find.text('CREATE ACCOUNT'));
        await tester.tap(find.text('CREATE ACCOUNT'));
        await tester.pumpAndSettle();
        expect(find.byType(RegisterScreen), findsOneWidget);
      },
    );

    testWidgets(
      'LoginScreen validates empty and invalid email/password inputs',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

        await tester.tap(find.text('LOGIN'));
        await tester.pump();
        expect(find.text('Email tidak boleh kosong'), findsOneWidget);
        expect(find.text('Password tidak boleh kosong'), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField).first,
          'invalid-email',
        );
        await tester.tap(find.text('LOGIN'));
        await tester.pump();
        expect(find.text('Email tidak valid'), findsOneWidget);
      },
    );

    testWidgets(
      'RegisterScreen validates password complexity and confirmation match',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Test Patient');
        await tester.enterText(fields.at(1), 'patient@example.test');
        await tester.enterText(fields.at(2), 'weak');
        await tester.enterText(fields.at(3), 'weak');

        await tester.ensureVisible(find.text('DAFTAR'));
        await tester.tap(find.text('DAFTAR'));
        await tester.pump();
        expect(find.text('Password minimal 8 karakter'), findsWidgets);

        await tester.enterText(fields.at(2), 'StrongPass1');
        await tester.enterText(fields.at(3), 'DifferentPass1');
        await tester.tap(find.text('DAFTAR'));
        await tester.pump();
        expect(find.text('Konfirmasi password tidak cocok'), findsOneWidget);
      },
    );
  });

  group('4. Terms, Onboarding, Account & Role-Based UI Tests', () {
    testWidgets(
      'TermsAndAboutScreen button is disabled until checkbox is agreed',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: TermsAndAboutScreen(
              uid: 'u1',
              name: 'Test User',
              role: 'user',
            ),
          ),
        );

        final buttonFinder = find.widgetWithText(
          ElevatedButton,
          'SIMPAN & LANJUTKAN',
        );
        expect(tester.widget<ElevatedButton>(buttonFinder).onPressed, isNull);

        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        expect(
          tester.widget<ElevatedButton>(buttonFinder).onPressed,
          isNotNull,
        );

        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingScreen), findsOneWidget);
      },
    );

    testWidgets(
      'OnboardingScreen validates smoke limits (high >= low) and required fields',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: OnboardingScreen(uid: 'u1', name: 'Test User', role: 'user'),
          ),
        );

        final fields = find.byType(TextFormField);
        // Set smoke limit low = 12, high = 5 (invalid: high < low)
        await tester.enterText(fields.at(0), '3');
        await tester.enterText(fields.at(1), '12');
        await tester.enterText(fields.at(2), '5');

        await tester.tap(find.text('MULAI SEKARANG'));
        await tester.pump();

        expect(find.text('Harus >= batas rendah'), findsOneWidget);
      },
    );

    testWidgets(
      'AccountScreen displays role-specific buttons for User, Dokter, and Admin/Master',
      (WidgetTester tester) async {
        // 1. Role: user
        await tester.pumpWidget(
          const MaterialApp(
            home: AccountScreen(uid: 'u1', name: 'Patient User', role: 'user'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Change Password'), findsOneWidget);
        expect(find.text('Perbandingan CT Scan'), findsOneWidget);
        expect(find.text('Perbandingan X-Ray'), findsOneWidget);
        expect(find.text('Edit Profile'), findsOneWidget);
        expect(find.text('List Pasien'), findsNothing);
        expect(find.text('Master User List'), findsNothing);

        // 2. Role: dokter
        await tester.pumpWidget(
          const MaterialApp(
            home: AccountScreen(uid: 'd1', name: 'Doctor User', role: 'dokter'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('List Pasien'), findsOneWidget);
        expect(find.text('Master User List'), findsNothing);

        // 3. Role: master / admin
        await tester.pumpWidget(
          const MaterialApp(
            home: AccountScreen(uid: 'm1', name: 'Admin User', role: 'master'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('List Pasien'), findsOneWidget);
        expect(find.text('Master User List'), findsOneWidget);
      },
    );

    testWidgets(
      'EditProfileScreen normalizes Indonesian gender ("Laki-laki") without crashing',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: EditProfileScreen(
              uid: 'u1',
              userData: {
                'name': 'Test User',
                'gender': 'Laki-laki',
                'bloodType': 'O',
                'height': 172,
                'weight': 68,
                'smoke_limit_low': 5,
                'smoke_limit_high': 10,
              },
              currentUserRole: 'user',
            ),
          ),
        );
        expect(find.text('Edit Profile'), findsOneWidget);
        expect(find.text('male'), findsOneWidget);
      },
    );

    testWidgets(
      'ChangePasswordScreen and EditUserRoleScreen render and validate unified password rules',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ChangePasswordScreen(uid: 'u1')),
        );
        expect(find.text('Current Password'), findsOneWidget);
        expect(find.text('New Password'), findsOneWidget);
        expect(find.text('Confirm Password'), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pump();
        expect(find.text('Harap isi semua kolom password.'), findsOneWidget);

        final pwFields = find.byType(TextField);
        await tester.enterText(pwFields.at(0), 'OldPass123');
        await tester.enterText(pwFields.at(1), 'weak');
        await tester.enterText(pwFields.at(2), 'weak');
        await tester.tap(find.text('Save'));
        await tester.pump();
        expect(find.text('Password minimal 8 karakter.'), findsOneWidget);

        await tester.pumpWidget(
          const MaterialApp(
            home: EditUserRoleScreen(
              uid: 'u1',
              userData: {
                'name': 'Test User',
                'email': 'user@example.test',
                'role': 'user',
              },
              currentUserRole: 'master',
            ),
          ),
        );
        expect(find.text('Edit User Role'), findsOneWidget);
        expect(find.text('user@example.test'), findsOneWidget);
      },
    );
  });
}
