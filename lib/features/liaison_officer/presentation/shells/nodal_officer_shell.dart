import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/nodal_lo_bloc.dart';

class NodalOfficerShell extends StatefulWidget {
  const NodalOfficerShell({
    super.key,
    required this.email,
    required this.roleLabel,
  });

  final String email;
  final String roleLabel;

  @override
  State<NodalOfficerShell> createState() => _NodalOfficerShellState();
}

class _NodalOfficerShellState extends State<NodalOfficerShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'LO Committee',
      actions: [
        IconButton(
          onPressed: () => context.read<ThemeCubit>().toggle(),
          icon: const Icon(Icons.brightness_6_rounded, color: Colors.white),
        ),
        IconButton(
          onPressed: () => performLogout(context),
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
        ),
      ],
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Org Types'),
              Tab(text: 'Organisations'),
              Tab(text: 'Templates'),
              Tab(text: 'LO Review'),
              Tab(text: 'Assign'),
              Tab(text: 'Tasks'),
            ],
          ),
          Expanded(
            child: BlocBuilder<NodalLoBloc, NodalLoState>(
              builder: (context, state) {
                if (state.status == NodalLoStatus.loading ||
                    state.status == NodalLoStatus.initial) {
                  return const AppLoading(label: 'Loading committee data…');
                }
                if (state.status == NodalLoStatus.failure &&
                    state.organisations.isEmpty) {
                  return AppErrorView(
                    message: state.errorMessage ?? 'Failed to load',
                    onRetry: () => context
                        .read<NodalLoBloc>()
                        .add(NodalLoLoadRequested()),
                  );
                }
                return TabBarView(
                  controller: _tabs,
                  children: [
                    _OverviewTab(email: widget.email, state: state),
                    _OrgTypesTab(state: state),
                    _OrganisationsTab(state: state),
                    _TemplatesTab(state: state),
                    _LoReviewTab(state: state),
                    _AssignTab(state: state),
                    _TasksMonitorTab(state: state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.email, required this.state});
  final String email;
  final NodalLoState state;

  @override
  Widget build(BuildContext context) {
    final quota = state.badgeQuota;
    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(label: 'Orgs ${state.organisations.length}'),
                  StatusChip(label: 'LOs ${state.liaisonOfficers.length}'),
                  StatusChip(label: 'Tasks ${state.tasks.length}'),
                  StatusChip(
                    label:
                        'Badges ${quota?['remaining'] ?? '—'} / ${quota?['allocated'] ?? '—'}',
                  ),
                ],
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DO Letter Templates',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                'Templates from /app/do-letter-templates. '
                'Signed DO upload & nomination email dispatch use CAP org workflows.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (state.doLetterTemplates.isEmpty)
                const Text('No templates configured.')
              else
                ...state.doLetterTemplates.map(
                  (t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: Text(t['name']?.toString() ?? 'Template'),
                    subtitle: Text(
                        t['signingAuthority']?.toString() ??
                            t['description']?.toString() ??
                            ''),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrgTypesTab extends StatelessWidget {
  const _OrgTypesTab({required this.state});
  final NodalLoState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: const Text('Add type'),
            ),
          ),
        ),
        Expanded(
          child: StaggeredList(
            itemCount: state.orgTypes.length,
            itemBuilder: (context, i) {
              final t = state.orgTypes[i];
              return AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.displayName),
                  subtitle: Text(t.description ?? ''),
                  trailing: StatusChip(
                    label: t.isActive == false ? 'Inactive' : 'Active',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    final name = TextEditingController();
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Organisation type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: desc,
                decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<NodalLoBloc>().add(
            NodalLoCreateOrgType({
              'displayName': name.text.trim(),
              'description': desc.text.trim(),
            }),
          );
    }
  }
}

class _OrganisationsTab extends StatelessWidget {
  const _OrganisationsTab({required this.state});
  final NodalLoState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add_business),
              label: const Text('Add organisation'),
            ),
          ),
        ),
        Expanded(
          child: state.organisations.isEmpty
              ? const AppEmptyState(message: 'No organisations yet.')
              : StaggeredList(
                  itemCount: state.organisations.length,
                  itemBuilder: (context, i) {
                    final o = state.organisations[i];
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.orgName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${o.orgTypeName ?? ''} · ${o.headName}'),
                          Text(o.primaryEmail),
                          Text(
                              'LOs submitted: ${o.loSubmittedCount ?? 0}/${o.loCount ?? 0}'),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    final name = TextEditingController();
    final head = TextEditingController();
    final desig = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    String? typeId =
        state.orgTypes.isNotEmpty ? state.orgTypes.first.id : null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add organisation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: typeId,
                  items: state.orgTypes
                      .where((t) => t.id != null)
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => typeId = v),
                  decoration:
                      const InputDecoration(labelText: 'Organisation type'),
                ),
                TextField(
                    controller: name,
                    decoration:
                        const InputDecoration(labelText: 'Organisation name')),
                TextField(
                    controller: head,
                    decoration: const InputDecoration(labelText: 'Head name')),
                TextField(
                    controller: desig,
                    decoration:
                        const InputDecoration(labelText: 'Head designation')),
                TextField(
                    controller: email,
                    decoration:
                        const InputDecoration(labelText: 'Primary email')),
                TextField(
                    controller: phone,
                    decoration:
                        const InputDecoration(labelText: 'Primary contact')),
                TextField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      context.read<NodalLoBloc>().add(
            NodalLoCreateOrganisation({
              'orgName': name.text.trim(),
              'orgTypeId': typeId,
              'headName': head.text.trim(),
              'headDesignation': desig.text.trim(),
              'primaryEmail': email.text.trim(),
              'primaryContact': phone.text.trim(),
              'address': address.text.trim(),
            }),
          );
    }
  }
}

class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab({required this.state});
  final NodalLoState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => _addEmail(context),
                  child: const Text('Add email template'),
                ),
                FilledButton.tonal(
                  onPressed: () => _addActivity(context),
                  child: const Text('Add activity'),
                ),
              ],
            ),
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Email templates',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              ...state.emailTemplates.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.name),
                  subtitle: Text('${e.purposeTag ?? ''} · ${e.subject}'),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Activity master',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              ...state.activities.map(
                (a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(a.activityTitle),
                  subtitle: Text(a.activityDesc ?? ''),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addEmail(BuildContext context) async {
    final name = TextEditingController();
    final subject = TextEditingController();
    final body = TextEditingController();
    final tag = TextEditingController(text: 'DO Letter Communication');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email template'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: tag,
                  decoration: const InputDecoration(labelText: 'Purpose / tag')),
              TextField(
                  controller: subject,
                  decoration: const InputDecoration(labelText: 'Subject')),
              TextField(
                  controller: body,
                  decoration: const InputDecoration(labelText: 'Body'),
                  maxLines: 4),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<NodalLoBloc>().add(
            NodalLoCreateEmailTemplate({
              'name': name.text.trim(),
              'purposeTag': tag.text.trim(),
              'subject': subject.text.trim(),
              'body': body.text.trim(),
            }),
          );
    }
  }

  Future<void> _addActivity(BuildContext context) async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: desc,
                decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<NodalLoBloc>().add(
            NodalLoCreateActivity({
              'activityTitle': title.text.trim(),
              'activityDesc': desc.text.trim(),
            }),
          );
    }
  }
}

class _LoReviewTab extends StatelessWidget {
  const _LoReviewTab({required this.state});
  final NodalLoState state;

  @override
  Widget build(BuildContext context) {
    final submitted = state.liaisonOfficers;
    if (submitted.isEmpty) {
      return const AppEmptyState(message: 'No LO profiles to review.');
    }
    return StaggeredList(
      itemCount: submitted.length,
      itemBuilder: (context, i) {
        final lo = submitted[i];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(lo.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  StatusChip(label: lo.profileStatus ?? '—'),
                ],
              ),
              Text('${lo.orgName ?? ''} · ${lo.orgTypeName ?? ''}'),
              Text(lo.officialEmail ?? ''),
              if (lo.currentPassNumber != null)
                Text('Badge: ${lo.currentPassNumber}'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: lo.id == null
                      ? null
                      : () => context.read<NodalLoBloc>().add(
                            NodalLoAssignBadge({'loId': lo.id}),
                          ),
                  child: const Text('Assign badge'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AssignTab extends StatelessWidget {
  const _AssignTab({required this.state});
  final NodalLoState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _assign(context),
              icon: const Icon(Icons.link),
              label: const Text('Assign LO → Delegate'),
            ),
          ),
        ),
        Expanded(
          child: state.assignments.isEmpty
              ? const AppEmptyState(message: 'No assignments yet.')
              : StaggeredList(
                  itemCount: state.assignments.length,
                  itemBuilder: (context, i) {
                    final a = state.assignments[i];
                    return AppCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(a.delegateName ?? 'Delegate'),
                        subtitle: Text(
                            '${a.loFullName ?? ''} · ${a.delegateType ?? ''}'),
                        trailing: IconButton(
                          onPressed: a.id == null
                              ? null
                              : () => context
                                  .read<NodalLoBloc>()
                                  .add(NodalLoDeleteAssignment(a.id!)),
                          icon: const Icon(Icons.link_off),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _assign(BuildContext context) async {
    final losWithId = state.liaisonOfficers.where((e) => e.id != null).toList();
    String? loId = losWithId.isNotEmpty ? losWithId.first.id : null;
    Map<String, dynamic>? delegate =
        state.assignableDelegates.isNotEmpty
            ? state.assignableDelegates.first
            : null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Assign LO'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: loId,
                items: state.liaisonOfficers
                    .where((e) => e.id != null)
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => loId = v),
                decoration: const InputDecoration(labelText: 'Liaison Officer'),
              ),
              DropdownButtonFormField<String>(
                initialValue: delegate?['personId']?.toString(),
                items: state.assignableDelegates
                    .map(
                      (d) => DropdownMenuItem(
                        value: d['personId']?.toString(),
                        child: Text(d['fullName']?.toString() ?? 'Delegate'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() {
                  delegate = state.assignableDelegates.firstWhere(
                    (d) => d['personId']?.toString() == v,
                    orElse: () => {},
                  );
                }),
                decoration: const InputDecoration(labelText: 'Delegate'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Assign')),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted && loId != null && delegate != null) {
      context.read<NodalLoBloc>().add(
            NodalLoCreateAssignment({
              'loId': loId,
              'personId': delegate!['personId'],
              'attendeeId': delegate!['attendeeId'],
              'delegateType': delegate!['attendeeType'],
              'delegateName': delegate!['fullName'],
            }),
          );
    }
  }
}

class _TasksMonitorTab extends StatelessWidget {
  const _TasksMonitorTab({required this.state});
  final NodalLoState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _createTask(context),
              icon: const Icon(Icons.add_task),
              label: const Text('Assign task'),
            ),
          ),
        ),
        Expanded(
          child: state.tasks.isEmpty
              ? const AppEmptyState(message: 'No tasks to monitor.')
              : StaggeredList(
                  itemCount: state.tasks.length,
                  itemBuilder: (context, i) {
                    final t = state.tasks[i];
                    return AppCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.taskTitle ?? ''),
                        subtitle: Text(
                          '${t.loFullName ?? ''} → ${t.delegateName ?? ''}\n'
                          '${t.scheduledDate ?? ''} ${t.scheduledTime ?? ''} · ${t.locationVenue ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: StatusChip(
                          label: t.statusName ?? t.statusCode ?? '—',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _createTask(BuildContext context) async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final losWithId = state.liaisonOfficers.where((e) => e.id != null).toList();
    final asgWithId = state.assignments.where((e) => e.id != null).toList();
    String? loId = losWithId.isNotEmpty ? losWithId.first.id : null;
    String? assignId = asgWithId.isNotEmpty ? asgWithId.first.id : null;
    String source = 'CUSTOM';
    String? activityId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Assign task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: loId,
                  items: state.liaisonOfficers
                      .where((e) => e.id != null)
                      .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.displayName),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => loId = v),
                  decoration: const InputDecoration(labelText: 'LO'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: assignId,
                  items: state.assignments
                      .where((e) => e.id != null)
                      .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.delegateName ?? e.id!),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => assignId = v),
                  decoration: const InputDecoration(labelText: 'Assignment'),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'CUSTOM', label: Text('Custom')),
                    ButtonSegment(
                        value: 'ACTIVITY_MASTER', label: Text('Master')),
                  ],
                  selected: {source},
                  onSelectionChanged: (s) =>
                      setLocal(() => source = s.first),
                ),
                if (source == 'ACTIVITY_MASTER')
                  DropdownButtonFormField<String>(
                    initialValue: activityId,
                    items: state.activities
                        .where((e) => e.id != null)
                        .map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.activityTitle),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setLocal(() {
                        activityId = v;
                        final act = state.activities
                            .firstWhere((a) => a.id == v);
                        title.text = act.activityTitle;
                        desc.text = act.activityDesc ?? '';
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Activity'),
                  ),
                TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title')),
                TextField(
                    controller: desc,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                    maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      LoAssignmentDto? assignment;
      for (final a in state.assignments) {
        if (a.id == assignId) {
          assignment = a;
          break;
        }
      }
      context.read<NodalLoBloc>().add(
            NodalLoCreateTask({
              'loId': loId,
              'loAssignId': assignId,
              'delegateName': assignment?.delegateName,
              'taskSource': source,
              if (activityId != null) 'activityId': activityId,
              'taskTitle': title.text.trim(),
              'taskDescription': desc.text.trim(),
            }),
          );
    }
  }
}
