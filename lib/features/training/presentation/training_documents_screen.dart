import 'dart:io';

import 'package:flutter/material.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/services/device_downloads.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';
import 'package:liaison_officer/core/services/lo_monitoring_events.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/training/data/training_downloads.dart';
import 'package:liaison_officer/features/training/data/training_repository.dart';
import 'package:liaison_officer/features/training/domain/training_material.dart';
import 'package:liaison_officer/features/training/presentation/training_video_player_screen.dart';

void openTrainingDocuments(BuildContext context) {
  LoFirebaseMonitor.instance.logFeature(LoMonitoringEvents.featureTraining);
  Navigator.of(
    context,
  ).push(AppPageFadeRoute<void>(page: const TrainingDocumentsScreen()));
}

/// "Training Document": training videos and documents from the LO Committee.
class TrainingDocumentsScreen extends StatefulWidget {
  const TrainingDocumentsScreen({super.key});

  @override
  State<TrainingDocumentsScreen> createState() =>
      _TrainingDocumentsScreenState();
}

class _TrainingDocumentsScreenState extends State<TrainingDocumentsScreen> {
  final TrainingRepository _repo = AppDependencies.instance.trainingRepository;
  TrainingList? _list;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _list == null;
      _error = null;
    });
    try {
      final list = await _repo.list();
      if (!mounted) return;
      setState(() {
        _list = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AppPageScaffold(
        title: 'Training Document',
        body: Column(
          children: [
            const SizedBox(height: 8),
            _Tabs(),
            if (_list?.fromCache == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Offline: showing the last saved list.',
                  style: TextStyle(color: context.semantic.textSecondary),
                ),
              ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const AppLoading(label: 'Loading training…');
    final list = _list;
    if (list == null) {
      return AppErrorView(
        message: apiErrorMessage(
          _error ?? 'error',
          fallback: 'Could not load training materials.',
        ),
        onRetry: _load,
      );
    }
    return TabBarView(
      children: [
        _MaterialList(
          items: list.videos,
          emptyMessage: 'No training videos yet.',
          emptyIcon: Icons.video_library_outlined,
          onRefresh: _load,
        ),
        _MaterialList(
          items: list.documents,
          emptyMessage: 'No training documents yet.',
          emptyIcon: Icons.description_outlined,
          onRefresh: _load,
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: colors.accent,
        unselectedLabelColor: colors.textSecondary,
        tabs: const [
          Tab(icon: Icon(Icons.play_circle_outline), text: 'Videos'),
          Tab(icon: Icon(Icons.description_outlined), text: 'Documents'),
        ],
      ),
    );
  }
}

class _MaterialList extends StatelessWidget {
  const _MaterialList({
    required this.items,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
  });

  final List<TrainingMaterial> items;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                AppEmptyState(message: emptyMessage, icon: emptyIcon),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: items.length,
              itemBuilder: (_, i) => _MaterialCard(material: items[i]),
            ),
    );
  }
}

class _MaterialCard extends StatefulWidget {
  const _MaterialCard({required this.material});

  final TrainingMaterial material;

  @override
  State<_MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<_MaterialCard> {
  final _downloads = TrainingDownloads.instance;
  bool _downloaded = false;
  int _partial = 0;

  TrainingMaterial get m => widget.material;

  @override
  void initState() {
    super.initState();
    _downloads.addListener(_onChange);
    _refreshLocal();
  }

  @override
  void dispose() {
    _downloads.removeListener(_onChange);
    super.dispose();
  }

  TrainingDownloadStatus _lastStatus = TrainingDownloadStatus.idle;

  void _onChange() {
    final status = _downloads.stateOf(m.id).status;
    // Re-check the files only when this item's download finished or paused,
    // not on every progress tick of another item.
    if (status != _lastStatus &&
        (status == TrainingDownloadStatus.done ||
            status == TrainingDownloadStatus.idle)) {
      _refreshLocal();
    }
    _lastStatus = status;
    if (mounted) setState(() {});
  }

  Future<void> _refreshLocal() async {
    if (!m.isVideo) return;
    final done = await _downloads.isVideoDownloaded(m);
    final partial = done ? 0 : await _downloads.partialBytes(m);
    if (!mounted) return;
    setState(() {
      _downloaded = done;
      _partial = partial;
    });
  }

  Future<void> _play() async {
    final file = await _downloads.videoFile(m);
    if (!mounted) return;
    Navigator.of(context).push(
      AppPageFadeRoute<void>(
        page: TrainingVideoPlayerScreen(title: m.title, file: File(file.path)),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove download?'),
        content: Text(
          'This frees ${formatFileSize(m.sizeBytes)} on your phone. '
          'You can download the video again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _downloads.deleteVideo(m);
      await _refreshLocal();
    }
  }

  Future<void> _startVideoDownload() async {
    if (_partial == 0 && m.sizeBytes > 200 * 1024 * 1024) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Download video?'),
          content: Text(
            'This video is ${formatFileSize(m.sizeBytes)}. Use Wi-Fi if you '
            'can. You can pause and resume the download.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Download'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await _downloads.downloadVideo(m);
  }

  Future<void> _downloadDocument() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _downloads.downloadDocument(m);
    if (!ok || !mounted) return;
    final handle = _downloads.documentHandle(m.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          Platform.isAndroid
              ? '${m.fileName} saved to Downloads.'
              : '${m.fileName} is ready.',
        ),
        action: handle == null
            ? null
            : SnackBarAction(label: 'Open', onPressed: () => _open(handle)),
      ),
    );
  }

  Future<void> _open(String handle) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await DeviceDownloads.open(handle, mimeType: m.mimeType);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No app on this phone can open this file.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final state = _downloads.stateOf(m.id);
    return AppCard(
      onTap: m.isVideo && _downloaded ? _play : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  m.isVideo ? Icons.play_circle_outline : _docIcon(m),
                  color: colors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (m.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        m.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _meta(),
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.busy) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: state.status == TrainingDownloadStatus.verifying
                  ? null
                  : state.progress,
            ),
            const SizedBox(height: 4),
            Text(
              state.status == TrainingDownloadStatus.verifying
                  ? 'Checking file…'
                  : '${formatFileSize(state.received)} of ${formatFileSize(state.total)}',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
          if (state.status == TrainingDownloadStatus.failed &&
              state.error != null) ...[
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: _actions(state)),
        ],
      ),
    );
  }

  String _meta() {
    final parts = <String>[
      formatFileSize(m.sizeBytes),
      m.extension.toUpperCase(),
    ];
    final d = m.createdAt;
    if (d != null) {
      parts.add(
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
      );
    }
    if (m.isVideo && _downloaded) parts.add('Downloaded');
    return parts.join(' · ');
  }

  Widget _actions(TrainingDownloadState state) {
    if (!m.isVideo) {
      if (state.busy) return const SizedBox.shrink();
      return FilledButton.tonalIcon(
        onPressed: _downloadDocument,
        icon: const Icon(Icons.download_outlined),
        label: const Text('Download'),
      );
    }
    if (state.status == TrainingDownloadStatus.downloading) {
      return TextButton.icon(
        onPressed: () => _downloads.cancel(m.id),
        icon: const Icon(Icons.pause_circle_outline),
        label: const Text('Pause'),
      );
    }
    if (state.status == TrainingDownloadStatus.verifying) {
      return const SizedBox.shrink();
    }
    if (_downloaded) {
      return Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove'),
          ),
          FilledButton.icon(
            onPressed: _play,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Play'),
          ),
        ],
      );
    }
    final resume = _partial > 0;
    return FilledButton.tonalIcon(
      onPressed: _startVideoDownload,
      icon: Icon(resume ? Icons.play_for_work : Icons.download_outlined),
      label: Text(
        resume
            ? 'Resume (${formatFileSize(_partial)} of ${formatFileSize(m.sizeBytes)})'
            : 'Download',
      ),
    );
  }

  static IconData _docIcon(TrainingMaterial m) {
    switch (m.extension) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}
