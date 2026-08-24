class FamilyMember {
  final String salutation;
  final String fullName;
  final String gender;
  final String relation;
  final String? passportNumber;
  final DateTime? passportValidity;

  const FamilyMember({
    required this.salutation,
    required this.fullName,
    required this.gender,
    required this.relation,
    this.passportNumber,
    this.passportValidity,
  });

  Map<String, dynamic> toMap() => {
        'salutation': salutation,
        'fullName': fullName,
        'gender': gender,
        'relation': relation,
        'passportNumber': passportNumber,
        'passportValidity': passportValidity?.toIso8601String(),
      };

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      salutation: map['salutation']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      gender: map['gender']?.toString() ?? '',
      relation: map['relation']?.toString() ?? '',
      passportNumber: map['passportNumber']?.toString(),
      passportValidity: map['passportValidity'] != null
          ? DateTime.tryParse(map['passportValidity'].toString())
          : null,
    );
  }
}
