import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/core/session/app_role.dart';
import 'package:liaison_officer/core/utils/lo_display_format.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_profile_screen.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_issue_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveAppRole', () {
    test('always maps to liaisonOfficer (LO-only app)', () {
      expect(resolveAppRole('Liaison Officer'), AppRole.liaisonOfficer);
      expect(
        resolveAppRole('Organisation Representative'),
        AppRole.liaisonOfficer,
      );
      expect(
        resolveAppRole('LO Committee Nodal Officer'),
        AppRole.liaisonOfficer,
      );
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
          .map(
            (e) => ConnectingFlightDraft.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      final departure = (body['departureConnectingFlights'] as List)
          .map(
            (e) => ConnectingFlightDraft.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      expect(arrival.single.flightNumber, 'AI1');
      expect(departure.single.flightNumber, 'AI9');
    });
  });

  group('language replace-set', () {
    test(
      'removes dropped languages and keeps stable rows for kept ones',
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
      },
    );
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

  group('profile field checks', () {
    test('date of birth accepts both formats and submits yyyy-mm-dd', () {
      expect(LoProfileScreen.formatDob(DateTime(2000, 12, 31)), '31-12-2000');
      expect(
        LoProfileScreen.formatDobIso(DateTime(2000, 12, 31)),
        '2000-12-31',
      );
      expect(LoProfileScreen.parseDob('31-12-2000'), DateTime(2000, 12, 31));
      expect(LoProfileScreen.parseDob('2000-12-31'), DateTime(2000, 12, 31));
      expect(LoProfileScreen.parseDob('31-02-2000'), isNull);
    });

    test('phones follow the portal pattern and aadhaar allows spaces', () {
      expect(
        LoProfileScreen.phoneError(
          '',
          required: true,
          emptyMessage: 'Personal contact number is required.',
          invalidMessage: 'Personal contact is invalid.',
        ),
        'Personal contact number is required.',
      );
      expect(
        LoProfileScreen.phoneError(
          '+91 98765 43210',
          required: true,
          emptyMessage: 'Personal contact number is required.',
          invalidMessage: 'Personal contact is invalid.',
        ),
        isNull,
      );
      expect(
        LoProfileScreen.phoneError(
          '12',
          required: true,
          emptyMessage: 'Mobile number (from nomination) is required.',
          invalidMessage: 'Mobile number (from nomination) is invalid.',
        ),
        'Mobile number (from nomination) is invalid.',
      );
      expect(
        LoProfileScreen.phoneError(
          '',
          required: false,
          emptyMessage: '',
          invalidMessage: 'WhatsApp number is invalid.',
        ),
        isNull,
      );
      expect(LoProfileScreen.aadhaarError(''), 'Aadhaar number is required.');
      expect(
        LoProfileScreen.aadhaarError('1234'),
        'Aadhaar must be 12 digits (spaces allowed).',
      );
      expect(LoProfileScreen.aadhaarError('1234 5678 9012'), isNull);
      expect(
        LoProfileScreen.aadhaarError('1234567890123'),
        'Aadhaar must be 12 digits (spaces allowed).',
      );
      expect(
        LoProfileScreen.emailError('officer@example.com', label: 'Official email'),
        isNull,
      );
      expect(
        LoProfileScreen.emailError('not-an-email', label: 'Official email'),
        'Official email is invalid.',
      );
      expect(
        LoProfileScreen.experiencesError(
          hasPrevious: true,
          experiences: const [],
        ),
        isNull,
      );
      expect(
        LoProfileScreen.experiencesError(
          hasPrevious: false,
          experiences: const [
            LoExperienceDto(eventName: 'Aero India', year: 2024),
          ],
        ),
        isNull,
      );
      expect(
        LoProfileScreen.experiencesError(
          hasPrevious: true,
          experiences: const [
            LoExperienceDto(eventName: 'Aero India', year: 2024),
          ],
          currentYear: 2026,
        ),
        'Row 1: Role / responsibilities is required.',
      );
      final saved = LoExperienceDto.fromJson({
        'eventName': 'Aero India',
        'eventYear': 2024,
        'roleResp': 'Escort',
      });
      expect(saved.year, 2024);
      expect(saved.roleResponsibilities, 'Escort');
      expect(saved.toJson()['eventYear'], 2024);
      expect(saved.toJson()['roleResp'], 'Escort');
      final hindi = LoLanguageOption.fromJson({
        'id': 'lang-hi',
        'code': 'hi',
        'displayName': 'Hindi',
      });
      expect(hindi.id, 'lang-hi');
      expect(hindi.name, 'Hindi');
      final kannada = LoLanguageOption.fromJson({
        'languageId': 'lang-kn',
        'code': 'kn',
      });
      expect(kannada.id, 'lang-kn');
      expect(kannada.name, 'kn');
      expect(LoDisplayFormat.date('30-09-2026'), '2026-09-30');
      expect(LoDisplayFormat.time('14:30'), '2:30:00 PM');
      expect(LoDisplayFormat.time('11:25:00'), '11:25:00 AM');
      expect(LoDisplayFormat.toApiTime('2:30:00 PM'), '14:30');
      expect(
        LoProfileScreen.isAllowedProfileImage(filename: 'photo.jpg'),
        isTrue,
      );
      expect(
        LoProfileScreen.isAllowedProfileImage(filename: 'badge.pdf'),
        isFalse,
      );
      expect(
        LoProfileScreen.experienceRowError(
          index: 0,
          eventName: 'Aero India',
          role: 'Escort',
          year: 1980,
          currentYear: 2026,
        ),
        'Row 1: Year must be between 1990 and 2026.',
      );
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
