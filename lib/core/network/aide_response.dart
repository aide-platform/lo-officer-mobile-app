import 'api_exception.dart';

/// CAP envelope: `{ success, message, data, errorCode, timestamp }`.
class AideResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? errorCode;
  final String? timestamp;

  const AideResponse({
    required this.success,
    this.message,
    this.data,
    this.errorCode,
    this.timestamp,
  });

  factory AideResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw)? parseData,
  ) {
    final raw = json['data'];
    return AideResponse<T>(
      success: json['success'] == true || json['success'] == null,
      message: json['message']?.toString(),
      data: raw == null || parseData == null ? raw as T? : parseData(raw),
      errorCode: json['errorCode']?.toString(),
      timestamp: json['timestamp']?.toString(),
    );
  }

  static AideResponse<T> unwrap<T>(
    dynamic body, {
    T Function(dynamic raw)? parseData,
  }) {
    if (body is! Map) {
      throw ApiException('Unexpected response shape.');
    }
    final map = Map<String, dynamic>.from(body);
    final parsed = AideResponse.fromJson(map, parseData);
    if (parsed.success == false) {
      throw ApiException(
        parsed.message ?? 'Request failed',
        statusCode: null,
      );
    }
    return parsed;
  }

  static Map<String, dynamic> asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw ApiException('Expected object payload.');
  }

  static List<Map<String, dynamic>> asMapList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
