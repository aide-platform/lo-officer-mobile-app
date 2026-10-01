import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';
import 'package:liaison_officer/core/services/lo_monitoring_events.dart';
import 'package:liaison_officer/core/services/push_notification_service.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/core/widgets/role_shell_drawer.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/help_support_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_delegates_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_helplines_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _refreshUnread();
    LoFirebaseMonitor.instance.logTab(LoMonitoringEvents.tabDelegates);
    PushNotificationService.instance.bindDeepLink(_openPushLink);
  }

  void _selectTab(int index) {
    setState(() => _index = index);
    if (index == 0) {
      LoFirebaseMonitor.instance.logTab(LoMonitoringEvents.tabDelegates);
    } else if (index == 1) {
      LoFirebaseMonitor.instance.logTab(LoMonitoringEvents.tabTasks);
    } else if (index == 2) {
      LoFirebaseMonitor.instance.logTab(LoMonitoringEvents.tabHelplines);
    } else if (index == 3) {
      LoFirebaseMonitor.instance.logTab(LoMonitoringEvents.tabAlerts);
    }
  }

  @override
  void dispose() {
    PushNotificationService.instance.bindDeepLink(null);
    super.dispose();
  }

  void _openPushLink(String link) {
    if (!mounted) return;
    LoFirebaseMonitor.instance.logNotificationOpen(link);
    final lower = link.toLowerCase();
    if (lower.contains('task')) {
      setState(() => _index = 1);
    } else if (lower.contains('delegate')) {
      setState(() => _index = 0);
    }
  }

  Future<void> _refreshUnread() async {
    try {
      final n = await AppDependencies.instance.notificationsRepository
          .unreadCount();
      if (mounted) setState(() => _unread = n);
    } catch (_) {}
  }

  void _openProfile(BuildContext context, {required bool forceWizard}) {
    LoFirebaseMonitor.instance.logTab(LoMonitoringEvents.tabProfile);
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
                LoFirebaseMonitor.instance.logNotificationOpen(link);
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
    return BlocConsumer<LoPortalBloc, LoPortalState>(
      listener: (context, state) async {
        final bloc = context.read<LoPortalBloc>();
        Object? shareError;
        if (state.lastDownloadBytes != null &&
            state.lastDownloadBytes!.isNotEmpty) {
          try {
            final bytes = state.lastDownloadBytes!;
            final name = _safeDownloadFilename(state.lastDownloadFilename);
            final dir = await getTemporaryDirectory();
            final file = File('${dir.path}/$name');
            await file.writeAsBytes(bytes);
            await Share.shareXFiles([XFile(file.path)], text: name);
          } catch (e) {
            shareError = e;
          }
        }
        if (state.infoMessage != null || state.lastDownloadBytes != null) {
          bloc.add(LoPortalClearMessages());
        }
        if (!context.mounted) return;
        if (shareError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(apiErrorMessage(shareError)),
            ),
          );
        } else if (state.infoMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(state.infoMessage!),
            ),
          );
        }
        if (state.errorMessage != null &&
            state.status == LoPortalStatus.failure &&
            state.profile?.profileComplete == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(state.errorMessage!),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == LoPortalStatus.loading ||
            state.status == LoPortalStatus.initial) {
          return const Scaffold(body: AppLoading(label: 'Loading portal…'));
        }
        if (state.status == LoPortalStatus.failure &&
            state.delegates.isEmpty &&
            state.profile == null) {
          return Scaffold(
            body: AppErrorView(
              message: state.errorMessage ?? 'Failed to load',
              onRetry: () =>
                  context.read<LoPortalBloc>().add(LoPortalLoadRequested()),
            ),
          );
        }

        // Web parity: finish My Profile before Delegates / Tasks / Helplines / Alerts.
        if (state.profile?.profileComplete != true) {
          return LoProfileScreen(email: widget.email, readOnly: false);
        }

        return _buildMainShell(context, state);
      },
    );
  }

  Widget _buildMainShell(BuildContext context, LoPortalState state) {
    final titles = ['Delegates', 'Tasks', 'Help Line Numbers', 'Alerts'];
    final pages = [
      const LoDelegatesScreen(),
      const LoTasksScreen(),
      const LoHelplinesScreen(),
      LoNotificationsScreen(onOpenInbox: () => _openInbox(context)),
    ];
    final showCacheBanner =
        state.status == LoPortalStatus.ready &&
        state.errorMessage != null &&
        state.errorMessage!.toLowerCase().contains('cached');
    final pending = state.pendingSyncCount;

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
              asset: AppAssetManager.iconDelegate,
              selected: _index == 0,
              label: 'Delegates',
              onTap: () => _selectTab(0),
            ),
            RoleDrawerNavItem(
              icon: Icons.task_alt_outlined,
              asset: AppAssetManager.iconTask,
              selected: _index == 1,
              label: 'Tasks',
              onTap: () => _selectTab(1),
            ),
            RoleDrawerNavItem(
              icon: Icons.phone_in_talk_outlined,
              selected: _index == 2,
              label: 'Help Line Numbers',
              onTap: () => _selectTab(2),
            ),
            RoleDrawerNavItem(
              icon: Icons.notifications_outlined,
              asset: AppAssetManager.iconAlert,
              selected: _index == 3,
              label: 'Alerts',
              onTap: () => _selectTab(3),
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
                  openHelpSupport(context);
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
        body: Column(
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
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.read<LoPortalBloc>().add(
                          LoPortalLoadRequested(),
                        ),
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
                        color: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$pending pending sync '
                          '(tasks, movements, or issues)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.read<LoPortalBloc>().add(
                          LoPortalLoadRequested(),
                        ),
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
        ),
        destinations: [
          NavigationDestination(
            icon: const _NavMark(asset: AppAssetManager.iconDelegate),
            selectedIcon: const _NavMark(
              asset: AppAssetManager.iconDelegate,
              selected: true,
            ),
            label: 'Delegates',
          ),
          NavigationDestination(
            icon: const _NavMark(asset: AppAssetManager.iconTask),
            selectedIcon: const _NavMark(
              asset: AppAssetManager.iconTask,
              selected: true,
            ),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: const _NavMark(icon: Icons.phone_in_talk_outlined),
            selectedIcon: const _NavMark(
              icon: Icons.phone_in_talk,
              selected: true,
            ),
            label: 'Helplines',
          ),
          NavigationDestination(
            icon: const _NavMark(asset: AppAssetManager.iconAlert),
            selectedIcon: const _NavMark(
              asset: AppAssetManager.iconAlert,
              selected: true,
            ),
            label: 'Alerts',
          ),
        ],
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
      ),
    );
  }
}

class _NavMark extends StatefulWidget {
  const _NavMark({this.asset, this.icon, this.selected = false});

  final String? asset;
  final IconData? icon;
  final bool selected;

  @override
  State<_NavMark> createState() => _NavMarkState();
}

class _NavMarkState extends State<_NavMark> {
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    if (widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _scale = 1.15);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.asset != null
        ? SafeAssetImage(
            assetPath: widget.asset!,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          )
        : Icon(widget.icon);
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: child,
    );
  }
}

String _safeDownloadFilename(String? raw) {
  final cleaned = (raw ?? 'badge.pdf')
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-')
      .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
  if (cleaned.isEmpty) return 'badge.pdf';
  return cleaned.toLowerCase().endsWith('.pdf') ? cleaned : '$cleaned.pdf';
}
