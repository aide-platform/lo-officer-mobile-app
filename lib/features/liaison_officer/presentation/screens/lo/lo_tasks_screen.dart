import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';

class LoTasksScreen extends StatelessWidget {
  const LoTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<LoPortalBloc>().add(LoPortalLoadRequested());
            await context.read<LoPortalBloc>().stream.firstWhere(
                  (s) =>
                      s.status == LoPortalStatus.ready ||
                      s.status == LoPortalStatus.failure,
                );
          },
          child: state.tasks.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    AppEmptyState(message: 'No tasks assigned.'),
                  ],
                )
              : Builder(
                  builder: (context) {
                    final grouped = <String, List<LoTaskDto>>{};
                    for (final t in state.tasks) {
                      final key = t.delegateName ?? 'Unassigned';
                      grouped.putIfAbsent(key, () => []).add(t);
                    }
                    final keys = grouped.keys.toList();
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: keys.length,
                      itemBuilder: (context, i) {
                        final delegate = keys[i];
                        final tasks = grouped[delegate]!;
                        final total = tasks.length;
                        final pending = tasks
                            .where((t) =>
                                (t.statusCode ?? '')
                                    .toUpperCase()
                                    .contains('PEND') ||
                                (t.statusName ?? '')
                                    .toUpperCase()
                                    .contains('PEND'))
                            .length;
                        final inProgress = tasks
                            .where((t) =>
                                (t.statusCode ?? '')
                                    .toUpperCase()
                                    .contains('PROGRESS') ||
                                (t.statusName ?? '')
                                    .toUpperCase()
                                    .contains('PROGRESS'))
                            .length;
                        final completed = tasks
                            .where((t) =>
                                (t.statusCode ?? '')
                                    .toUpperCase()
                                    .contains('COMPLETE') ||
                                (t.statusName ?? '')
                                    .toUpperCase()
                                    .contains('COMPLETE'))
                            .length;
                        return AppCard(
                          child: ExpansionTile(
                            initiallyExpanded: i == 0,
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            title: Text(
                              delegate,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              'Total $total · Pending $pending · In progress $inProgress · Done $completed',
                            ),
                            children:
                                tasks.map((t) => _TaskTile(task: t)).toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});
  final LoTaskDto task;

  Future<void> _updateStatus(BuildContext context) async {
    if (task.id == null) return;
    var status = task.statusCode ?? 'PENDING';
    final remarks = TextEditingController();
    final ok = await showAppFormSheet(
      context: context,
      title: 'Update status',
      builder: (ctx, setLocal) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
              DropdownMenuItem(
                value: 'IN_PROGRESS',
                child: Text('In Progress'),
              ),
              DropdownMenuItem(
                value: 'COMPLETED',
                child: Text('Completed'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setLocal(() => status = v);
            },
          ),
          TextField(
            controller: remarks,
            decoration: const InputDecoration(
              labelText: 'Remarks (optional)',
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      remarks.dispose();
      return;
    }
    context.read<LoPortalBloc>().add(
          LoPortalTaskStatusUpdated(
            taskId: task.id!,
            statusCode: status,
            remarks: remarks.text.trim().isEmpty ? null : remarks.text.trim(),
          ),
        );
    remarks.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(task.taskTitle ?? ''),
      subtitle: Text(
        [
          task.taskDescription,
          if (task.scheduledDate != null)
            '${task.scheduledDate} ${task.scheduledTime ?? ''}',
          task.locationVenue,
        ].where((e) => e != null && e.toString().isNotEmpty).join(' · '),
      ),
      trailing: IconButton(
        tooltip: 'Update status',
        onPressed: () => _updateStatus(context),
        icon: AppStatusChip(label: task.statusName ?? task.statusCode ?? '—'),
      ),
    );
  }
}
