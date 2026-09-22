import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for LO.3.2/3.3 signed-DO + nomination status.
///
/// CAP OpenAPI does not yet expose `/app/lo-organisations/{id}/do-letter/*`.
/// Live Dio calls may 404; this store keeps UI state consistent in mock and
/// as a fallback when the server has no endpoint.
class DoLetterLocalStore {
  DoLetterLocalStore._();

  static const _key = 'lo_org_do_letter_status_v1';
  static const _pdfKey = 'lo_org_do_letter_pdf_v1';

  static Future<Map<String, dynamic>> _all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  static Future<void> _save(Map<String, dynamic> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(all));
  }

  static Future<Map<String, dynamic>> statusFor(String orgId) async {
    final all = await _all();
    final v = all[orgId];
    if (v is Map) return Map<String, dynamic>.from(v);
    return {
      'signedUploaded': false,
      'nominationSent': false,
      'checklistConfirmed': false,
      'signingAuthority': null,
      'templateId': null,
      'updatedAt': null,
      'hasPdf': false,
    };
  }

  static Future<void> markSigned({
    required String orgId,
    required String signingAuthority,
    String? templateId,
    List<int>? pdfBytes,
  }) async {
    final all = await _all();
    all[orgId] = {
      ...await statusFor(orgId),
      'signedUploaded': true,
      'checklistConfirmed': true,
      'signingAuthority': signingAuthority,
      'templateId': templateId,
      'hasPdf': pdfBytes != null && pdfBytes.isNotEmpty,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _save(all);
    if (pdfBytes != null && pdfBytes.isNotEmpty) {
      await _savePdf(orgId, pdfBytes);
    }
  }

  static Future<void> _savePdf(String orgId, List<int> bytes) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pdfKey);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map[orgId] = base64Encode(bytes);
    await prefs.setString(_pdfKey, jsonEncode(map));
  }

  static Future<Uint8List?> signedPdfBytes(String orgId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pdfKey);
    if (raw == null || raw.isEmpty) return null;
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final b64 = map[orgId]?.toString();
    if (b64 == null || b64.isEmpty) return null;
    return Uint8List.fromList(base64Decode(b64));
  }

  static Future<void> markNominationSent(String orgId) async {
    final all = await _all();
    final cur = await statusFor(orgId);
    all[orgId] = {
      ...cur,
      'nominationSent': true,
      'nominationSentAt': DateTime.now().toIso8601String(),
    };
    await _save(all);
  }

  static Future<Map<String, Map<String, dynamic>>> allStatuses() async {
    final all = await _all();
    return all.map(
      (k, v) => MapEntry(
        k,
        v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{},
      ),
    );
  }
}
