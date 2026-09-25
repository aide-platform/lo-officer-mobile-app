import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_issue_report_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/notifications_inbox_screen.dart';

/// Alerts tab: local operational alerts + entry to CAP inbox + issues.
class LoNotificationsScreen extends StatelessWidget {
  const LoNotificationsScreen({
    super.key,
    this.onOpenInbox,
  });

  final VoidCallback? onOpenInbox;

  static const _leadOptions = [15, 30, 60, 120];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        final lead = _leadOptions.contains(state.alertLeadMinutes)
            ? state.alertLeadMinutes
            : 60;
        final pendingIssues =
            state.issues.where((e) => !e.synced).length;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<LoPortalBloc>().add(LoPortalAlertsRefreshRequested());
            context.read<LoPortalBloc>().add(LoPortalIssuesRefreshRequested());
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Alert lead time',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DropdownButton<int>(
                      value: lead,
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
                        context
                            .read<LoPortalBloc>()
                            .add(LoPortalAlertLeadMinutesChanged(v));
                      },
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () {
                        context
                            .read<LoPortalBloc>()
                            .add(LoPortalAlertsRefreshRequested());
                        context
                            .read<LoPortalBloc>()
                            .add(LoPortalIssuesRefreshRequested());
                      },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              AppCard(
                onTap: () {
                  if (onOpenInbox != null) {
                    onOpenInbox!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsInboxScreen(),
                      ),
                    );
                  }
                },
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.inbox_outlined),
                  title: Text(
                    'CAP notification inbox',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('Schedule updates, task assignments, B2B'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              AppCard(
                onTap: () {
                  final bloc = context.read<LoPortalBloc>();
                  Navigator.of(context).push(
                    AppPageFadeRoute<void>(
                      page: BlocProvider.value(
                        value: bloc,
                        child: const LoIssueReportScreen(),
                      ),
                    ),
                  );
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.report_problem_outlined),
                  title: const Text(
                    'Issue reports',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    pendingIssues > 0
                        ? '$pendingIssues on device — open to share/escalate'
                        : 'Report operational issues',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Local alerts',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (state.alerts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: AppEmptyState(
                    message: 'No local alerts yet.',
                    icon: Icons.notifications_none,
                  ),
                )
              else
                ...state.alerts.map((a) {
                  final title = a['title']?.toString() ?? 'Alert';
                  final body = a['body']?.toString() ?? '';
                  final at = a['at']?.toString() ?? a['createdAt']?.toString();
                  return AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.notifications_active_outlined,
                        color: AppStatusPalette.forLabel('PENDING'),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [body, if (at != null) at]
                            .where((e) => e.toString().isNotEmpty)
                            .join('\n'),
                      ),
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
