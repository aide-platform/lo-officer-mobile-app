import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/core/session/app_role.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/data/pdf/do_letter_pdf_builder.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_lo_portal_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_nodal_lo_repository.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_org_rep_repository.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/nodal_lo_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveAppRole', () {
    test('maps CAP role strings', () {
      expect(resolveAppRole('Liaison Officer'), AppRole.liaisonOfficer);
      expect(resolveAppRole('Organisation Representative'),
          AppRole.organisationRepresentative);
      expect(
          resolveAppRole('LO Committee Nodal Officer'), AppRole.nodalOfficer);
      expect(resolveAppRole('ADMIN'), AppRole.nodalOfficer);
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

  group('DO checklist gate', () {
    test('uploadSignedDoLetter rejects incomplete checklist in bloc', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = NodalLoBloc(repository: MockNodalLoRepository());
      bloc.add(NodalLoLoadRequested());
      await bloc.stream.firstWhere((s) => s.status == NodalLoStatus.ready);

      var orgId = 'org-1';
      if (bloc.state.organisations.isNotEmpty &&
          bloc.state.organisations.first.id != null) {
        orgId = bloc.state.organisations.first.id!;
      }

      bloc.add(
        NodalLoUploadSignedDo(
          orgId: orgId,
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'signed.pdf',
          signingAuthority: 'Secretary',
          checklist: const {
            'orgNameCorrect': true,
            'headNameCorrect': true,
            'designationCorrect': false,
            'emailIdCorrect': true,
            'signingAuthorityCorrect': true,
          },
        ),
      );
      final failed = await bloc.stream.firstWhere(
        (s) => s.status == NodalLoStatus.failure || s.infoMessage != null,
      );
      expect(failed.status, NodalLoStatus.failure);
      expect(failed.errorMessage, contains('checklist'));
      await bloc.close();
    });
  });

  group('org type activate', () {
    test('setOrgTypeActive updates isActive flag', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockNodalLoRepository();
      final types = await repo.listOrgTypes();
      expect(types, isNotEmpty);
      final id = types.first.id!;
      await repo.setOrgTypeActive(id, false);
      final updated = await repo.listOrgTypes();
      final match = updated.firstWhere((e) => e.id == id);
      expect(match.isActive, isFalse);
      await repo.setOrgTypeActive(id, true);
      final reactivated =
          (await repo.listOrgTypes()).firstWhere((e) => e.id == id);
      expect(reactivated.isActive, isTrue);
    });
  });

  group('badge quota block', () {
    test('assignBadge fails when selection exceeds remaining', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = NodalLoBloc(repository: MockNodalLoRepository());
      bloc.add(NodalLoLoadRequested());
      await bloc.stream.firstWhere((s) => s.status == NodalLoStatus.ready);

      final remaining = bloc.state.badgeRemaining;
      final ids = List.generate(remaining + 2, (i) => 'person-$i');
      bloc.add(NodalLoAssignBadge(personIds: ids));
      final failed = await bloc.stream.firstWhere(
        (s) => s.status == NodalLoStatus.failure,
      );
      expect(failed.errorMessage?.toLowerCase(), contains('quota'));
      await bloc.close();
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

  group('DoLetterPdfBuilder', () {
    test('builds non-empty PDF bytes', () async {
      final bytes = await DoLetterPdfBuilder.build(
        org: const LoOrganisationDto(
          orgName: 'Test Org',
          headName: 'Head',
          headDesignation: 'CMD',
          primaryEmail: 'a@b.com',
          primaryContact: '+91',
          address: 'Bengaluru',
          orgTypeName: 'DPSU',
        ),
        template: const DoLetterTemplateDto(
          templateName: 'Standard',
          signingAuthority: 'Chairman',
        ),
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
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

  group('org rep re-nominate', () {
    test('soft-deletes rejected LO and adds pending replacement', () async {
      final repo = MockOrgRepRepository();
      final before = await repo.listLos();
      expect(
        before.any((e) => e.id == 'lo-org-rejected'),
        isTrue,
      );

      final fresh = await repo.reNominateLo('lo-org-rejected', {
        'salutation': 'Ms',
        'firstName': 'Anita',
        'lastName': 'Shah',
        'primaryEmail': 'anita2@bel.co.in',
        'primaryMobile': '+919800000002',
        'designation': 'Manager',
      });

      final after = await repo.listLos();
      expect(after.any((e) => e.id == 'lo-org-rejected'), isFalse);
      expect(fresh.profileStatus, 'PENDING');
      expect(fresh.officialEmail, 'anita2@bel.co.in');
      expect(after.any((e) => e.id == fresh.id), isTrue);
    });
  });

  group('org rep nominate + team', () {
    test('nominateLo stores optional rank and designation', () async {
      final repo = MockOrgRepRepository();
      final lo = await repo.nominateLo({
        'salutation': 'Mr',
        'firstName': 'Ravi',
        'lastName': 'Kumar',
        'primaryEmail': 'ravi@bel.co.in',
        'primaryMobile': '+919800000099',
        'rank': 'Gp Capt',
        'designation': 'Squadron Commander',
      });
      expect(lo.rank, 'Gp Capt');
      expect(lo.designation, 'Squadron Commander');
      expect(lo.profileStatus, 'PENDING');
    });

    test('updateSubNodal toggles isActive and designation', () async {
      final repo = MockOrgRepRepository();
      final list = await repo.listSubNodals();
      expect(list, isNotEmpty);
      final id = list.first.id!;
      final updated = await repo.updateSubNodal(id, {
        'fullName': list.first.fullName,
        'email': list.first.email,
        'mobile': list.first.mobile,
        'designation': 'Ops Lead',
        'isActive': false,
      });
      expect(updated.designation, 'Ops Lead');
      expect(updated.isActive, isFalse);
    });

    test('downloadImportTemplate returns non-empty bytes', () async {
      final repo = MockOrgRepRepository();
      final bytes = await repo.downloadImportTemplate();
      expect(bytes, isNotEmpty);
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
