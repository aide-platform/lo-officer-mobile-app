import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/services/pick_services.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/org_rep_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class OrgRepShell extends StatefulWidget {
  const OrgRepShell({
    super.key,
    required this.email,
    required this.roleLabel,
  });

  final String email;
  final String roleLabel;

  @override
  State<OrgRepShell> createState() => _OrgRepShellState();
}

class _OrgRepShellState extends State<OrgRepShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Organisation Portal',
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
      body: BlocConsumer<OrgRepBloc, OrgRepState>(
        listener: (context, state) async {
          final bloc = context.read<OrgRepBloc>();
          if (state.lastDownloadBytes != null &&
              state.lastDownloadBytes!.isNotEmpty) {
            final bytes = state.lastDownloadBytes!;
            final name = state.lastDownloadFilename ?? 'badge.pdf';
            final dir = await getTemporaryDirectory();
            final file = File('${dir.path}/$name');
            await file.writeAsBytes(bytes);
            await Share.shareXFiles([XFile(file.path)], text: name);
          }
          if (!context.mounted) return;
          if (state.infoMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(state.infoMessage!),
              ),
            );
          }
          if (state.errorMessage != null &&
              state.status == OrgRepStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(state.errorMessage!),
              ),
            );
          }
          if (state.infoMessage != null ||
              state.errorMessage != null ||
              state.lastDownloadBytes != null) {
            bloc.add(OrgRepClearMessages());
          }
        },
        builder: (context, state) {
          if (state.status == OrgRepStatus.loading ||
              state.status == OrgRepStatus.initial) {
            return const AppLoading(label: 'Loading organisation…');
          }
          if (state.status == OrgRepStatus.failure && state.los.isEmpty) {
            return AppErrorView(
              message: state.errorMessage ?? 'Failed to load',
              onRetry: () =>
                  context.read<OrgRepBloc>().add(OrgRepLoadRequested()),
            );
          }
          return Column(
            children: [
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'LOs'),
                  Tab(text: 'Sub Nodals'),
                  Tab(text: 'Import'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _LosTab(email: widget.email, roleLabel: widget.roleLabel),
                    const _SubNodalsTab(),
                    const _ImportTab(),
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

class _LosTab extends StatelessWidget {
  const _LosTab({required this.email, required this.roleLabel});
  final String email;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrgRepBloc, OrgRepState>(
      builder: (context, state) {
        final orgName =
            state.organisation?['orgName']?.toString() ?? 'Organisation';
        return Column(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(orgName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(email),
                  Text(roleLabel),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: () => context
                            .read<OrgRepBloc>()
                            .add(OrgRepBulkReminderRequested()),
                        child: const Text('Remind incomplete'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _nominate(context),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Nominate LO'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.los.isEmpty
                  ? const AppEmptyState(message: 'No LOs nominated yet.')
                  : StaggeredList(
                      itemCount: state.los.length,
                      itemBuilder: (context, i) {
                        final lo = state.los[i];
                        return AppCard(
                          onTap: () => _showDetail(context, lo),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(lo.displayName),
                            subtitle: Text(
                              '${lo.officialEmail ?? ''}\n'
                              'Status: ${lo.profileStatus ?? '—'}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'Send reminder',
                              onPressed: lo.id == null
                                  ? null
                                  : () => context.read<OrgRepBloc>().add(
                                        OrgRepReminderRequested(lo.id!),
                                      ),
                              icon: const Icon(
                                  Icons.notifications_active_outlined),
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

  void _showDetail(BuildContext context, LiaisonOfficerDto lo) {
    final bloc = context.read<OrgRepBloc>();
    if (lo.id != null) {
      bloc.add(OrgRepLoadLoDetail(lo.id!));
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: BlocBuilder<OrgRepBloc, OrgRepState>(
            builder: (context, state) {
              final d = state.selectedLoDetail ?? lo;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    StatusChip(label: d.profileStatus ?? '—'),
                    const SizedBox(height: 8),
                    Text(
                      'Org: ${d.orgName ?? '—'} (${d.orgTypeName ?? '—'})',
                    ),
                    Text('Gender: ${d.genderName ?? '—'}'),
                    Text('DOB: ${d.dateOfBirth ?? '—'}'),
                    Text('Rank: ${d.rank ?? '—'}'),
                    Text('Designation: ${d.designation ?? '—'}'),
                    Text('Official email: ${d.officialEmail ?? '—'}'),
                    Text('Personal email: ${d.personalEmail ?? '—'}'),
                    Text('Official contact: ${d.officialContact ?? '—'}'),
                    Text('Personal contact: ${d.personalContact ?? '—'}'),
                    Text('Profile status: ${d.profileStatus ?? '—'}'),
                    if (d.currentPassId != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => context.read<OrgRepBloc>().add(
                              OrgRepBadgeDownloadRequested(
                                passId: d.currentPassId!,
                                filename:
                                    'badge-${d.currentPassNumber ?? d.currentPassId}.pdf',
                              ),
                            ),
                        icon: const Icon(Icons.badge_outlined),
                        label: const Text('Download badge'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Profiles submitted by the LO are read-only for Organisation Representatives.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _nominate(BuildContext context) async {
    const salutations = ['Mr', 'Ms', 'Mrs', 'Dr', 'Prof'];
    var salutation = 'Mr';
    final first = TextEditingController();
    final last = TextEditingController();
    final email = TextEditingController();
    final countryCode = TextEditingController(text: '+91');
    final mobile = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nominate LO'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: salutation,
                  decoration:
                      const InputDecoration(labelText: 'Salutation'),
                  items: salutations
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setLocal(() => salutation = v);
                  },
                ),
                TextField(
                  controller: first,
                  decoration:
                      const InputDecoration(labelText: 'First name'),
                ),
                TextField(
                  controller: last,
                  decoration:
                      const InputDecoration(labelText: 'Last name'),
                ),
                TextField(
                  controller: email,
                  decoration:
                      const InputDecoration(labelText: 'Primary email'),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: TextField(
                        controller: countryCode,
                        decoration:
                            const InputDecoration(labelText: 'Code'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: mobile,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Primary mobile',
                        ),
                      ),
                    ),
                  ],
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

    if (ok == true && context.mounted) {
      final code = countryCode.text.trim();
      final local = mobile.text.trim();
      final primaryMobile = local.startsWith('+')
          ? local
          : '$code$local'.replaceAll(' ', '');
      context.read<OrgRepBloc>().add(
            OrgRepNominateRequested({
              'salutation': salutation,
              'firstName': first.text.trim(),
              'lastName': last.text.trim(),
              'primaryEmail': email.text.trim(),
              'primaryMobile': primaryMobile,
            }),
          );
    }

    first.dispose();
    last.dispose();
    email.dispose();
    countryCode.dispose();
    mobile.dispose();
  }
}

class _SubNodalsTab extends StatelessWidget {
  const _SubNodalsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrgRepBloc, OrgRepState>(
      builder: (context, state) {
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: () => _add(context),
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
                            subtitle: Text('${s.email}\n${s.mobile ?? ''}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _edit(context, s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: s.id == null
                                      ? null
                                      : () => context.read<OrgRepBloc>().add(
                                            OrgRepSubNodalDeleteRequested(
                                                s.id!),
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

  Future<void> _add(BuildContext context) async {
    await _upsert(context);
  }

  Future<void> _edit(BuildContext context, OrgSubNodalOfficerDto existing) async {
    await _upsert(context, existing: existing);
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
        title: Text(existing == null
            ? 'Sub Nodal Officer'
            : 'Edit Sub Nodal Officer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Full name')),
            TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: mobile,
                decoration: const InputDecoration(labelText: 'Mobile')),
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
      final body = {
        'fullName': name.text.trim(),
        'email': email.text.trim(),
        'mobile': mobile.text.trim(),
      };
      if (existing?.id == null) {
        context.read<OrgRepBloc>().add(OrgRepSubNodalCreateRequested(body));
      } else {
        context
            .read<OrgRepBloc>()
            .add(OrgRepSubNodalUpdateRequested(existing!.id!, body));
      }
    }
  }
}

class _ImportTab extends StatelessWidget {
  const _ImportTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bulk LO import',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'Download the Excel/CSV template, fill LO basic details, then upload.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () => _downloadTemplate(context),
                    child: const Text('Download template'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _pickImport(context),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Excel/CSV'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    final bloc = context.read<OrgRepBloc>();
    bloc.add(OrgRepImportTemplateRequested());
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final bytes = bloc.state.lastTemplateBytes;
    if (bytes == null || !context.mounted) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/lo-import-template.csv');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'LO import template');
  }

  Future<void> _pickImport(BuildContext context) async {
    final picked = await FilePickService.pickSpreadsheet();
    if (picked == null || !context.mounted) return;
    context.read<OrgRepBloc>().add(
          OrgRepBulkImportRequested(
            bytes: picked.bytes,
            filename: picked.filename,
          ),
        );
  }
}
