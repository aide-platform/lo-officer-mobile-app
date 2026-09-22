part of 'org_rep_bloc.dart';

enum OrgRepStatus { initial, loading, ready, failure }

class OrgRepState {
  final OrgRepStatus status;
  final Map<String, dynamic>? organisation;
  final List<LiaisonOfficerDto> los;
  final String? errorMessage;
  final String? infoMessage;
  final List<int>? lastTemplateBytes;

  const OrgRepState({
    this.status = OrgRepStatus.initial,
    this.organisation,
    this.los = const [],
    this.errorMessage,
    this.infoMessage,
    this.lastTemplateBytes,
  });

  OrgRepState copyWith({
    OrgRepStatus? status,
    Map<String, dynamic>? organisation,
    List<LiaisonOfficerDto>? los,
    String? errorMessage,
    String? infoMessage,
    List<int>? lastTemplateBytes,
    bool clearError = false,
  }) {
    return OrgRepState(
      status: status ?? this.status,
      organisation: organisation ?? this.organisation,
      los: los ?? this.los,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: infoMessage ?? this.infoMessage,
      lastTemplateBytes: lastTemplateBytes ?? this.lastTemplateBytes,
    );
  }
}
