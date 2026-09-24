import 'package:flutter/material.dart';
import 'package:liaison_officer/core/di/app_dependencies.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/domain/notifications_repository.dart';

/// Live / mock in-app notifications inbox (`/app/notifications/mine`).
class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key, this.onOpenDeepLink});

  /// Called with CAP `link` / `kind` so the parent shell can navigate.
  final void Function(String link)? onOpenDeepLink;

  @override
  State<NotificationsInboxScreen> createState() =>
      _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  late final NotificationsRepository _repo;
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = AppDependencies.instance.notificationsRepository;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.listMine();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Notifications',
      actions: [
        IconButton(
          tooltip: 'Mark all read',
          onPressed: () async {
            await _repo.markAllRead();
            await _load();
          },
          icon: const Icon(Icons.done_all, color: Colors.white),
        ),
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
      body: _loading
          ? const AppLoading(label: 'Loading notifications…')
          : _error != null
              ? AppErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const AppEmptyState(
                      message: 'No notifications yet.',
                      icon: Icons.notifications_off_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final n = _items[i];
                          final unread =
                              n['isRead'] != true && n['read'] != true;
                          return AppCard(
                            onTap: () async {
                              final id = n['id']?.toString();
                              if (id != null) await _repo.markRead(id);
                              final link = (n['link'] ??
                                      n['deepLink'] ??
                                      n['kind'] ??
                                      n['type'] ??
                                      '')
                                  .toString();
                              if (!context.mounted) return;
                              if (widget.onOpenDeepLink != null &&
                                  link.isNotEmpty) {
                                Navigator.pop(context);
                                widget.onOpenDeepLink!(link);
                              } else {
                                await _load();
                              }
                            },
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                unread
                                    ? Icons.notifications_active
                                    : Icons.notifications_none,
                              ),
                              title: Text(
                                n['title']?.toString() ?? 'Notification',
                                style: TextStyle(
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                n['message']?.toString() ??
                                    n['body']?.toString() ??
                                    '',
                              ),
                              trailing: Text(
                                _shortDate(n['createdAt']?.toString()),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _shortDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
