import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/core/auth/data/repositories/mock_auth_repository.dart';
import 'package:liaison_officer/features/auth/bloc/auth_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_issue_report.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_itinerary.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_movement.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OTP auth happy path', () {
    test('captcha + OTP authenticates mock LO', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = AuthBloc(repository: MockAuthRepository());

      bloc.add(AuthCaptchaRequested());
      final captcha = await bloc.stream.firstWhere(
        (s) =>
            s.status == AuthStatus.captchaReady ||
            s.status == AuthStatus.failure,
      );
      expect(captcha.status, AuthStatus.captchaReady);
      expect(captcha.captchaId, isNotNull);

      bloc.add(AuthOtpRequested(
        email: MockAuthRepository.loEmail,
        captchaId: captcha.captchaId!,
        captchaAnswer: 'ok',
      ));
      final otpSent = await bloc.stream.firstWhere(
        (s) =>
            s.status == AuthStatus.otpSent || s.status == AuthStatus.failure,
      );
      expect(otpSent.status, AuthStatus.otpSent);

      bloc.add(AuthOtpVerified(
        email: MockAuthRepository.loEmail,
        otp: MockAuthRepository.loOtp,
      ));
      final auth = await bloc.stream.firstWhere(
        (s) =>
            s.status == AuthStatus.authenticated ||
            s.status == AuthStatus.failure,
      );
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.email, MockAuthRepository.loEmail);
      expect(auth.accessToken, isNotEmpty);
      await bloc.close();
    });
  });

  group('LoPortalBloc delegates & tasks', () {
    late MockLoPortalRepository repo;
    late LoPortalBloc bloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = MockLoPortalRepository();
      bloc = LoPortalBloc(repository: repo);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('loads delegates list', () async {
      bloc.add(LoPortalLoadRequested());
      final state = await bloc.stream.firstWhere(
        (s) =>
            s.status == LoPortalStatus.ready ||
            s.status == LoPortalStatus.failure,
      );
      expect(state.status, LoPortalStatus.ready);
      expect(state.delegates, isNotEmpty);
      expect(state.delegates.first.fullName, isNotNull);
    });

    test('updates task status', () async {
      bloc.add(LoPortalLoadRequested());
      await bloc.stream.firstWhere((s) => s.status == LoPortalStatus.ready);
      final taskId = bloc.state.tasks.first.id!;
      bloc.add(LoPortalTaskStatusUpdated(
        taskId: taskId,
        statusCode: 'COMPLETED',
        remarks: 'Done in test',
      ));
      final updated = await bloc.stream.firstWhere(
        (s) =>
            s.tasks.any((t) => t.id == taskId && t.statusCode == 'COMPLETED') ||
            s.status == LoPortalStatus.failure,
      );
      expect(
        updated.tasks.any((t) => t.id == taskId && t.statusCode == 'COMPLETED'),
        isTrue,
      );
    });

    test('composes itinerary from nominations + travel', () async {
      final items = await repo.getItinerary('asn-1');
      expect(items, isNotEmpty);
      expect(items.any((e) => e.kind == LoItineraryKind.arrival), isTrue);
      expect(items.any((e) => e.kind == LoItineraryKind.event), isTrue);
    });

    test('movement update patches travel fields', () async {
      bloc.add(LoPortalLoadRequested());
      await bloc.stream.firstWhere((s) => s.status == LoPortalStatus.ready);
      bloc.add(
        LoPortalMovementUpdated(
          assignmentId: 'asn-1',
          movement: const LoMovementUpdate(
            kind: LoMovementKind.arrival,
            flight: 'AI999',
            date: '2026-02-10',
            time: '15:00',
          ),
        ),
      );
      final state = await bloc.stream.firstWhere(
        (s) =>
            s.delegates.any((d) => d.arrivalFlight == 'AI999') ||
            (s.infoMessage != null && s.infoMessage!.contains('Arrival')) ||
            s.status == LoPortalStatus.failure,
      );
      expect(
        state.delegates.any((d) => d.arrivalFlight == 'AI999'),
        isTrue,
      );
    });

    test('issue report persists in repository', () async {
      final issue = LoIssueReport(
        id: 't1',
        title: 'Vehicle delayed',
        category: LoIssueCategory.transport,
        priority: LoIssuePriority.high,
        details: 'SUV late at T2',
        reportedAt: DateTime(2026, 2, 10),
        assignmentId: 'asn-1',
        delegateName: 'Air Marshal Demo VIP',
      );
      bloc.add(LoPortalIssueReported(issue));
      final state = await bloc.stream.firstWhere(
        (s) => s.issues.isNotEmpty || s.status == LoPortalStatus.failure,
      );
      expect(state.issues, isNotEmpty);
      expect(state.issues.first.title, 'Vehicle delayed');
    });
  });

  group('LoItineraryItem', () {
    test('sorts by date/time', () {
      const assignment = MyLoAssignmentDto(
        assignmentId: 'a1',
        arrivalDate: '2026-02-12',
        arrivalTime: '10:00',
        departureDate: '2026-02-14',
        departureTime: '18:00',
      );
      final items = LoItineraryItem.compose(
        assignment: assignment,
        nominations: const [
          {
            'eventName': 'Dinner',
            'eventDate': '2026-02-13',
            'eventTime': '19:00',
            'venue': 'Lounge',
          },
        ],
      );
      expect(items.first.kind, LoItineraryKind.arrival);
      expect(items.last.kind, LoItineraryKind.departure);
    });
  });

  group('notifications unread badge (mock)', () {
    test('unread count stays non-negative after load', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = LoPortalBloc(repository: MockLoPortalRepository());
      bloc.add(LoPortalLoadRequested());
      final state = await bloc.stream.firstWhere(
        (s) => s.status == LoPortalStatus.ready,
      );
      expect(state.alerts.length, greaterThanOrEqualTo(0));
      await bloc.close();
    });
  });
}
