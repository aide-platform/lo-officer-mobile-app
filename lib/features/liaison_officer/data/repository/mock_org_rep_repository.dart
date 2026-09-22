import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/org_rep_repository.dart';

class MockOrgRepRepository implements OrgRepRepository {
  final List<LiaisonOfficerDto> _los = [
    const LiaisonOfficerDto(
      id: 'lo-org-1',
      firstName: 'Ravi',
      lastName: 'Kumar',
      fullName: 'Ravi Kumar',
      officialEmail: 'ravi@bel.co.in',
      officialContact: '+919876543210',
      profileStatus: 'PENDING',
      profileComplete: false,
      orgName: 'BEL',
    ),
  ];

  @override
  Future<Map<String, dynamic>?> getMyOrganisation() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return {
      'orgName': 'Bharat Electronics Limited',
      'orgTypeName': 'DPSU',
      'headName': 'Demo Head',
    };
  }

  @override
  Future<List<LiaisonOfficerDto>> listLos() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List.of(_los);
  }

  @override
  Future<LiaisonOfficerDto> nominateLo(Map<String, dynamic> body) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final lo = LiaisonOfficerDto(
      id: 'lo-${_los.length + 1}',
      firstName: body['firstName']?.toString(),
      lastName: body['lastName']?.toString(),
      fullName:
          '${body['firstName'] ?? ''} ${body['lastName'] ?? ''}'.trim(),
      officialEmail: body['primaryEmail']?.toString(),
      officialContact: body['primaryMobile']?.toString(),
      salutationName: body['salutation']?.toString(),
      profileStatus: 'PENDING',
      profileComplete: false,
      orgName: 'BEL',
    );
    _los.add(lo);
    return lo;
  }

  @override
  Future<void> sendReminder(String loId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<void> sendPendingReminders() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<List<int>> downloadImportTemplate() async {
    return 'firstName,lastName,primaryEmail,primaryMobile\n'.codeUnits;
  }

  @override
  Future<void> bulkImport(List<int> bytes, String filename) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
