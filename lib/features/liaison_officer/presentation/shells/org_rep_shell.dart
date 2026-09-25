import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/services/pick_services.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/core/widgets/role_shell_drawer.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/org_rep_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/help_support_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/notifications_inbox_screen.dart';
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

class _OrgRepShellState extends State<OrgRepShell> {
  int _index = 0;

  Future<void> _shareDownload(OrgRepState state) async {
    final bytes = state.lastDownloadBytes;
    if (bytes == null || bytes.isEmpty) return;
    final name = state.lastDownloadFilename ?? 'badge.pdf';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: name);
  }

  void _openImport(BuildContext context) {
    final bloc = context.read<OrgRepBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const _ImportPage(),
        ),
      ),
    );
  }

  void _openSubNodals(BuildContext context) {
    final bloc = context.read<OrgRepBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const _SubNodalsPage(),
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
    final rank = TextEditingController();
    final designation = TextEditingController();

    final ok = await showAppFormSheet(
      context: context,
      title: 'Nominate LO',
      confirmLabel: 'Save',
      builder: (ctx, setLocal) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: salutation,
            decoration: const InputDecoration(labelText: 'Salutation'),
            items: salutations
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setLocal(() => salutation = v);
            },
          ),
          TextField(
            controller: first,
            decoration: const InputDecoration(labelText: 'First name'),
            textCapitalization: TextCapitalization.words,
          ),
          TextField(
            controller: last,
            decoration: const InputDecoration(labelText: 'Last name'),
            textCapitalization: TextCapitalization.words,
          ),
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Primary email'),
            keyboardType: TextInputType.emailAddress,
          ),
          Row(
            children: [
              SizedBox(
                width: 88,
                child: TextField(
                  controller: countryCode,
                  decoration: const InputDecoration(labelText: 'Code'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: mobile,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Primary mobile'),
                ),
              ),
            ],
          ),
          TextField(
            controller: rank,
            decoration: const InputDecoration(labelText: 'Rank (optional)'),
          ),
          TextField(
            controller: designation,
            decoration:
                const InputDecoration(labelText: 'Designation (optional)'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final code = countryCode.text.trim();
      final local = mobile.text.trim();
      final primaryMobile =
          local.startsWith('+') ? local : '$code$local'.replaceAll(' ', '');
      context.read<OrgRepBloc>().add(
            OrgRepNominateRequested({
              'salutation': salutation,
              'firstName': first.text.trim(),
              'lastName': last.text.trim(),
              'primaryEmail': email.text.trim(),
              'primaryMobile': primaryMobile,
              if (rank.text.trim().isNotEmpty) 'rank': rank.text.trim(),
              if (designation.text.trim().isNotEmpty)
                'designation': designation.text.trim(),
            }),
          );
    }

    first.dispose();
    last.dispose();
    email.dispose();
    countryCode.dispose();
    mobile.dispose();
    rank.dispose();
    designation.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Overview', 'Nominations'];
    return AdaptiveRoleScaffold(
      title: titles[_index.clamp(0, titles.length - 1)],
      drawer: RoleShellDrawer(
        email: widget.email,
        roleLabel: widget.roleLabel,
        navItems: [
          RoleDrawerNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Overview',
            onTap: () => setState(() => _index = 0),
          ),
          RoleDrawerNavItem(
            icon: Icons.people_outline,
            label: 'Nominations',
            onTap: () => setState(() => _index = 1),
          ),
          RoleDrawerNavItem(
            icon: Icons.upload_file_outlined,
            label: 'Bulk import',
            onTap: () => _openImport(context),
          ),
          RoleDrawerNavItem(
            icon: Icons.group_outlined,
            label: 'Sub Nodal Officers',
            onTap: () => _openSubNodals(context),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsInboxScreen(),
              ),
            );
          },
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        ),
        PopupMenuButton<String>(
          tooltip: 'More',
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (v) {
            switch (v) {
              case 'remind':
                context.read<OrgRepBloc>().add(OrgRepBulkReminderRequested());
              case 'import':
                _openImport(context);
              case 'subnodals':
                _openSubNodals(context);
              case 'help':
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HelpSupportScreen(),
                  ),
                );
              case 'theme':
                context.read<ThemeCubit>().toggle();
              case 'logout':
                performLogout(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'remind',
              child: Text('Remind all pending'),
            ),
            PopupMenuItem(
              value: 'import',
              child: Text('Bulk import'),
            ),
            PopupMenuItem(
              value: 'subnodals',
              child: Text('Sub Nodal Officers'),
            ),
            PopupMenuItem(
              value: 'help',
              child: Text('Help & Support'),
            ),
            PopupMenuItem(
              value: 'theme',
              child: Text('Toggle theme'),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
        ),
      ],
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _nominate(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nominate LO'),
            )
          : null,
      body: BlocConsumer<OrgRepBloc, OrgRepState>(
        listener: (context, state) async {
          final bloc = context.read<OrgRepBloc>();
          if (state.lastDownloadBytes != null &&
              state.lastDownloadBytes!.isNotEmpty) {
            await _shareDownload(state);
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
          return AppTabFade(
            index: _index,
            children: [
              _OverviewTab(email: widget.email, roleLabel: widget.roleLabel),
              const _NominationsTab(),
            ],
          );
        },
      ),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.badge_outlined),
          selectedIcon: Icon(Icons.badge),
          label: 'Nominations',
        ),
      ],
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
    );
  }
}

// ── Stats helpers ───────────────────────────────────────────────────────────

class _LoStats {
  const _LoStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.rejected,
  });

  final int total;
  final int completed;
  final int pending;
  final int rejected;

  factory _LoStats.fromLos(List<LiaisonOfficerDto> los) {
    var completed = 0;
    var pending = 0;
    var rejected = 0;
    for (final lo in los) {
      final s = (lo.profileStatus ?? '').trim().toUpperCase();
      if (_isRejected(s)) {
        rejected++;
      } else if (_isCompleted(s, lo.profileComplete)) {
        completed++;
      } else {
        pending++;
      }
    }
    return _LoStats(
      total: los.length,
      completed: completed,
      pending: pending,
      rejected: rejected,
    );
  }

  static bool _isRejected(String s) =>
      s == 'REJECTED' || s.contains('REJECT');

  static bool _isCompleted(String s, bool? profileComplete) {
    if (profileComplete == true) return true;
    return s.contains('COMPLETE') ||
        s.contains('APPROV') ||
        s.contains('SUBMIT') ||
        s == 'ACTIVE' ||
        s == 'DONE';
  }
}

class _HorizontalStatCards extends StatelessWidget {
  const _HorizontalStatCards({required this.stats});

  final _LoStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total', stats.total, Icons.groups_outlined, const Color(0xFF1565C0)),
      (
        'Completed',
        stats.completed,
        Icons.check_circle_outline,
        const Color(0xFF2E7D32)
      ),
      (
        'Pending',
        stats.pending,
        Icons.hourglass_empty,
        const Color(0xFFEF6C00)
      ),
      (
        'Rejected',
        stats.rejected,
        Icons.cancel_outlined,
        const Color(0xFFC62828)
      ),
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, value, icon, color) = items[i];
          return SizedBox(
            width: 118,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const Spacer(),
                      Text(
                        '$value',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Overview ────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.email, required this.roleLabel});

  final String email;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrgRepBloc, OrgRepState>(
      builder: (context, state) {
        final orgName =
            state.organisation?['orgName']?.toString() ?? 'Organisation';
        final stats = _LoStats.fromLos(state.los);
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orgName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(email),
                  Text(
                    roleLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _HorizontalStatCards(stats: stats),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Quick actions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Remind all pending'),
                    onTap: () => context
                        .read<OrgRepBloc>()
                        .add(OrgRepBulkReminderRequested()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.upload_file_outlined),
                    title: const Text('Bulk import'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final bloc = context.read<OrgRepBloc>();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider.value(
                            value: bloc,
                            child: const _ImportPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.group_outlined),
                    title: const Text('Sub Nodal Officers'),
                    subtitle: Text('${state.subNodals.length} on team'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final bloc = context.read<OrgRepBloc>();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider.value(
                            value: bloc,
                            child: const _SubNodalsPage(),
                          ),
                        ),
                      );
                    },
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

// ── Nominations ─────────────────────────────────────────────────────────────

class _NominationsTab extends StatelessWidget {
  const _NominationsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrgRepBloc, OrgRepState>(
      builder: (context, state) {
        final stats = _LoStats.fromLos(state.los);
        return Column(
          children: [
            const SizedBox(height: 8),
            _HorizontalStatCards(stats: stats),
            const SizedBox(height: 4),
            Expanded(
              child: state.los.isEmpty
                  ? const AppEmptyState(
                      message: 'No LOs nominated yet.',
                      icon: Icons.person_off_outlined,
                    )
                  : StaggeredList(
                      itemCount: state.los.length,
                      itemBuilder: (context, i) {
                        final lo = state.los[i];
                        return AppCard(
                          onTap: () => _showDetail(context, lo),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lo.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  AppStatusChip(
                                    label: lo.profileStatus ?? 'Pending',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(lo.officialEmail ?? '—'),
                              Text(lo.officialContact ?? '—'),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (_isRejected(lo.profileStatus) &&
                                      lo.id != null)
                                    IconButton(
                                      tooltip: 'Re-nominate',
                                      onPressed: () =>
                                          _reNominate(context, lo),
                                      icon: const Icon(Icons.refresh),
                                    ),
                                  IconButton(
                                    tooltip: 'Send reminder',
                                    onPressed: lo.id == null
                                        ? null
                                        : () => context
                                            .read<OrgRepBloc>()
                                            .add(
                                              OrgRepReminderRequested(lo.id!),
                                            ),
                                    icon: const Icon(
                                      Icons.notifications_active_outlined,
                                    ),
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

  void _showDetail(BuildContext context, LiaisonOfficerDto lo) {
    final bloc = context.read<OrgRepBloc>();
    if (lo.id != null) {
      bloc.add(OrgRepLoadLoDetail(lo.id!));
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
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
                    AppStatusChip(label: d.profileStatus ?? '—'),
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
                    if (_isRejected(d.profileStatus) && d.id != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _reNominate(context, d);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Re-nominate'),
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

  Future<void> _reNominate(
    BuildContext context,
    LiaisonOfficerDto rejected,
  ) async {
    if (rejected.id == null) return;
    const salutations = ['Mr', 'Ms', 'Mrs', 'Dr', 'Prof'];
    var salutation = rejected.salutationName ?? 'Mr';
    if (!salutations.contains(salutation)) salutation = 'Mr';
    final first = TextEditingController(text: rejected.firstName ?? '');
    final last = TextEditingController(text: rejected.lastName ?? '');
    final email =
        TextEditingController(text: rejected.officialEmail ?? '');
    final mobile =
        TextEditingController(text: rejected.officialContact ?? '');
    final designation =
        TextEditingController(text: rejected.designation ?? '');
    final rank = TextEditingController(text: rejected.rank ?? '');

    final ok = await showAppFormSheet(
      context: context,
      title: 'Re-nominate LO',
      confirmLabel: 'Re-nominate',
      builder: (ctx, setLocal) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: salutation,
            decoration: const InputDecoration(labelText: 'Salutation'),
            items: salutations
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setLocal(() => salutation = v);
            },
          ),
          TextField(
            controller: first,
            decoration: const InputDecoration(labelText: 'First name'),
          ),
          TextField(
            controller: last,
            decoration: const InputDecoration(labelText: 'Last name'),
          ),
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Primary email'),
          ),
          TextField(
            controller: mobile,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Primary mobile'),
          ),
          TextField(
            controller: rank,
            decoration: const InputDecoration(labelText: 'Rank'),
          ),
          TextField(
            controller: designation,
            decoration: const InputDecoration(labelText: 'Designation'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      context.read<OrgRepBloc>().add(
            OrgRepReNominateRequested(
              rejectedLoId: rejected.id!,
              body: {
                'salutation': salutation,
                'firstName': first.text.trim(),
                'lastName': last.text.trim(),
                'primaryEmail': email.text.trim(),
                'primaryMobile': mobile.text.trim(),
                if (rank.text.trim().isNotEmpty) 'rank': rank.text.trim(),
                if (designation.text.trim().isNotEmpty)
                  'designation': designation.text.trim(),
              },
            ),
          );
    }

    first.dispose();
    last.dispose();
    email.dispose();
    mobile.dispose();
    designation.dispose();
    rank.dispose();
  }

  static bool _isRejected(String? status) {
    final s = status?.trim().toUpperCase() ?? '';
    return s == 'REJECTED' || s.contains('REJECT');
  }
}

// ── Bulk import (pushed page) ───────────────────────────────────────────────

class _ImportPage extends StatelessWidget {
  const _ImportPage();

  Future<void> _downloadTemplate(BuildContext context) async {
    final bloc = context.read<OrgRepBloc>();
    bloc.add(OrgRepImportTemplateRequested());
    try {
      final state = await bloc.stream
          .firstWhere(
            (s) =>
                (s.lastTemplateBytes != null &&
                    s.lastTemplateBytes!.isNotEmpty) ||
                (s.status == OrgRepStatus.failure && s.errorMessage != null),
          )
          .timeout(const Duration(seconds: 20));
      final bytes = state.lastTemplateBytes;
      if (bytes == null || bytes.isEmpty || !context.mounted) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lo-import-template.csv');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'LO import template');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not download import template.'),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk import')),
      body: BlocBuilder<OrgRepBloc, OrgRepState>(
        builder: (context, state) {
          final result = state.lastImportResult;
          final errors = (result?['errors'] as List?) ?? const [];
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bulk LO import',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Download the Excel/CSV template, fill LO basic details, then upload.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => _downloadTemplate(context),
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Download template'),
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
              if (result != null) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last import result',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text('Inserted: ${result['inserted'] ?? 0}'),
                      Text('Skipped: ${result['skipped'] ?? 0}'),
                      if (result['error'] != null)
                        Text(
                          'Error: ${result['error']}',
                          style: const TextStyle(color: Color(0xFFC62828)),
                        ),
                      if (errors.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Error rows',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        ...errors.map((e) {
                          final map = e is Map
                              ? Map<String, dynamic>.from(e)
                              : <String, dynamic>{};
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Row ${map['row'] ?? '—'}: ${map['message'] ?? e}',
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Sub Nodals (pushed page) ────────────────────────────────────────────────

class _SubNodalsPage extends StatelessWidget {
  const _SubNodalsPage();

  Future<void> _upsert(
    BuildContext context, {
    OrgSubNodalOfficerDto? existing,
  }) async {
    final name = TextEditingController(text: existing?.fullName ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final mobile = TextEditingController(text: existing?.mobile ?? '');
    final designation =
        TextEditingController(text: existing?.designation ?? '');
    var isActive = existing?.isActive != false;

    final ok = await showAppFormSheet(
      context: context,
      title: existing == null
          ? 'Add Sub Nodal Officer'
          : 'Edit Sub Nodal Officer',
      builder: (ctx, setLocal) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Full name'),
            textCapitalization: TextCapitalization.words,
          ),
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: mobile,
            decoration: const InputDecoration(labelText: 'Mobile'),
            keyboardType: TextInputType.phone,
          ),
          TextField(
            controller: designation,
            decoration: const InputDecoration(labelText: 'Designation'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: isActive,
            onChanged: (v) => setLocal(() => isActive = v),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final body = <String, dynamic>{
        'fullName': name.text.trim(),
        'email': email.text.trim(),
        'mobile': mobile.text.trim(),
        'designation': designation.text.trim(),
        'isActive': isActive,
      };
      if (existing?.id == null) {
        context.read<OrgRepBloc>().add(OrgRepSubNodalCreateRequested(body));
      } else {
        context
            .read<OrgRepBloc>()
            .add(OrgRepSubNodalUpdateRequested(existing!.id!, body));
      }
    }

    name.dispose();
    email.dispose();
    mobile.dispose();
    designation.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sub Nodal Officers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _upsert(context),
        icon: const Icon(Icons.group_add),
        label: const Text('Add'),
      ),
      body: BlocBuilder<OrgRepBloc, OrgRepState>(
        builder: (context, state) {
          if (state.subNodals.isEmpty) {
            return const AppEmptyState(
              message: 'No sub nodal officers yet.',
              icon: Icons.group_off_outlined,
            );
          }
          return StaggeredList(
            itemCount: state.subNodals.length,
            itemBuilder: (context, i) {
              final s = state.subNodals[i];
              final active = s.isActive != false;
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        s.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          s.email,
                          if (s.designation != null &&
                              s.designation!.isNotEmpty)
                            s.designation!,
                          if (s.mobile != null && s.mobile!.isNotEmpty)
                            s.mobile!,
                        ].join(' · '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _upsert(context, existing: s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: s.id == null
                                ? null
                                : () => context.read<OrgRepBloc>().add(
                                      OrgRepSubNodalDeleteRequested(s.id!),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        AppStatusChip(
                          label: active ? 'Active' : 'Inactive',
                        ),
                        const Spacer(),
                        const Text('Active'),
                        Switch(
                          value: active,
                          onChanged: s.id == null
                              ? null
                              : (v) {
                                  context.read<OrgRepBloc>().add(
                                        OrgRepSubNodalUpdateRequested(
                                          s.id!,
                                          {
                                            'fullName': s.fullName,
                                            'email': s.email,
                                            if (s.mobile != null)
                                              'mobile': s.mobile,
                                            if (s.designation != null)
                                              'designation': s.designation,
                                            'isActive': v,
                                          },
                                        ),
                                      );
                                },
                        ),
                      ],
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
