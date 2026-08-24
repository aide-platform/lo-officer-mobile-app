import 'package:flutter/foundation.dart';
import '../storage/sqlite/app_sqlite_db.dart';

class MockEmailNotifier {
  MockEmailNotifier._();
  static const outboxKey = 'email_outbox';

  /// Store a mock email in local sqlite outbox for inspection.
  static Future<void> send({
    required String to,
    required String subject,
    required String body,
  }) async {
    if (kDebugMode) {
      // Print in debug runs for immediate visibility
      // ignore: avoid_print
      print('MockEmailNotifier.send -> to: $to subject: $subject');
    }

    final now = DateTime.now().toIso8601String();
    final entry = {
      'to': to,
      'subject': subject,
      'body': body,
      'timestamp': now,
    };

    final existing = await AppSqliteDb.getJsonList(outboxKey) ?? <dynamic>[];
    existing.insert(0, entry);
    await AppSqliteDb.saveJsonList(outboxKey, existing);
  }
}
