import 'package:liaison_officer/features/liaison_officer/data/models/connecting_flight.dart';

import '../../../../core/storage/sqlite/app_sqlite_db.dart';

class LoTravelUpdate {
  final String delegateName;
  final String arrivalFlightNumber;
  final String arrivalTerminal;
  final DateTime? arrivalDate;
  final String? arrivalTime;
  final List<ConnectingFlight> arrivalConnectingFlights;
  final String departureFlightNumber;
  final String departureTerminal;
  final DateTime? departureDate;
  final String? departureTime;
  final List<ConnectingFlight> departureConnectingFlights;

  const LoTravelUpdate({
    required this.delegateName,
    this.arrivalFlightNumber = '',
    this.arrivalTerminal = '',
    this.arrivalDate,
    this.arrivalTime,
    this.arrivalConnectingFlights = const [],
    this.departureFlightNumber = '',
    this.departureTerminal = '',
    this.departureDate,
    this.departureTime,
    this.departureConnectingFlights = const [],
  });

  LoTravelUpdate copyWith({
    String? delegateName,
    String? arrivalFlightNumber,
    String? arrivalTerminal,
    DateTime? arrivalDate,
    String? arrivalTime,
    List<ConnectingFlight>? arrivalConnectingFlights,
    String? departureFlightNumber,
    String? departureTerminal,
    DateTime? departureDate,
    String? departureTime,
    List<ConnectingFlight>? departureConnectingFlights,
  }) {
    return LoTravelUpdate(
      delegateName: delegateName ?? this.delegateName,
      arrivalFlightNumber: arrivalFlightNumber ?? this.arrivalFlightNumber,
      arrivalTerminal: arrivalTerminal ?? this.arrivalTerminal,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      arrivalConnectingFlights:
          arrivalConnectingFlights ?? this.arrivalConnectingFlights,
      departureFlightNumber:
          departureFlightNumber ?? this.departureFlightNumber,
      departureTerminal: departureTerminal ?? this.departureTerminal,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      departureConnectingFlights:
          departureConnectingFlights ?? this.departureConnectingFlights,
    );
  }

  Map<String, dynamic> toMap() => {
        'delegateName': delegateName,
        'arrivalFlightNumber': arrivalFlightNumber,
        'arrivalTerminal': arrivalTerminal,
        'arrivalDate': arrivalDate?.toIso8601String(),
        'arrivalTime': arrivalTime,
        'arrivalConnectingFlights':
            arrivalConnectingFlights.map((e) => e.toMap()).toList(),
        'departureFlightNumber': departureFlightNumber,
        'departureTerminal': departureTerminal,
        'departureDate': departureDate?.toIso8601String(),
        'departureTime': departureTime,
        'departureConnectingFlights':
            departureConnectingFlights.map((e) => e.toMap()).toList(),
      };

  factory LoTravelUpdate.fromMap(Map<String, dynamic> map) {
    return LoTravelUpdate(
      delegateName: map['delegateName']?.toString() ?? '',
      arrivalFlightNumber: map['arrivalFlightNumber']?.toString() ?? '',
      arrivalTerminal: map['arrivalTerminal']?.toString() ?? '',
      arrivalDate: map['arrivalDate'] != null
          ? DateTime.tryParse(map['arrivalDate'].toString())
          : null,
      arrivalTime: map['arrivalTime']?.toString(),
      arrivalConnectingFlights: (map['arrivalConnectingFlights'] as List? ?? [])
          .whereType<Map>()
          .map((e) => ConnectingFlight.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      departureFlightNumber: map['departureFlightNumber']?.toString() ?? '',
      departureTerminal: map['departureTerminal']?.toString() ?? '',
      departureDate: map['departureDate'] != null
          ? DateTime.tryParse(map['departureDate'].toString())
          : null,
      departureTime: map['departureTime']?.toString(),
      departureConnectingFlights:
          (map['departureConnectingFlights'] as List? ?? [])
              .whereType<Map>()
              .map((e) => ConnectingFlight.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
    );
  }

  static Future<List<LoTravelUpdate>> all() async {
    final rows = await AppSqliteDb.getJsonList('lo_travel_updates');
    if (rows == null) return const [];
    return rows
        .whereType<Map>()
        .map((value) => LoTravelUpdate.fromMap(Map<String, dynamic>.from(value)))
        .toList();
  }

  static Future<void> saveAll(List<LoTravelUpdate> updates) async {
    await AppSqliteDb.saveJsonList(
      'lo_travel_updates',
      updates.map((e) => e.toMap()).toList(),
    );
  }

  static Future<void> upsert(LoTravelUpdate update) async {
    final current = await all();
    final newList = <LoTravelUpdate>[];
    var replaced = false;

    for (final item in current) {
      if (item.delegateName == update.delegateName) {
        newList.add(update);
        replaced = true;
      } else {
        newList.add(item);
      }
    }

    if (!replaced) newList.add(update);
    await saveAll(newList);
  }
}
