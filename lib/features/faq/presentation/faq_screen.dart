import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/design/app_spacing.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/liaison_brand_header.dart';
import 'package:liaison_officer/features/faq/domain/faq_category.dart';
import 'package:liaison_officer/features/helpdesk/presentation/helpdesk_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Opens FAQs under the same brand header as the home shell.
///
/// Pops `'alerts'` or `'more'` when those header actions are used.
Future<String?> openFaqScreen(BuildContext context, {String email = ''}) {
  final bloc = context.read<LoPortalBloc>();
  return Navigator.of(context).push<String>(
    AppPageFadeRoute<String>(
      page: BlocProvider.value(
        value: bloc,
        child: FaqScreen(email: email),
      ),
    ),
  );
}

/// Active FAQs from `GET /app/my-lo/me/faqs`, in the order received.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key, this.email = ''});

  final String email;

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _search = TextEditingController();

  List<FaqItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final firstLoad = _items.isEmpty;
    setState(() {
      _loading = firstLoad;
      _error = null;
    });
    try {
      final faqs = await AppDependencies.instance.loPortalRepository
          .getMyFaqs();
      if (!mounted) return;
      setState(() {
        _items = faqItemsInOrder(faqs);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(error, fallback: 'Could not load FAQs.');
      });
    }
  }

  List<FaqItem> get _visible {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items
        .where(
          (item) =>
              item.question.toLowerCase().contains(query) ||
              item.answer.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF070B18), Color(0xFF12182E)]
                : const [Color(0xFFF4F7FC), Color(0xFFE8F1FF)],
          ),
        ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'FAQs',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search questions',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
            const SizedBox(height: AppSpacing.sm),
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
      return _Message(
        icon: Icons.cloud_off_rounded,
        text: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            80,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            const _Message(icon: Icons.quiz_outlined, text: 'No FAQs yet.'),
            const SizedBox(height: AppSpacing.lg),
            _HelpdeskPrompt(onTap: _openHelpdesk),
          ],
        ),
      );
    }
    final items = _visible;
    if (items.isEmpty) {
      return const _Message(
        icon: Icons.search_off_rounded,
        text: 'No questions match your search.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        itemCount: items.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: _HelpdeskPrompt(onTap: _openHelpdesk),
            );
          }
          return _FaqTile(item: items[index], colors: colors);
        },
      ),
    );
  }

  /// Help Desk opened from the FAQ "Contact Support" prompt. Header actions
  /// chosen there close the FAQ page too.
  Future<void> _openHelpdesk() async {
    final action = await openHelpdeskScreen(context, email: widget.email);
    if (!mounted || action == null) return;
    Navigator.pop(context, action);
  }
}

/// "Still have questions?" card that opens the Help Desk, like the
/// attendees FAQ page. Always shown.
class _HelpdeskPrompt extends StatelessWidget {
  const _HelpdeskPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        children: [
          Text(
            'Still have questions?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "If you couldn't find the answer you were looking for, "
            'our support team is here to help.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item, required this.colors});

  final FaqItem item;
  final AppSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: AppTheme.glassCardDecoration(
        radius: AppRadii.md,
        isDark: isDark,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            iconColor: colors.accent,
            collapsedIconColor: colors.textSecondary,
            title: Text(
              item.question,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                height: 1.3,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    item.answer.isEmpty ? 'No answer provided.' : item.answer,
                    style: TextStyle(
                      color: colors.textSecondary,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: colors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
