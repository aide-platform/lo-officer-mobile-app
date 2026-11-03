import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/utils/lo_display_format.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Alerts tab: alert lead time + local operational alerts.
class LoNotificationsScreen extends StatelessWidget {
  const LoNotificationsScreen({super.key});

  static const _leadOptions = [15, 30, 60, 120];

  /// Lead minutes embedded by the bloc in "Upcoming task" bodies.
  static final _leadInBody = RegExp(r'\(alert (\d+)m before\)');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        final colors = context.semantic;
        final lead = _leadOptions.contains(state.alertLeadMinutes)
            ? state.alertLeadMinutes
            : 60;

        void refresh() {
          context.read<LoPortalBloc>().add(LoPortalAlertsRefreshRequested());
        }

        return RefreshIndicator(
          onRefresh: () async => refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppStagger(
                index: 0,
                child: AppCard(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      const heading = Row(
                        children: [
                          _CircleIcon(icon: Icons.notifications_rounded),
                          SizedBox(width: 12),
                          Expanded(
                            child: _TitleBlock(
                              title: 'Alert lead time',
                              subtitle: 'Get notified before scheduled tasks.',
                            ),
                          ),
                        ],
                      );
                      final controls = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 12, right: 6),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: lead,
                                borderRadius: BorderRadius.circular(12),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: colors.textPrimary,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                                items: _leadOptions
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text('$m min'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  context.read<LoPortalBloc>().add(
                                    LoPortalAlertLeadMinutesChanged(v),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filled(
                            tooltip: 'Refresh',
                            style: IconButton.styleFrom(
                              backgroundColor: colors.accent.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: colors.textPrimary,
                            ),
                            onPressed: refresh,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      );
                      if (c.maxWidth >= 320) {
                        return Row(
                          children: [
                            const Expanded(child: heading),
                            const SizedBox(width: 8),
                            controls,
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          heading,
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: controls,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const _CircleIcon(icon: Icons.notifications_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Local alerts',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (state.alerts.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${state.alerts.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (state.alerts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: AppEmptyState(
                    icon: Icons.notifications_none_rounded,
                    message: 'No local alerts yet.',
                  ),
                )
              else
                ...state.alerts.asMap().entries.map((entry) {
                  final a = entry.value;
                  final title = a['title']?.toString() ?? 'Alert';
                  final body = a['body']?.toString() ?? '';
                  final at = a['at']?.toString() ?? a['createdAt']?.toString();
                  final when = at == null || at.isEmpty
                      ? null
                      : LoDisplayFormat.when(at);
                  final leadMatch = _leadInBody.firstMatch(body);
                  return AppStagger(
                    index: 1 + entry.key,
                    child: _AlertCard(
                      title: title,
                      body: body,
                      when: when,
                      leadMinutes: leadMatch?.group(1),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = context.semantic.accent;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.1),
      ),
      child: Icon(icon, size: 22, color: accent),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.body,
    required this.when,
    required this.leadMinutes,
  });

  final String title;
  final String body;
  final String? when;
  final String? leadMinutes;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: AppTheme.glassCardDecoration(radius: 18, isDark: isDark),
          child: InkWell(
            onTap: () => _showDetails(context),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: accent.withValues(alpha: 0.5)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _CircleIcon(
                                icon: Icons.notifications_rounded,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    if (body.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        body,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colors.textPrimary,
                              ),
                            ],
                          ),
                          if (when != null || leadMinutes != null) ...[
                            const SizedBox(height: 10),
                            Divider(height: 1, color: colors.border),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (when != null) ...[
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      when!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ] else
                                  const Spacer(),
                                if (leadMinutes != null)
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 14,
                                            color: accent,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Alert $leadMinutes min before',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: accent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      // Long broadcast messages scroll instead of overflowing.
      isScrollControlled: true,
      builder: (ctx) {
        final colors = ctx.semantic;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _CircleIcon(icon: Icons.notifications_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  body,
                  style: TextStyle(height: 1.45, color: colors.textPrimary),
                ),
              ],
              if (when != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Received $when',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
