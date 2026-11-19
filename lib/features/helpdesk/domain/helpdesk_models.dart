/// Help desk models. Field names follow the event-services payloads that the
/// attendees app reads, so both apps see the same tickets.
library;

/// Ticket status codes used by event-services.
class HelpdeskStatus {
  HelpdeskStatus._();

  static const int inReview = 0;
  static const int inProgress = 1;
  static const int assigned = 2;
  static const int closed = 4;

  /// Label shown next to the tracking number; null for codes with no label.
  static String? label(int? status) {
    switch (status) {
      case inReview:
        return 'In review';
      case inProgress:
      case assigned:
        return 'In progress';
      case closed:
        return 'Closed';
    }
    return null;
  }
}

class HelpdeskQuery {
  const HelpdeskQuery({
    required this.id,
    required this.title,
    required this.queryType,
    required this.trackingNo,
    required this.status,
    required this.description,
    required this.attachments,
    this.modifiedAt,
  });

  final String id;
  final String title;
  final String queryType;
  final String trackingNo;
  final int? status;
  final String description;
  final List<String> attachments;
  final DateTime? modifiedAt;

  bool get isClosed => status == HelpdeskStatus.closed;

  factory HelpdeskQuery.fromJson(Map<String, dynamic> json) {
    var description = '';
    final attachments = <String>[];
    final moreInfo = json['moreInfo'];
    if (moreInfo is List) {
      for (final entry in moreInfo.whereType<Map>()) {
        final name = entry['name']?.toString();
        final value = entry['value'];
        if (name == 'description' && value != null) {
          description = value.toString();
        } else if (name == 'attachments') {
          attachments.addAll(_urls(value));
        }
      }
    }
    return HelpdeskQuery(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      queryType: _text(json['queryType']),
      trackingNo: json['trackingNo']?.toString() ?? '',
      status: _int(json['status']),
      description: description,
      attachments: attachments,
      modifiedAt: parseHelpdeskDate(json['modifiedAt'] ?? json['createdAt']),
    );
  }
}

class HelpdeskComment {
  const HelpdeskComment({
    required this.firstName,
    required this.lastName,
    required this.description,
    required this.attachments,
    this.logo,
    this.createdAt,
  });

  final String firstName;
  final String lastName;
  final String description;
  final List<String> attachments;
  final String? logo;
  final DateTime? createdAt;

  String get name => '$firstName $lastName'.trim();

  String get initials {
    String first(String s) => s.trim().isEmpty ? '' : s.trim()[0];
    final value = (first(firstName) + first(lastName)).toUpperCase();
    return value.isEmpty ? '?' : value;
  }

  factory HelpdeskComment.fromJson(Map<String, dynamic> json) {
    final info = json['replyInfo'] is Map
        ? Map<String, dynamic>.from(json['replyInfo'] as Map)
        : const <String, dynamic>{};
    final logo = info['logo']?.toString();
    return HelpdeskComment(
      firstName: info['firstName']?.toString() ?? '',
      lastName: info['lastName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      attachments: _urls(json['attachment']),
      logo: logo == null || logo.isEmpty ? null : logo,
      createdAt: parseHelpdeskDate(json['createdAt']),
    );
  }
}

/// Who is writing: sent as `userInfo` / `replyInfo` with every ticket and
/// comment, like the attendees app does. The ticket owner (EventUser id) is
/// set by aide-service from the login, never by the app.
class HelpdeskUser {
  const HelpdeskUser({
    this.firstName,
    this.lastName,
    this.email,
    this.contactNo,
  });

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? contactNo;

  Map<String, dynamic> toInfo() => {
    if (_has(firstName)) 'firstName': firstName,
    if (_has(lastName)) 'lastName': lastName,
    if (_has(email)) 'email': email,
    if (_has(contactNo)) 'contactNo': contactNo,
  };

  static bool _has(String? v) => v != null && v.trim().isNotEmpty;
}

// ── Dynamic "Ask for Help" form ───────────────────────────────────────────

class HelpdeskForm {
  const HelpdeskForm({required this.id, required this.pages});

  final String? id;
  final List<HelpdeskFormPage> pages;

  Iterable<HelpdeskField> get fields => pages.expand((p) => p.elements);

  factory HelpdeskForm.fromJson(Map<String, dynamic> json) {
    final pages = (json['pages'] is List ? json['pages'] as List : const [])
        .whereType<Map>()
        .map((p) => HelpdeskFormPage.fromJson(Map<String, dynamic>.from(p)))
        .where((p) => p.elements.isNotEmpty)
        .toList();
    return HelpdeskForm(id: json['id']?.toString(), pages: pages);
  }
}

class HelpdeskFormPage {
  const HelpdeskFormPage({required this.elements});

  final List<HelpdeskField> elements;

  factory HelpdeskFormPage.fromJson(Map<String, dynamic> json) {
    final raw = json['elements'] is List ? json['elements'] as List : const [];
    return HelpdeskFormPage(
      elements: raw
          .whereType<Map>()
          .map((e) => HelpdeskField.fromJson(Map<String, dynamic>.from(e)))
          .where((f) => f.name.isNotEmpty)
          .toList(),
    );
  }
}

/// One option of a choice field. [raw] keeps the whole server object so the
/// configured `textName` can be read back on submit.
class HelpdeskChoice {
  const HelpdeskChoice({required this.text, required this.value, this.raw});

  final String text;
  final Object? value;
  final Map<String, dynamic>? raw;

  @override
  bool operator ==(Object other) =>
      other is HelpdeskChoice && other.text == text && other.value == value;

  @override
  int get hashCode => Object.hash(text, value);
}

class HelpdeskChoicesByUrl {
  const HelpdeskChoicesByUrl({
    required this.url,
    required this.path,
    required this.textName,
    required this.methodType,
  });

  final String url;
  final String path;
  final String textName;
  final String methodType;

  bool get isConfigured => url.isNotEmpty && path.isNotEmpty;

  /// `{name}` placeholders in [url], in order.
  List<String> get placeholders =>
      RegExp(r'\{(.*?)\}').allMatches(url).map((m) => m.group(1)!).toList();

  factory HelpdeskChoicesByUrl.fromJson(Map<String, dynamic> json) =>
      HelpdeskChoicesByUrl(
        url: json['url']?.toString() ?? '',
        path: json['path']?.toString() ?? '',
        textName: json['textName']?.toString() ?? 'text',
        methodType: (json['methodType']?.toString() ?? 'GET').toUpperCase(),
      );
}

class HelpdeskField {
  HelpdeskField({
    required this.name,
    required this.title,
    required this.type,
    required this.inputType,
    required this.placeholder,
    required this.isRequired,
    required this.requiredErrorText,
    required this.allowMultiple,
    required this.isPrimary,
    required this.acceptedTypes,
    required this.maxSizeMb,
    required this.choices,
    this.choicesByUrl,
    this.visibleIf,
  });

  final String name;
  final String title;
  final String type;
  final String inputType;
  final String placeholder;
  final bool isRequired;
  final String requiredErrorText;
  final bool allowMultiple;
  final bool isPrimary;
  final List<String> acceptedTypes;
  final double maxSizeMb;
  final HelpdeskChoicesByUrl? choicesByUrl;
  final String? visibleIf;

  /// Static choices, or the last list loaded from [choicesByUrl].
  List<HelpdeskChoice> choices;

  bool get isChoice =>
      type == 'dropdown' || type == 'checkbox' || type == 'radiogroup';
  bool get isFile => type == 'file';
  bool get isText =>
      type == 'text' || type == 'texteditor' || type == 'comment';
  bool get isMultiline =>
      type == 'texteditor' || type == 'comment' || inputType == 'textarea';
  bool get hasRemoteChoices => choicesByUrl?.isConfigured ?? false;

  /// The attendees app never shows the banner / logo upload fields here.
  bool get isSupported {
    if (isFile) return name != 'profileBanner' && name != 'logo';
    return isChoice || isText;
  }

  factory HelpdeskField.fromJson(Map<String, dynamic> json) {
    final byUrl = json['choicesByUrl'];
    final accepted = json['acceptedTypes'];
    return HelpdeskField(
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      inputType: json['inputType']?.toString() ?? 'text',
      placeholder:
          json['placeHolder']?.toString() ??
          json['placeholder']?.toString() ??
          '',
      isRequired: json['isRequired'] == true,
      requiredErrorText:
          (json['requiredErrorText']?.toString().trim().isNotEmpty ?? false)
          ? json['requiredErrorText'].toString()
          : 'This field is required.',
      allowMultiple: json['allowMultiple'] == true,
      isPrimary: json['isPrimary'] == true,
      acceptedTypes: accepted is List
          ? accepted.map((e) => e.toString().toLowerCase()).toList()
          : const ['jpg', 'jpeg', 'png', 'pdf'],
      maxSizeMb: (json['maxSize'] is num)
          ? (json['maxSize'] as num).toDouble()
          : double.tryParse(json['maxSize']?.toString() ?? '') ?? 5,
      choices: parseChoices(json['choices']),
      choicesByUrl: byUrl is Map
          ? HelpdeskChoicesByUrl.fromJson(Map<String, dynamic>.from(byUrl))
          : null,
      visibleIf: (json['visibleIf']?.toString().trim().isEmpty ?? true)
          ? null
          : json['visibleIf'].toString(),
    );
  }

  static List<HelpdeskChoice> parseChoices(Object? raw) {
    if (raw is! List) return [];
    return raw.map((c) {
      if (c is Map) {
        final map = Map<String, dynamic>.from(c);
        final text = (map['text'] ?? map['value'] ?? '').toString();
        return HelpdeskChoice(
          text: text,
          value: map['value'] ?? text,
          raw: map,
        );
      }
      return HelpdeskChoice(text: c.toString(), value: c.toString());
    }).toList();
  }
}

/// A parsed `visibleIf` rule: `{parent} anyOf ['a','b']` or
/// `{parent} NOT ['a']` (same two forms the attendees app understands).
class HelpdeskVisibleRule {
  const HelpdeskVisibleRule({
    required this.parent,
    required this.values,
    required this.negate,
  });

  final String parent;
  final List<String> values;
  final bool negate;

  static HelpdeskVisibleRule? parse(String? expression) {
    if (expression == null) return null;
    final anyOf = expression.split('anyOf');
    final parts = anyOf.length > 1 ? anyOf : expression.split('NOT');
    if (parts.length < 2) return null;
    final head = parts[0];
    final open = head.lastIndexOf('{');
    final close = head.lastIndexOf('}');
    if (open < 0 || close <= open) return null;
    final values = parts[1]
        .replaceAll(RegExp(r'''["|\[\]{}']+'''), '')
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    return HelpdeskVisibleRule(
      parent: head.substring(open + 1, close),
      values: values,
      negate: anyOf.length <= 1,
    );
  }

  /// [selected] are the parent's current values as text.
  bool isVisible(List<String> selected) {
    if (selected.isEmpty) return false;
    final hit = selected.any(values.contains);
    return negate ? !hit : hit;
  }
}

// ── Parsing helpers ───────────────────────────────────────────────────────

DateTime? parseHelpdeskDate(Object? raw) {
  if (raw == null) return null;
  if (raw is num) {
    final ms = raw > 1e12 ? raw.toInt() : raw.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  return DateTime.tryParse(raw.toString())?.toLocal();
}

/// Same wording as the attendees app: "Updated 3 hrs ago".
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

String _text(Object? value) {
  if (value is Map) return (value['text'] ?? value['name'] ?? '').toString();
  if (value is List) return value.map(_text).join(', ');
  return value?.toString() ?? '';
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
