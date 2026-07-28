class Engagement {
  String eventName;
  DateTime dateTime;
  String rsvpStatus;
  String comments;
  Engagement({
    required this.eventName,
    required this.dateTime,
    required this.rsvpStatus,
    this.comments = '',
  });
  Map<String, dynamic> toMap() => {
        'eventName': eventName,
        'dateTime': dateTime.toIso8601String(),
        'rsvpStatus': rsvpStatus,
        'comments': comments,
      };
  factory Engagement.fromMap(Map<String, dynamic> map) {
    DateTime parsed;
    try {
      parsed = DateTime.parse(map['dateTime']?.toString() ?? '');
    } catch (_) {
      parsed = DateTime.now();
    }
    return Engagement(
      eventName: map['eventName']?.toString() ?? '',
      dateTime: parsed,
      rsvpStatus: map['rsvpStatus']?.toString() ?? 'Pending',
      comments: map['comments']?.toString() ?? '',
    );
  }
}
