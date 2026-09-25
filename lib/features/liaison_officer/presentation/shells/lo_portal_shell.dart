import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/core/widgets/role_shell_drawer.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/help_support_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_delegates_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_notifications_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_profile_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_tasks_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/notifications_inbox_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class LoPortalShell extends StatefulWidget {
  const LoPortalShell({
    super.key,
    required this.email,
    required this.roleLabel,
  });

  final String email;
  final String roleLabel;

  @override
  State<LoPortalShell> createState() => _LoPortalShellState();
}

class _LoPortalShellState extends State<LoPortalShell> {
  int _index = 0;
  int _unread = 0;
  bool _wizardPrompted = false;

  @override
  void initState() {
    super.initState();
    _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    try {
      final n =
          await AppDependencies.instance.notificationsRepository.unreadCount();
      if (mounted) setState(() => _unread = n);
    } catch (_) {}
  }

  void _openProfile(BuildContext context, {required bool forceWizard}) {
    final bloc = context.read<LoPortalBloc>();
    final complete = bloc.state.profile?.profileComplete == true;
    Navigator.of(context).push(
      AppPageFadeRoute<void>(
        page: BlocProvider.value(
          value: bloc,
          child: LoProfileScreen(
            email: widget.email,
            readOnly: complete && !forceWizard,
          ),
        ),
      ),
    );
  }

  void _openInbox(BuildContext context) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsInboxScreen(
          onOpenDeepLink: (link) {
            if (link.toLowerCase().contains('task')) {
              setState(() => _index = 1);
            } else if (link.toLowerCase().contains('delegate')) {
              setState(() => _index = 0);
            }
          },
        ),
      ),
    )
        .then((_) => _refreshUnread());
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Delegates', 'Tasks', 'Alerts'];
    final pages = [
      const LoDelegatesScreen(),
      const LoTasksScreen(),
      LoNotificationsScreen(onOpenInbox: () => _openInbox(context)),
    ];

    return AnimatedTheme(
      data: Theme.of(context),
      duration: AppMotion.medium,
      child: AdaptiveRoleScaffold(
        title: titles[_index.clamp(0, titles.length - 1)],
        drawer: RoleShellDrawer(
          email: widget.email,
          roleLabel: widget.roleLabel,
          navItems: [
            RoleDrawerNavItem(
              icon: Icons.groups_outlined,
              label: 'Delegates',
              onTap: () => setState(() => _index = 0),
            ),
            RoleDrawerNavItem(
              icon: Icons.task_alt_outlined,
              label: 'Tasks',
              onTap: () => setState(() => _index = 1),
            ),
            RoleDrawerNavItem(
              icon: Icons.notifications_outlined,
              label: 'Alerts',
              onTap: () => setState(() => _index = 2),
            ),
            RoleDrawerNavItem(
              icon: Icons.person_outline,
              label: 'My Profile',
              onTap: () => _openProfile(context, forceWizard: false),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () => _openInbox(context),
              icon: Badge(
                isLabelVisible: _unread > 0,
                label: Text('$_unread'),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
            ),
            onSelected: (v) {
              switch (v) {
                case 'profile':
                  _openProfile(context, forceWizard: false);
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
              PopupMenuItem(value: 'profile', child: Text('My Profile')),
              PopupMenuItem(value: 'help', child: Text('Help & Support')),
              PopupMenuItem(value: 'theme', child: Text('Toggle theme')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
        body: BlocConsumer<LoPortalBloc, LoPortalState>(
          listener: (context, state) async {
            final bloc = context.read<LoPortalBloc>();
            if (!_wizardPrompted &&
                state.status == LoPortalStatus.ready &&
                state.profile?.profileComplete != true) {
              _wizardPrompted = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _openProfile(context, forceWizard: true);
              });
            }
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
                state.status == LoPortalStatus.failure &&
                state.delegates.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(state.errorMessage!),
                ),
              );
            }
            if (state.infoMessage != null ||
                state.lastDownloadBytes != null) {
              bloc.add(LoPortalClearMessages());
            }
          },
          builder: (context, state) {
            if (state.status == LoPortalStatus.loading ||
                state.status == LoPortalStatus.initial) {
              return const AppLoading(label: 'Loading portal…');
            }
            if (state.status == LoPortalStatus.failure &&
                state.delegates.isEmpty &&
                state.profile == null) {
              return AppErrorView(
                message: state.errorMessage ?? 'Failed to load',
                onRetry: () =>
                    context.read<LoPortalBloc>().add(LoPortalLoadRequested()),
              );
            }
            final showCacheBanner = state.status == LoPortalStatus.ready &&
                state.errorMessage != null &&
                state.errorMessage!.toLowerCase().contains('cached');
            final pending = state.pendingSyncCount;
            return Column(
              children: [
                if (showCacheBanner)
                  Material(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context
                                .read<LoPortalBloc>()
                                .add(LoPortalLoadRequested()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (pending > 0)
                  Material(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync_outlined,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$pending pending sync '
                              '(tasks, movements, or issues)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context
                                .read<LoPortalBloc>()
                                .add(LoPortalLoadRequested()),
                            child: const Text('Sync now'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: AppTabFade(index: _index, children: pages),
                ),
              ],
            );
          },
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Delegates',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
