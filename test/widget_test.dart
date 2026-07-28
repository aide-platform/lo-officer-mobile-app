import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/session/auth_session.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/engagement.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/hotel.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/transport.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/vip.dart';
import 'package:liaison_officer/main.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthSession.isValid', () {
    test('requires email, access token, and future expiresAt', () {
      expect(
        const AuthSession(email: 'a@b.com', role: 'LO').isValid,
        isFalse,
      );
      expect(
        AuthSession(
          email: 'a@b.com',
          role: 'LO',
          accessToken: 'tok',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        ).isValid,
        isFalse,
      );
      expect(
        AuthSession(
          email: 'a@b.com',
          role: 'LO',
          accessToken: 'tok',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ).isValid,
        isTrue,
      );
    });
  });

  group('VIP.completedTasks', () {
    test('hotel counts only when roomNumber is set', () {
      final vip = VIP(
        name: 'Test',
        designation: 'D',
        contact: '1',
        hotel: Hotel(name: 'Taj', roomNumber: '', stayDuration: '2n'),
        transport: Transport(
          carType: 'Sedan',
          driverName: 'A',
          driverContact: '1',
          status: 'Pending',
        ),
        engagements: [
          Engagement(
            eventName: 'Brief',
            dateTime: DateTime.now(),
            rsvpStatus: 'Confirmed',
          ),
        ],
      );
      expect(vip.completedTasks, 1); // engagement only

      vip.hotel.roomNumber = '101';
      expect(vip.completedTasks, 2);
    });
  });

  group('AuthBloc captcha expiry', () {
    test('accepts captcha within 120 seconds', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = AuthBloc();
      final generatedAt =
          DateTime.now().subtract(const Duration(seconds: 90));
      bloc.add(AuthLoginRequested(
        email: 'liaison@test.com',
        password: 'liaison123',
        captcha: 'ABC12',
        generatedCaptcha: 'ABC12',
        captchaGeneratedAt: generatedAt,
      ));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthBlocState>(
            (s) => s.status == AuthStatus.authenticated,
          ),
        ),
      );
      await bloc.close();
    });
  });

  testWidgets('App loads login screen when no session', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final themeCubit = await ThemeCubit.create();
    await tester.pumpWidget(
      LiaisonOfficerApp(themeCubit: themeCubit, initialSession: null),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Liaison Officer'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Sign in to continue'), findsOneWidget);
  });

  testWidgets('semantic colors adapt to theme brightness', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            final lightText = context.semantic.textPrimary;
            return Theme(
              data: AppTheme.darkTheme,
              child: Builder(
                builder: (ctx) {
                  expect(ctx.semantic.textPrimary, isNot(lightText));
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
  });
}
