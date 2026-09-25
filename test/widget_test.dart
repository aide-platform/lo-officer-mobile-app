import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/core/auth/data/repositories/mock_auth_repository.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/session/app_role.dart';
import 'package:liaison_officer/core/session/auth_session.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
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

  group('AuthBloc OTP login', () {
    test('verifies demo OTP and authenticates', () async {
      SharedPreferences.setMockInitialValues({});
      AppDependencies.resetForTest();
      final bloc = AuthBloc(repository: MockAuthRepository());
      bloc.add(AuthOtpVerified(email: 'liaison@test.com', otp: '123456'));
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthBlocState>(
            (s) =>
                s.status == AuthStatus.authenticated &&
                s.role == MockAuthRepository.loRole,
          ),
        ),
      );
      await bloc.close();
    });
  });

  testWidgets('App loads login screen when no session', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    AppDependencies.resetForTest();
    final themeCubit = await ThemeCubit.create();
    await tester.pumpWidget(
      LiaisonOfficerApp(themeCubit: themeCubit, initialSession: null),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('Liaison Officer Portal'), findsOneWidget);
    await tester.tap(find.text('Continue to Sign In'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verify your identity'), findsOneWidget);
    expect(find.textContaining('EMAIL'), findsWidgets);
  });

  group('CAP models', () {
    test('MyLoAssignmentDto parses family', () {
      final dto = MyLoAssignmentDto.fromJson({
        'assignmentId': 'a1',
        'fullName': 'VIP',
        'family': [
          {'fullName': 'Spouse', 'relation': 'Spouse'},
        ],
      });
      expect(dto.family, hasLength(1));
      expect(dto.family.first.relation, 'Spouse');
    });

    test('resolveAppRole always returns liaisonOfficer', () {
      expect(resolveAppRole('Liaison Officer'), AppRole.liaisonOfficer);
      expect(resolveAppRole('Organisation Representative'), AppRole.liaisonOfficer);
      expect(resolveAppRole('LO Committee Nodal Officer'), AppRole.liaisonOfficer);
      expect(resolveAppRole('ADMIN'), AppRole.liaisonOfficer);
      expect(resolveAppRole(null), AppRole.liaisonOfficer);
    });
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
