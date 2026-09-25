import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/services/pick_services.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/core/widgets/role_shell_drawer.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/nodal_lo_repository.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/nodal_lo_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/help_support_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/nodal/catering_requirements_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/nodal/ecoupons_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/nodal/quota_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/notifications_inbox_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/widgets/dash_charts.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class NodalOfficerShell extends StatefulWidget {
  const NodalOfficerShell({
    super.key,
    required this.email,
    required this.roleLabel,
    this.isSubNodal = false,
  });

  final String email;
  final String roleLabel;
  final bool isSubNodal;

  @override
  State<NodalOfficerShell> createState() => _NodalOfficerShellState();
}

class _NodalOfficerShellState extends State<NodalOfficerShell> {
  int _index = 0;
  int _opsSegment = 0; // 0 Assign, 1 Tasks
  int _losSegment = 0; // 0 Review, 1 Badges (Phase 2 merges actions)

  Future<void> _shareDownload(NodalLoState state) async {
    final bytes = state.lastDownloadBytes;
    if (bytes == null || bytes.isEmpty) return;
    final name = state.lastDownloadFilename ?? 'download.bin';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: name);
  }

  void _goTo(int index, {int? opsSegment, int? losSegment}) {
    setState(() {
      _index = index;
      if (opsSegment != null) _opsSegment = opsSegment;
      if (losSegment != null) _losSegment = losSegment;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'Organisations', 'Liaison Officers', 'Operations', 'More'];
    return AdaptiveRoleScaffold(
      title: titles[_index.clamp(0, titles.length - 1)],
      drawer: RoleShellDrawer(
        email: widget.email,
        roleLabel: widget.roleLabel,
        navItems: [
          RoleDrawerNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            onTap: () => _goTo(0),
          ),
          RoleDrawerNavItem(
            icon: Icons.business_outlined,
            label: 'Organisations',
            onTap: () => _goTo(1),
          ),
          RoleDrawerNavItem(
            icon: Icons.badge_outlined,
            label: 'Liaison Officers',
            onTap: () => _goTo(2),
          ),
          RoleDrawerNavItem(
            icon: Icons.task_alt_outlined,
            label: 'Operations',
            onTap: () => _goTo(3),
          ),
          RoleDrawerNavItem(
            icon: Icons.more_horiz,
            label: 'More',
            onTap: () => _goTo(4),
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
            return const AppLoading(label: 'Loading committee dataâ€¦');
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
          return AppTabFade(
            index: _index,
            children: [
              _NodalHomeTab(
                email: widget.email,
                onShortcut: _goTo,
              ),
              const _NodalOrgsHub(),
              _NodalLosHub(
                segment: _losSegment,
                onSegmentChanged: (v) => setState(() => _losSegment = v),
              ),
              _NodalOpsHub(
                segment: _opsSegment,
                onSegmentChanged: (v) => setState(() => _opsSegment = v),
              ),
              _NodalMoreTab(
                email: widget.email,
                isSubNodal: widget.isSubNodal,
              ),
            ],
          );
        },
      ),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.business_outlined),
          selectedIcon: Icon(Icons.business),
          label: 'Orgs',
        ),
        NavigationDestination(
          icon: Icon(Icons.badge_outlined),
          selectedIcon: Icon(Icons.badge),
          label: 'LOs',
        ),
        NavigationDestination(
          icon: Icon(Icons.hub_outlined),
          selectedIcon: Icon(Icons.hub),
          label: 'Ops',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
    );
  }
}

// â”€â”€ Mobile hubs (bottom-nav destinations) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NodalHomeTab extends StatelessWidget {
  const _NodalHomeTab({required this.email, required this.onShortcut});
  final String email;
  final void Function(int index, {int? opsSegment, int? losSegment}) onShortcut;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        final coverage = state.totalVips > 0
            ? ((state.vipsAssigned / state.totalVips) * 100).round()
            : 0;
        final kpis = <(IconData, String, String, String?)>[
          (
            Icons.apartment_outlined,
            '${state.organisations.length}',
            'Total Organisations',
            null
          ),
          (
            Icons.groups_outlined,
            '${state.liaisonOfficers.length}',
            'Total LOs',
            null
          ),
          (Icons.military_tech_outlined, '${state.totalVips}', 'Total VIPs', null),
          (
            Icons.person_add_alt_1_outlined,
            '${state.vipsAssigned}',
            'VIPs Assigned to LOs',
            state.totalVips > 0 ? '$coverage% coverage' : null
          ),
          (
            Icons.verified_outlined,
            '${state.losWithVipAssignment}',
            'LOs with VIP Assignments',
            null
          ),
          (
            Icons.layers_outlined,
            '${state.losWithoutVipAssignment}',
            'LOs without VIP Assignments',
            null
          ),
          (Icons.checklist_outlined, '${state.tasks.length}', 'Total Tasks', null),
          (
            Icons.check_circle_outline,
            '${state.completedTasks}',
            'Completed Tasks',
            null
          ),
          (
            Icons.schedule_outlined,
            '${state.pendingTasksCount}',
            'Pending Tasks',
            null
          ),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            Text(
              'LO Committee Dashboard',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Live view of organisations, Liaison Officers, VIP assignments and task workload.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(email, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kpis.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (context, i) {
                final k = kpis[i];
                return _DashKpiCard(
                  icon: k.$1,
                  value: k.$2,
                  label: k.$3,
                  hint: k.$4,
                );
              },
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LO Profile Status',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  DashDonutChart(
                    segments: state.loProfileStatusCounts,
                    centerHint: '${state.liaisonOfficers.length}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LO Assignment Coverage',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  DashDonutChart(
                    segments: {
                      'With VIP': state.losWithVipAssignment,
                      'Without VIP': state.losWithoutVipAssignment,
                    },
                    centerHint:
                        state.liaisonOfficers.isEmpty ? null : '$coverage%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Status',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  DashDonutChart(
                    segments: {
                      'Pending': state.pendingTasksCount,
                      'In Progress': state.inProgressTasksCount,
                      'Completed': state.completedTasks,
                    },
                    centerHint: '${state.tasks.length}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Organisations by Type',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  DashBarList(
                    entries: state.orgsByTypeCount.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Organisations by VIPs Assigned',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  DashBarList(entries: state.orgWiseVipSummary),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Organisation Type-wise Summary',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (state.typeWiseSummary.isEmpty)
                    const Text('No type rollups yet')
                  else
                    ...state.typeWiseSummary.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.type,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Orgs ${r.orgs} · LOs ${r.los} · '
                              'With VIP ${r.withVip} · Without ${r.withoutVip} · '
                              'VIPs ${r.vips}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Organisation-wise Details',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (state.orgWiseDetails.isEmpty)
                    const Text('No organisations yet')
                  else
                    ...state.orgWiseDetails.take(12).map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${r.type} · LOs ${r.los} · VIPs ${r.vips} · '
                                  'Tasks ${r.completed}/${r.tasks}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delegate Coverage',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(state.delegateCoverageLabel),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Shortcuts',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _ShortcutTile(
              icon: Icons.business_outlined,
              title: 'Manage Organisations',
              subtitle: 'Register orgs · DO · nominations',
              onTap: () => onShortcut(1),
            ),
            _ShortcutTile(
              icon: Icons.badge_outlined,
              title: 'Liaison Officers',
              subtitle: 'Review profiles · assign badges',
              onTap: () => onShortcut(2),
            ),
            _ShortcutTile(
              icon: Icons.link_outlined,
              title: 'Assign LOs to Delegates',
              subtitle: 'Filter delegates · many-to-many assign',
              onTap: () => onShortcut(3, opsSegment: 0),
            ),
            _ShortcutTile(
              icon: Icons.task_alt_outlined,
              title: 'Task Management',
              subtitle: 'Activity master · monitor status',
              onTap: () => onShortcut(3, opsSegment: 1),
            ),
            _ShortcutTile(
              icon: Icons.confirmation_number_outlined,
              title: 'Badge & Vehicle Quota',
              subtitle: 'Read-only committee quota',
              onTap: () {
                final bloc = context.read<NodalLoBloc>();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: const QuotaScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _DashKpiCard extends StatelessWidget {
  const _DashKpiCard({
    required this.icon,
    required this.value,
    required this.label,
    this.hint,
  });
  final IconData icon;
  final String value;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(icon, color: scheme.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrgHubKpi extends StatelessWidget {
  const _OrgHubKpi({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _NodalOrgsHub extends StatelessWidget {
  const _NodalOrgsHub();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () {
                final bloc = context.read<NodalLoBloc>();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: Scaffold(
                        appBar: AppBar(title: const Text('Organisation Types')),
                        body: const _OrgTypesTab(),
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.category_outlined),
              label: const Text('Organisation Types'),
            ),
          ),
        ),
        const Expanded(child: _OrganisationsTab()),
      ],
    );
  }
}

class _NodalLosHub extends StatelessWidget {
  const _NodalLosHub({
    required this.segment,
    required this.onSegmentChanged,
  });
  final int segment;
  final ValueChanged<int> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _LoStatMini(
                      label: 'Total LOs',
                      value: '${state.liaisonOfficers.length}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LoStatMini(
                      label: 'Prior Experience',
                      value: '${state.losWithPriorExperience}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LoStatMini(
                      label: 'Active',
                      value: '${state.activeLos}',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Profiles'),
                    icon: Icon(Icons.people_outline),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Badges'),
                    icon: Icon(Icons.workspace_premium_outlined),
                  ),
                ],
                selected: {segment},
                onSelectionChanged: (s) => onSegmentChanged(s.first),
              ),
            ),
            Expanded(
              child: segment == 0 ? const _LoReviewTab() : const _BadgesTab(),
            ),
          ],
        );
      },
    );
  }
}

class _LoStatMini extends StatelessWidget {
  const _LoStatMini({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NodalOpsHub extends StatelessWidget {
  const _NodalOpsHub({
    required this.segment,
    required this.onSegmentChanged,
  });
  final int segment;
  final ValueChanged<int> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Assign'),
                        icon: Icon(Icons.link),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Tasks'),
                        icon: Icon(Icons.task_alt),
                      ),
                    ],
                    selected: {segment},
                    onSelectionChanged: (s) => onSegmentChanged(s.first),
                  ),
                ),
              ),
              if (segment == 1) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Activity Master',
                  onPressed: () {
                    final bloc = context.read<NodalLoBloc>();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: bloc,
                          child: Scaffold(
                            appBar: AppBar(title: const Text('Activity Master')),
                            body: const _ActivityMasterTab(),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt_outlined),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: segment == 0 ? const _AssignTab() : const _TasksTab(),
        ),
      ],
    );
  }
}

class _NodalMoreTab extends StatelessWidget {
  const _NodalMoreTab({required this.email, this.isSubNodal = false});
  final String email;
  final bool isSubNodal;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NodalLoBloc>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Signed in', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(email),
          ),
        ),
        if (!isSubNodal)
          _MoreLink(
            icon: Icons.groups_outlined,
            title: 'Sub Nodal Officers',
            onTap: () => _pushEmbedded(context, bloc, const _SubNodalsTab(), 'Sub Nodals'),
          ),
        _MoreLink(
          icon: Icons.confirmation_number_outlined,
          title: 'Badge & Vehicle Pass Quota',
          onTap: () {
            final b = bloc;
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: b,
                  child: const QuotaScreen(),
                ),
              ),
            );
          },
        ),
        if (!isSubNodal)
          _MoreLink(
            icon: Icons.restaurant_outlined,
            title: 'Catering Requirements',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CateringRequirementsScreen(),
              ),
            ),
          ),
        _MoreLink(
          icon: Icons.qr_code_2_outlined,
          title: 'E-Coupons',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const EcouponsScreen(),
            ),
          ),
        ),
        _MoreLink(
          icon: Icons.mail_outline,
          title: 'Email & DO Templates',
          onTap: () => _pushEmbedded(context, bloc, const _TemplatesTab(), 'Templates'),
        ),
        _MoreLink(
          icon: Icons.category_outlined,
          title: 'Organisation Types',
          onTap: () => _pushEmbedded(
            context,
            bloc,
            const _OrgTypesTab(),
            'Organisation Types',
          ),
        ),
        _MoreLink(
          icon: Icons.list_alt_outlined,
          title: 'Activity Master',
          onTap: () => _pushEmbedded(
            context,
            bloc,
            const _ActivityMasterTab(),
            'Activity Master',
          ),
        ),
        _MoreLink(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const HelpSupportScreen(),
            ),
          ),
        ),
        _MoreLink(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NotificationsInboxScreen(),
            ),
          ),
        ),
        _MoreLink(
          icon: Icons.logout_rounded,
          title: 'Logout',
          onTap: () => performLogout(context),
        ),
      ],
    );
  }

  void _pushEmbedded(
    BuildContext context,
    NodalLoBloc bloc,
    Widget child,
    String title,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: Scaffold(
            appBar: AppBar(title: Text(title)),
            body: child,
          ),
        ),
      ),
    );
  }
}

class _MoreLink extends StatelessWidget {
  const _MoreLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// Compact filter dropdown that truncates long labels (avoids RenderFlex overflow).
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.width,
    required this.label,
    required this.value,
    required this.allLabel,
    required this.options,
    required this.onChanged,
  });

  final double width;
  final String label;
  final String? value;
  final String allLabel;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        key: ValueKey<String?>('filter-$label-$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(allLabel, overflow: TextOverflow.ellipsis),
          ),
          ...options.map(
            (n) => DropdownMenuItem<String>(
              value: n,
              child: Text(n, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        selectedItemBuilder: (context) => [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(allLabel, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          ...options.map(
            (n) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(n, overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// â”€â”€ Legacy Overview (unused by bottom-nav Home; kept helpers live in hubs) â”€

// ignore: unused_element
// ignore: unused_element â€” retained for possible deep-link embeds
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
                            '${quota != null ? ' / ${quota['allocated'] ?? quota['total'] ?? 'â€”'}' : ''}',
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

// â”€â”€ Sub Nodals â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SubNodalsTab extends StatefulWidget {
  const _SubNodalsTab();

  @override
  State<_SubNodalsTab> createState() => _SubNodalsTabState();
}

class _SubNodalsTabState extends State<_SubNodalsTab> {
  String _query = '';

  List<OrgSubNodalOfficerDto> _filtered(List<OrgSubNodalOfficerDto> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((s) {
      final hay =
          '${s.fullName} ${s.email} ${s.mobile ?? ''} ${s.designation ?? ''}'
              .toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        final list = _filtered(state.subNodals);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search name / email / mobile',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _upsert(context),
                    icon: const Icon(Icons.group_add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? AppEmptyState(
                      message: state.subNodals.isEmpty
                          ? 'No sub nodal officers yet.'
                          : 'No matches for "$_query".',
                    )
                  : StaggeredList(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final s = list[i];
                        final active = s.isActive != false;
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(s.fullName),
                                subtitle: Text(
                                  [
                                    s.email,
                                    if (s.designation != null &&
                                        s.designation!.isNotEmpty)
                                      s.designation!,
                                    if (s.orgName != null &&
                                        s.orgName!.isNotEmpty)
                                      s.orgName!,
                                    if (s.mobile != null &&
                                        s.mobile!.isNotEmpty)
                                      s.mobile!,
                                  ].join(' · '),
                                ),
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
                                          : () => context
                                              .read<NodalLoBloc>()
                                              .add(
                                                NodalLoDeleteSubNodal(s.id!),
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  StatusChip(
                                    label: active ? 'Active' : 'Inactive',
                                  ),
                                  const SizedBox(width: 8),
                                  StatusChip(
                                    label: s.canApprove == true
                                        ? 'Role: Can approve'
                                        : 'Role: Manage',
                                  ),
                                  const Spacer(),
                                  const Text('Active'),
                                  Switch(
                                    value: active,
                                    onChanged: s.id == null
                                        ? null
                                        : (v) {
                                            context.read<NodalLoBloc>().add(
                                                  NodalLoUpdateSubNodal(
                                                    s.id!,
                                                    {
                                                      'fullName': s.fullName,
                                                      'email': s.email,
                                                      if (s.mobile != null)
                                                        'mobile': s.mobile,
                                                      if (s.designation != null)
                                                        'designation':
                                                            s.designation,
                                                      'isActive': v,
                                                      if (s.canApprove != null)
                                                        'canApprove':
                                                            s.canApprove,
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
    final designation =
        TextEditingController(text: existing?.designation ?? '');
    var isActive = existing?.isActive != false;
    var canApprove = existing?.canApprove == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            existing == null ? 'Sub Nodal Officer' : 'Edit Sub Nodal Officer',
          ),
          content: SingleChildScrollView(
            child: Column(
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Can approve (role / scope)'),
                  value: canApprove,
                  onChanged: (v) => setLocal(() => canApprove = v),
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
    final body = <String, dynamic>{
      'fullName': name.text.trim(),
      'email': email.text.trim(),
      'mobile': mobile.text.trim(),
      'designation': designation.text.trim(),
      'isActive': isActive,
      'canApprove': canApprove,
    };
    final bloc = context.read<NodalLoBloc>();
    if (existing?.id == null) {
      bloc.add(NodalLoCreateSubNodal(body));
    } else {
      bloc.add(NodalLoUpdateSubNodal(existing!.id!, body));
    }
  }
}

// â”€â”€ Org Types â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                            subtitle: Text(
                              [
                                if (t.code != null && t.code!.isNotEmpty)
                                  t.code!,
                                if (t.description != null &&
                                    t.description!.isNotEmpty)
                                  t.description!,
                              ].join(' · '),
                            ),
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
    final code = TextEditingController(text: existing?.code ?? '');
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
              controller: code,
              decoration: const InputDecoration(
                labelText: 'Technical code',
                hintText: 'e.g. DPSU',
              ),
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
      'code': code.text.trim(),
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

// â”€â”€ Organisations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OrganisationsTab extends StatelessWidget {
  const _OrganisationsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _OrgHubKpi(
                          label: 'Organisations',
                          value: '${state.organisations.length}',
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OrgHubKpi(
                          label: 'LOs Nominated',
                          value: '${state.liaisonOfficers.length}',
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _OrgHubKpi(
                          label: 'Profiles Submitted',
                          value:
                              '${state.organisations.fold<int>(0, (a, o) => a + (o.loSubmittedCount ?? o.profilesCompletedCount ?? 0))}',
                          color: AppTheme.indiaGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OrgHubKpi(
                          label: 'Types Represented',
                          value:
                              '${state.organisations.map((o) => o.orgTypeName ?? '').where((t) => t.isNotEmpty).toSet().length}',
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text('${o.orgTypeName ?? ''} · ${o.headName}'),
                              Text(o.primaryEmail),
                              if (o.primaryContact.isNotEmpty)
                                Text('Contact: ${o.primaryContact}'),
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
      case 'delete':
        _confirmDeleteOrg(context, org);
    }
  }

  Future<void> _confirmDeleteOrg(
    BuildContext context,
    LoOrganisationDto org,
  ) async {
    if (org.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete organisation?'),
        content: Text('Remove ${org.orgName}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<NodalLoBloc>().add(NodalLoDeleteOrganisation(org.id!));
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
            title: Text('Upload signed DO â€” ${org.orgName}'),
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
          title: Text('Send nomination â€” ${org.orgName}'),
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

// â”€â”€ Templates â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// â”€â”€ Activity Master (own screen) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ActivityMasterTab extends StatelessWidget {
  const _ActivityMasterTab();

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
                          'Activities',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _TemplatesTab()._editActivity(context, null),
                        child: const Text('Add activity'),
                      ),
                    ],
                  ),
                  if (state.activities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No activities yet.'),
                    )
                  else
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
                              onPressed: () =>
                                  _TemplatesTab()._editActivity(context, a),
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
}

// â”€â”€ Templates â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                          '${t.applicableOrgTypeIds.isEmpty ? '' : ' Â· ${t.applicableOrgTypeIds.length} org type(s)'}',
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
                      subtitle: Text('${e.purposeTag ?? ''} Â· ${e.subject}'),
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
    final ok = await showAppFormSheet(
      context: context,
      title: existing == null ? 'Email template' : 'Edit email',
      builder: (ctx, setLocal) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextFormField(
            controller: tag,
            decoration: const InputDecoration(labelText: 'Purpose / tag'),
          ),
          TextFormField(
            controller: subject,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 8),
          Text(
            'Body (HTML supported â€” same as web Quill)',
            style: Theme.of(ctx).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [
              ActionChip(
                label: const Text('<p>'),
                onPressed: () => setLocal(
                  () => body.text = '${body.text}<p></p>',
                ),
              ),
              ActionChip(
                label: const Text('<b>'),
                onPressed: () => setLocal(
                  () => body.text = '${body.text}<b></b>',
                ),
              ),
              ActionChip(
                label: const Text('<br/>'),
                onPressed: () => setLocal(
                  () => body.text = '${body.text}<br/>',
                ),
              ),
            ],
          ),
          TextFormField(
            controller: body,
            decoration: const InputDecoration(
              labelText: 'Body HTML',
              alignLabelWithHint: true,
            ),
            minLines: 8,
            maxLines: 16,
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
      onConfirmValidate: () =>
          name.text.trim().isNotEmpty && subject.text.trim().isNotEmpty,
    );

    if (ok != true || !context.mounted) return;
    final payload = {
      'name': name.text.trim(),
      'subject': subject.text.trim(),
      'body': body.text,
      'purposeTag': tag.text.trim(),
      'isActive': existing?.isActive ?? true,
    };
    final bloc = context.read<NodalLoBloc>();
    if (existing?.id == null) {
      bloc.add(NodalLoCreateEmailTemplate(payload));
    } else {
      bloc.add(NodalLoUpdateEmailTemplate(existing!.id!, payload));
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

// â”€â”€ LO Review â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LoReviewTab extends StatelessWidget {
  const _LoReviewTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        final orgNames = <String>{};
        final orgTypes = <String>{};
        final statuses = <String>{};
        final languages = <String>{};
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
          languages.addAll(lo.languages);
        }

        final filtered = state.filteredLiaisonOfficers;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => context.read<NodalLoBloc>().add(
                                NodalLoSendPendingLoReminders(),
                              ),
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: const Text('Remind pending'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _upsertLo(context, state),
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Add LO'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppFilterChipsBar(
                    chips: {
                      if (state.filterOrgName != null)
                        'org': 'Org: ${state.filterOrgName}',
                      if (state.filterOrgTypeName != null)
                        'orgType': 'Type: ${state.filterOrgTypeName}',
                      if (state.filterProfileStatus != null)
                        'status': 'Status: ${state.filterProfileStatus}',
                      if (state.filterLanguage != null)
                        'language': 'Lang: ${state.filterLanguage}',
                      if (state.filterAvailability != null)
                        'availability': 'Avail: ${state.filterAvailability}',
                    },
                    onOpenFilters: () async {
                      final result = await showAppFiltersSheet(
                        context: context,
                        filters: [
                          AppFilterOption(
                            key: 'org',
                            label: 'Org',
                            allLabel: 'All orgs',
                            options: orgNames.toList()..sort(),
                            value: state.filterOrgName,
                          ),
                          AppFilterOption(
                            key: 'orgType',
                            label: 'Org type',
                            allLabel: 'All types',
                            options: orgTypes.toList()..sort(),
                            value: state.filterOrgTypeName,
                          ),
                          AppFilterOption(
                            key: 'status',
                            label: 'Status',
                            allLabel: 'All statuses',
                            options: statuses.toList()..sort(),
                            value: state.filterProfileStatus,
                          ),
                          AppFilterOption(
                            key: 'language',
                            label: 'Language',
                            allLabel: 'Any language',
                            options: languages.toList()..sort(),
                            value: state.filterLanguage,
                          ),
                          AppFilterOption(
                            key: 'availability',
                            label: 'Availability',
                            allLabel: 'Any',
                            options: const [
                              'AVAILABLE',
                              'LIMITED',
                              'UNAVAILABLE',
                            ],
                            value: state.filterAvailability,
                          ),
                        ],
                      );
                      if (result == null || !context.mounted) return;
                      context.read<NodalLoBloc>().add(
                            NodalLoSetLoFilters(
                              orgName: result['org'],
                              clearOrgName: result['org'] == null,
                              orgTypeName: result['orgType'],
                              clearOrgTypeName: result['orgType'] == null,
                              profileStatus: result['status'],
                              clearProfileStatus: result['status'] == null,
                              language: result['language'],
                              clearLanguage: result['language'] == null,
                              availability: result['availability'],
                              clearAvailability:
                                  result['availability'] == null,
                            ),
                          );
                    },
                    onClearKey: (key) {
                      context.read<NodalLoBloc>().add(
                            NodalLoSetLoFilters(
                              clearOrgName: key == 'org',
                              clearOrgTypeName: key == 'orgType',
                              clearProfileStatus: key == 'status',
                              clearLanguage: key == 'language',
                              clearAvailability: key == 'availability',
                            ),
                          );
                    },
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
                        final inactive = lo.isActive == false;
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
                                  const SizedBox(width: 6),
                                  StatusChip(
                                    label: inactive ? 'Inactive' : 'Active',
                                  ),
                                  if (lo.id != null)
                                    PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        final bloc =
                                            context.read<NodalLoBloc>();
                                        switch (v) {
                                          case 'edit':
                                            await _upsertLo(
                                              context,
                                              state,
                                              existing: lo,
                                            );
                                          case 'remind':
                                            bloc.add(
                                              NodalLoSendLoReminder(lo.id!),
                                            );
                                          case 'activate':
                                            bloc.add(
                                              NodalLoSetLiaisonActive(
                                                lo.id!,
                                                true,
                                              ),
                                            );
                                          case 'deactivate':
                                            bloc.add(
                                              NodalLoSetLiaisonActive(
                                                lo.id!,
                                                false,
                                              ),
                                            );
                                          case 'delete':
                                            await _confirmDeleteLo(
                                              context,
                                              lo,
                                            );
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remind',
                                          child: Text('Send reminder'),
                                        ),
                                        if (inactive)
                                          const PopupMenuItem(
                                            value: 'activate',
                                            child: Text('Set active'),
                                          )
                                        else
                                          const PopupMenuItem(
                                            value: 'deactivate',
                                            child: Text('Set inactive'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              if (lo.designation != null &&
                                  lo.designation!.trim().isNotEmpty)
                                Text(
                                  lo.designation!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              Text(
                                '${lo.orgName ?? ''} · ${lo.orgTypeName ?? ''}',
                              ),
                              Text(lo.officialEmail ?? ''),
                              if ((lo.officialContact ?? '').isNotEmpty)
                                Text('Mobile: ${lo.officialContact}'),
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
                child: AppLoading(label: 'Loading LOâ€¦'),
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
                    Text('Organisation: ${lo.orgName ?? 'â€”'}'),
                    Text('Org type: ${lo.orgTypeName ?? 'â€”'}'),
                    Text('Status: ${lo.profileStatus ?? 'â€”'}'),
                    Text('Gender: ${lo.genderName ?? 'â€”'}'),
                    Text('DOB: ${lo.dateOfBirth ?? 'â€”'}'),
                    Text('Rank: ${lo.rank ?? 'â€”'}'),
                    Text('Designation: ${lo.designation ?? 'â€”'}'),
                    Text('Official email: ${lo.officialEmail ?? 'â€”'}'),
                    Text('Personal email: ${lo.personalEmail ?? 'â€”'}'),
                    Text('Official contact: ${lo.officialContact ?? 'â€”'}'),
                    Text('Personal contact: ${lo.personalContact ?? 'â€”'}'),
                    Text('WhatsApp: ${lo.whatsappNumber ?? 'â€”'}'),
                    Text('Availability: ${lo.availabilityStatus ?? 'â€”'}'),
                    Text(
                      'Active: ${lo.isActive == false ? 'No' : 'Yes'}',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(label: lo.profileStatus ?? 'â€”'),
                        if (lo.isActive == false)
                          const StatusChip(label: 'Inactive'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: lo.id == null
                              ? null
                              : () => context.read<NodalLoBloc>().add(
                                    NodalLoSendLoReminder(lo.id!),
                                  ),
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                          label: const Text('Remind'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: lo.id == null
                              ? null
                              : () => context.read<NodalLoBloc>().add(
                                    NodalLoSetLiaisonActive(
                                      lo.id!,
                                      lo.isActive == false,
                                    ),
                                  ),
                          icon: Icon(
                            lo.isActive == false
                                ? Icons.check_circle_outline
                                : Icons.block_outlined,
                          ),
                          label: Text(
                            lo.isActive == false
                                ? 'Set active'
                                : 'Set inactive',
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _upsertLo(context, state, existing: lo);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Documents',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (lo.documentFileIds.isEmpty)
                      const Text('No documents uploaded.')
                    else
                      _LoDocumentPreviewRow(lo: lo),
                    const SizedBox(height: 16),
                    const Text(
                      'Languages',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (state.detailLanguages.isEmpty && lo.languages.isEmpty)
                      const Text('â€”')
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
                            '${e.year ?? ''} Â· ${e.roleResponsibilities ?? ''}',
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

  Future<void> _confirmDeleteLo(
    BuildContext context,
    LiaisonOfficerDto lo,
  ) async {
    if (lo.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Liaison Officer?'),
        content: Text('Remove ${lo.displayName}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<NodalLoBloc>().add(NodalLoDeleteLiaisonOfficer(lo.id!));
    }
  }

  Future<void> _upsertLo(
    BuildContext context,
    NodalLoState state, {
    LiaisonOfficerDto? existing,
  }) async {
    final orgs = state.organisations.where((e) => e.id != null).toList();
    if (orgs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an organisation first.')),
      );
      return;
    }
    const salutations = ['Mr', 'Ms', 'Mrs', 'Dr', 'Prof'];
    var salutation = existing?.salutationName ?? 'Mr';
    if (!salutations.contains(salutation)) salutation = 'Mr';
    String? orgId = existing?.orgId ?? orgs.first.id;
    final first = TextEditingController(text: existing?.firstName ?? '');
    final last = TextEditingController(text: existing?.lastName ?? '');
    final email =
        TextEditingController(text: existing?.officialEmail ?? '');
    final mobile =
        TextEditingController(text: existing?.officialContact ?? '');
    final rank = TextEditingController(text: existing?.rank ?? '');
    final designation =
        TextEditingController(text: existing?.designation ?? '');

    final ok = await showAppFormSheet(
      context: context,
      title: existing == null ? 'Add Liaison Officer' : 'Edit Liaison Officer',
      builder: (ctx, setLocal) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: orgId,
            decoration: const InputDecoration(labelText: 'Organisation'),
            items: orgs
                .map(
                  (o) => DropdownMenuItem(
                    value: o.id,
                    child: Text(o.orgName),
                  ),
                )
                .toList(),
            onChanged: (v) => setLocal(() => orgId = v),
          ),
          DropdownButtonFormField<String>(
            initialValue: salutation,
            decoration: const InputDecoration(labelText: 'Salutation'),
            items: salutations
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setLocal(() => salutation = v ?? 'Mr'),
          ),
          TextFormField(
            controller: first,
            decoration: const InputDecoration(labelText: 'First name'),
          ),
          TextFormField(
            controller: last,
            decoration: const InputDecoration(labelText: 'Last name'),
          ),
          TextFormField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Primary email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextFormField(
            controller: mobile,
            decoration: const InputDecoration(labelText: 'Primary mobile'),
            keyboardType: TextInputType.phone,
          ),
          TextFormField(
            controller: rank,
            decoration: const InputDecoration(labelText: 'Rank'),
          ),
          TextFormField(
            controller: designation,
            decoration: const InputDecoration(labelText: 'Designation'),
          ),
        ],
      ),
      onConfirmValidate: () =>
          first.text.trim().isNotEmpty &&
          email.text.trim().isNotEmpty &&
          mobile.text.trim().isNotEmpty &&
          orgId != null,
    );
    if (ok != true || !context.mounted) return;
    final body = <String, dynamic>{
      'orgId': orgId,
      'salutation': salutation,
      'firstName': first.text.trim(),
      'lastName': last.text.trim(),
      'primaryEmail': email.text.trim(),
      'primaryMobile': mobile.text.trim(),
      if (rank.text.trim().isNotEmpty) 'rank': rank.text.trim(),
      if (designation.text.trim().isNotEmpty)
        'designation': designation.text.trim(),
    };
    final bloc = context.read<NodalLoBloc>();
    if (existing?.id == null) {
      bloc.add(NodalLoCreateLiaisonOfficer(body));
    } else {
      bloc.add(NodalLoUpdateLiaisonOfficer(existing!.id!, body));
    }
  }
}

class _LoDocumentPreviewRow extends StatelessWidget {
  const _LoDocumentPreviewRow({required this.lo});
  final LiaisonOfficerDto lo;

  @override
  Widget build(BuildContext context) {
    final docs = lo.documentFileIds.entries.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: docs
          .map(
            (e) => ActionChip(
              avatar: const Icon(Icons.attach_file, size: 16),
              label: Text(e.key),
              onPressed: () => _open(context, e.key, e.value),
            ),
          )
          .toList(),
    );
  }

  Future<void> _open(
    BuildContext context,
    String label,
    String fileId,
  ) async {
    final repo = context.read<NodalLoBloc>().repository;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final bytes = await repo.fetchFileBytes(fileId);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empty file.')),
        );
        return;
      }
      final isImage = bytes.length >= 4 &&
          ((bytes[0] == 0xFF && bytes[1] == 0xD8) ||
              (bytes[0] == 0x89 && bytes[1] == 0x50));
      if (isImage) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                    maxWidth: MediaQuery.sizeOf(context).width * 0.9,
                  ),
                  child: InteractiveViewer(
                    child: Image.memory(
                      Uint8List.fromList(bytes),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final safe = label.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final file = File('${dir.path}/$safe-$fileId.bin');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: label);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $label: $e')),
        );
      }
    }
  }
}

// â”€â”€ Badges â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                              : () => _assignBadgesWithCategory(
                                    context,
                                    state,
                                  ),
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
                          child: GestureDetector(
                            onLongPress: () =>
                                context.read<NodalLoBloc>().add(
                                      NodalLoToggleLoSelection(lo.id!),
                                    ),
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: selected,
                              onChanged: (_) =>
                                  context.read<NodalLoBloc>().add(
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

  Future<void> _assignBadgesWithCategory(
    BuildContext context,
    NodalLoState state,
  ) async {
    final personIds = <String>[];
    for (final lo in state.liaisonOfficers) {
      if (lo.id != null && state.selectedLoIds.contains(lo.id)) {
        personIds.add(lo.personId ?? lo.id!);
      }
    }
    final lines = <Map<String, dynamic>>[];
    final raw = state.badgeQuota?['badgeLines'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) lines.add(Map<String, dynamic>.from(e));
      }
    }
    String? badgeCatId = lines.isEmpty
        ? null
        : (lines.first['badgeCatId'] ?? lines.first['id'])?.toString();

    if (lines.isNotEmpty) {
      final ok = await showAppFormSheet(
        context: context,
        title: 'Assign badge',
        confirmLabel: 'Assign',
        builder: (ctx, setLocal) => DropdownButtonFormField<String>(
          initialValue: badgeCatId,
          decoration: const InputDecoration(labelText: 'Badge category'),
          items: lines
              .map(
                (l) => DropdownMenuItem(
                  value: (l['badgeCatId'] ?? l['id'])?.toString(),
                  child: Text(
                    l['name']?.toString() ??
                        l['badgeCatName']?.toString() ??
                        'Category',
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setLocal(() => badgeCatId = v),
        ),
      );
      if (ok != true || !context.mounted) return;
    }

    context.read<NodalLoBloc>().add(
          NodalLoAssignBadge(
            personIds: personIds,
            badgeCatId: badgeCatId,
          ),
        );
  }
}

// ── Assign (delegate-first, matches CAP web) ────────────────────────────────

class _AssignTab extends StatefulWidget {
  const _AssignTab();

  @override
  State<_AssignTab> createState() => _AssignTabState();
}

class _AssignTabState extends State<_AssignTab> {
  String? _type;
  String? _country;
  String? _assignedLoId;
  String? _arrivalDate;
  String? _departureDate;
  String? _experience; // 'Prior' | 'None'
  String? _language;
  String? _event;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodalLoBloc, NodalLoState>(
      builder: (context, state) {
        final delegates = _filtered(state);
        final withLo = delegates.where((d) {
          final personId = d['personId']?.toString();
          return state.assignments.any((a) => a.personId == personId);
        }).length;
        final unassigned = delegates.length - withLo;
        final countries = <String>{};
        for (final d in state.assignableDelegates) {
          final c = d['countryName']?.toString() ??
              d['delegateCountry']?.toString();
          if (c != null && c.isNotEmpty) countries.add(c);
        }
        final types = <String>{};
        for (final d in state.assignableDelegates) {
          final t = d['attendeeType']?.toString() ??
              d['delegateType']?.toString();
          if (t != null && t.isNotEmpty) types.add(t);
        }
        final arrivalDates = <String>{};
        final departureDates = <String>{};
        final events = <String>{};
        for (final d in state.assignableDelegates) {
          final ad = d['arrivalDate']?.toString();
          if (ad != null && ad.isNotEmpty) {
            arrivalDates.add(ad.length >= 10 ? ad.substring(0, 10) : ad);
          }
          final dd = d['departureDate']?.toString();
          if (dd != null && dd.isNotEmpty) {
            departureDates.add(dd.length >= 10 ? dd.substring(0, 10) : dd);
          }
          final ev = _delegateEventLabel(d);
          if (ev != null && ev.isNotEmpty) events.add(ev);
        }
        final languages = <String>{};
        for (final lo in state.liaisonOfficers) {
          languages.addAll(lo.languages);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _OrgHubKpi(
                          label: 'On screen',
                          value: '${delegates.length}',
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _OrgHubKpi(
                          label: 'With LO',
                          value: '$withLo',
                          color: AppTheme.indiaGreen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _OrgHubKpi(
                          label: 'Unassigned',
                          value: '$unassigned',
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RSVP-accepted VIPs · many-to-many LO assignment.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(
                                    _arrivalDate ?? '',
                                  ) ??
                                  DateTime(2027, 2, 8),
                              firstDate: DateTime(2026, 1, 1),
                              lastDate: DateTime(2027, 12, 31),
                            );
                            if (picked == null || !mounted) return;
                            final y = picked.year.toString().padLeft(4, '0');
                            final m = picked.month.toString().padLeft(2, '0');
                            final d = picked.day.toString().padLeft(2, '0');
                            setState(() => _arrivalDate = '$y-$m-$d');
                          },
                          icon: const Icon(Icons.flight_land, size: 18),
                          label: Text(
                            _arrivalDate == null
                                ? 'Arrival date'
                                : 'Arr $_arrivalDate',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(
                                    _departureDate ?? '',
                                  ) ??
                                  DateTime(2027, 2, 17),
                              firstDate: DateTime(2026, 1, 1),
                              lastDate: DateTime(2027, 12, 31),
                            );
                            if (picked == null || !mounted) return;
                            final y = picked.year.toString().padLeft(4, '0');
                            final m = picked.month.toString().padLeft(2, '0');
                            final d = picked.day.toString().padLeft(2, '0');
                            setState(() => _departureDate = '$y-$m-$d');
                          },
                          icon: const Icon(Icons.flight_takeoff, size: 18),
                          label: Text(
                            _departureDate == null
                                ? 'Departure date'
                                : 'Dep $_departureDate',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppFilterChipsBar(
                    chips: {
                      if (_type != null) 'type': 'Type: $_type',
                      if (_country != null) 'country': 'Country: $_country',
                      if (_assignedLoId != null) 'lo': 'Assigned LO',
                      if (_arrivalDate != null)
                        'arrival': 'Arrival: $_arrivalDate',
                      if (_departureDate != null)
                        'departure': 'Departure: $_departureDate',
                      if (_experience != null) 'exp': 'Exp: $_experience',
                      if (_language != null) 'lang': 'Lang: $_language',
                      if (_event != null) 'event': 'Event: $_event',
                      if (_query.trim().isNotEmpty) 'q': 'Search: $_query',
                    },
                    onOpenFilters: () async {
                      final result = await showAppFiltersSheet(
                        context: context,
                        filters: [
                          AppFilterOption(
                            key: 'type',
                            label: 'Type',
                            allLabel: 'All types',
                            options: types.toList()..sort(),
                            value: _type,
                          ),
                          AppFilterOption(
                            key: 'country',
                            label: 'Country',
                            allLabel: 'All countries',
                            options: countries.toList()..sort(),
                            value: _country,
                          ),
                          AppFilterOption(
                            key: 'lo',
                            label: 'Assigned LO',
                            allLabel: 'All LOs',
                            options: state.liaisonOfficers
                                .where((e) => e.id != null)
                                .map((e) => e.displayName)
                                .toList(),
                            value: _assignedLoId == null
                                ? null
                                : state.liaisonOfficers
                                    .where((e) => e.id == _assignedLoId)
                                    .map((e) => e.displayName)
                                    .cast<String?>()
                                    .firstWhere(
                                      (e) => true,
                                      orElse: () => null,
                                    ),
                          ),
                          AppFilterOption(
                            key: 'arrival',
                            label: 'Arrival date',
                            allLabel: 'Any arrival',
                            options: arrivalDates.toList()..sort(),
                            value: _arrivalDate,
                          ),
                          if (departureDates.isNotEmpty)
                            AppFilterOption(
                              key: 'departure',
                              label: 'Departure date',
                              allLabel: 'Any departure',
                              options: departureDates.toList()..sort(),
                              value: _departureDate,
                            ),
                          AppFilterOption(
                            key: 'exp',
                            label: 'LO experience',
                            allLabel: 'Any experience',
                            options: const ['Prior', 'None'],
                            value: _experience,
                          ),
                          AppFilterOption(
                            key: 'lang',
                            label: 'LO language',
                            allLabel: 'Any language',
                            options: languages.toList()..sort(),
                            value: _language,
                          ),
                          if (events.isNotEmpty)
                            AppFilterOption(
                              key: 'event',
                              label: 'Event nomination',
                              allLabel: 'All events',
                              options: events.toList()..sort(),
                              value: _event,
                            ),
                        ],
                      );
                      if (result == null || !mounted) return;
                      setState(() {
                        _type = result['type'];
                        _country = result['country'];
                        _arrivalDate = result['arrival'];
                        _departureDate = result['departure'];
                        _experience = result['exp'];
                        _language = result['lang'];
                        _event = result['event'];
                        final loName = result['lo'];
                        if (loName == null) {
                          _assignedLoId = null;
                        } else {
                          for (final lo in state.liaisonOfficers) {
                            if (lo.displayName == loName) {
                              _assignedLoId = lo.id;
                              break;
                            }
                          }
                        }
                      });
                    },
                    onClearKey: (key) => setState(() {
                      if (key == 'type') _type = null;
                      if (key == 'country') _country = null;
                      if (key == 'lo') _assignedLoId = null;
                      if (key == 'arrival') _arrivalDate = null;
                      if (key == 'departure') _departureDate = null;
                      if (key == 'exp') _experience = null;
                      if (key == 'lang') _language = null;
                      if (key == 'event') _event = null;
                      if (key == 'q') _query = '';
                    }),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Search delegates',
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: delegates.isEmpty
                  ? const AppEmptyState(
                      message:
                          'No delegates match filters. RSVP Attending VIPs appear here.',
                    )
                  : StaggeredList(
                      itemCount: delegates.length,
                      itemBuilder: (context, i) {
                        final d = delegates[i];
                        final personId = d['personId']?.toString();
                        final name =
                            d['fullName']?.toString() ?? 'Delegate';
                        final type = d['attendeeType']?.toString() ??
                            d['delegateType']?.toString() ??
                            '';
                        final country = d['countryName']?.toString() ??
                            d['delegateCountry']?.toString() ??
                            '';
                        final arrival = [
                          d['arrivalDate'],
                          d['arrivalTime'],
                        ].whereType<Object>().join(' ');
                        final departure = [
                          d['departureDate'],
                          d['departureTime'],
                        ].whereType<Object>().join(' ');
                        final family = d['familyCount'] ??
                            d['familyMembersCount'] ??
                            (d['familyMembers'] is List
                                ? (d['familyMembers'] as List).length
                                : null);
                        final losForDelegate = state.assignments
                            .where((a) => a.personId == personId)
                            .toList();
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (type.isNotEmpty)
                                    StatusChip(label: type),
                                ],
                              ),
                              Text(
                                [
                                  if (country.isNotEmpty) country,
                                  if (arrival.trim().isNotEmpty)
                                    'Arr $arrival',
                                  if (departure.trim().isNotEmpty)
                                    'Dep $departure',
                                  if (family != null) 'Family $family',
                                  'LOs ${losForDelegate.length}',
                                ].join(' · '),
                              ),
                              if (d['designation'] != null)
                                Text(d['designation'].toString()),
                              const SizedBox(height: 8),
                              if (losForDelegate.isNotEmpty)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: losForDelegate
                                      .map(
                                        (a) => InputChip(
                                          label: Text(a.loFullName ?? 'LO'),
                                          onDeleted: a.id == null
                                              ? null
                                              : () => context
                                                  .read<NodalLoBloc>()
                                                  .add(
                                                    NodalLoDeleteAssignment(
                                                      a.id!,
                                                    ),
                                                  ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.tonalIcon(
                                  onPressed: () => _assignLosToDelegate(
                                    context,
                                    state,
                                    d,
                                  ),
                                  icon: const Icon(Icons.person_add_alt_1),
                                  label: const Text('Assign LOs'),
                                ),
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

  String? _delegateEventLabel(Map<String, dynamic> d) {
    final direct = d['eventName']?.toString() ??
        d['nominationEvent']?.toString() ??
        d['event']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final noms = d['nominations'] ?? d['events'];
    if (noms is List && noms.isNotEmpty) {
      final first = noms.first;
      if (first is Map) {
        return first['eventName']?.toString() ??
            first['name']?.toString() ??
            first['label']?.toString();
      }
      return first.toString();
    }
    return null;
  }

  List<Map<String, dynamic>> _filtered(NodalLoState state) {
    return state.assignableDelegates.where((d) {
      final personId = d['personId']?.toString();
      final type = d['attendeeType']?.toString() ??
          d['delegateType']?.toString() ??
          '';
      final country = d['countryName']?.toString() ??
          d['delegateCountry']?.toString() ??
          '';
      final name = d['fullName']?.toString() ?? '';
      if (_type != null && type != _type) return false;
      if (_country != null && country != _country) return false;
      if (_assignedLoId != null) {
        final has = state.assignments.any(
          (a) => a.personId == personId && a.loId == _assignedLoId,
        );
        if (!has) return false;
      }
      if (_arrivalDate != null) {
        final ad = d['arrivalDate']?.toString() ?? '';
        final day = ad.length >= 10 ? ad.substring(0, 10) : ad;
        if (!day.startsWith(_arrivalDate!) && day != _arrivalDate) {
          return false;
        }
      }
      if (_departureDate != null) {
        final dd = d['departureDate']?.toString() ?? '';
        final day = dd.length >= 10 ? dd.substring(0, 10) : dd;
        if (!day.startsWith(_departureDate!) && day != _departureDate) {
          return false;
        }
      }
      if (_event != null) {
        final ev = _delegateEventLabel(d);
        if (ev != _event) return false;
      }
      if (_experience != null || _language != null) {
        final assignedLos = state.assignments
            .where((a) => a.personId == personId)
            .map((a) => a.loId)
            .whereType<String>()
            .toSet();
        if (assignedLos.isEmpty) return false;
        final los = state.liaisonOfficers
            .where((lo) => lo.id != null && assignedLos.contains(lo.id))
            .toList();
        if (_experience == 'Prior' &&
            !los.any((lo) => lo.hasPrevLoExp == true)) {
          return false;
        }
        if (_experience == 'None' &&
            !los.any((lo) => lo.hasPrevLoExp != true)) {
          return false;
        }
        if (_language != null &&
            !los.any(
              (lo) => lo.languages.any(
                (l) => l.toLowerCase() == _language!.toLowerCase(),
              ),
            )) {
          return false;
        }
      }
      final q = _query.trim().toLowerCase();
      if (q.isNotEmpty && !name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  Future<void> _assignLosToDelegate(
    BuildContext context,
    NodalLoState state,
    Map<String, dynamic> delegate,
  ) async {
    final losWithId =
        state.liaisonOfficers.where((e) => e.id != null).toList();
    if (losWithId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No LOs available to assign.')),
      );
      return;
    }
    final personId = delegate['personId']?.toString();
    final already = {
      for (final a in state.assignments)
        if (a.personId == personId && a.loId != null) a.loId!,
    };
    final selected = Set<String>.from(already);
    String? filterOrg;
    String? filterExp;
    String? filterLang;
    String search = '';

    int workload(String loId) =>
        state.assignments.where((a) => a.loId == loId).length;

    final ok = await showAppFormSheet(
      context: context,
      title: 'Assign Liaison Officer(s)',
      confirmLabelBuilder: () => 'Assign ${selected.length} LO(s)',
      onConfirmValidate: () => selected.isNotEmpty,
      builder: (ctx, setLocal) {
        final orgs = losWithId
            .map((e) => e.orgName)
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        final langs = <String>{};
        for (final lo in losWithId) {
          langs.addAll(lo.languages);
        }
        final visible = losWithId.where((lo) {
          if (filterOrg != null && lo.orgName != filterOrg) return false;
          if (filterExp == 'Prior' && lo.hasPrevLoExp != true) return false;
          if (filterExp == 'None' && lo.hasPrevLoExp == true) return false;
          if (filterLang != null &&
              !lo.languages.any(
                (l) => l.toLowerCase() == filterLang!.toLowerCase(),
              )) {
            return false;
          }
          final q = search.trim().toLowerCase();
          if (q.isNotEmpty && !lo.displayName.toLowerCase().contains(q)) {
            return false;
          }
          return true;
        }).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(delegate['fullName']?.toString() ?? 'Delegate'),
            Text(
              '${already.length} LO(s) already assigned · '
              '${selected.length} selected',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search LOs',
                isDense: true,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setLocal(() => search = v),
            ),
            DropdownButtonFormField<String?>(
              value: filterOrg,
              decoration: const InputDecoration(
                labelText: 'Organisation',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any org')),
                ...orgs.map(
                  (o) => DropdownMenuItem(value: o, child: Text(o)),
                ),
              ],
              onChanged: (v) => setLocal(() => filterOrg = v),
            ),
            DropdownButtonFormField<String?>(
              value: filterExp,
              decoration: const InputDecoration(
                labelText: 'Experience',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Any')),
                DropdownMenuItem(value: 'Prior', child: Text('Prior')),
                DropdownMenuItem(value: 'None', child: Text('None')),
              ],
              onChanged: (v) => setLocal(() => filterExp = v),
            ),
            DropdownButtonFormField<String?>(
              value: filterLang,
              decoration: const InputDecoration(
                labelText: 'Language',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any')),
                ...langs.map(
                  (l) => DropdownMenuItem(value: l, child: Text(l)),
                ),
              ],
              onChanged: (v) => setLocal(() => filterLang = v),
            ),
            const SizedBox(height: 8),
            ...visible.map(
              (lo) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: selected.contains(lo.id),
                title: Text(lo.displayName),
                subtitle: Text(
                  '${lo.orgName ?? '—'} · '
                  '${lo.hasPrevLoExp == true ? 'Prior exp' : 'No prior'} · '
                  'Workload ${workload(lo.id!)} VIP(s)',
                ),
                onChanged: (v) => setLocal(() {
                  if (v == true) {
                    selected.add(lo.id!);
                  } else {
                    selected.remove(lo.id);
                  }
                }),
              ),
            ),
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No LOs match picker filters.'),
              ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;

    final bloc = context.read<NodalLoBloc>();
    for (final a in state.assignments) {
      if (a.personId == personId &&
          a.id != null &&
          a.loId != null &&
          !selected.contains(a.loId!)) {
        bloc.add(NodalLoDeleteAssignment(a.id!));
      }
    }
    for (final loId in selected) {
      if (already.contains(loId)) continue;
      bloc.add(
        NodalLoCreateAssignment({
          'loId': loId,
          'personId': delegate['personId'],
          'attendeeId': delegate['attendeeId'],
          'delegateType':
              delegate['attendeeType'] ?? delegate['delegateType'],
          'delegateName': delegate['fullName'],
        }),
      );
    }
  }
}


// â”€â”€ Tasks â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
              child: Row(
                children: [
                  Expanded(
                    child: _LoStatMini(
                      label: 'Tasks',
                      value: '${state.tasks.length}',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _LoStatMini(
                      label: 'Pending',
                      value: '${state.pendingTasksCount}',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _LoStatMini(
                      label: 'In Progress',
                      value: '${state.inProgressTasksCount}',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _LoStatMini(
                      label: 'Completed',
                      value: '${state.completedTasks}',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey<String?>('task-lo-${state.filterTaskLoId}'),
                      initialValue: state.filterTaskLoId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'LO',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All LOs', overflow: TextOverflow.ellipsis),
                        ),
                        ...state.liaisonOfficers
                            .where((e) => e.id != null)
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(
                                  e.displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                      ],
                      selectedItemBuilder: (context) {
                        final los = state.liaisonOfficers
                            .where((e) => e.id != null)
                            .toList();
                        return [
                          const Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              'All LOs',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          ...los.map(
                            (e) => Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                e.displayName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ];
                      },
                      onChanged: (v) => context.read<NodalLoBloc>().add(
                            NodalLoSetTaskFilters(
                              loId: v,
                              clearLoId: v == null,
                            ),
                          ),
                    ),
                  ),
                  _FilterDropdown(
                    width: 150,
                    label: 'Delegate',
                    value: state.filterTaskDelegate,
                    allLabel: 'All',
                    options: delegates.toList()..sort(),
                    onChanged: (v) => context.read<NodalLoBloc>().add(
                          NodalLoSetTaskFilters(
                            delegateName: v,
                            clearDelegateName: v == null,
                          ),
                        ),
                  ),
                  _FilterDropdown(
                    width: 130,
                    label: 'Source',
                    value: state.filterTaskSource,
                    allLabel: 'All',
                    options: sources.toList()..sort(),
                    onChanged: (v) => context.read<NodalLoBloc>().add(
                          NodalLoSetTaskFilters(
                            taskSource: v,
                            clearTaskSource: v == null,
                          ),
                        ),
                  ),
                  _FilterDropdown(
                    width: 130,
                    label: 'Status',
                    value: state.filterTaskStatus,
                    allLabel: 'All',
                    options: statuses.toList()..sort(),
                    onChanged: (v) => context.read<NodalLoBloc>().add(
                          NodalLoSetTaskFilters(
                            status: v,
                            clearStatus: v == null,
                          ),
                        ),
                  ),
                  _FilterDropdown(
                    width: 130,
                    label: 'Date',
                    value: state.filterTaskDate,
                    allLabel: 'All',
                    options: dates.toList()..sort(),
                    onChanged: (v) => context.read<NodalLoBloc>().add(
                          NodalLoSetTaskFilters(
                            date: v,
                            clearDate: v == null,
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
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => _editTask(context, state, t),
                            title: Text(t.taskTitle ?? ''),
                            subtitle: Text(
                              '${t.loFullName ?? ''} → ${t.delegateName ?? ''}\n'
                              '${t.scheduledDate ?? ''} ${t.scheduledTime ?? ''} · ${t.locationVenue ?? ''}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StatusChip(
                                  label:
                                      t.statusName ?? t.statusCode ?? '—',
                                ),
                                if (t.id != null)
                                  IconButton(
                                    tooltip: 'Delete',
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete task?'),
                                          content: Text(
                                            t.taskTitle ?? 'This task',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok == true && context.mounted) {
                                        context.read<NodalLoBloc>().add(
                                              NodalLoDeleteTask(t.id!),
                                            );
                                      }
                                    },
                                    icon: const Icon(Icons.delete_outline),
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
    String? loId = existing?.loId;
    String? assignId = existing?.loAssignId;
    if (loId != null &&
        assignId != null &&
        !asgWithId.any((a) => a.id == assignId && a.loId == loId)) {
      assignId = null;
    }
    String source = existing?.taskSource ?? 'CUSTOM';
    String? activityId = existing?.activityId;

    final ok = await pushAppFormPage<bool>(
      context: context,
      title: existing == null ? 'Assign task' : 'Edit task',
      actions: [
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ),
      ],
      body: StatefulBuilder(
        builder: (ctx, setLocal) {
          final delegatesForLo = loId == null
              ? const <LoAssignmentDto>[]
              : asgWithId.where((a) => a.loId == loId).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
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
                onChanged: (v) => setLocal(() {
                  loId = v;
                  assignId = null;
                }),
                decoration: const InputDecoration(labelText: 'LO'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('assign-$loId-$assignId'),
                initialValue: assignId,
                items: delegatesForLo
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.delegateName ?? e.id!),
                      ),
                    )
                    .toList(),
                onChanged: loId == null
                    ? null
                    : (v) => setLocal(() => assignId = v),
                decoration: InputDecoration(
                  labelText: 'Assignment / delegate',
                  helperText:
                      loId == null ? 'Pick LO first' : null,
                ),
              ),
              const SizedBox(height: 12),
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
            if (source == 'ACTIVITY_MASTER') ...[
              const SizedBox(height: 12),
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
            ],
            const SizedBox(height: 12),
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
          );
        },
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