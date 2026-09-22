part of 'org_rep_bloc.dart';

enum OrgRepStatus { initial, loading, ready, failure }

class OrgRepState {
  final OrgRepStatus status;
  final Map<String, dynamic>? organisation;
  final List<LiaisonOfficerDto> los;
  final List<OrgSubNodalOfficerDto> subNodals;
  final LiaisonOfficerDto? selectedLoDetail;
  final String? errorMessage;
  final String? infoMessage;
  final List<int>? lastTemplateBytes;
  final List<int>? lastDownloadBytes;
  final String? lastDownloadFilename;

  const OrgRepState({
    this.status = OrgRepStatus.initial,
    this.organisation,
    this.los = const [],
    this.subNodals = const [],
    this.selectedLoDetail,
    this.errorMessage,
    this.infoMessage,
    this.lastTemplateBytes,
    this.lastDownloadBytes,
    this.lastDownloadFilename,
  });

  OrgRepState copyWith({
    OrgRepStatus? status,
    Map<String, dynamic>? organisation,
    List<LiaisonOfficerDto>? los,
    List<OrgSubNodalOfficerDto>? subNodals,
    LiaisonOfficerDto? selectedLoDetail,
    String? errorMessage,
    String? infoMessage,
    List<int>? lastTemplateBytes,
    List<int>? lastDownloadBytes,
    String? lastDownloadFilename,
    bool clearError = false,
    bool clearInfo = false,
    bool clearDownload = false,
    bool clearSelectedDetail = false,
  }) {
    return OrgRepState(
      status: status ?? this.status,
      organisation: organisation ?? this.organisation,
      los: los ?? this.los,
      subNodals: subNodals ?? this.subNodals,
      selectedLoDetail: clearSelectedDetail
          ? null
          : (selectedLoDetail ?? this.selectedLoDetail),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      lastTemplateBytes: lastTemplateBytes ?? this.lastTemplateBytes,
      lastDownloadBytes: clearDownload
          ? null
          : (lastDownloadBytes ?? this.lastDownloadBytes),
      lastDownloadFilename: clearDownload
          ? null
          : (lastDownloadFilename ?? this.lastDownloadFilename),
    );
  }
}
