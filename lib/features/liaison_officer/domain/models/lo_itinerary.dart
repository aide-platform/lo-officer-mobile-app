import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';

/// Composed itinerary item (no dedicated CAP itinerary endpoint).
enum LoItineraryKind { arrival, event, transport, departure }

class LoItineraryItem {
  const LoItineraryItem({
    required this.kind,
    required this.title,
    this.subtitle,
    this.date,
    this.time,
    this.venue,
    this.sortKey,
  });

  final LoItineraryKind kind;
  final String title;
  final String? subtitle;
  final String? date;
  final String? time;
  final String? venue;
  final String? sortKey;

  static List<LoItineraryItem> compose({
    required MyLoAssignmentDto assignment,
    List<Map<String, dynamic>> nominations = const [],
    List<Map<String, dynamic>> vehicles = const [],
  }) {
    final items = <LoItineraryItem>[];

    if (_hasAny([
      assignment.arrivalFlight,
      assignment.arrivalDate,
      assignment.arrivalTime,
      assignment.arrivalTerminal,
    ])) {
      items.add(LoItineraryItem(
        kind: LoItineraryKind.arrival,
        title: 'Arrival',
        subtitle: [
          if (assignment.arrivalFlight != null &&
              assignment.arrivalFlight!.isNotEmpty)
            'Flight ${assignment.arrivalFlight}',
          if (assignment.arrivalTerminal != null &&
              assignment.arrivalTerminal!.isNotEmpty)
            'Terminal ${assignment.arrivalTerminal}',
        ].join(' · '),
        date: assignment.arrivalDate,
        time: assignment.arrivalTime,
        venue: assignment.arrivalTerminal,
        sortKey: _sortKey(assignment.arrivalDate, assignment.arrivalTime),
      ));
    }

    for (final v in vehicles) {
      final pickup = v['pickupTime']?.toString() ??
          v['pickupSchedule']?.toString() ??
          v['schedule']?.toString();
      final number = v['vehicleNumber']?.toString() ?? '';
      final type = v['vehicleType']?.toString() ?? 'Vehicle';
      final driver = v['driverName']?.toString();
      items.add(LoItineraryItem(
        kind: LoItineraryKind.transport,
        title: '$type${number.isNotEmpty ? ' · $number' : ''}',
        subtitle: [
          if (driver != null && driver.isNotEmpty) 'Driver: $driver',
          if (v['driverContact'] != null) v['driverContact'].toString(),
        ].join(' · '),
        date: v['pickupDate']?.toString() ?? assignment.arrivalDate,
        time: pickup,
        venue: v['pickupLocation']?.toString(),
        sortKey: _sortKey(
          v['pickupDate']?.toString() ?? assignment.arrivalDate,
          pickup,
        ),
      ));
    }

    for (final n in nominations) {
      items.add(LoItineraryItem(
        kind: LoItineraryKind.event,
        title: n['eventName']?.toString() ?? 'Event',
        subtitle: n['eventDescription']?.toString(),
        date: n['eventDate']?.toString(),
        time: n['eventTime']?.toString(),
        venue: n['venue']?.toString() ?? n['location']?.toString(),
        sortKey: _sortKey(
          n['eventDate']?.toString(),
          n['eventTime']?.toString(),
        ),
      ));
    }

    if (_hasAny([
      assignment.departureFlight,
      assignment.departureDate,
      assignment.departureTime,
      assignment.departureTerminal,
    ])) {
      items.add(LoItineraryItem(
        kind: LoItineraryKind.departure,
        title: 'Departure',
        subtitle: [
          if (assignment.departureFlight != null &&
              assignment.departureFlight!.isNotEmpty)
            'Flight ${assignment.departureFlight}',
          if (assignment.departureTerminal != null &&
              assignment.departureTerminal!.isNotEmpty)
            'Terminal ${assignment.departureTerminal}',
        ].join(' · '),
        date: assignment.departureDate,
        time: assignment.departureTime,
        venue: assignment.departureTerminal,
        sortKey: _sortKey(assignment.departureDate, assignment.departureTime),
      ));
    }

    items.sort((a, b) {
      final ka = a.sortKey ?? '9999';
      final kb = b.sortKey ?? '9999';
      return ka.compareTo(kb);
    });
    return items;
  }

  static bool _hasAny(List<String?> values) =>
      values.any((e) => e != null && e.trim().isNotEmpty);

  static String _sortKey(String? date, String? time) {
    final d = (date ?? '').trim();
    final t = (time ?? '').trim();
    if (d.isEmpty) return '9999-99-99T99:99';
    return '${d}T${t.isEmpty ? '00:00' : t}';
  }
}
