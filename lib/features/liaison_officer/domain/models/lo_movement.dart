/// First-class movement kinds for LO coordination (maps onto travel APIs).
enum LoMovementKind {
  arrival,
  transfer,
  venueEntry,
  departure;

  String get label => switch (this) {
        LoMovementKind.arrival => 'Arrival',
        LoMovementKind.transfer => 'Transfer',
        LoMovementKind.venueEntry => 'Venue entry',
        LoMovementKind.departure => 'Departure',
      };

  String get apiCode => switch (this) {
        LoMovementKind.arrival => 'arrival',
        LoMovementKind.transfer => 'transfer',
        LoMovementKind.venueEntry => 'venue_entry',
        LoMovementKind.departure => 'departure',
      };

  static LoMovementKind? tryParse(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return switch (v) {
      'arrival' => LoMovementKind.arrival,
      'transfer' => LoMovementKind.transfer,
      'venue_entry' || 'venue' || 'venueentry' => LoMovementKind.venueEntry,
      'departure' => LoMovementKind.departure,
      _ => null,
    };
  }
}

class LoMovementUpdate {
  const LoMovementUpdate({
    required this.kind,
    this.flight,
    this.terminal,
    this.date,
    this.time,
    this.notes,
    this.location,
  });

  final LoMovementKind kind;
  final String? flight;
  final String? terminal;
  final String? date;
  final String? time;
  final String? notes;
  final String? location;

  /// Body for CAP `PUT …/travel` and/or `PUT …/arrival-flight`.
  Map<String, dynamic> toTravelBody() {
    final body = <String, dynamic>{
      'movementKind': kind.apiCode,
      if (notes != null && notes!.trim().isNotEmpty) 'remarks': notes!.trim(),
      if (location != null && location!.trim().isNotEmpty)
        'location': location!.trim(),
    };
    switch (kind) {
      case LoMovementKind.arrival:
        if (flight != null) body['arrivalFlight'] = flight;
        if (terminal != null) body['arrivalTerminal'] = terminal;
        if (date != null) body['arrivalDate'] = date;
        if (time != null) body['arrivalTime'] = time;
      case LoMovementKind.departure:
        if (flight != null) body['departureFlight'] = flight;
        if (terminal != null) body['departureTerminal'] = terminal;
        if (date != null) body['departureDate'] = date;
        if (time != null) body['departureTime'] = time;
      case LoMovementKind.transfer:
      case LoMovementKind.venueEntry:
        if (date != null) body['movementDate'] = date;
        if (time != null) body['movementTime'] = time;
        if (flight != null) body['arrivalFlight'] = flight;
    }
    return body;
  }

  bool get usesArrivalFlightEndpoint =>
      kind == LoMovementKind.arrival ||
      kind == LoMovementKind.transfer ||
      kind == LoMovementKind.venueEntry;
}
