class Transport {
  String carType;
  String vehicleNumber;
  String driverName;
  String driverContact;
  String status;
  String? flightNumber;
  DateTime? arrivalTime;
  String? arrivalTerminal;
  String? arrivalLocation;

  Transport({
    required this.carType,
    this.vehicleNumber = '',
    required this.driverName,
    required this.driverContact,
    required this.status,
    this.flightNumber,
    this.arrivalTime,
    this.arrivalTerminal,
    this.arrivalLocation,
  });

  String get vehicleType => carType;

  Map<String, dynamic> toMap() => {
        'carType': carType,
        'vehicleNumber': vehicleNumber,
        'driverName': driverName,
        'driverContact': driverContact,
        'status': status,
        'flightNumber': flightNumber,
        'arrivalTime': arrivalTime?.toIso8601String(),
        'arrivalTerminal': arrivalTerminal,
        'arrivalLocation': arrivalLocation,
      };

  factory Transport.empty() {
    return Transport(
      carType: '',
      vehicleNumber: '',
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
        carType: map['carType']?.toString() ?? map['vehicleType']?.toString() ?? '',
        vehicleNumber: map['vehicleNumber']?.toString() ?? '',
        driverName: map['driverName']?.toString() ?? '',
        driverContact: map['driverContact']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Pending',
        flightNumber: map['flightNumber']?.toString(),
        arrivalTime: map['arrivalTime'] != null
            ? DateTime.tryParse(map['arrivalTime'].toString())
            : null,
        arrivalTerminal: map['arrivalTerminal']?.toString(),
        arrivalLocation: map['arrivalLocation']?.toString(),
      );
}
