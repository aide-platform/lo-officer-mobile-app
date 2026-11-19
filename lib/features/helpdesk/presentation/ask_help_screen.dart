import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/config/api_config.dart';
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
      page: BlocProvider.value(
        value: bloc,
        child: AskHelpScreen(email: email),
      ),
    ),
  );
}

/// "Ask for Help": the help desk form configured on the dashboard
/// (survey formType 16 / subFormType 8), rendered field by field, one page
/// at a time. Same behaviour as the attendees app's Ask for Help page:
/// `visibleIf` rules, choice lists loaded from a URL (including lists that
/// depend on another answer), attachments, and required-field checks.
class AskHelpScreen extends StatefulWidget {
  const AskHelpScreen({super.key, this.repository, this.email = ''});

  final HelpdeskRepository? repository;
  final String email;

  @override
  State<AskHelpScreen> createState() => _AskHelpScreenState();
}

class _AskHelpScreenState extends State<AskHelpScreen> {
  late final HelpdeskRepository _repository =
      widget.repository ?? HelpdeskRepository();

  HelpdeskForm? _form;
  bool _loading = true;
  String? _error;
  int _page = 0;
  bool _showErrors = false;
  bool _submitting = false;
  bool _dirty = false;

  /// Answers by field name. Text and single files are `String`, choices are
  /// [HelpdeskChoice], multi-selects and multi-files are lists.
  final Map<String, Object?> _values = {};
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _loadingChoices = {};
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final form = await _repository.fetchForm();
      if (!mounted) return;
      if (form.pages.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'The help form is not set up for this event yet.';
        });
        return;
      }
      _prefill(form);
      setState(() {
        _form = form;
        _page = 0;
        _loading = false;
      });
      for (final field in form.fields) {
        if (field.hasRemoteChoices) _loadChoices(field);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(error, fallback: 'Could not load the form.');
      });
    }
  }

  /// Fills contact fields from the LO profile when the form asks for them.
  void _prefill(HelpdeskForm form) {
    final user = helpdeskUserOf(context, email: widget.email);
    final known = <String, String?>{
      'firstName': user.firstName,
      'lastName': user.lastName,
      'email': user.email,
      'contactNo': user.contactNo,
    };
    for (final field in form.fields) {
      final value = known[field.name];
      if (field.isText && value != null && value.isNotEmpty) {
        _values[field.name] = value;
        _controller(field).text = value;
      }
    }
  }

  TextEditingController _controller(HelpdeskField field) =>
      _controllers.putIfAbsent(
        field.name,
        () => TextEditingController(text: _values[field.name] as String?),
      );

  HelpdeskField? _field(String name) {
    for (final f in _form?.fields ?? const <HelpdeskField>[]) {
      if (f.name == name) return f;
    }
    return null;
  }

  // ── Choice lists ───────────────────────────────────────────────────────

  /// Loads a URL-backed list once every `{placeholder}` it needs has a value.
  /// `{eventID}` is the event; any other placeholder is another field's
  /// selected value.
  Future<void> _loadChoices(HelpdeskField field) async {
    final config = field.choicesByUrl!;
    var url = config.url;
    for (final name in config.placeholders) {
      String? value;
      if (name.toLowerCase() == 'eventid') {
        value = HelpdeskRepository.eventId;
      } else {
        final selected = _values[name];
        if (selected is HelpdeskChoice) value = selected.value?.toString();
      }
      if (value == null || value.isEmpty) return;
      url = url.replaceAll('{$name}', Uri.encodeComponent(value));
    }
    setState(() => _loadingChoices.add(field.name));
    try {
      var choices = await _repository.fetchChoices(url, config);
      // Query types are shared with other apps; keep the help desk ones.
      if (field.name == 'queryType') {
        choices = choices.where((c) {
          final spots = c.raw?['visibilitySpot'];
          return spots is! List ||
              spots
                  .map((e) => e.toString())
                  .contains('${ApiConfig.helpdeskSubFormType}');
        }).toList();
      }
      if (!mounted) return;
      setState(() {
        field.choices = choices;
        _loadingChoices.remove(field.name);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingChoices.remove(field.name));
      showHelpdeskSnack(
        context,
        apiErrorMessage(
          error,
          fallback: 'Could not load options for ${field.title}.',
        ),
      );
    }
  }

  void _setChoice(HelpdeskField field, Object? value) {
    setState(() {
      _dirty = true;
      _values[field.name] = value;
    });
    _resetDependants(field.name);
  }

  /// Clears and reloads every list whose URL uses [parent]'s value.
  void _resetDependants(String parent) {
    for (final child in _form?.fields ?? const <HelpdeskField>[]) {
      if (!child.hasRemoteChoices) continue;
      if (!child.choicesByUrl!.placeholders.contains(parent)) continue;
      setState(() {
        _values.remove(child.name);
        child.choices = [];
      });
      _resetDependants(child.name);
      _loadChoices(child);
    }
  }

  // ── Values, visibility, validation ─────────────────────────────────────

  /// A choice as the text the server stores: the `textName` property for
  /// URL lists, the value for static lists.
  Object? _choiceAnswer(HelpdeskField field, HelpdeskChoice choice) {
    if (field.hasRemoteChoices) {
      return choice.raw?[field.choicesByUrl!.textName] ?? choice.text;
    }
    return choice.value;
  }

  Object? _answer(HelpdeskField field) {
    final value = _values[field.name];
    if (value is HelpdeskChoice) return _choiceAnswer(field, value);
    if (value is List<HelpdeskChoice>) {
      return value.map((c) => _choiceAnswer(field, c)).toList();
    }
    if (value is String) return value.trim();
    return value;
  }

  List<String> _selectedTexts(String fieldName) {
    final field = _field(fieldName);
    if (field == null) return const [];
    final answer = _answer(field);
    if (answer == null) return const [];
    if (answer is List) return answer.map((e) => e.toString()).toList();
    final s = answer.toString();
    return s.isEmpty ? const [] : [s];
  }

  bool _isVisible(HelpdeskField field) {
    if (!field.isSupported) return false;
    final rule = HelpdeskVisibleRule.parse(field.visibleIf);
    if (rule == null) return true;
    return rule.isVisible(_selectedTexts(rule.parent));
  }

  bool _isEmpty(HelpdeskField field) {
    final value = _values[field.name];
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    return false;
  }

  bool _hasError(HelpdeskField field) =>
      _showErrors && field.isRequired && _isEmpty(field);

  void _next() {
    final form = _form!;
    final missing = form.pages[_page].elements.where(
      (f) => _isVisible(f) && f.isRequired && _isEmpty(f),
    );
    if (missing.isNotEmpty) {
      setState(() => _showErrors = true);
      showHelpdeskSnack(context, 'Please fill in the required fields.');
      return;
    }
    FocusScope.of(context).unfocus();
    if (_page < form.pages.length - 1) {
      setState(() {
        _page += 1;
        _showErrors = false;
      });
      _scrollToTop();
    } else {
      _submit();
    }
  }

  void _previous() {
    if (_page == 0) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _page -= 1;
      _showErrors = false;
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _submit() async {
    final form = _form!;
    final answers = <Map<String, dynamic>>[];
    final info = <String, dynamic>{};
    Object? queryType;
    Object? title;
    for (final field in form.fields) {
      if (!_isVisible(field) || _isEmpty(field)) continue;
      final value = _answer(field);
      if (field.isPrimary) info[field.name] = value;
      if (field.name == 'queryType') queryType = value;
      if (field.name == 'title') title = value;
      answers.add({'name': field.name, 'title': field.title, 'value': value});
    }

    setState(() => _submitting = true);
    try {
      await _repository.submitQuery(
        form: form,
        user: helpdeskUserOf(context, email: widget.email),
        answers: answers,
        info: info,
        queryType: queryType,
        title: title,
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

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final form = _form;
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
                  trailing: form != null && form.pages.length > 1
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Step ${_page + 1} of ${form.pages.length}',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                ),
                Expanded(child: _body(colors)),
                if (form != null && !_loading && _error == null) _footer(form),
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
        onAction: _load,
      );
    }
    final fields = _form!.pages[_page].elements.where(_isVisible).toList();
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: fields.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _fieldWidget(fields[index], colors),
    );
  }

  Widget _footer(HelpdeskForm form) {
    final isLast = _page == form.pages.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (_page > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : _previous,
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              onPressed: _submitting ? null : _next,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isLast ? 'Submit' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldWidget(HelpdeskField field, AppSemanticColors colors) {
    final Widget input;
    if (field.isChoice) {
      input = _choiceInput(field, colors);
    } else if (field.isFile) {
      input = _fileInput(field, colors);
    } else {
      input = _textInput(field, colors);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: field.title,
            children: [
              if (field.isRequired)
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
        const SizedBox(height: 6),
        input,
        if (_hasError(field))
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              field.requiredErrorText,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
            ),
          ),
      ],
    );
  }

  InputDecoration _decoration(
    HelpdeskField field,
    AppSemanticColors colors, {
    IconData? icon,
  }) {
    final error = _hasError(field);
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: c),
    );
    return InputDecoration(
      hintText: field.placeholder.isEmpty ? null : field.placeholder,
      prefixIcon: icon == null ? null : Icon(icon, color: colors.accent),
      filled: true,
      fillColor: colors.surface,
      border: border(colors.border),
      enabledBorder: border(error ? const Color(0xFFDC2626) : colors.border),
    );
  }

  Widget _textInput(HelpdeskField field, AppSemanticColors colors) {
    TextInputType keyboard = TextInputType.text;
    List<TextInputFormatter>? formatters;
    IconData? icon;
    switch (field.inputType) {
      case 'email':
        keyboard = TextInputType.emailAddress;
        icon = Icons.mail_outline_rounded;
      case 'number':
        keyboard = TextInputType.number;
        formatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))];
        if (field.name == 'contactNo') icon = Icons.call_outlined;
      case 'telephone':
      case 'tel':
        keyboard = TextInputType.phone;
        formatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))];
        icon = Icons.phone_iphone_rounded;
      case 'url':
        keyboard = TextInputType.url;
        icon = Icons.public_rounded;
    }
    final multiline = field.isMultiline;
    return TextField(
      controller: _controller(field),
      enabled: !_submitting,
      obscureText: field.inputType == 'password',
      keyboardType: multiline ? TextInputType.multiline : keyboard,
      inputFormatters: formatters,
      minLines: multiline ? 4 : 1,
      maxLines: multiline ? 8 : 1,
      textCapitalization: multiline || field.inputType == 'text'
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      style: TextStyle(color: colors.textPrimary),
      decoration: _decoration(field, colors, icon: multiline ? null : icon),
      onChanged: (value) => setState(() {
        _dirty = true;
        _values[field.name] = value;
      }),
    );
  }

  Widget _choiceInput(HelpdeskField field, AppSemanticColors colors) {
    final value = _values[field.name];
    final loading = _loadingChoices.contains(field.name);
    final selected = <HelpdeskChoice>[
      if (value is HelpdeskChoice) value,
      if (value is List<HelpdeskChoice>) ...value,
    ];
    Widget content;
    if (selected.isEmpty) {
      content = Text(
        loading
            ? 'Loading options…'
            : (field.placeholder.isEmpty ? 'Select' : field.placeholder),
        style: TextStyle(color: colors.textMuted),
      );
    } else if (field.allowMultiple) {
      content = Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final c in selected)
            Chip(
              label: Text(c.text),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      );
    } else {
      content = Text(
        selected.first.text,
        style: TextStyle(color: colors.textPrimary),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: _submitting || loading ? null : () => _pickChoice(field),
      child: InputDecorator(
        decoration:
            _decoration(
              field,
              colors,
              icon: field.name == 'country'
                  ? Icons.public_rounded
                  : field.name == 'state'
                  ? Icons.map_outlined
                  : Icons.list_alt_rounded,
            ).copyWith(
              hintText: null,
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.expand_more_rounded),
            ),
        child: content,
      ),
    );
  }

  Future<void> _pickChoice(HelpdeskField field) async {
    // A dependent list needs its parent answered first.
    final missingParent = field.hasRemoteChoices
        ? field.choicesByUrl!.placeholders
              .where((p) => p.toLowerCase() != 'eventid')
              .map(_field)
              .whereType<HelpdeskField>()
              .where(_isEmpty)
              .firstOrNull
        : null;
    if (missingParent != null) {
      showHelpdeskSnack(context, 'Please select ${missingParent.title} first.');
      return;
    }
    if (field.choices.isEmpty) {
      if (field.hasRemoteChoices) {
        await _loadChoices(field);
        if (!mounted || field.choices.isEmpty) {
          if (mounted) showHelpdeskSnack(context, 'No options available.');
          return;
        }
      } else {
        showHelpdeskSnack(context, 'No options available.');
        return;
      }
    }
    final current = _values[field.name];
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ChoiceSheet(
        title: field.title,
        choices: field.choices,
        multiple: field.allowMultiple,
        initial: [
          if (current is HelpdeskChoice) current,
          if (current is List<HelpdeskChoice>) ...current,
        ],
      ),
    );
    if (result == null || !mounted) return;
    _setChoice(field, result);
  }

  Widget _fileInput(HelpdeskField field, AppSemanticColors colors) {
    final value = _values[field.name];
    final urls = <String>[
      if (value is String && value.isNotEmpty) value,
      if (value is List<String>) ...value,
    ];
    final canAdd = field.allowMultiple || urls.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: _hasError(field) ? const Color(0xFFDC2626) : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (urls.isNotEmpty)
            HelpdeskPendingAttachments(
              urls: urls,
              onRemove: (i) => setState(() {
                final next = List<String>.of(urls)..removeAt(i);
                _values[field.name] = field.allowMultiple
                    ? next
                    : (next.isEmpty ? null : next.first);
              }),
            ),
          if (canAdd)
            TextButton.icon(
              onPressed: _submitting ? null : () => _addFile(field, urls),
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: Text(
                field.placeholder.isEmpty
                    ? 'Add attachment'
                    : field.placeholder,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Text(
              '${field.acceptedTypes.map((e) => e.toUpperCase()).join(', ')}'
              ' · up to ${field.maxSizeMb.toStringAsFixed(field.maxSizeMb % 1 == 0 ? 0 : 1)} MB',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addFile(HelpdeskField field, List<String> current) async {
    final url = await pickAndUploadHelpdeskAttachment(
      context,
      repository: _repository,
      accepted: field.acceptedTypes,
      maxSizeMb: field.maxSizeMb,
      title: field.title,
    );
    if (url == null || !mounted) return;
    setState(() {
      _dirty = true;
      _values[field.name] = field.allowMultiple ? [...current, url] : url;
    });
  }
}

/// Bottom sheet list for a choice field: radio for one answer, checkboxes
/// for several, with a search box once the list gets long.
class _ChoiceSheet extends StatefulWidget {
  const _ChoiceSheet({
    required this.title,
    required this.choices,
    required this.multiple,
    required this.initial,
  });

  final String title;
  final List<HelpdeskChoice> choices;
  final bool multiple;
  final List<HelpdeskChoice> initial;

  @override
  State<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends State<_ChoiceSheet> {
  late final List<HelpdeskChoice> _selected = List.of(widget.initial);
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? widget.choices
        : widget.choices
              .where((c) => c.text.toLowerCase().contains(query))
              .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.multiple)
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _selected.isEmpty ? null : List.of(_selected),
                      ),
                      child: const Text('Done'),
                    ),
                ],
              ),
            ),
            if (widget.choices.length > 8)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        'No matches',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final choice = visible[index];
                        final isSelected = _selected.contains(choice);
                        if (widget.multiple) {
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(choice.text),
                            onChanged: (checked) => setState(() {
                              if (checked == true) {
                                _selected.add(choice);
                              } else {
                                _selected.remove(choice);
                              }
                            }),
                          );
                        }
                        return ListTile(
                          title: Text(choice.text),
                          trailing: isSelected
                              ? Icon(Icons.check_rounded, color: colors.accent)
                              : null,
                          onTap: () => Navigator.pop(context, choice),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
