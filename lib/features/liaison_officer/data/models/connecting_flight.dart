class ConnectingFlight {
  final String flightNumber;
  final String terminal;
  final DateTime? date;
  final String? time;

  const ConnectingFlight({
    this.flightNumber = '',
    this.terminal = '',
    this.date,
    this.time,
  });

  ConnectingFlight copyWith({
    String? flightNumber,
    String? terminal,
    DateTime? date,
    String? time,
    bool clearDate = false,
    bool clearTime = false,
  }) {
    return ConnectingFlight(
      flightNumber: flightNumber ?? this.flightNumber,
      terminal: terminal ?? this.terminal,
      date: clearDate ? null : (date ?? this.date),
      time: clearTime ? null : (time ?? this.time),
    );
  }

  Map<String, dynamic> toMap() => {
        'flightNumber': flightNumber,
        'terminal': terminal,
        'date': date?.toIso8601String(),
        'time': time,
      };

  factory ConnectingFlight.fromMap(Map<String, dynamic> map) {
    return ConnectingFlight(
      flightNumber: map['flightNumber']?.toString() ?? '',
      terminal: map['terminal']?.toString() ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString())
          : null,
      time: map['time']?.toString(),
    );
  }
}
