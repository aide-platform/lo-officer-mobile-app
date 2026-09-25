/// Local / offline LO operational issue (CAP has no LO-scoped create endpoint).
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
    this.status = 'pending_sync',
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
      status: json['status']?.toString() ?? 'pending_sync',
      synced: json['synced'] == true,
    );
  }
}
