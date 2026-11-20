import 'package:flutter/foundation.dart';

/// Tells open help desk screens that a query changed on the server (a
/// `helpdesk:<id>` push arrived while the app was in the foreground), so the
/// list and an open query reload.
class HelpdeskUpdates extends ChangeNotifier {
  HelpdeskUpdates._();

  static final HelpdeskUpdates instance = HelpdeskUpdates._();

  /// Id of the query that changed last.
  String? lastQueryId;

  void notify(String queryId) {
    lastQueryId = queryId;
    notifyListeners();
  }
}
