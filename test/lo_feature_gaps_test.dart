import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/core/session/app_role.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/data/pdf/do_letter_pdf_builder.dart';
import 'package:liaison_officer/features/liaison_officer/data/repository/mock_nodal_lo_repository.dart';
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
