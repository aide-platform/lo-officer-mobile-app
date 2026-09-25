import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/core/session/app_role.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_issue_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveAppRole', () {
    test('always maps to liaisonOfficer (LO-only app)', () {
      expect(resolveAppRole('Liaison Officer'), AppRole.liaisonOfficer);
      expect(resolveAppRole('Organisation Representative'), AppRole.liaisonOfficer);
      expect(resolveAppRole('LO Committee Nodal Officer'), AppRole.liaisonOfficer);
      expect(resolveAppRole('ADMIN'), AppRole.liaisonOfficer);
    });
  });

  group('profile age', () {
    test('calcAge handles birthday not yet reached this year', () {
      final dob = DateTime(2000, 12, 31);
      final now = DateTime.now();
      final age = _ProfileAge.calc(dob);
      var expected = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        expected--;
      }
      expect(age, expected);
    });
  });

  group('ConnectingFlightDraft', () {
    test('round-trips travel connecting flights map', () {
      const draft = ConnectingFlightDraft(
        flightNumber: 'AI50',
        terminal: 'T2',
        date: '2026-02-10',
        time: '14:00',
      );
      final restored = ConnectingFlightDraft.fromJson(draft.toJson());
      expect(restored.flightNumber, 'AI50');
      expect(restored.terminal, 'T2');
      expect(restored.date, '2026-02-10');
      expect(restored.time, '14:00');
    });
  });

  group('MyLoAssignmentDto passport', () {
    test('parses passport and decorations', () {
      final dto = MyLoAssignmentDto.fromJson({
        'assignmentId': 'a1',
        'fullName': 'VIP',
        'passportNumber': 'P123',
        'passportExpiry': '2030-01-01',
        'gender': 'Male',
        'ministry': 'Defence',
        'decorations': ['Padma Shri'],
      });
      expect(dto.passportNumber, 'P123');
      expect(dto.decorations, ['Padma Shri']);
      expect(dto.gender, 'Male');
      expect(dto.ministry, 'Defence');
    });
  });

  group('dual connecting flights payload', () {
    test('maps arrival and departure connecting lists', () {
      final body = {
        'arrivalConnectingFlights': [
          const ConnectingFlightDraft(flightNumber: 'AI1').toJson(),
        ],
        'departureConnectingFlights': [
          const ConnectingFlightDraft(flightNumber: 'AI9').toJson(),
        ],
      };
      final arrival = (body['arrivalConnectingFlights'] as List)
          .map((e) => ConnectingFlightDraft.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
      final departure = (body['departureConnectingFlights'] as List)
          .map((e) => ConnectingFlightDraft.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
      expect(arrival.single.flightNumber, 'AI1');
      expect(departure.single.flightNumber, 'AI9');
    });
  });

  group('language replace-set', () {
    test('removes dropped languages and keeps stable rows for kept ones',
        () async {
      final repo = MockLoPortalRepository();
      final englishId = repo.languageRowIds.first;
      expect(await repo.listLanguages(), ['English', 'Hindi']);

      await repo.setLanguages(['English', 'Kannada']);
      final after = await repo.listLanguages();
      expect(after, containsAll(['English', 'Kannada']));
      expect(after, isNot(contains('Hindi')));
      expect(after.length, 2);
      // English row id preserved across replace-set.
      expect(repo.languageRowIds, contains(englishId));
      expect(repo.languageRowIds.length, 2);
    });
  });

  group('arrival-flight update', () {
    test('updateArrivalFlight patches arrival fields only', () async {
      final repo = MockLoPortalRepository();
      final updated = await repo.updateArrivalFlight(
        assignmentId: 'asn-1',
        body: {
          'arrivalFlight': 'AI 999',
          'arrivalTerminal': 'T1',
          'arrivalDate': '2026-02-11',
          'arrivalTime': '09:00',
        },
      );
      expect(updated.arrivalFlight, 'AI 999');
      expect(updated.arrivalTerminal, 'T1');
      expect(updated.departureFlight, 'AI 803');
    });
  });

  group('lo portal badge download', () {
    test('downloadBadge returns bytes for currentPassId', () async {
      final repo = MockLoPortalRepository();
      final profile = await repo.getMyProfile();
      expect(profile?.currentPassId, isNotNull);
      final bytes = await repo.downloadBadge(profile!.currentPassId!);
      expect(bytes, isNotEmpty);
    });
  });

  group('issue reporting', () {
    test('mock reportIssue marks submitted/synced', () async {
      final repo = MockLoPortalRepository();
      final saved = await repo.reportIssue(
        LoIssueReport(
          id: 'i1',
          title: 'Gate delay',
          category: LoIssueCategory.venue,
          priority: LoIssuePriority.medium,
          details: 'Queue at Gate 3',
          reportedAt: DateTime(2026, 2, 11, 9),
          delegateName: 'VIP',
        ),
      );
      expect(saved.synced, isTrue);
      expect(saved.status, 'submitted');
      final list = await repo.listReportedIssues();
      expect(list.single.title, 'Gate delay');
    });

    test('toShareText includes title and delegate', () {
      final text = LoIssueReport(
        id: 'i2',
        title: 'Transport late',
        category: LoIssueCategory.transport,
        priority: LoIssuePriority.high,
        details: 'Driver ETA +20m',
        reportedAt: DateTime(2026, 2, 11, 10),
        delegateName: 'Amb. Demo',
        synced: false,
        status: 'on_device',
      ).toShareText();
      expect(text, contains('Transport late'));
      expect(text, contains('Amb. Demo'));
      expect(text, contains('On device'));
    });

    test('fromJson migrates pending_sync to on_device', () {
      final issue = LoIssueReport.fromJson({
        'id': 'legacy',
        'title': 'Old',
        'category': 'other',
        'priority': 'low',
        'details': '',
        'reportedAt': '2026-01-01T00:00:00.000',
        'status': 'pending_sync',
        'synced': false,
      });
      expect(issue.status, 'on_device');
      expect(issue.synced, isFalse);
    });

    test('validate requires title and details length', () {
      expect(
        LoIssueReport.validate(title: '  ', details: 'long enough text'),
        isNotNull,
      );
      expect(
        LoIssueReport.validate(title: 'Gate', details: 'short'),
        isNotNull,
      );
      expect(
        LoIssueReport.validate(
          title: '  Gate delay  ',
          details: 'Queue building at Gate 3 entrance',
        ),
        isNull,
      );
      expect(LoIssueReport.sanitizeTitle('  Gate   delay  '), 'Gate delay');
    });
  });
}

/// Mirrors profile DOB → age calculation used in LO portal.
class _ProfileAge {
  static int calc(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
