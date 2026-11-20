/// Help desk models, matching aide-service `/app/my-lo/me/helpdesk/*`.
library;

/// Query status (aide-service `status`).
class HelpdeskStatus {
  HelpdeskStatus._();

  /// New, waiting for the help desk team.
  static const String open = 'OPEN';

  /// The help desk team has replied.
  static const String inProgress = 'IN_PROGRESS';
  static const String closed = 'CLOSED';

  static String? label(String? status) {
    switch (status) {
      case open:
        return 'Open';
      case inProgress:
        return 'In progress';
      case closed:
        return 'Closed';
    }
    return null;
  }
}

/// A query type the LO picks in "Select your Query".
class HelpdeskQueryType {
  const HelpdeskQueryType({required this.id, required this.name});

  final String id;
  final String name;

  factory HelpdeskQueryType.fromJson(Map<String, dynamic> json) =>
      HelpdeskQueryType(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}

class HelpdeskQuery {
  const HelpdeskQuery({
    required this.id,
    required this.ticketNo,
    required this.queryTypeName,
    required this.title,
    required this.description,
    required this.attachments,
    this.status,
    this.closedType,
    this.createdAt,
    this.modifiedAt,
  });

  final String id;
  final String ticketNo;
  final String queryTypeName;
  final String title;
  final String description;
  final List<String> attachments;
  final String? status;

  /// CHAT or CALL when closed.
  final String? closedType;
  final DateTime? createdAt;

  /// Last message or status change.
  final DateTime? modifiedAt;

  bool get isClosed => status == HelpdeskStatus.closed;

  factory HelpdeskQuery.fromJson(Map<String, dynamic> json) => HelpdeskQuery(
    id: json['id']?.toString() ?? '',
    ticketNo: json['ticketNo']?.toString() ?? '',
    queryTypeName: json['queryTypeName']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    attachments: _urls(json['attachments']),
    status: json['status']?.toString(),
    closedType: json['closedType']?.toString(),
    createdAt: parseHelpdeskDate(json['createdAt']),
    modifiedAt: parseHelpdeskDate(json['lastActivityAt'] ?? json['createdAt']),
  );
}

/// One entry in a query's conversation.
class HelpdeskComment {
  const HelpdeskComment({
    required this.senderType,
    required this.senderName,
    required this.body,
    required this.attachments,
    this.createdAt,
  });

  /// LO (the officer), TEAM (help desk) or SYSTEM (automatic note).
  final String senderType;
  final String senderName;
  final String body;
  final List<String> attachments;
  final DateTime? createdAt;

  bool get fromTeam => senderType == 'TEAM';
  bool get isSystem => senderType == 'SYSTEM';

  String get name => senderName.trim();

  String get initials {
    final parts = senderName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return fromTeam ? 'HD' : '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  factory HelpdeskComment.fromJson(Map<String, dynamic> json) =>
      HelpdeskComment(
        senderType: json['senderType']?.toString() ?? '',
        senderName: json['senderName']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        attachments: _urls(json['attachments']),
        createdAt: parseHelpdeskDate(json['createdAt']),
      );
}

/// A query with its conversation (detail call).
class HelpdeskQueryDetail {
  const HelpdeskQueryDetail({required this.query, required this.messages});

  final HelpdeskQuery query;
  final List<HelpdeskComment> messages;

  factory HelpdeskQueryDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'];
    return HelpdeskQueryDetail(
      query: HelpdeskQuery.fromJson(json),
      messages: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => HelpdeskComment.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────

DateTime? parseHelpdeskDate(Object? raw) {
  if (raw == null) return null;
  if (raw is num) {
    final ms = raw > 1e12 ? raw.toInt() : raw.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  return DateTime.tryParse(raw.toString())?.toLocal();
}

/// "Updated 3 hrs ago".
String helpdeskTimeAgo(DateTime? date, {DateTime? now}) {
  if (date == null) return '';
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.isNegative) return 'Just now';
  if (diff.inDays >= 7) return 'Updated on ${_formatDate(date)}';
  if (diff.inDays >= 1) {
    return 'Updated ${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
  }
  if (diff.inHours >= 1) {
    return 'Updated ${diff.inHours} ${diff.inHours == 1 ? 'hr' : 'hrs'} ago';
  }
  if (diff.inMinutes >= 1) {
    final m = diff.inMinutes;
    return 'Updated $m ${m == 1 ? 'min' : 'mins'} ago';
  }
  return 'Updated just now';
}

String _formatDate(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${d.day}/${d.month}/${d.year}, $hour:$minute $ampm';
}

List<String> _urls(Object? value) {
  if (value is List) {
    return value
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }
  final s = value?.toString() ?? '';
  return s.isEmpty ? const [] : [s];
}
