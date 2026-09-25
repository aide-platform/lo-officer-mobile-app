/// LO operational issue report (durable on device; CAP create is speculative).
enum LoIssuePriority { low, medium, high, critical }

enum LoIssueCategory {
  transport,
  schedule,
  venue,
  protocol,
  medical,
  other,
}

class LoIssueReport {
  const LoIssueReport({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.details,
    required this.reportedAt,
    this.assignmentId,
    this.delegateName,
    this.status = 'on_device',
    this.synced = false,
  });

  final String id;
  final String title;
  final LoIssueCategory category;
  final LoIssuePriority priority;
  final String details;
  final DateTime reportedAt;
  final String? assignmentId;
  final String? delegateName;
  final String status;
  final bool synced;

  LoIssueReport copyWith({
    String? id,
    String? title,
    LoIssueCategory? category,
    LoIssuePriority? priority,
    String? details,
    DateTime? reportedAt,
    String? assignmentId,
    String? delegateName,
    String? status,
    bool? synced,
  }) {
    return LoIssueReport(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      details: details ?? this.details,
      reportedAt: reportedAt ?? this.reportedAt,
      assignmentId: assignmentId ?? this.assignmentId,
      delegateName: delegateName ?? this.delegateName,
      status: status ?? this.status,
      synced: synced ?? this.synced,
    );
  }

  /// Plain-text summary for share / escalate to organisers.
  String toShareText() {
    final buf = StringBuffer()
      ..writeln('Liaison Officer — Issue Report')
      ..writeln('=' * 32)
      ..writeln('Title: $title')
      ..writeln('Category: ${category.name}')
      ..writeln('Priority: ${priority.name}')
      ..writeln('Status: ${synced ? 'Submitted' : 'On device'}')
      ..writeln('Reported: ${reportedAt.toLocal()}');
    if ((delegateName ?? '').isNotEmpty) {
      buf.writeln('Delegate: $delegateName');
    }
    if ((assignmentId ?? '').isNotEmpty) {
      buf.writeln('Assignment: $assignmentId');
    }
    if (details.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('Details:')
        ..writeln(details);
    }
    return buf.toString();
  }

  Map<String, dynamic> toApiBody() => {
        'title': title,
        'category': category.name,
        'priority': priority.name,
        'details': details,
        'reportedAt': reportedAt.toIso8601String(),
        if (assignmentId != null) 'assignmentId': assignmentId,
        if (delegateName != null) 'delegateName': delegateName,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'priority': priority.name,
        'details': details,
        'reportedAt': reportedAt.toIso8601String(),
        'assignmentId': assignmentId,
        'delegateName': delegateName,
        'status': status,
        'synced': synced,
      };

  factory LoIssueReport.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status']?.toString();
    // Migrate legacy pending_sync label to on_device.
    final status = statusRaw == 'pending_sync' || statusRaw == null || statusRaw.isEmpty
        ? (json['synced'] == true ? 'submitted' : 'on_device')
        : statusRaw;
    return LoIssueReport(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: LoIssueCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => LoIssueCategory.other,
      ),
      priority: LoIssuePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => LoIssuePriority.medium,
      ),
      details: json['details']?.toString() ?? '',
      reportedAt: DateTime.tryParse(json['reportedAt']?.toString() ?? '') ??
          DateTime.now(),
      assignmentId: json['assignmentId']?.toString(),
      delegateName: json['delegateName']?.toString(),
      status: status,
      synced: json['synced'] == true || status == 'submitted',
    );
  }
}
