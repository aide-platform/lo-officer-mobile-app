import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/features/helpdesk/data/helpdesk_repository.dart';
import 'package:liaison_officer/features/helpdesk/domain/helpdesk_models.dart';
import 'package:liaison_officer/features/helpdesk/presentation/helpdesk_widgets.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';

/// Pops `true` once a query has been submitted.
Future<bool?> openAskHelpScreen(BuildContext context, {String email = ''}) {
  final bloc = context.read<LoPortalBloc>();
  return Navigator.of(context).push<bool>(
    AppPageFadeRoute<bool>(
      page: BlocProvider.value(value: bloc, child: const AskHelpScreen()),
    ),
  );
}

/// "Ask for Help": Select your Query, Query Title, Description and
/// Attachments (up to 5 JPG / JPEG / PNG / PDF files, 5 MB each).
class AskHelpScreen extends StatefulWidget {
  const AskHelpScreen({super.key, this.repository});

  final HelpdeskRepository? repository;

  @override
  State<AskHelpScreen> createState() => _AskHelpScreenState();
}

class _AskHelpScreenState extends State<AskHelpScreen> {
  static const int _maxTitle = 200;
  static const int _maxDescription = 4000;

  late final HelpdeskRepository _repository =
      widget.repository ?? HelpdeskRepository();
  final _title = TextEditingController();
  final _description = TextEditingController();

  List<HelpdeskQueryType> _types = const [];
  HelpdeskQueryType? _type;
  final List<String> _attachments = [];
  bool _loading = true;
  String? _error;
  bool _showErrors = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final types = await _repository.fetchQueryTypes();
      if (!mounted) return;
      setState(() {
        _types = types;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(error, fallback: 'Could not load the form.');
      });
    }
  }

  bool get _dirty =>
      _type != null ||
      _title.text.trim().isNotEmpty ||
      _description.text.trim().isNotEmpty ||
      _attachments.isNotEmpty;

  Future<void> _pickType() async {
    if (_types.isEmpty) {
      showHelpdeskSnack(context, 'No query types are available yet.');
      return;
    }
    final colors = context.semantic;
    final picked = await showModalBottomSheet<HelpdeskQueryType>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Select your Query',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final t in _types)
                ListTile(
                  title: Text(t.name),
                  trailing: t.id == _type?.id
                      ? Icon(Icons.check_rounded, color: colors.accent)
                      : null,
                  onTap: () => Navigator.pop(ctx, t),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _type = picked);
  }

  Future<void> _addAttachment() async {
    if (_attachments.length >= HelpdeskRepository.maxAttachments) {
      showHelpdeskSnack(
        context,
        'You can attach up to ${HelpdeskRepository.maxAttachments} files.',
      );
      return;
    }
    final url = await pickAndUploadHelpdeskAttachment(
      context,
      repository: _repository,
      accepted: HelpdeskRepository.acceptedTypes,
      maxSizeMb: HelpdeskRepository.maxAttachmentMb,
      title: 'Attachments',
    );
    if (url != null && mounted) setState(() => _attachments.add(url));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final title = _title.text.trim();
    final description = _description.text.trim();
    if (_type == null || title.isEmpty || description.isEmpty) {
      setState(() => _showErrors = true);
      showHelpdeskSnack(context, 'Please fill in the required fields.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repository.raiseQuery(
        queryTypeId: _type!.id,
        title: title,
        description: description,
        attachments: List.of(_attachments),
      );
      if (!mounted) return;
      showHelpdeskSnack(context, 'Your query was submitted.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showHelpdeskSnack(
        context,
        apiErrorMessage(error, fallback: 'Could not submit your query.'),
      );
    }
  }

  Future<void> _confirmExit() async {
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave without submitting?'),
        content: const Text(
          'If you leave now, the details you entered will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay here'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit anyway'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_submitting) _confirmExit();
      },
      child: Scaffold(
        body: HelpdeskBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HelpdeskTitleRow(
                  title: 'Ask for Help',
                  onBack: () {
                    if (!_submitting) _confirmExit();
                  },
                ),
                Expanded(child: _body(colors)),
                if (!_loading && _error == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(AppSemanticColors colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return HelpdeskMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not open the form',
        text: _error,
        actionLabel: 'Try again',
        onAction: _loadTypes,
      );
    }
    final typeMissing = _showErrors && _type == null;
    final titleMissing = _showErrors && _title.text.trim().isEmpty;
    final descMissing = _showErrors && _description.text.trim().isEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        _label('Select your Query', colors, required: true),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: _submitting ? null : _pickType,
          child: InputDecorator(
            decoration: _decoration(
              colors,
              icon: Icons.list_alt_rounded,
              error: typeMissing,
            ).copyWith(suffixIcon: const Icon(Icons.expand_more_rounded)),
            child: Text(
              _type?.name ?? 'Select',
              style: TextStyle(
                color: _type == null ? colors.textMuted : colors.textPrimary,
              ),
            ),
          ),
        ),
        _errorText(typeMissing),
        const SizedBox(height: AppSpacing.md),
        _label('Query Title', colors, required: true),
        TextField(
          controller: _title,
          enabled: !_submitting,
          maxLength: _maxTitle,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: colors.textPrimary),
          decoration: _decoration(
            colors,
            error: titleMissing,
          ).copyWith(counterText: ''),
          onChanged: (_) => setState(() {}),
        ),
        _errorText(titleMissing),
        const SizedBox(height: AppSpacing.md),
        _label('Description', colors, required: true),
        TextField(
          controller: _description,
          enabled: !_submitting,
          maxLength: _maxDescription,
          minLines: 4,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: colors.textPrimary),
          decoration: _decoration(
            colors,
            error: descMissing,
          ).copyWith(counterText: ''),
          onChanged: (_) => setState(() {}),
        ),
        _errorText(descMissing),
        const SizedBox(height: AppSpacing.md),
        _label('Attachments', colors),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_attachments.isNotEmpty)
                HelpdeskPendingAttachments(
                  urls: _attachments,
                  onRemove: (i) => setState(() => _attachments.removeAt(i)),
                ),
              if (_attachments.length < HelpdeskRepository.maxAttachments)
                TextButton.icon(
                  onPressed: _submitting ? null : _addAttachment,
                  icon: const Icon(Icons.attach_file_rounded, size: 18),
                  label: const Text('Add attachment'),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  'JPEG, JPG, PNG, PDF · up to 5 MB each · max '
                  '${HelpdeskRepository.maxAttachments} files',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(
    String text,
    AppSemanticColors colors, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
          ],
        ),
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _errorText(bool show) {
    if (!show) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(top: 4, left: 4),
      child: Text(
        'This field cannot be left blank.',
        style: TextStyle(color: Color(0xFFDC2626), fontSize: 12),
      ),
    );
  }

  InputDecoration _decoration(
    AppSemanticColors colors, {
    IconData? icon,
    bool error = false,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: c),
    );
    return InputDecoration(
      prefixIcon: icon == null ? null : Icon(icon, color: colors.accent),
      filled: true,
      fillColor: colors.surface,
      border: border(colors.border),
      enabledBorder: border(error ? const Color(0xFFDC2626) : colors.border),
    );
  }
}
