class EventNomination {
  final String eventName;
  final DateTime dateTime;
  final String venue;
  final String? notes;

  const EventNomination({
    required this.eventName,
    required this.dateTime,
    required this.venue,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'eventName': eventName,
        'dateTime': dateTime.toIso8601String(),
        'venue': venue,
        'notes': notes,
      };

  factory EventNomination.fromMap(Map<String, dynamic> map) {
    return EventNomination(
      eventName: map['eventName']?.toString() ?? '',
      dateTime: map['dateTime'] != null
          ? DateTime.tryParse(map['dateTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      venue: map['venue']?.toString() ?? '',
      notes: map['notes']?.toString(),
    );
  }
}
