import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';

/// Result of the native checks in `DeviceIntegrity.kt` (VAPT HIGH-05).
class DeviceIntegrityResult {
  const DeviceIntegrityResult({
    this.rooted = false,
    this.emulator = false,
    this.hooked = false,
    this.debuggerAttached = false,
    this.debuggable = false,
    this.signatureValid,
    this.reasons = const [],
  });

  factory DeviceIntegrityResult.fromMap(Map<dynamic, dynamic> map) =>
      DeviceIntegrityResult(
        rooted: map['rooted'] == true,
        emulator: map['emulator'] == true,
        hooked: map['hooked'] == true,
        debuggerAttached: map['debuggerAttached'] == true,
        debuggable: map['debuggable'] == true,
        signatureValid: map['signatureValid'] as bool?,
        reasons:
            (map['reasons'] as List?)?.map((e) => '$e').toList() ?? const [],
      );

  final bool rooted;
  final bool emulator;
  final bool hooked;
  final bool debuggerAttached;

  /// Debug build of the app itself; never warned about.
  final bool debuggable;

  /// False = APK re-signed with another key; null = not checked.
  final bool? signatureValid;
  final List<String> reasons;

  /// Something worth telling the user about. An emulator alone is not:
  /// testers and auditors use them.
  bool get atRisk =>
      rooted ||
      hooked ||
      signatureValid == false ||
      (debuggerAttached && !debuggable);
}

/// Runs the device checks once at start-up, logs them, and warns the user.
///
/// Mode comes from `--dart-define=INTEGRITY_MODE=warn|block` (default warn):
/// warn shows a dismissible notice, block stops the app on an unsafe device.
/// Start with warn until the app is on Play Store and the Play Integrity
/// verdict is checked on the server.
class DeviceIntegrity {
  DeviceIntegrity._();

  static const _channel = MethodChannel('com.bel.liaison_officer/security');
  static const _mode = String.fromEnvironment(
    'INTEGRITY_MODE',
    defaultValue: 'warn',
  );

  static bool get blockMode => _mode == 'block';

  static DeviceIntegrityResult? _last;
  static DeviceIntegrityResult? get last => _last;

  static Future<DeviceIntegrityResult> check() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _last = const DeviceIntegrityResult();
    }
    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('check');
      _last = map == null
          ? const DeviceIntegrityResult()
          : DeviceIntegrityResult.fromMap(map);
    } catch (e) {
      debugPrint('Device integrity check skipped: $e');
      _last = const DeviceIntegrityResult();
    }
    final r = _last!;
    LoFirebaseMonitor.instance.logDeviceIntegrity(
      rooted: r.rooted,
      emulator: r.emulator,
      hooked: r.hooked,
      debuggerAttached: r.debuggerAttached,
      signatureValid: r.signatureValid,
    );
    if (r.reasons.isNotEmpty) {
      debugPrint('Device integrity: ${r.reasons.join(', ')}');
    }
    return r;
  }
}

/// Wraps the app: shows the integrity notice once over whatever screen is up.
class DeviceIntegrityGate extends StatefulWidget {
  const DeviceIntegrityGate({
    super.key,
    required this.result,
    required this.child,
  });

  final DeviceIntegrityResult result;
  final Widget child;

  @override
  State<DeviceIntegrityGate> createState() => _DeviceIntegrityGateState();
}

class _DeviceIntegrityGateState extends State<DeviceIntegrityGate> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    if (!r.atRisk || _dismissed) return widget.child;
    final block = DeviceIntegrity.blockMode;
    final theme = Theme.of(context);
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black54,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.gpp_maybe_outlined,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Device security warning',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          r.signatureValid == false
                              ? 'This copy of the app is not the official Aero India LO app. '
                                    'Uninstall it and install the app from the official source.'
                              : 'This phone appears to be rooted or running tools that can '
                                    'read app data. Your login and personal details may not be safe on it.',
                        ),
                        if (block) ...[
                          const SizedBox(height: 12),
                          const Text('The app cannot be used on this device.'),
                        ],
                        if (!block) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _dismissed = true),
                              child: const Text('I understand'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
