import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/network/aide_response.dart';
import 'package:liaison_officer/features/training/domain/training_material.dart';
import 'package:path_provider/path_provider.dart';

/// Result of [TrainingRepository.list]: [fromCache] is true when the server
/// could not be reached and the last saved list is shown instead.
class TrainingList {
  const TrainingList(this.items, {this.fromCache = false});

  final List<TrainingMaterial> items;
  final bool fromCache;

  List<TrainingMaterial> get videos => items.where((m) => m.isVideo).toList();
  List<TrainingMaterial> get documents =>
      items.where((m) => !m.isVideo).toList();
}

abstract class TrainingRepository {
  /// Active training materials. Falls back to the last saved list offline.
  Future<TrainingList> list();
}

class DioTrainingRepository implements TrainingRepository {
  DioTrainingRepository({required this.dio});

  final Dio dio;

  @override
  Future<TrainingList> list() async {
    try {
      final res = await dio.get(ApiConfig.myLoTrainingPath);
      final aide = AideResponse.unwrap(
        res.data,
        parseData: (raw) => AideResponse.asMapList(
          raw,
        ).map(TrainingMaterial.fromJson).where((m) => m.id.isNotEmpty).toList(),
      );
      final items = aide.data ?? const <TrainingMaterial>[];
      await TrainingListCache.save(items);
      return TrainingList(items);
    } on DioException catch (e) {
      // 404: backend without this feature yet — show an empty list.
      if (e.response?.statusCode == 404) return const TrainingList([]);
      final cached = await TrainingListCache.load();
      if (cached != null) return TrainingList(cached, fromCache: true);
      rethrow;
    }
  }
}

class MockTrainingRepository implements TrainingRepository {
  @override
  Future<TrainingList> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return TrainingList([
      TrainingMaterial(
        id: 'mock-video-1',
        title: 'LO induction briefing',
        description: 'Recording of the induction session for liaison officers.',
        type: TrainingMaterialType.video,
        fileName: 'lo-induction.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 524288000,
        sha256: '',
        createdAt: DateTime(2026, 11, 18),
      ),
      TrainingMaterial(
        id: 'mock-doc-1',
        title: 'Liaison Officer handbook',
        description: 'Duties, protocol and contacts.',
        type: TrainingMaterialType.document,
        fileName: 'lo-handbook.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 2097152,
        sha256: '',
        createdAt: DateTime(2026, 11, 18),
      ),
    ]);
  }
}

/// Last training list, kept on the device so downloaded videos stay
/// reachable offline. Removed on logout with the downloads.
class TrainingListCache {
  TrainingListCache._();

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/lo-training/list.json');
  }

  static Future<void> save(List<TrainingMaterial> items) async {
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode(items.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  static Future<List<TrainingMaterial>?> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final raw = jsonDecode(await f.readAsString());
      return AideResponse.asMapList(
        raw,
      ).map(TrainingMaterial.fromJson).toList();
    } catch (_) {
      return null;
    }
  }
}
