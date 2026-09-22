import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/org_rep_repository.dart';

class MockOrgRepRepository implements OrgRepRepository {
  final List<LiaisonOfficerDto> _los = [
    const LiaisonOfficerDto(
      id: 'lo-org-1',
      personId: 'p-1',
      firstName: 'Ravi',
      lastName: 'Kumar',
      fullName: 'Ravi Kumar',
      salutationName: 'Mr',
      officialEmail: 'ravi@bel.co.in',
      personalEmail: 'ravi.personal@gmail.com',
      officialContact: '+919876543210',
      personalContact: '+919876543211',
      genderName: 'Male',
      dateOfBirth: '1988-05-12',
      rank: 'Gp Capt',
      designation: 'Engineer',
      profileStatus: 'PENDING',
      profileComplete: false,
      orgName: 'BEL',
      orgTypeName: 'DPSU',
      currentPassId: 'pass-org-1',
      currentPassNumber: 'B-1001',
    ),
    const LiaisonOfficerDto(
      id: 'lo-org-rejected',
      personId: 'p-rej',
      firstName: 'Anita',
      lastName: 'Shah',
      fullName: 'Anita Shah',
      salutationName: 'Ms',
      officialEmail: 'anita@bel.co.in',
      officialContact: '+919800000001',
      designation: 'Manager',
      profileStatus: 'REJECTED',
      profileComplete: false,
      orgName: 'BEL',
      orgTypeName: 'DPSU',
    ),
  ];

  final List<OrgSubNodalOfficerDto> _subNodals = [
    const OrgSubNodalOfficerDto(
      id: 'sn-1',
      fullName: 'Sub Nodal One',
      email: 'sub1@bel.co.in',
      mobile: '+919111111111',
      orgName: 'BEL',
    ),
  ];

  @override
  Future<Map<String, dynamic>?> getMyOrganisation() async => {
        'orgName': 'Bharat Electronics Limited',
        'orgTypeName': 'DPSU',
        'headName': 'Demo Head',
      };

  @override
  Future<List<LiaisonOfficerDto>> listLos() async => List.of(_los);

  @override
  Future<LiaisonOfficerDto?> getLo(String loId) async {
    for (final lo in _los) {
      if (lo.id == loId) return lo;
    }
    return null;
  }

  @override
  Future<LiaisonOfficerDto> nominateLo(Map<String, dynamic> body) async {
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
  Future<LiaisonOfficerDto> reNominateLo(
    String rejectedLoId,
    Map<String, dynamic> body,
  ) async {
    _los.removeWhere((e) => e.id == rejectedLoId);
    final lo = LiaisonOfficerDto(
      id: 'lo-renom-${_los.length + 1}',
      firstName: body['firstName']?.toString(),
      lastName: body['lastName']?.toString(),
      fullName:
          '${body['firstName'] ?? ''} ${body['lastName'] ?? ''}'.trim(),
      officialEmail: body['primaryEmail']?.toString(),
      officialContact: body['primaryMobile']?.toString(),
      salutationName: body['salutation']?.toString(),
      rank: body['rank']?.toString(),
      designation: body['designation']?.toString(),
      profileStatus: 'PENDING',
      profileComplete: false,
      orgName: 'BEL',
    );
    _los.add(lo);
    return lo;
  }

  @override
  Future<void> sendReminder(String loId) async {}

  @override
  Future<void> sendPendingReminders() async {}

  @override
  Future<List<int>> downloadImportTemplate() async =>
      'firstName,lastName,primaryEmail,primaryMobile\n'.codeUnits;

  @override
  Future<void> bulkImport(List<int> bytes, String filename) async {
    _los.add(
      LiaisonOfficerDto(
        id: 'lo-import-${_los.length + 1}',
        firstName: 'Imported',
        lastName: filename,
        fullName: 'Imported from $filename',
        officialEmail: 'imported@example.com',
        profileStatus: 'PENDING',
        profileComplete: false,
        orgName: 'BEL',
      ),
    );
  }

  @override
  Future<List<OrgSubNodalOfficerDto>> listSubNodals() async =>
      List.of(_subNodals);

  @override
  Future<OrgSubNodalOfficerDto> createSubNodal(Map<String, dynamic> body) async {
    final item = OrgSubNodalOfficerDto(
      id: 'sn-${_subNodals.length + 1}',
      fullName: body['fullName']?.toString() ?? '',
      email: body['email']?.toString() ?? '',
      mobile: body['mobile']?.toString(),
      orgName: 'BEL',
    );
    _subNodals.add(item);
    return item;
  }

  @override
  Future<OrgSubNodalOfficerDto> updateSubNodal(
    String id,
    Map<String, dynamic> body,
  ) async {
    final idx = _subNodals.indexWhere((e) => e.id == id);
    final item = OrgSubNodalOfficerDto(
      id: id,
      fullName: body['fullName']?.toString() ?? _subNodals[idx].fullName,
      email: body['email']?.toString() ?? _subNodals[idx].email,
      mobile: body['mobile']?.toString() ?? _subNodals[idx].mobile,
      orgName: _subNodals[idx].orgName,
    );
    _subNodals[idx] = item;
    return item;
  }

  @override
  Future<void> deleteSubNodal(String id) async {
    _subNodals.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<int>> downloadBadge(String passId) async =>
      'BADGE-$passId'.codeUnits;
}
