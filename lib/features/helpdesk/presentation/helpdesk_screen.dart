import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/liaison_brand_header.dart';
import 'package:liaison_officer/features/helpdesk/data/helpdesk_repository.dart';
import 'package:liaison_officer/features/helpdesk/domain/helpdesk_models.dart';
import 'package:liaison_officer/features/helpdesk/presentation/ask_help_screen.dart';
import 'package:liaison_officer/features/helpdesk/presentation/helpdesk_widgets.dart';
import 'package:liaison_officer/features/helpdesk/presentation/query_detail_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';

/// Opens the help desk under the same brand header as the home shell.
///
/// Pops `'alerts'` or `'more'` when those header actions are used.
Future<String?> openHelpdeskScreen(BuildContext context, {String email = ''}) {
  final bloc = context.read<LoPortalBloc>();
  return Navigator.of(context).push<String>(
    AppPageFadeRoute<String>(
      page: BlocProvider.value(
        value: bloc,
        child: HelpdeskScreen(email: email),
      ),
    ),
  );
}

/// The LO's help desk tickets: search, pull to refresh, load more on scroll,
/// and "Ask for Help" to raise a new one. Mirrors the attendees app's
/// Help Center page.
class HelpdeskScreen extends StatefulWidget {
  const HelpdeskScreen({super.key, this.repository, this.email = ''});

  final HelpdeskRepository? repository;
  final String email;

  @override
  State<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _HelpdeskScreenState extends State<HelpdeskScreen> {
  late final HelpdeskRepository _repository =
      widget.repository ?? HelpdeskRepository();
  final _search = TextEditingController();
  final _scroll = ScrollController();

  List<HelpdeskQuery> _queries = const [];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _searchOpen = false;
  String _appliedSearch = '';
  String? _error;

  /// Bumped on every reload so a slow older response is dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scroll.position.extentAfter < 300) _loadMore();
  }

  Future<void> _reload({bool showSpinner = true}) async {
    final generation = ++_generation;
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.fetchQueries(
        page: 0,
        search: _appliedSearch,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _queries = items;
        _page = 0;
        _hasMore = items.length == HelpdeskRepository.pageSize;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(
          error,
          fallback: 'Could not load your queries.',
        );
      });
    }
  }

  Future<void> _loadMore() async {
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final items = await _repository.fetchQueries(
        page: _page + 1,
        search: _appliedSearch,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _queries = [..._queries, ...items];
        _page += 1;
        _hasMore = items.length == HelpdeskRepository.pageSize;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loadingMore = false;
        _hasMore = false;
      });
      showHelpdeskSnack(
        context,
        apiErrorMessage(error, fallback: 'Could not load more queries.'),
      );
    }
  }

  void _applySearch() {
    final text = _search.text.trim();
    if (text == _appliedSearch) return;
    _appliedSearch = text;
    _reload();
  }

  void _closeSearch() {
    _search.clear();
    setState(() => _searchOpen = false);
    if (_appliedSearch.isNotEmpty) {
      _appliedSearch = '';
      _reload();
    }
  }

  Future<void> _askHelp() async {
    final submitted = await openAskHelpScreen(context, email: widget.email);
    if (submitted == true && mounted) _reload();
  }

  Future<void> _openQuery(HelpdeskQuery query) async {
    final changed = await openQueryDetailScreen(
      context,
      query: query,
      email: widget.email,
    );
    if (changed == true && mounted) _reload(showSpinner: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final showSearchButton =
        _searchOpen || _queries.isNotEmpty || _appliedSearch.isNotEmpty;
    return Scaffold(
      floatingActionButton: _queries.isEmpty || _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _askHelp,
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Ask for Help'),
            ),
      body: HelpdeskBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocBuilder<LoPortalBloc, LoPortalState>(
              buildWhen: (previous, next) =>
                  previous.profile != next.profile ||
                  previous.alerts != next.alerts,
              builder: (context, portalState) {
                final name = portalState.profile?.displayName ?? '';
                return LiaisonBrandHeader(
                  initials: liaisonInitials(name, widget.email),
                  alertCount: portalState.alerts.length,
                  onAlerts: () => Navigator.pop(context, 'alerts'),
                  onAccountTap: () => Navigator.pop(context, 'more'),
                );
              },
            ),
            HelpdeskTitleRow(
              title: 'Help Desk',
              onBack: () => Navigator.pop(context),
              trailing: showSearchButton && !_searchOpen
                  ? IconButton(
                      tooltip: 'Search queries',
                      onPressed: () => setState(() => _searchOpen = true),
                      icon: Icon(Icons.search_rounded, color: colors.accent),
                    )
                  : null,
            ),
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _applySearch(),
                        onChanged: (value) {
                          setState(() {});
                          // Clearing the box shows every query again.
                          if (value.isEmpty && _appliedSearch.isNotEmpty) {
                            _appliedSearch = '';
                            _reload();
                          }
                        },
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search queries',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: colors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _closeSearch,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            Expanded(child: _body(colors)),
          ],
        ),
      ),
    );
  }

  Widget _body(AppSemanticColors colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return HelpdeskMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load queries',
        text: _error,
        actionLabel: 'Try again',
        onAction: _reload,
      );
    }
    if (_queries.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _reload(showSpinner: false),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: _appliedSearch.isNotEmpty
                  ? const HelpdeskMessage(
                      icon: Icons.search_off_rounded,
                      title: 'No matching queries',
                      text: 'Try a different search.',
                    )
                  : HelpdeskMessage(
                      icon: Icons.support_agent_rounded,
                      title: 'No queries yet',
                      text:
                          'You have not raised any help desk queries. '
                          'Ask for help and the team will get back to you.',
                      actionLabel: 'Ask for Help',
                      onAction: _askHelp,
                    ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _reload(showSpinner: false),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          96,
        ),
        itemCount: _queries.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index >= _queries.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final query = _queries[index];
          return HelpdeskQueryCard(
            query: query,
            onTap: () => _openQuery(query),
          );
        },
      ),
    );
  }
}

/// Ticket summary card, used in the list and at the top of the detail page.
class HelpdeskQueryCard extends StatelessWidget {
  const HelpdeskQueryCard({super.key, required this.query, this.onTap});

  final HelpdeskQuery query;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  query.queryTypeName.toUpperCase(),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                helpdeskTimeAgo(query.modifiedAt),
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (query.ticketNo.isNotEmpty) ...[
                Flexible(
                  child: Text(
                    query.ticketNo,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              HelpdeskStatusPill(status: query.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            query.title.isEmpty ? 'Untitled query' : query.title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (query.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              query.description,
              maxLines: onTap == null ? null : 3,
              overflow: onTap == null ? null : TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, height: 1.4),
            ),
          ],
          if (query.attachments.isNotEmpty) ...[
            const SizedBox(height: 4),
            HelpdeskAttachmentLinks(urls: query.attachments),
          ],
        ],
      ),
    );
  }
}
