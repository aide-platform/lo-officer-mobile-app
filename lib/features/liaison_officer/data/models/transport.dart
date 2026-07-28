
class Transport {
  String carType;
  String driverName;
  String driverContact;
  String status;
  String? flightNumber;
  DateTime? arrivalTime;
  String? arrivalTerminal;
  String? arrivalLocation;

  Transport({
    required this.carType,
    required this.driverName,
    required this.driverContact,
    required this.status,
    this.flightNumber,
    this.arrivalTime,
    this.arrivalTerminal,
    this.arrivalLocation,
  });

  Map<String, dynamic> toMap() => {
    'carType': carType,
    'driverName': driverName,
    'driverContact': driverContact,
    'status': status,
    'flightNumber': flightNumber,
    'arrivalTime': arrivalTime?.toIso8601String(), // ✅ FIXED
    'arrivalTerminal': arrivalTerminal,
    'arrivalLocation': arrivalLocation,
  };
  factory Transport.empty() {
    return  Transport(
      carType: '',
      driverName: '',
      driverContact: '',
      status: 'Pending',
      flightNumber: '',
      arrivalTime: DateTime.now(),
      arrivalTerminal: '',
      arrivalLocation: 'Pending',
    );
  }
  factory Transport.fromMap(Map<String, dynamic> map) => Transport(
    carType: map['carType'] ?? '',
    driverName: map['driverName'] ?? '',
    driverContact: map['driverContact'] ?? '',
    status: map['status'] ?? 'Pending',
    flightNumber: map['flightNumber'],
    arrivalTime: map['arrivalTime'] != null
        ? DateTime.parse(map['arrivalTime'])
        : null, // ✅ FIXED
    arrivalTerminal: map['arrivalTerminal'],
    arrivalLocation: map['arrivalLocation'],
  );
}