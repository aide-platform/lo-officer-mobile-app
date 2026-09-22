import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/services/pick_services.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/nodal_lo_repository.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/nodal_lo_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
    _tabs = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _shareDownload(NodalLoState state) async {
    final bytes = state.lastDownloadBytes;
    if (bytes == null || bytes.isEmpty) return;
    final name = state.lastDownloadFilename ?? 'download.bin';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: name);
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
      body: BlocConsumer<NodalLoBloc, NodalLoState>(
        listener: (context, state) async {
          final messenger = ScaffoldMessenger.of(context);
          final bloc = context.read<NodalLoBloc>();
          if (state.infoMessage != null) {
            messenger.showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(state.infoMessage!),
              ),
            );
          }
          if (state.errorMessage != null &&
              state.status == NodalLoStatus.failure) {
            messenger.showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(state.errorMessage!),
              ),
            );
          }
          if (state.lastDownloadBytes != null &&
              state.lastDownloadBytes!.isNotEmpty) {
            await _shareDownload(state);
          }
          if (state.infoMessage != null ||
              state.errorMessage != null ||
              state.lastDownloadBytes != null) {
            bloc.add(NodalLoClearMessages());
          }
        },
        builder: (context, state) {
          if (state.status == NodalLoStatus.loading ||
              state.status == NodalLoStatus.initial) {
            return const AppLoading(label: 'Loading committee data…');
          }
          if (state.status == NodalLoStatus.failure &&
              state.organisations.isEmpty &&
              state.orgTypes.isEmpty) {
            return AppErrorView(
              message: state.errorMessage ?? 'Failed to load',
              onRetry: () =>
                  context.read<NodalLoBloc>().add(NodalLoLoadRequested()),
            );
          }
          return Column(
            children: [
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Sub Nodals'),
                  Tab(text: 'Org Types'),
                  Tab(text: 'Organisations'),
                  Tab(text: 'Templates'),
                  Tab(text: 'LO Review'),
                  Tab(text: 'Badges'),
                  Tab(text: 'Assign'),
                  Tab(text: 'Tasks'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _OverviewTab(email: widget.email),
                    const _SubNodalsTab(),
                    const _OrgTypesTab(),
                    const _OrganisationsTab(),
                    const _TemplatesTab(),
                    const _LoReviewTab(),
                    const _BadgesTab(),
                    const _AssignTab(),
                    const _TasksTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Overview ────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        final quota = state.badgeQuota;
        return ListView(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                          label: 'Org types ${state.orgTypes.length}'),
                      StatusChip(
                          label: 'Sub nodals ${state.subNodals.length}'),
                      StatusChip(label: 'Orgs ${state.organisations.length}'),
                      StatusChip(
                          label: 'LOs ${state.liaisonOfficers.length}'),
                      StatusChip(
                          label: 'Assignments ${state.assignments.length}'),
                      StatusChip(label: 'Tasks ${state.tasks.length}'),
                      StatusChip(
                        label:
                            'Badges remaining ${state.badgeRemaining}'
                            '${quota != null ? ' / ${quota['allocated'] ?? quota['total'] ?? '—'}' : ''}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Sub Nodals ──────────────────────────────────────────────────────────────

class _SubNodalsTab extends StatelessWidget {
  const _SubNodalsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: () => _upsert(context),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Add Sub Nodal'),
                ),
              ),
            ),
            Expanded(
              child: state.subNodals.isEmpty
                  ? const AppEmptyState(
                      message: 'No sub nodal officers yet.',
                    )
                  : StaggeredList(
                      itemCount: state.subNodals.length,
                      itemBuilder: (context, i) {
                        final s = state.subNodals[i];
                        return AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(s.fullName),
                            subtitle: Text(
                              '${s.email}\n'
                              '${s.orgName ?? ''}'
                              '${s.mobile == null || s.mobile!.isEmpty ? '' : ' · ${s.mobile}'}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _upsert(context, existing: s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: s.id == null
                                      ? null
                                      : () => context.read<NodalLoBloc>().add(
                                            NodalLoDeleteSubNodal(s.id!),
                                          ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _upsert(
    BuildContext context, {
    OrgSubNodalOfficerDto? existing,
  }) async {
    final name = TextEditingController(text: existing?.fullName ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final mobile = TextEditingController(text: existing?.mobile ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? 'Sub Nodal Officer' : 'Edit Sub Nodal Officer',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: mobile,
              decoration: const InputDecoration(labelText: 'Mobile'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final body = {
      'fullName': name.text.trim(),
      'email': email.text.trim(),
      'mobile': mobile.text.trim(),
    };
    final bloc = context.read<NodalLoBloc>();
    if (existing?.id == null) {
      bloc.add(NodalLoCreateSubNodal(body));
    } else {
      bloc.add(NodalLoUpdateSubNodal(existing!.id!, body));
    }
  }
}

// ── Org Types ───────────────────────────────────────────────────────────────

class _OrgTypesTab extends StatelessWidget {
  const _OrgTypesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: () => _edit(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add type'),
                ),
              ),
            ),
            Expanded(
              child: state.orgTypes.isEmpty
                  ? const AppEmptyState(message: 'No organisation types yet.')
                  : StaggeredList(
                      itemCount: state.orgTypes.length,
                      itemBuilder: (context, i) {
                        final t = state.orgTypes[i];
                        return AppCard(
                          onTap: () => _edit(context, t),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(t.displayName),
                            subtitle: Text(t.description ?? ''),
                            trailing: Switch(
                              value: t.isActive != false,
                              onChanged: t.id == null
                                  ? null
                                  : (v) => context.read<NodalLoBloc>().add(
                                        NodalLoSetOrgTypeActive(t.id!, v),
                                      ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, LoOrgTypeDto? existing) async {
    final name = TextEditingController(text: existing?.displayName ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Organisation type' : 'Edit type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final body = {
      'displayName': name.text.trim(),
      'description': desc.text.trim(),
    };
    final bloc = context.read<NodalLoBloc>();
    if (existing?.id == null) {
      bloc.add(NodalLoCreateOrgType(body));
    } else {
      bloc.add(NodalLoUpdateOrgType(existing!.id!, body));
    }
  }
}

// ── Organisations ───────────────────────────────────────────────────────────

class _OrganisationsTab extends StatelessWidget {
  const _OrganisationsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _bulkNomination(context, state),
                    icon: const Icon(Icons.outgoing_mail),
                    label: const Text('Bulk nomination'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _editOrg(context, state, null),
                    icon: const Icon(Icons.add_business),
                    label: const Text('Add organisation'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.organisations.isEmpty
                  ? const AppEmptyState(message: 'No organisations yet.')
                  : StaggeredList(
                      itemCount: state.organisations.length,
                      itemBuilder: (context, i) {
                        final o = state.organisations[i];
                        final st = o.id == null
                            ? const <String, dynamic>{}
                            : (state.orgStatuses[o.id!] ??
                                const <String, dynamic>{});
                        final signed = st['signedUploaded'] == true;
                        final nominated = st['nominationSent'] == true;
                        final profilesCompleted =
                            o.profilesCompletedCount ??
                                o.loSubmittedCount ??
                                0;
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      o.orgName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (v) => _onOrgAction(
                                      context,
                                      state,
                                      o,
                                      v,
                                    ),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 'download',
                                        child: Text('Download DO'),
                                      ),
                                      PopupMenuItem(
                                        value: 'upload',
                                        child: Text('Upload signed DO'),
                                      ),
                                      PopupMenuItem(
                                        value: 'nominate',
                                        child: Text('Send nomination'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text('${o.orgTypeName ?? ''} · ${o.headName}'),
                              Text(o.primaryEmail),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  StatusChip(
                                    label: signed
                                        ? 'Signed DO'
                                        : 'DO pending',
                                  ),
                                  StatusChip(
                                    label: nominated
                                        ? 'Nomination sent'
                                        : 'Not nominated',
                                  ),
                                  StatusChip(
                                    label:
                                        'Logged in: ${o.loggedInCount ?? 0}',
                                  ),
                                  StatusChip(
                                    label:
                                        'Submitted: ${o.loSubmittedCount ?? 0} / ${o.loCount ?? 0}',
                                  ),
                                  StatusChip(
                                    label: 'Completed: $profilesCompleted',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bulkNomination(
    BuildContext context,
    NodalLoState state,
  ) async {
    final orgIds = <String>[];
    for (final o in state.organisations) {
      if (o.id == null) continue;
      final st = state.orgStatuses[o.id!] ?? const <String, dynamic>{};
      if (st['signedUploaded'] == true) {
        orgIds.add(o.id!);
      }
    }
    if (orgIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No organisations with signed DO')),
      );
      return;
    }

    final templates = state.emailTemplates
        .where((e) => e.isActive != false && e.id != null)
        .toList();
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active email templates available.')),
      );
      return;
    }
    String? templateId = templates.first.id;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Bulk nomination (${orgIds.length} orgs)'),
          content: DropdownButtonFormField<String>(
            initialValue: templateId,
            items: templates
                .map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.name),
                  ),
                )
                .toList(),
            onChanged: (v) => setLocal(() => templateId = v),
            decoration: const InputDecoration(labelText: 'Email template'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  templateId == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || templateId == null || !context.mounted) return;
    context.read<NodalLoBloc>().add(
          NodalLoSendNominationBulk(
            orgIds: orgIds,
            emailTemplateId: templateId!,
          ),
        );
  }

  void _onOrgAction(
    BuildContext context,
    NodalLoState state,
    LoOrganisationDto org,
    String action,
  ) {
    switch (action) {
      case 'edit':
        _editOrg(context, state, org);
      case 'download':
        if (org.id != null) {
          context.read<NodalLoBloc>().add(
                NodalLoDownloadOrgDo(
                  org.id!,
                  filename: 'do-${org.orgName.replaceAll(' ', '_')}.pdf',
                ),
              );
        }
      case 'upload':
        _uploadSignedDo(context, org);
      case 'nominate':
        _sendNomination(context, state, org);
    }
  }

  Future<void> _editOrg(
    BuildContext context,
    NodalLoState state,
    LoOrganisationDto? existing,
  ) async {
    final name = TextEditingController(text: existing?.orgName ?? '');
    final head = TextEditingController(text: existing?.headName ?? '');
    final desig =
        TextEditingController(text: existing?.headDesignation ?? '');
    final address = TextEditingController(text: existing?.address ?? '');
    final email = TextEditingController(text: existing?.primaryEmail ?? '');
    final altEmail = TextEditingController(text: existing?.altEmail ?? '');
    final phone =
        TextEditingController(text: existing?.primaryContact ?? '');
    final altPhone = TextEditingController(text: existing?.altContact ?? '');
    final remarks = TextEditingController(text: existing?.remarks ?? '');
    String? typeId = existing?.orgTypeId;
    if (typeId == null && state.orgTypes.isNotEmpty) {
      typeId = state.orgTypes.first.id;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title:
              Text(existing == null ? 'Add organisation' : 'Edit organisation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownMenu<String>(
                  initialSelection: typeId,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  label: const Text('Organisation type'),
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: state.orgTypes
                      .where((t) => t.id != null)
                      .map(
                        (t) => DropdownMenuEntry(
                          value: t.id!,
                          label: t.displayName,
                        ),
                      )
                      .toList(),
                  onSelected: (v) => setLocal(() => typeId = v),
                ),
                TextField(
                  controller: name,
                  decoration:
                      const InputDecoration(labelText: 'Organisation name'),
                ),
                TextField(
                  controller: head,
                  decoration: const InputDecoration(labelText: 'Head name'),
                ),
                TextField(
                  controller: desig,
                  decoration:
                      const InputDecoration(labelText: 'Head designation'),
                ),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                TextField(
                  controller: email,
                  decoration:
                      const InputDecoration(labelText: 'Primary email'),
                ),
                TextField(
                  controller: altEmail,
                  decoration: const InputDecoration(labelText: 'Alt email'),
                ),
                TextField(
                  controller: phone,
                  decoration:
                      const InputDecoration(labelText: 'Primary contact'),
                ),
                TextField(
                  controller: altPhone,
                  decoration: const InputDecoration(labelText: 'Alt contact'),
                ),
                TextField(
                  controller: remarks,
                  decoration: const InputDecoration(labelText: 'Remarks'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !context.mounted) return;
    final body = {
      'orgName': name.text.trim(),
      'orgTypeId': typeId,
      'headName': head.text.trim(),
      'headDesignation': desig.text.trim(),
      'address': address.text.trim(),
      'primaryEmail': email.text.trim(),
      'altEmail': altEmail.text.trim(),
      'primaryContact': phone.text.trim(),
      'altContact': altPhone.text.trim(),
      'remarks': remarks.text.trim(),
    };
    final bloc = context.read<NodalLoBloc>();
    if (existing?.id == null) {
      bloc.add(NodalLoCreateOrganisation(body));
    } else {
      bloc.add(NodalLoUpdateOrganisation(existing!.id!, body));
    }
  }

  Future<void> _previewPickedPdf(PickedFileBytes picked) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${picked.filename}');
    await file.writeAsBytes(picked.bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: picked.filename,
    );
  }

  Future<void> _showPreviewDialog(
    BuildContext context,
    PickedFileBytes picked,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PDF preview'),
        content: Text(
          '${picked.filename}\n${picked.bytes.length} bytes',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _previewPickedPdf(picked);
              } catch (_) {
                // Share unavailable; dialog already dismissed.
              }
            },
            child: const Text('Open/Share preview'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadSignedDo(
    BuildContext context,
    LoOrganisationDto org,
  ) async {
    if (org.id == null) return;
    final authority = TextEditingController();
    final checks = <String, bool>{
      'orgNameCorrect': false,
      'headNameCorrect': false,
      'designationCorrect': false,
      'emailIdCorrect': false,
      'signingAuthorityCorrect': false,
    };
    const checkLabels = <String, String>{
      'orgNameCorrect': 'Organisation Name is correct',
      'headNameCorrect': 'Head of Organisation Name is correct',
      'designationCorrect': 'Designation is correct',
      'emailIdCorrect': 'Email ID is correct',
      'signingAuthorityCorrect': 'Signing Authority is correct',
    };
    PickedFileBytes? picked;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final allChecked = checks.values.every((v) => v);
          return AlertDialog(
            title: Text('Upload signed DO — ${org.orgName}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: authority,
                    decoration: const InputDecoration(
                      labelText: 'Signing authority',
                    ),
                    onChanged: (_) => setLocal(() {}),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in checkLabels.entries)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: checks[entry.key],
                      onChanged: (v) => setLocal(
                        () => checks[entry.key] = v ?? false,
                      ),
                      title: Text(entry.value),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () async {
                      final file = await FilePickService.pickPdfOrDoc();
                      if (file != null) setLocal(() => picked = file);
                    },
                    child: Text(
                      picked == null
                          ? 'Pick PDF'
                          : 'Selected: ${picked!.filename}',
                    ),
                  ),
                  if (picked != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await _previewPickedPdf(picked!);
                        } catch (_) {
                          if (ctx.mounted) {
                            await _showPreviewDialog(ctx, picked!);
                          }
                        }
                      },
                      icon: const Icon(Icons.preview_outlined),
                      label: const Text('Preview PDF'),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: allChecked &&
                        picked != null &&
                        authority.text.trim().isNotEmpty
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: const Text('Upload'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || picked == null || !context.mounted) return;
    context.read<NodalLoBloc>().add(
          NodalLoUploadSignedDo(
            orgId: org.id!,
            bytes: picked!.bytes,
            filename: picked!.filename,
            signingAuthority: authority.text.trim(),
            checklist: Map<String, bool>.from(checks),
          ),
        );
  }

  Future<void> _sendNomination(
    BuildContext context,
    NodalLoState state,
    LoOrganisationDto org,
  ) async {
    if (org.id == null) return;
    final nominationTemplates = state.emailTemplates.where((e) {
      if (e.isActive == false || e.id == null) return false;
      final tag = (e.purposeTag ?? '').toLowerCase();
      return tag.contains('do letter') ||
          tag.contains('nomination') ||
          tag.contains('invite');
    }).toList();
    final templates = nominationTemplates.isNotEmpty
        ? nominationTemplates
        : state.emailTemplates
            .where((e) => e.isActive != false && e.id != null)
            .toList();
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active email templates available.')),
      );
      return;
    }
    String? templateId = templates.first.id;
    PickedFileBytes? attachment;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Send nomination — ${org.orgName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: templateId,
                items: templates
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => templateId = v),
                decoration: const InputDecoration(labelText: 'Email template'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () async {
                  final file = await FilePickService.pickAnyAttachment();
                  if (file != null) setLocal(() => attachment = file);
                },
                child: Text(
                  attachment == null
                      ? 'Optional attachment'
                      : 'Attached: ${attachment!.filename}',
                ),
              ),
              TextButton(
                onPressed: () async {
                  final file = await ImagePickService.pickImage();
                  if (file != null) setLocal(() => attachment = file);
                },
                child: const Text('Or attach image'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  templateId == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || templateId == null || !context.mounted) return;
    context.read<NodalLoBloc>().add(
          NodalLoSendNomination(
            orgId: org.id!,
            emailTemplateId: templateId!,
            attachments: attachment == null
                ? const []
                : [
                    PickedAttachment(
                      bytes: attachment!.bytes,
                      filename: attachment!.filename,
                    ),
                  ],
          ),
        );
  }
}

// ── Templates ───────────────────────────────────────────────────────────────

class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        return ListView(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'DO letter templates',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _editDo(context, state, null),
                        child: const Text('Add DO'),
                      ),
                    ],
                  ),
                  if (state.doLetterTemplates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No DO templates yet.'),
                    )
                  else
                    ...state.doLetterTemplates.map((t) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.picture_as_pdf_outlined),
                        title: Text(t.templateName),
                        subtitle: Text(
                          '${t.signingAuthority}'
                          '${t.applicableOrgTypeIds.isEmpty ? '' : ' · ${t.applicableOrgTypeIds.length} org type(s)'}',
                        ),
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              tooltip: 'Download',
                              onPressed: t.id == null
                                  ? null
                                  : () => context.read<NodalLoBloc>().add(
                                        NodalLoDownloadDoTemplate(
                                          t.id!,
                                          filename: t.templateFileName ??
                                              '${t.templateName}.pdf',
                                        ),
                                      ),
                              icon: const Icon(Icons.download_outlined),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _editDo(context, state, t),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: t.id == null
                                  ? null
                                  : () => context.read<NodalLoBloc>().add(
                                        NodalLoDeleteDoTemplate(t.id!),
                                      ),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Email templates',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _editEmail(context, null),
                        child: const Text('Add email'),
                      ),
                    ],
                  ),
                  ...state.emailTemplates.map((e) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.name),
                      subtitle: Text('${e.purposeTag ?? ''} · ${e.subject}'),
                      trailing: Wrap(
                        children: [
                          Switch(
                            value: e.isActive != false,
                            onChanged: e.id == null
                                ? null
                                : (v) => context.read<NodalLoBloc>().add(
                                      NodalLoUpdateEmailTemplate(
                                        e.id!,
                                        {
                                          'name': e.name,
                                          'purposeTag': e.purposeTag,
                                          'subject': e.subject,
                                          'body': e.body,
                                          'isActive': v,
                                        },
                                      ),
                                    ),
                          ),
                          IconButton(
                            onPressed: () => _editEmail(context, e),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: e.id == null
                                ? null
                                : () => context.read<NodalLoBloc>().add(
                                      NodalLoDeleteEmailTemplate(e.id!),
                                    ),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Activities',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _editActivity(context, null),
                        child: const Text('Add activity'),
                      ),
                    ],
                  ),
                  ...state.activities.map((a) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.activityTitle),
                      subtitle: Text(a.activityDesc ?? ''),
                      trailing: Wrap(
                        children: [
                          Switch(
                            value: a.isActive != false,
                            onChanged: a.id == null
                                ? null
                                : (v) => context.read<NodalLoBloc>().add(
                                      NodalLoSetActivityActive(a.id!, v),
                                    ),
                          ),
                          IconButton(
                            onPressed: () => _editActivity(context, a),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editDo(
    BuildContext context,
    NodalLoState state,
    DoLetterTemplateDto? existing,
  ) async {
    final name = TextEditingController(text: existing?.templateName ?? '');
    final authority =
        TextEditingController(text: existing?.signingAuthority ?? '');
    final selected = <String>{...?(existing?.applicableOrgTypeIds)};
    PickedFileBytes? picked;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'DO template' : 'Edit DO template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: authority,
                  decoration:
                      const InputDecoration(labelText: 'Signing authority'),
                ),
                const SizedBox(height: 8),
                const Text('Applicable org types',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                ...state.orgTypes.where((t) => t.id != null).map((t) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: selected.contains(t.id),
                    title: Text(t.displayName),
                    onChanged: (v) => setLocal(() {
                      if (v == true) {
                        selected.add(t.id!);
                      } else {
                        selected.remove(t.id);
                      }
                    }),
                  );
                }),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () async {
                    final file = await FilePickService.pickPdfOrDoc();
                    if (file != null) setLocal(() => picked = file);
                  },
                  child: Text(
                    picked == null
                        ? (existing?.templateFileName ?? 'Pick PDF/DOC')
                        : 'Selected: ${picked!.filename}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !context.mounted) return;
    final payload = {
      'templateName': name.text.trim(),
      'signingAuthority': authority.text.trim(),
      'recipientType': selected.join(','),
      'isActive': true,
    };
    final bloc = context.read<NodalLoBloc>();
    if (existing?.id == null) {
      bloc.add(NodalLoCreateDoTemplate(
        payload: payload,
        fileBytes: picked?.bytes,
        filename: picked?.filename,
      ));
    } else {
      bloc.add(NodalLoUpdateDoTemplate(
        existing!.id!,
        payload: payload,
        fileBytes: picked?.bytes,
        filename: picked?.filename,
      ));
    }
  }

  Future<void> _editEmail(
    BuildContext context,
    EmailTemplateDto? existing,
  ) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final subject = TextEditingController(text: existing?.subject ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    final tag = TextEditingController(
      text: existing?.purposeTag ?? 'nomination',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Email template' : 'Edit email'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: tag,
                decoration: const InputDecoration(labelText: 'Purpose / tag'),
              ),
              TextField(
                controller: subject,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              TextField(
                controller: body,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final map = {
      'name': name.text.trim(),
      'purposeTag': tag.text.trim(),
      'subject': subject.text.trim(),
      'body': body.text.trim(),
      'isActive': existing?.isActive ?? true,
    };
    final bloc = context.read<NodalLoBloc>();
    if (existing?.id == null) {
      bloc.add(NodalLoCreateEmailTemplate(map));
    } else {
      bloc.add(NodalLoUpdateEmailTemplate(existing!.id!, map));
    }
  }

  Future<void> _editActivity(
    BuildContext context,
    LoActivityDto? existing,
  ) async {
    final title = TextEditingController(text: existing?.activityTitle ?? '');
    final desc = TextEditingController(text: existing?.activityDesc ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Activity' : 'Edit activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final map = {
      'activityTitle': title.text.trim(),
      'activityDesc': desc.text.trim(),
    };
    final bloc = context.read<NodalLoBloc>();
    if (existing?.id == null) {
      bloc.add(NodalLoCreateActivity(map));
    } else {
      bloc.add(NodalLoUpdateActivity(existing!.id!, map));
    }
  }
}

// ── LO Review ───────────────────────────────────────────────────────────────

class _LoReviewTab extends StatelessWidget {
  const _LoReviewTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        final orgNames = <String>{};
        final orgTypes = <String>{};
        final statuses = <String>{};
        for (final lo in state.liaisonOfficers) {
          if (lo.orgName != null && lo.orgName!.isNotEmpty) {
            orgNames.add(lo.orgName!);
          }
          if (lo.orgTypeName != null && lo.orgTypeName!.isNotEmpty) {
            orgTypes.add(lo.orgTypeName!);
          }
          if (lo.profileStatus != null && lo.profileStatus!.isNotEmpty) {
            statuses.add(lo.profileStatus!);
          }
        }

        final filtered = state.filteredLiaisonOfficers;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.filterOrgName,
                      decoration: const InputDecoration(
                        labelText: 'Org',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All orgs'),
                        ),
                        ...orgNames.map(
                          (n) => DropdownMenuItem(value: n, child: Text(n)),
                        ),
                      ],
                      onChanged: (v) => context.read<NodalLoBloc>().add(
                            NodalLoSetLoFilters(
                              orgName: v,
                              clearOrgName: v == null,
                            ),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.filterOrgTypeName,
                      decoration: const InputDecoration(
                        labelText: 'Org type',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All types'),
                        ),
                        ...orgTypes.map(
                          (n) => DropdownMenuItem(value: n, child: Text(n)),
                        ),
                      ],
                      onChanged: (v) => context.read<NodalLoBloc>().add(
                            NodalLoSetLoFilters(
                              orgTypeName: v,
                              clearOrgTypeName: v == null,
                            ),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.filterProfileStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All statuses'),
                        ),
                        ...statuses.map(
                          (n) => DropdownMenuItem(value: n, child: Text(n)),
                        ),
                      ],
                      onChanged: (v) => context.read<NodalLoBloc>().add(
                            NodalLoSetLoFilters(
                              profileStatus: v,
                              clearProfileStatus: v == null,
                            ),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextFormField(
                      initialValue: state.filterLanguage ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final trimmed = v.trim();
                        context.read<NodalLoBloc>().add(
                              NodalLoSetLoFilters(
                                language: trimmed.isEmpty ? null : trimmed,
                                clearLanguage: trimmed.isEmpty,
                              ),
                            );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextFormField(
                      initialValue: state.filterAvailability ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Availability',
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final trimmed = v.trim();
                        context.read<NodalLoBloc>().add(
                              NodalLoSetLoFilters(
                                availability:
                                    trimmed.isEmpty ? null : trimmed,
                                clearAvailability: trimmed.isEmpty,
                              ),
                            );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const AppEmptyState(message: 'No LO profiles to review.')
                  : StaggeredList(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final lo = filtered[i];
                        return AppCard(
                          onTap: lo.id == null
                              ? null
                              : () => _showDetail(context, lo.id!),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lo.displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  StatusChip(label: lo.profileStatus ?? '—'),
                                ],
                              ),
                              Text(
                                  '${lo.orgName ?? ''} · ${lo.orgTypeName ?? ''}'),
                              Text(lo.officialEmail ?? ''),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDetail(BuildContext context, String loId) async {
    final bloc = context.read<NodalLoBloc>();
    bloc.add(NodalLoLoadLoDetail(loId));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return BlocBuilder<NodalLoBloc, NodalLoState>(
          builder: (ctx, state) {
            if (state.detailLoading || state.detailLo == null) {
              return const SizedBox(
                height: 200,
                child: AppLoading(label: 'Loading LO…'),
              );
            }
            final lo = state.detailLo!;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lo.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Organisation: ${lo.orgName ?? '—'}'),
                    Text('Org type: ${lo.orgTypeName ?? '—'}'),
                    Text('Status: ${lo.profileStatus ?? '—'}'),
                    Text('Gender: ${lo.genderName ?? '—'}'),
                    Text('DOB: ${lo.dateOfBirth ?? '—'}'),
                    Text('Rank: ${lo.rank ?? '—'}'),
                    Text('Designation: ${lo.designation ?? '—'}'),
                    Text('Official email: ${lo.officialEmail ?? '—'}'),
                    Text('Personal email: ${lo.personalEmail ?? '—'}'),
                    Text('Official contact: ${lo.officialContact ?? '—'}'),
                    Text('Personal contact: ${lo.personalContact ?? '—'}'),
                    Text('WhatsApp: ${lo.whatsappNumber ?? '—'}'),
                    Text('Availability: ${lo.availabilityStatus ?? '—'}'),
                    const SizedBox(height: 12),
                    StatusChip(label: lo.profileStatus ?? '—'),
                    const SizedBox(height: 16),
                    const Text(
                      'Languages',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (state.detailLanguages.isEmpty && lo.languages.isEmpty)
                      const Text('—')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (state.detailLanguages.isNotEmpty
                                ? state.detailLanguages
                                : lo.languages)
                            .map((l) => StatusChip(label: l))
                            .toList(),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Experience',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (state.detailExperiences.isEmpty)
                      const Text('No experience recorded.')
                    else
                      ...state.detailExperiences.map(
                        (e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.eventName ?? 'Event'),
                          subtitle: Text(
                            '${e.year ?? ''} · ${e.roleResponsibilities ?? ''}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (context.mounted) {
      bloc.add(NodalLoClearLoDetail());
    }
  }
}

// ── Badges ──────────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        final remaining = state.badgeRemaining;
        final selectedCount = state.selectedLoIds.length;
        final overQuota = selectedCount > remaining;

        return Column(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quota remaining: $remaining',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text('Selected: $selectedCount'),
                  if (overQuota)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Selection exceeds remaining badge quota.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: GradientButton(
                          label: 'Assign selected',
                          onPressed: selectedCount == 0 || overQuota
                              ? null
                              : () {
                                  final personIds = <String>[];
                                  for (final lo in state.liaisonOfficers) {
                                    if (lo.id != null &&
                                        state.selectedLoIds.contains(lo.id)) {
                                      personIds.add(lo.personId ?? lo.id!);
                                    }
                                  }
                                  context.read<NodalLoBloc>().add(
                                        NodalLoAssignBadge(
                                          personIds: personIds,
                                        ),
                                      );
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: selectedCount == 0
                            ? null
                            : () => context
                                .read<NodalLoBloc>()
                                .add(NodalLoClearLoSelection()),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.liaisonOfficers.isEmpty
                  ? const AppEmptyState(message: 'No LOs available.')
                  : ListView.builder(
                      itemCount: state.liaisonOfficers.length,
                      itemBuilder: (context, i) {
                        final lo = state.liaisonOfficers[i];
                        if (lo.id == null) return const SizedBox.shrink();
                        final selected = state.selectedLoIds.contains(lo.id);
                        return AppCard(
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: selected,
                            onChanged: (_) => context.read<NodalLoBloc>().add(
                                  NodalLoToggleLoSelection(lo.id!),
                                ),
                            title: Text(lo.displayName),
                            subtitle: Text(
                              '${lo.orgName ?? ''}\n'
                              '${lo.currentPassNumber != null ? 'Pass: ${lo.currentPassNumber}' : 'No badge yet'}',
                            ),
                            isThreeLine: true,
                            secondary: lo.currentPassId == null
                                ? null
                                : IconButton(
                                    tooltip: 'Download badge',
                                    onPressed: () =>
                                        context.read<NodalLoBloc>().add(
                                              NodalLoDownloadBadge(
                                                lo.currentPassId!,
                                                filename:
                                                    'badge-${lo.currentPassNumber ?? lo.currentPassId}.pdf',
                                              ),
                                            ),
                                    icon: const Icon(Icons.badge_outlined),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Assign ──────────────────────────────────────────────────────────────────

class _AssignTab extends StatelessWidget {
  const _AssignTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: () => _assign(context, state),
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
                              '${a.loFullName ?? ''} · ${a.delegateType ?? ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: a.id == null
                                      ? null
                                      : () => _editAssignment(
                                            context,
                                            state,
                                            a,
                                          ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Unassign',
                                  onPressed: a.id == null
                                      ? null
                                      : () => context.read<NodalLoBloc>().add(
                                            NodalLoDeleteAssignment(a.id!),
                                          ),
                                  icon: const Icon(Icons.link_off),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _assign(BuildContext context, NodalLoState state) async {
    await _upsertAssignment(context, state);
  }

  Future<void> _editAssignment(
    BuildContext context,
    NodalLoState state,
    LoAssignmentDto existing,
  ) async {
    await _upsertAssignment(context, state, existing: existing);
  }

  Future<void> _upsertAssignment(
    BuildContext context,
    NodalLoState state, {
    LoAssignmentDto? existing,
  }) async {
    final losWithId =
        state.liaisonOfficers.where((e) => e.id != null).toList();
    String? loId = existing?.loId ??
        (losWithId.isEmpty ? null : losWithId.first.id);
    Map<String, dynamic>? delegate;
    if (existing?.personId != null) {
      for (final d in state.assignableDelegates) {
        if (d['personId']?.toString() == existing!.personId) {
          delegate = d;
          break;
        }
      }
      if (delegate == null && existing!.personId != null) {
        delegate = {
          'personId': existing.personId,
          'fullName': existing.delegateName,
          'attendeeType': existing.delegateType,
        };
      }
    } else if (state.assignableDelegates.isNotEmpty) {
      delegate = state.assignableDelegates.first;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Assign LO' : 'Edit assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: loId,
                items: losWithId
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => loId = v),
                decoration:
                    const InputDecoration(labelText: 'Liaison Officer'),
              ),
              DropdownButtonFormField<String>(
                initialValue: delegate?['personId']?.toString(),
                items: [
                  if (delegate != null &&
                      !state.assignableDelegates.any(
                        (d) =>
                            d['personId']?.toString() ==
                            delegate!['personId']?.toString(),
                      ))
                    DropdownMenuItem(
                      value: delegate!['personId']?.toString(),
                      child: Text(
                        delegate!['fullName']?.toString() ?? 'Delegate',
                      ),
                    ),
                  ...state.assignableDelegates.map(
                    (d) => DropdownMenuItem(
                      value: d['personId']?.toString(),
                      child: Text(d['fullName']?.toString() ?? 'Delegate'),
                    ),
                  ),
                ],
                onChanged: (v) => setLocal(() {
                  Map<String, dynamic>? found;
                  for (final d in state.assignableDelegates) {
                    if (d['personId']?.toString() == v) {
                      found = d;
                      break;
                    }
                  }
                  if (found == null &&
                      delegate != null &&
                      delegate!['personId']?.toString() == v) {
                    found = delegate;
                  }
                  delegate = found;
                }),
                decoration: const InputDecoration(labelText: 'Delegate'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(existing == null ? 'Assign' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !context.mounted || loId == null || delegate == null) {
      return;
    }

    final bloc = context.read<NodalLoBloc>();
    final body = {
      'loId': loId,
      'personId': delegate!['personId'],
      'attendeeId': delegate!['attendeeId'],
      'delegateType':
          delegate!['attendeeType'] ?? delegate!['delegateType'],
      'delegateName': delegate!['fullName'],
    };
    if (existing?.id != null) {
      bloc.add(NodalLoDeleteAssignment(existing!.id!));
    }
    bloc.add(NodalLoCreateAssignment(body));
  }
}

// ── Tasks ───────────────────────────────────────────────────────────────────

class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        final filtered = state.filteredTasks;

        final delegates = <String>{};
        final sources = <String>{};
        final statuses = <String>{};
        final dates = <String>{};
        for (final t in state.tasks) {
          if (t.delegateName != null && t.delegateName!.isNotEmpty) {
            delegates.add(t.delegateName!);
          }
          if (t.taskSource != null && t.taskSource!.isNotEmpty) {
            sources.add(t.taskSource!);
          }
          final s = t.statusCode ?? t.statusName;
          if (s != null && s.isNotEmpty) statuses.add(s);
          if (t.scheduledDate != null && t.scheduledDate!.isNotEmpty) {
            dates.add(t.scheduledDate!);
          }
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.filterTaskLoId,
                      decoration: const InputDecoration(
                        labelText: 'LO',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All LOs'),
                        ),
                        ...state.liaisonOfficers
                            .where((e) => e.id != null)
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(e.displayName),
                              ),
                            ),
                      ],
                      onChanged: (v) => context.read<NodalLoBloc>().add(
                            NodalLoSetTaskFilters(
                              loId: v,
                              clearLoId: v == null,
                            ),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.filterTaskDelegate,
                      decoration: const InputDecoration(
                        labelText: 'Delegate',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All'),
                        ),
                        ...delegates.map(
                          (n) => DropdownMenuItem(value: n, child: Text(n)),
                        ),
                      ],
                      onChanged: (v) => context.read<NodalLoBloc>().add(
                            NodalLoSetTaskFilters(
                              delegateName: v,
                              clearDelegateName: v == null,
                            ),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.filterTaskSource,
                      decoration: const InputDecoration(
                        labelText: 'Source',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All'),
                        ),
                        ...sources.map(
                          (n) => DropdownMenuItem(value: n, child: Text(n)),
                        ),
                      ],
                      onChanged: (v) => context.read<NodalLoBloc>().add(
                            NodalLoSetTaskFilters(
                              taskSource: v,
                              clearTaskSource: v == null,
                            ),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.filterTaskStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All'),
                        ),
                        ...statuses.map(
                          (n) => DropdownMenuItem(value: n, child: Text(n)),
                        ),
                      ],
                      onChanged: (v) => context.read<NodalLoBloc>().add(
                            NodalLoSetTaskFilters(
                              status: v,
                              clearStatus: v == null,
                            ),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.filterTaskDate,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All'),
                        ),
                        ...dates.map(
                          (n) => DropdownMenuItem(value: n, child: Text(n)),
                        ),
                      ],
                      onChanged: (v) => context.read<NodalLoBloc>().add(
                            NodalLoSetTaskFilters(
                              date: v,
                              clearDate: v == null,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: () => _editTask(context, state, null),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Assign task'),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const AppEmptyState(message: 'No tasks to monitor.')
                  : StaggeredList(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final t = filtered[i];
                        return AppCard(
                          onTap: () => _editTask(context, state, t),
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
      },
    );
  }

  Future<void> _editTask(
    BuildContext context,
    NodalLoState state,
    LoTaskDto? existing,
  ) async {
    final title = TextEditingController(text: existing?.taskTitle ?? '');
    final desc =
        TextEditingController(text: existing?.taskDescription ?? '');
    final venue =
        TextEditingController(text: existing?.locationVenue ?? '');
    final remarks = TextEditingController(text: existing?.remarks ?? '');
    final dateCtrl =
        TextEditingController(text: existing?.scheduledDate ?? '');
    final timeCtrl =
        TextEditingController(text: existing?.scheduledTime ?? '');

    final losWithId =
        state.liaisonOfficers.where((e) => e.id != null).toList();
    final asgWithId = state.assignments.where((e) => e.id != null).toList();
    String? loId =
        existing?.loId ?? (losWithId.isEmpty ? null : losWithId.first.id);
    String? assignId = existing?.loAssignId ??
        (asgWithId.isEmpty ? null : asgWithId.first.id);
    String source = existing?.taskSource ?? 'CUSTOM';
    String? activityId = existing?.activityId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Assign task' : 'Edit task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: loId,
                  items: losWithId
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => loId = v),
                  decoration: const InputDecoration(labelText: 'LO'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: assignId,
                  items: asgWithId
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.delegateName ?? e.id!),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => assignId = v),
                  decoration: const InputDecoration(
                      labelText: 'Assignment / delegate'),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'CUSTOM', label: Text('Custom')),
                    ButtonSegment(
                      value: 'ACTIVITY_MASTER',
                      label: Text('Master'),
                    ),
                  ],
                  selected: {source},
                  onSelectionChanged: (s) {
                    String? first;
                    for (final v in s) {
                      first = v;
                      break;
                    }
                    setLocal(() => source = first ?? 'CUSTOM');
                  },
                ),
                if (source == 'ACTIVITY_MASTER')
                  DropdownButtonFormField<String>(
                    initialValue: activityId,
                    items: state.activities
                        .where((e) => e.id != null)
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.activityTitle),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setLocal(() {
                        activityId = v;
                        for (final a in state.activities) {
                          if (a.id == v) {
                            title.text = a.activityTitle;
                            desc.text = a.activityDesc ?? '';
                            break;
                          }
                        }
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Activity'),
                  ),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Scheduled date (YYYY-MM-DD)',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    DateTime initial = now;
                    final existingDate = dateCtrl.text.trim();
                    if (existingDate.isNotEmpty) {
                      final parsed = DateTime.tryParse(existingDate);
                      if (parsed != null) initial = parsed;
                    }
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: initial,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked == null) return;
                    final y = picked.year.toString().padLeft(4, '0');
                    final m = picked.month.toString().padLeft(2, '0');
                    final d = picked.day.toString().padLeft(2, '0');
                    setLocal(() => dateCtrl.text = '$y-$m-$d');
                  },
                ),
                TextField(
                  controller: timeCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Scheduled time (HH:mm)',
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  onTap: () async {
                    TimeOfDay initial = TimeOfDay.now();
                    final existingTime = timeCtrl.text.trim();
                    if (existingTime.isNotEmpty) {
                      final parts = existingTime.split(':');
                      if (parts.length >= 2) {
                        final h = int.tryParse(parts[0]);
                        final m = int.tryParse(parts[1]);
                        if (h != null && m != null) {
                          initial = TimeOfDay(hour: h, minute: m);
                        }
                      }
                    }
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: initial,
                    );
                    if (picked == null) return;
                    final h = picked.hour.toString().padLeft(2, '0');
                    final m = picked.minute.toString().padLeft(2, '0');
                    setLocal(() => timeCtrl.text = '$h:$m');
                  },
                ),
                TextField(
                  controller: venue,
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                TextField(
                  controller: remarks,
                  decoration: const InputDecoration(labelText: 'Remarks'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !context.mounted) return;

    LoAssignmentDto? assignment;
    for (final a in state.assignments) {
      if (a.id == assignId) {
        assignment = a;
        break;
      }
    }

    final body = <String, dynamic>{
      'loId': loId,
      'loAssignId': assignId,
      'delegateName': assignment?.delegateName,
      'delegatePersonId': assignment?.personId,
      'taskSource': source,
      'activityId': ?activityId,
      'taskTitle': title.text.trim(),
      'taskDescription': desc.text.trim(),
      'scheduledDate': dateCtrl.text.trim(),
      'scheduledTime': timeCtrl.text.trim(),
      'locationVenue': venue.text.trim(),
      'remarks': remarks.text.trim(),
    };

    final bloc = context.read<NodalLoBloc>();
    if (existing?.id == null) {
      bloc.add(NodalLoCreateTask(body));
    } else {
      bloc.add(NodalLoUpdateTask(existing!.id!, body));
    }
  }
}
