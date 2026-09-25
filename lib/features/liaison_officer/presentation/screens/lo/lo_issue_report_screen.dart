import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_issue_report.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:share_plus/share_plus.dart';

/// Issue reporting — durable on device; speculative CAP POST when available.
class LoIssueReportScreen extends StatefulWidget {
  const LoIssueReportScreen({
    super.key,
    this.assignmentId,
    this.delegateName,
  });

  final String? assignmentId;
  final String? delegateName;

  @override
  State<LoIssueReportScreen> createState() => _LoIssueReportScreenState();
}

class _LoIssueReportScreenState extends State<LoIssueReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LoPortalBloc>().add(LoPortalIssuesRefreshRequested());
    });
  }

  Future<void> _shareIssue(LoIssueReport issue) async {
    await Share.share(
      issue.toShareText(),
      subject: 'LO issue: ${issue.title}',
    );
  }

  Future<void> _openForm() async {
    final title = TextEditingController();
    final details = TextEditingController();
    var category = LoIssueCategory.other;
    var priority = LoIssuePriority.medium;

    final ok = await showAppFormSheet(
      context: context,
      title: 'Report issue',
      confirmLabel: 'Submit',
      builder: (ctx, setLocal) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Theme.of(ctx).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Issues are stored on this device. If CAP accepts the report it '
                'shows as Submitted; otherwise use Share to escalate to organisers.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          DropdownButtonFormField<LoIssueCategory>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: LoIssueCategory.values
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.name),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setLocal(() => category = v);
            },
          ),
          DropdownButtonFormField<LoIssuePriority>(
            initialValue: priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: LoIssuePriority.values
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setLocal(() => priority = v);
            },
          ),
          TextField(
            controller: details,
            decoration: const InputDecoration(labelText: 'Details'),
            maxLines: 3,
          ),
          if (widget.delegateName != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Delegate: ${widget.delegateName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      onConfirmValidate: () => title.text.trim().isNotEmpty,
    );

    if (ok == true && mounted) {
      context.read<LoPortalBloc>().add(
            LoPortalIssueReported(
              LoIssueReport(
                id: 'issue-${DateTime.now().millisecondsSinceEpoch}',
                title: title.text.trim(),
                category: category,
                priority: priority,
                details: details.text.trim(),
                reportedAt: DateTime.now(),
                assignmentId: widget.assignmentId,
                delegateName: widget.delegateName,
              ),
            ),
          );
    }
    title.dispose();
    details.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issue reports')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Report'),
      ),
      body: BlocBuilder<LoPortalBloc, LoPortalState>(
        builder: (context, state) {
          if (state.issues.isEmpty) {
            return const AppEmptyState(
              message: 'No issues reported yet.',
              icon: Icons.report_problem_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: state.issues.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Issues stay on this device. Share any report to escalate '
                        'to organisers when CAP write is unavailable.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                );
              }
              final issue = state.issues[i - 1];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        AppStatusChip(
                          label: issue.synced ? 'Submitted' : 'On device',
                        ),
                        IconButton(
                          tooltip: 'Share / escalate',
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () => _shareIssue(issue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        AppStatusChip(label: issue.category.name),
                        AppStatusChip(label: issue.priority.name),
                      ],
                    ),
                    if ((issue.delegateName ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Delegate: ${issue.delegateName}'),
                    ],
                    if (issue.details.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(issue.details),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      issue.reportedAt.toLocal().toString().split('.').first,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
