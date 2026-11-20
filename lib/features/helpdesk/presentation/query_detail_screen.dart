import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/services/pick_services.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/helpdesk/data/helpdesk_repository.dart';
import 'package:liaison_officer/features/helpdesk/data/helpdesk_updates.dart';
import 'package:liaison_officer/features/helpdesk/domain/helpdesk_models.dart';
import 'package:liaison_officer/features/helpdesk/presentation/helpdesk_screen.dart';
import 'package:liaison_officer/features/helpdesk/presentation/helpdesk_widgets.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';

/// Pops `true` when the user added a comment, so the list can refresh.
Future<bool?> openQueryDetailScreen(
  BuildContext context, {
  required HelpdeskQuery query,
  String email = '',
}) {
  final bloc = context.read<LoPortalBloc>();
  return Navigator.of(context).push<bool>(
    AppPageFadeRoute<bool>(
      page: BlocProvider.value(
        value: bloc,
        child: QueryDetailScreen(query: query, email: email),
      ),
    ),
  );
}

/// Opens a query by id (help desk push `helpdesk:<id>`). The screen loads the
/// query itself.
Future<bool?> openHelpdeskQueryById(
  BuildContext context, {
  required String id,
  String email = '',
}) {
  return openQueryDetailScreen(
    context,
    query: HelpdeskQuery(
      id: id,
      ticketNo: '',
      queryTypeName: '',
      title: '',
      description: '',
      attachments: const [],
    ),
    email: email,
  );
}

/// One ticket with its conversation, and a comment box while it is open.
class QueryDetailScreen extends StatefulWidget {
  const QueryDetailScreen({
    super.key,
    required this.query,
    this.repository,
    this.email = '',
  });

  final HelpdeskQuery query;
  final HelpdeskRepository? repository;
  final String email;

  @override
  State<QueryDetailScreen> createState() => _QueryDetailScreenState();
}

class _QueryDetailScreenState extends State<QueryDetailScreen> {
  static const _maxComment = 200;

  late final HelpdeskRepository _repository =
      widget.repository ?? HelpdeskRepository();
  final _comment = TextEditingController();

  /// Latest copy from the server (status changes while the screen is open).
  late HelpdeskQuery _query = widget.query;
  List<HelpdeskComment> _conversation = const [];
  final List<PickedFileBytes> _attachments = [];
  bool _loading = true;
  bool _sending = false;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    HelpdeskUpdates.instance.addListener(_onPush);
    _load();
  }

  @override
  void dispose() {
    HelpdeskUpdates.instance.removeListener(_onPush);
    _comment.dispose();
    super.dispose();
  }

  /// A help desk push for this query arrived: reload the conversation.
  void _onPush() {
    if (mounted && !_loading && HelpdeskUpdates.instance.lastQueryId == widget.query.id) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _repository.fetchQuery(widget.query.id);
      if (!mounted) return;
      setState(() {
        _query = detail.query;
        _conversation = detail.messages;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(error, fallback: 'Could not load replies.');
      });
    }
  }

  Future<void> _addAttachment() async {
    if (_attachments.length >= HelpdeskRepository.maxAttachments) {
      showHelpdeskSnack(
        context,
        'You can attach up to ${HelpdeskRepository.maxAttachments} files.',
      );
      return;
    }
    final file = await pickHelpdeskAttachment(
      context,
    );
    if (file != null && mounted) setState(() => _attachments.add(file));
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty) {
      showHelpdeskSnack(context, 'Please write a comment.');
      return;
    }
    setState(() => _sending = true);
    try {
      final detail = await _repository.addComment(
        queryId: widget.query.id,
        text: text,
        files: List.of(_attachments),
      );
      if (!mounted) return;
      setState(() {
        _query = detail.query;
        _conversation = detail.messages;
        _comment.clear();
        _attachments.clear();
        _sending = false;
        _changed = true;
      });
      FocusScope.of(context).unfocus();
      showHelpdeskSnack(context, 'Comment added.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      showHelpdeskSnack(
        context,
        apiErrorMessage(error, fallback: 'Could not add your comment.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        body: HelpdeskBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HelpdeskTitleRow(
                  title: 'Query details',
                  onBack: () => Navigator.pop(context, _changed),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xs,
                        AppSpacing.lg,
                        AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
                      ),
                      children: [
                        HelpdeskQueryCard(query: _query),
                        const SizedBox(height: AppSpacing.md),
                        _conversationSection(colors),
                        if (!_query.isClosed) ...[
                          const SizedBox(height: AppSpacing.md),
                          _commentBox(colors),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _conversationSection(AppSemanticColors colors) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return AppCard(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Text(_error!, style: TextStyle(color: colors.textSecondary)),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (_conversation.isEmpty) return const SizedBox.shrink();
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _conversation.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            _CommentTile(comment: _conversation[i]),
          ],
        ],
      ),
    );
  }

  Widget _commentBox(AppSemanticColors colors) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Write a comment',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _comment,
                builder: (context, value, _) => Text(
                  '${value.text.length} / $_maxComment',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _comment,
            maxLength: _maxComment,
            minLines: 3,
            maxLines: 5,
            enabled: !_sending,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Describe your update or question',
              counterText: '',
              filled: true,
              fillColor: colors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_attachments.isNotEmpty) ...[
            HelpdeskPendingAttachments(
              files: _attachments,
              onRemove: (i) => setState(() => _attachments.removeAt(i)),
            ),
            const SizedBox(height: 6),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _sending ? null : _addAttachment,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Add attachment'),
            ),
          ),
          const SizedBox(height: 6),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final HelpdeskComment comment;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.accent.withValues(alpha: 0.12),
            child: comment.isSystem
                ? Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colors.accent,
                  )
                : Text(
                    comment.initials,
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.isSystem
                      ? 'Help desk'
                      : comment.fromTeam
                      ? '${comment.name.isEmpty ? 'Help desk' : comment.name} · Help desk'
                      : (comment.name.isEmpty ? 'You' : comment.name),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: TextStyle(color: colors.textSecondary, height: 1.4),
                ),
                if (comment.attachments.isNotEmpty)
                  HelpdeskAttachmentLinks(attachments: comment.attachments),
                if (comment.createdAt != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        helpdeskTimeAgo(comment.createdAt),
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
