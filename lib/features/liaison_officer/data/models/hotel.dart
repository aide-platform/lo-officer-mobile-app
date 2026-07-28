
class Hotel {
  String name;
  String roomNumber;
  String stayDuration;
  Hotel({
    required this.name,
    required this.roomNumber,
    required this.stayDuration,
  });
  Map<String, dynamic> toMap() => {
        'name': name,
        'roomNumber': roomNumber,
        'stayDuration': stayDuration,
      };
  factory Hotel.empty() {
    return Hotel(
      name: '',
      roomNumber: '',
      stayDuration: '',
    );
  }
  factory Hotel.fromMap(Map<String, dynamic> map) => Hotel(
        name: map['name']?.toString() ?? '',
        roomNumber: map['roomNumber']?.toString() ?? '',
        stayDuration: map['stayDuration']?.toString() ?? '',
      );
}
