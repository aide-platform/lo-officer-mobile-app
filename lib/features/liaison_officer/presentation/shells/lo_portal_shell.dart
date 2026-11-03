import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/services/device_downloads.dart';
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

  @override
  void initState() {
    super.initState();
    LoFirebaseMonitor.instance.logTab(LoMonitoringEvents.tabDelegates);
    PushNotificationService.instance.bindDeepLink(_openPushLink);
    PushNotificationService.instance.onForegroundPush = _onForegroundPush;
  }

  void _onForegroundPush(String? link) {
    if (!mounted) return;
    if (link != null && link.toLowerCase().startsWith('broadcast:')) {
      context.read<LoPortalBloc>().add(LoPortalAlertsRefreshRequested());
    }
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
    if (PushNotificationService.instance.onForegroundPush == _onForegroundPush) {
      PushNotificationService.instance.onForegroundPush = null;
    }
    super.dispose();
  }

  void _openPushLink(String link) {
    if (!mounted) return;
    LoFirebaseMonitor.instance.logNotificationOpen(link);
    final lower = link.toLowerCase();
    if (lower.startsWith('broadcast:')) {
      _selectTab(3);
      context.read<LoPortalBloc>().add(LoPortalAlertsRefreshRequested());
    } else if (lower.contains('task')) {
      setState(() => _index = 1);
    } else if (lower.contains('delegate')) {
      setState(() => _index = 0);
    }
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoPortalBloc, LoPortalState>(
      listener: (context, state) async {
        final bloc = context.read<LoPortalBloc>();
        Object? shareError;
        String? savedName;
        String? savedHandle;
        if (state.lastDownloadBytes != null &&
            state.lastDownloadBytes!.isNotEmpty) {
          try {
            final bytes = state.lastDownloadBytes!;
            final name = _safeDownloadFilename(state.lastDownloadFilename);
            if (state.lastDownloadSaveToDevice) {
              savedHandle = await DeviceDownloads.save(
                bytes: bytes,
                filename: name,
              );
              savedName = name;
            } else {
              final dir = await getTemporaryDirectory();
              final file = File('${dir.path}/$name');
              await file.writeAsBytes(bytes);
              await Share.shareXFiles([XFile(file.path)], text: name);
            }
          } on PlatformException catch (e) {
            shareError = e.message ?? e.code;
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
        } else if (savedName != null && Platform.isAndroid) {
          final handle = savedHandle;
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Saved to Downloads: $savedName'),
              action: handle == null
                  ? null
                  : SnackBarAction(
                      label: 'Open',
                      onPressed: () async {
                        final opened = await DeviceDownloads.open(handle);
                        if (!opened) {
                          messenger.showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'No app found to open PDF. Find it in Downloads.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
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
      const LoNotificationsScreen(),
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
                  context.read<ThemeCubit>().toggle(
                    Theme.of(context).brightness,
                  );
                case 'logout':
                  confirmLogout(context).then((ok) {
                    if (ok && context.mounted) performLogout(context);
                  });
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('My Profile')),
              PopupMenuItem(value: 'help', child: Text('Help & Support')),
              // PopupMenuItem(value: 'theme', child: Text('Toggle theme')),
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
                          '(tasks or movements)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
            icon: const _NavMark(icon: Icons.groups_outlined),
            selectedIcon: const _NavMark(icon: Icons.groups, selected: true),
            label: 'Delegates',
          ),
          NavigationDestination(
            icon: const _NavMark(icon: Icons.task_alt_outlined),
            selectedIcon: const _NavMark(icon: Icons.task_alt, selected: true),
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
            icon: const _NavMark(icon: Icons.notifications_outlined),
            selectedIcon: const _NavMark(
              icon: Icons.notifications,
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
  const _NavMark({required this.icon, this.selected = false});

  final IconData icon;
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
    final child = Icon(
      widget.icon,
      color: widget.selected
          ? Theme.of(context).colorScheme.primary
          : context.semantic.textSecondary,
    );
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
