import 'dart:io';

import 'package:flutter/material.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Help & Support — Liaison Officer mobile walkthrough.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _overview = <(String, String)>[
    (
      '1 · Secure login',
      'Sign in with your registered email. Complete CAPTCHA, then enter the OTP sent to you.',
    ),
    (
      '2 · Assigned delegates',
      'Delegates tab lists VIPs assigned to you. Pull to refresh.',
    ),
    (
      '3–5 · Profile, itinerary & transport',
      'Open a delegate for profile details, itinerary timeline, and assigned vehicle / driver info.',
    ),
    (
      '6 · Tasks',
      'Tasks tab shows organiser assignments. Update status: Pending → In Progress → Completed.',
    ),
    (
      '7 · Movement updates',
      'On delegate detail, log arrival, transfer, venue entry, or departure (travel editor).',
    ),
    (
      '8 · Issues & alerts',
      'Report issues from delegate detail or Alerts. Offline reports sync on next load; Share escalates. Local OS reminders cover task lead times.',
    ),
    (
      '9 · Profile, Help & Theme',
      'Avatar menu: My Profile wizard, Help & Support, light/dark theme, Logout.',
    ),
  ];

  static const _topics = <(String, String)>[
    (
      '1. Secure OTP login',
      'Email + CAPTCHA + OTP. Session stays valid until expiry or logout.',
    ),
    (
      '2. Assigned delegate list',
      'Delegates tab. Search/filter as available. Tap a row for full detail.',
    ),
    (
      '3. Delegate profile',
      'Name, designation, organisation, country, and other CAP assignment fields.',
    ),
    (
      '4. Delegate itinerary',
      'Composed timeline from travel fields, nominations, and vehicle pickup times.',
    ),
    (
      '5. Transport assignment',
      'Vehicle number, driver details, and pickup schedule on the transport card.',
    ),
    (
      '6. Task list & status',
      'Tasks grouped by delegate. Update status with optional remarks. Offline queue syncs when online.',
    ),
    (
      '7. Delegate movement',
      'Log arrival / transfer / venue entry / departure via travel and arrival-flight updates.',
    ),
    (
      '8. Issue reporting',
      'Report exceptions during coordination. Stored on device; Submitted if CAP accepts, otherwise Share to escalate.',
    ),
    (
      '9. Notifications',
      'Alerts tab for local notices. AppBar bell opens CAP inbox (schedule, tasks, B2B-related updates).',
    ),
    (
      '10. My Profile',
      'Complete identity and contact fields so organisers can reach you. Forced wizard if incomplete.',
    ),
  ];

  Future<void> _shareManual(BuildContext context) async {
    final buf = StringBuffer()
      ..writeln('Liaison Officer — Aero India')
      ..writeln('User Manual (mobile)')
      ..writeln('=' * 40)
      ..writeln()
      ..writeln('Quick Overview')
      ..writeln('-' * 14);
    for (final t in _overview) {
      buf
        ..writeln(t.$1)
        ..writeln(t.$2)
        ..writeln();
    }
    buf.writeln('Detailed Sections');
    buf.writeln('-' * 17);
    for (final t in _topics) {
      buf
        ..writeln(t.$1)
        ..writeln(t.$2)
        ..writeln();
    }
    buf.writeln(
      'Liaison Officer app — Aero India · Content mirrors the live LO portal.',
    );
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lo-officer-user-manual.md');
      await file.writeAsString(buf.toString());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Liaison Officer user manual',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('User manual ready to share.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Help & Support',
      actions: [
        IconButton(
          tooltip: 'Download user manual',
          onPressed: () => _shareManual(context),
          icon: const Icon(Icons.download_outlined, color: Colors.white),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Overview',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Liaison Officer features only. Accommodation is out of scope.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ..._overview.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.$1,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(t.$2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contents',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ..._topics.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '· ${t.$1}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._topics.map(
            (t) => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.$1,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(t.$2),
                ],
              ),
            ),
          ),
          AppCard(
            child: Text(
              'NOTE: This app is for Liaison Officers only. '
              'Use Delegates · Tasks · Alerts, plus Profile, Help, and Theme from the account menu.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
