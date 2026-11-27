import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaison_officer/core/network/certificate_pinning_io.dart';
import 'package:liaison_officer/core/network/pinned_roots.dart';
import 'package:liaison_officer/core/security/device_integrity.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_offline_store.dart';
import 'package:liaison_officer/core/services/device_downloads.dart';
import 'package:liaison_officer/core/storage/secure_cache.dart';
import 'package:liaison_officer/features/liaison_officer/data/cache/lo_portal_cache.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureCache', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
    });

    test('moves a value from older prefs into secure storage', () async {
      SharedPreferences.setMockInitialValues({'cap_lo_profile': '{"a":1}'});

      expect(await SecureCache.read('cap_lo_profile'), '{"a":1}');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cap_lo_profile'), isNull);
      expect(
        await SecureCache.storage.read(key: 'cache.cap_lo_profile'),
        '{"a":1}',
      );
      expect(await SecureCache.read('cap_lo_profile'), '{"a":1}');
    });

    test('drops a value left from an earlier install', () async {
      // Keychain survived an uninstall; SharedPreferences (the marker) did not.
      FlutterSecureStorage.setMockInitialValues({
        'cache.cap_lo_profile': '{"old":true}',
      });

      expect(await SecureCache.read('cap_lo_profile'), isNull);
      expect(
        await SecureCache.storage.read(key: 'cache.cap_lo_profile'),
        isNull,
      );
    });

    test('profile with Aadhaar is not kept in plain prefs', () async {
      await LoPortalCache.saveProfile(
        LiaisonOfficerDto.fromJson({
          'id': 'lo-1',
          'firstName': 'Test',
          'aadhaarNumber': '123456789012',
        }),
      );

      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        expect('${prefs.get(key)}', isNot(contains('123456789012')));
      }
      final loaded = await LoPortalCache.loadProfile();
      expect(loaded?.aadhaarNumber, '123456789012');

      await LoPortalCache.clearOfficerData();
      expect(await LoPortalCache.loadProfile(), isNull);
    });
  });

  group('LoOfflineStore encryption', () {
    late Directory dir;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      dir = await Directory.systemTemp.createTemp('lo_hive_');
    });

    tearDown(() async {
      await LoOfflineStore.close();
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('moves an older plain box into an encrypted one', () async {
      // Box as written by app 1.0.12: plain, with a queued offline write.
      Hive.init(dir.path);
      final plain = await Hive.openBox('lo_offline');
      await plain.put('task_status_queue', '[{"taskId":"T-PLAIN-42"}]');
      await plain.close();

      await LoOfflineStore.initAt(dir.path);

      final queue = await LoOfflineStore.peekQueue();
      expect(queue.single['taskId'], 'T-PLAIN-42');

      await LoOfflineStore.close();
      final bytes = await File('${dir.path}/lo_offline.hive').readAsBytes();
      expect(String.fromCharCodes(bytes), isNot(contains('T-PLAIN-42')));

      // Second start: already encrypted, data still there.
      await LoOfflineStore.initAt(dir.path);
      expect((await LoOfflineStore.peekQueue()).single['taskId'], 'T-PLAIN-42');
    });
  });

  group('DeviceIntegrityGate', () {
    Widget app(DeviceIntegrityResult r) => MaterialApp(
      home: DeviceIntegrityGate(result: r, child: const Text('home')),
    );

    testWidgets('no warning on an emulator alone', (tester) async {
      await tester.pumpWidget(app(const DeviceIntegrityResult(emulator: true)));
      expect(find.text('Device security warning'), findsNothing);
    });

    testWidgets('warns on a rooted phone and can be dismissed', (tester) async {
      await tester.pumpWidget(app(const DeviceIntegrityResult(rooted: true)));
      expect(find.text('Device security warning'), findsOneWidget);
      await tester.tap(find.text('I understand'));
      await tester.pump();
      expect(find.text('Device security warning'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('repackaged app gets the official-source message', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const DeviceIntegrityResult(signatureValid: false)),
      );
      expect(find.textContaining('not the official'), findsOneWidget);
    });

    test('fromMap reads the native result', () {
      final r = DeviceIntegrityResult.fromMap({
        'rooted': true,
        'hooked': false,
        'signatureValid': null,
        'reasons': ['su binary'],
      });
      expect(r.rooted, isTrue);
      expect(r.signatureValid, isNull);
      expect(r.reasons, ['su binary']);
      expect(r.atRisk, isTrue);
    });
  });

  group('Certificate pinning', () {
    test('pinned roots parse and build a TLS context', () {
      expect(pinnedRootCertificates, hasLength(10));
      expect(pinnedSecurityContext, returnsNormally);
    });
  });

  group('DeviceDownloads.safeFileName', () {
    test('keeps a normal name', () {
      expect(
        DeviceDownloads.safeFileName('LO Badge (1).pdf'),
        'LO Badge (1).pdf',
      );
    });

    test('strips folder parts', () {
      expect(DeviceDownloads.safeFileName('../../data/x.pdf'), 'x.pdf');
      expect(DeviceDownloads.safeFileName(r'..\..\x.pdf'), 'x.pdf');
      expect(DeviceDownloads.safeFileName('/etc/passwd'), 'passwd');
    });

    test('replaces unsafe characters and leading dots', () {
      expect(DeviceDownloads.safeFileName('a:b*c?.pdf'), 'a_b_c_.pdf');
      expect(DeviceDownloads.safeFileName('..hidden'), 'hidden');
    });

    test('falls back when nothing is left', () {
      expect(DeviceDownloads.safeFileName('../'), 'download');
      expect(DeviceDownloads.safeFileName('   '), 'download');
    });
  });
}
