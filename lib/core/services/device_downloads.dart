import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves files into the phone's public Downloads folder, the way a browser
/// download works on aide-ui (`saveBlob`). Android uses the native channel in
/// `MainActivity.kt` (MediaStore on Android 10+). iOS has no shared Downloads
/// folder, so the file goes to app Documents and the share sheet opens
/// ("Save to Files").
class DeviceDownloads {
  DeviceDownloads._();

  static const _channel = MethodChannel('com.bel.liaison_officer/downloads');

  /// Returns a handle for [open], or null when the platform has none.
  static Future<String?> save({
    required List<int> bytes,
    required String filename,
    String mimeType = 'application/pdf',
  }) async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod<String>('saveToDownloads', {
        'bytes': Uint8List.fromList(bytes),
        'name': filename,
        'mime': mimeType,
      });
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)]);
    return null;
  }

  /// Opens a saved file in the default viewer. False when no app can open it.
  static Future<bool> open(
    String handle, {
    String mimeType = 'application/pdf',
  }) async {
    if (!Platform.isAndroid) return false;
    final ok = await _channel.invokeMethod<bool>('open', {
      'uri': handle,
      'mime': mimeType,
    });
    return ok ?? false;
  }
}
