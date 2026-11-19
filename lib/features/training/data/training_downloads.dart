import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:liaison_officer/core/config/api_config.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/network/api_exception.dart';
import 'package:liaison_officer/core/services/device_downloads.dart';
import 'package:liaison_officer/features/training/domain/training_material.dart';
import 'package:path_provider/path_provider.dart';

enum TrainingDownloadStatus { idle, downloading, verifying, done, failed }

@immutable
class TrainingDownloadState {
  const TrainingDownloadState({
    this.status = TrainingDownloadStatus.idle,
    this.received = 0,
    this.total = 0,
    this.error,
  });

  final TrainingDownloadStatus status;
  final int received;
  final int total;
  final String? error;

  double? get progress => total > 0 ? (received / total).clamp(0.0, 1.0) : null;
  bool get busy =>
      status == TrainingDownloadStatus.downloading ||
      status == TrainingDownloadStatus.verifying;
}

/// Downloads training files from aide-service.
///
/// Videos go to the app's private storage and play in the app, offline.
/// They are streamed to a `.part` file, never held in memory; an interrupted
/// download resumes with an HTTP `Range` request, and the finished file is
/// checked against the server's SHA-256 before use.
///
/// Documents are small (50 MB max): they are saved to the phone's Downloads
/// folder with [DeviceDownloads], like the user manual and badge.
class TrainingDownloads extends ChangeNotifier {
  TrainingDownloads._();

  static final TrainingDownloads instance = TrainingDownloads._();

  final Map<String, TrainingDownloadState> _states = {};
  final Map<String, CancelToken> _tokens = {};
  final Map<String, String> _documentHandles = {};

  TrainingDownloadState stateOf(String id) =>
      _states[id] ?? const TrainingDownloadState();

  /// Android content URI of a document saved this session, for "Open".
  String? documentHandle(String id) => _documentHandles[id];

  Dio get _dio => AppDependencies.instance.dio;

  static Future<Directory> _root() async {
    final dir = await getApplicationSupportDirectory();
    return Directory('${dir.path}/lo-training');
  }

  Future<File> videoFile(TrainingMaterial m) async {
    final root = await _root();
    return File('${root.path}/videos/${m.id}.${m.extension}');
  }

  Future<File> _partFile(TrainingMaterial m) async {
    final f = await videoFile(m);
    return File('${f.path}.part');
  }

  /// True when the full video is on the device.
  Future<bool> isVideoDownloaded(TrainingMaterial m) async {
    final f = await videoFile(m);
    return await f.exists() && await f.length() == m.sizeBytes;
  }

  /// Bytes of a paused download, so the UI can offer "Resume".
  Future<int> partialBytes(TrainingMaterial m) async {
    final p = await _partFile(m);
    return await p.exists() ? await p.length() : 0;
  }

  void _set(String id, TrainingDownloadState s) {
    _states[id] = s;
    notifyListeners();
  }

  /// Downloads (or resumes) a video. Completes when the file is verified.
  Future<void> downloadVideo(TrainingMaterial m) async {
    if (stateOf(m.id).busy) return;
    if (ApiConfig.useMockApi) {
      _set(
        m.id,
        const TrainingDownloadState(
          status: TrainingDownloadStatus.failed,
          error: 'Downloads are not available in demo mode.',
        ),
      );
      return;
    }
    final token = CancelToken();
    _tokens[m.id] = token;
    try {
      await _streamToPart(m, token, allowRestart: true);
      _set(
        m.id,
        TrainingDownloadState(
          status: TrainingDownloadStatus.verifying,
          received: m.sizeBytes,
          total: m.sizeBytes,
        ),
      );
      final part = await _partFile(m);
      if (m.sha256.isNotEmpty) {
        final actual = await _sha256Of(part.path);
        if (actual != m.sha256.toLowerCase()) {
          await _deleteQuietly(part);
          throw ApiException(
            'The video did not download correctly. Please try again.',
          );
        }
      }
      final target = await videoFile(m);
      if (await target.exists()) await target.delete();
      await part.rename(target.path);
      _set(
        m.id,
        TrainingDownloadState(
          status: TrainingDownloadStatus.done,
          received: m.sizeBytes,
          total: m.sizeBytes,
        ),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // Keep the .part file: the next tap resumes from here.
        _set(
          m.id,
          TrainingDownloadState(
            received: await partialBytes(m),
            total: m.sizeBytes,
          ),
        );
        return;
      }
      _fail(m, _messageOf(e));
    } on FileSystemException catch (e) {
      _fail(
        m,
        e.osError?.errorCode == 28
            ? 'Not enough storage on the phone for this video.'
            : 'Could not save the video on the phone.',
      );
    } catch (e) {
      _fail(
        m,
        e is ApiException ? e.message : 'Download failed. Please try again.',
      );
    } finally {
      _tokens.remove(m.id);
    }
  }

  Future<void> _streamToPart(
    TrainingMaterial m,
    CancelToken token, {
    required bool allowRestart,
  }) async {
    final part = await _partFile(m);
    await part.parent.create(recursive: true);
    var existing = await part.exists() ? await part.length() : 0;
    if (existing > m.sizeBytes) {
      await part.delete();
      existing = 0;
    }
    if (existing > 0 && existing == m.sizeBytes) return;

    _set(
      m.id,
      TrainingDownloadState(
        status: TrainingDownloadStatus.downloading,
        received: existing,
        total: m.sizeBytes,
      ),
    );

    final res = await _dio.get<ResponseBody>(
      ApiConfig.myLoTrainingDownloadPath(m.id),
      cancelToken: token,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 2),
        headers: {
          'Accept': '*/*',
          if (existing > 0) 'Range': 'bytes=$existing-',
          // Server returns the whole file (200) if the file changed.
          if (existing > 0 && m.sha256.isNotEmpty) 'If-Range': '"${m.sha256}"',
        },
        validateStatus: (s) => s == 200 || s == 206 || s == 416,
      ),
    );

    if (res.statusCode == 416) {
      await _deleteQuietly(part);
      if (allowRestart) {
        return _streamToPart(m, token, allowRestart: false);
      }
      throw ApiException('Download failed. Please try again.');
    }

    final append = res.statusCode == 206;
    var received = append ? existing : 0;
    final sink = part.openWrite(
      mode: append ? FileMode.append : FileMode.write,
    );
    var lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      await for (final chunk in res.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        final now = DateTime.now();
        if (now.difference(lastNotify).inMilliseconds >= 250) {
          lastNotify = now;
          _set(
            m.id,
            TrainingDownloadState(
              status: TrainingDownloadStatus.downloading,
              received: received,
              total: m.sizeBytes,
            ),
          );
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
    if (received != m.sizeBytes) {
      throw ApiException('Download stopped early. Tap to resume.');
    }
  }

  /// Pauses a running video download; the partial file is kept.
  void cancel(String id) => _tokens[id]?.cancel('paused');

  Future<void> deleteVideo(TrainingMaterial m) async {
    cancel(m.id);
    await _deleteQuietly(await videoFile(m));
    await _deleteQuietly(await _partFile(m));
    _states.remove(m.id);
    notifyListeners();
  }

  /// Downloads a document into memory and saves it to the phone's Downloads
  /// folder (iOS: share sheet). Returns true when saved.
  Future<bool> downloadDocument(TrainingMaterial m) async {
    if (stateOf(m.id).busy) return false;
    if (ApiConfig.useMockApi) {
      _fail(m, 'Downloads are not available in demo mode.');
      return false;
    }
    final token = CancelToken();
    _tokens[m.id] = token;
    _set(
      m.id,
      TrainingDownloadState(
        status: TrainingDownloadStatus.downloading,
        total: m.sizeBytes,
      ),
    );
    try {
      final res = await _dio.get<List<int>>(
        ApiConfig.myLoTrainingDownloadPath(m.id),
        cancelToken: token,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 2),
          headers: {'Accept': '*/*'},
        ),
        onReceiveProgress: (received, total) {
          _set(
            m.id,
            TrainingDownloadState(
              status: TrainingDownloadStatus.downloading,
              received: received,
              total: total > 0 ? total : m.sizeBytes,
            ),
          );
        },
      );
      final bytes = res.data ?? const <int>[];
      if (bytes.isEmpty) throw ApiException('File was empty.');
      if (m.sha256.isNotEmpty &&
          sha256.convert(bytes).toString() != m.sha256.toLowerCase()) {
        throw ApiException(
          'The document did not download correctly. Please try again.',
        );
      }
      final handle = await DeviceDownloads.save(
        bytes: bytes,
        filename: _safeName(m),
        mimeType: m.mimeType,
      );
      if (handle != null) _documentHandles[m.id] = handle;
      _set(
        m.id,
        TrainingDownloadState(
          status: TrainingDownloadStatus.done,
          received: bytes.length,
          total: bytes.length,
        ),
      );
      return true;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _states.remove(m.id);
        notifyListeners();
        return false;
      }
      _fail(m, _messageOf(e));
      return false;
    } catch (e) {
      _fail(
        m,
        e is ApiException ? e.message : 'Download failed. Please try again.',
      );
      return false;
    } finally {
      _tokens.remove(m.id);
    }
  }

  /// Removes every downloaded training file. Called on logout.
  Future<void> clearAll() async {
    for (final t in _tokens.values) {
      t.cancel('logout');
    }
    _tokens.clear();
    _states.clear();
    _documentHandles.clear();
    try {
      final root = await _root();
      if (await root.exists()) await root.delete(recursive: true);
    } catch (_) {}
    notifyListeners();
  }

  void _fail(TrainingMaterial m, String message) {
    _set(
      m.id,
      TrainingDownloadState(
        status: TrainingDownloadStatus.failed,
        total: m.sizeBytes,
        error: message,
      ),
    );
  }

  static String _messageOf(DioException e) {
    final wrapped = e.error;
    if (wrapped is ApiException) return wrapped.message;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Network problem. Tap to resume when you are back online.';
    }
    return 'Download failed. Please try again.';
  }

  /// Display name with the server's extension, safe for a file name.
  static String _safeName(TrainingMaterial m) {
    var base = m.fileName
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .trim();
    if (base.isEmpty) base = m.title;
    final dot = base.lastIndexOf('.');
    if (dot > 0) base = base.substring(0, dot);
    return '$base.${m.extension}';
  }

  static Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// SHA-256 of a large file, computed off the UI thread.
  static Future<String> _sha256Of(String path) => Isolate.run(
    () async => (await sha256.bind(File(path).openRead()).first).toString(),
  );
}
