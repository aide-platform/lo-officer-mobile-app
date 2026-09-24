import 'dart:io';

import 'package:flutter/material.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Help & Support — CAP LO Committee walkthrough (Quick Overview + §§1–18).
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _overview = <(String, String)>[
    (
      '1 · Access Setup',
      'Hospitality creates the LO Committee Nodal. Sub Nodals share the work via Email OTP (no passwords).',
    ),
    (
      '2 · Configure Masters',
      'Organisation Types from Manage Organisations; Activity Master from Task Management.',
    ),
    (
      '3 · Register Organisations',
      'Capture head, address, Org Rep contact — invitation email fires on save.',
    ),
    (
      '4 · Org Rep Nominates LOs',
      'Single nominate or Excel import; Remind Pending skips Completed profiles.',
    ),
    (
      '5 · LO Submits Profile',
      'Identity fields flip status to Completed; documents support but do not gate.',
    ),
    (
      '6 · Review Profiles',
      'Filter by org type / name / language / status; Assign Badge and Download Badges.',
    ),
    (
      '7 · Badge / Vehicle Quota',
      'Issued by Invitation Committee — LO Nodal view is read-only Total/Assigned/Available.',
    ),
    (
      '8 · Assign Badges',
      'Select LOs → Assign Badge category from available quota pool.',
    ),
    (
      '9 · Assign LOs to Delegates',
      'RSVP Attending only; many-to-many; filters include experience and language.',
    ),
    (
      '10 · Assign & Monitor Tasks',
      'Activity Master or custom; LO → Delegate cascade; Pending / In Progress / Completed.',
    ),
    (
      '11–14 · LO Portal',
      'Delegates, travel, task status updates, and notifications (email + in-app).',
    ),
    (
      '15–16 · Catering & E-Coupons',
      'Submit meal quotas; distribute on approved rows; review/download coupons separately.',
    ),
    (
      '17–18 · Sub Nodals & Dashboard',
      'Add helpers (two-level hierarchy). Dashboard is a live read-only snapshot with shortcuts.',
    ),
  ];

  static const _topics = <(String, String)>[
    (
      '1. Access Setup',
      'Purpose: Bring the LO Committee online. Fields: Name, Email, Mobile, Designation (required). '
          'NOTE: Email OTP only; Sub Nodals cannot create further Sub Nodals.',
    ),
    (
      '2. Configure Masters',
      'Organisation Types dialog on Organisations (no delete — dependents rely on master). '
          'Activity Master on Tasks (Add / Edit / soft Remove).',
    ),
    (
      '3. Register Organisations',
      'Type, Head, Address, Org Rep email & contact required. Invitation fires on save; email can be re-invited later.',
    ),
    (
      '4. Org Rep — Nominate LOs',
      'Add Nomination or Bulk Import Excel. Optional Org Rep Sub Nodals for nomination work.',
    ),
    (
      '5. LO — Complete Profile',
      'Personal, org, identity, contacts, signature, experience, availability, languages, documents. '
          'Completed when identity fields save.',
    ),
    (
      '6. Review LO Profiles',
      'Filters: Organisation Type, Name, Language (master list), Profile Status. '
          'Remind / Remove (soft-delete). Badges via selection Actions.',
    ),
    (
      '7. Badge & Vehicle Pass Quota',
      'Read-only KPIs and per-category / parking lines. Ask Invitation Committee for top-ups.',
    ),
    (
      '8. Assign Badges to LOs',
      'Select rows → Assign Badge (category with available quota) or Download Badges. '
          'QUOTA_EXHAUSTED rejects without partial assign.',
    ),
    (
      '9. Assign LOs to Delegates',
      'Attending RSVP only. Filters: Type, Country, Assigned LO, Arrival/Departure, Experience, Language, Event. '
          'Many-to-many; LO emailed on assign/unassign.',
    ),
    (
      '10. Assign and Monitor Tasks',
      'LO required → Delegate filtered to that LO. Title, description, date-time, venue, remarks, status. '
          'Update Status dialog; soft-delete supported.',
    ),
    (
      '11. LO — View Delegates',
      'Personal, designation, org/ministry, contacts, nominations, schedules, transport & accommodation.',
    ),
    (
      '12. LO — Travel Details',
      'Flight, terminal, arrival/departure, optional connecting flight (CAP may not persist connecting legs).',
    ),
    (
      '13. LO — Update Task Status',
      'Tasks grouped by delegate; status badge + Update Status (Pending / In Progress / Completed + remarks).',
    ),
    (
      '14. Notifications',
      'New tasks, updates/reassign, delegate/travel/event changes, upcoming scheduled tasks — portal + email.',
    ),
    (
      '15. Catering Requirements',
      'Dining Area, Date, Meal, Persons. Irreversible submit. Distribute on approved; Resubmit on rejected. '
          'Hidden from Sub Nodals.',
    ),
    (
      '16. E-Coupons',
      'Read-only committee coupons. QR view, per-coupon PDF, Download All. Distribution lives on Catering.',
    ),
    (
      '17. Manage Sub Nodal Officers',
      'Add / Edit / Remove (soft-delete). Same sidebar minus this page and Catering. Two-level hierarchy only.',
    ),
    (
      '18. Dashboard',
      'Live KPIs and charts (profile / assignment / task coverage, orgs by type, top orgs by VIP). '
          'Read-only — cards shortcut into underlying pages.',
    ),
  ];

  Future<void> _shareManual(BuildContext context) async {
    final buf = StringBuffer()
      ..writeln('LO Committee — Aero India 2027')
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
      'Made for LO Committee — Aero India 2027 · Content mirrors the live application.',
    );
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lo-committee-user-manual.md');
      await file.writeAsString(buf.toString());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'LO Committee user manual',
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
                  'End-to-end LO Committee flow. Each step links to detail below.',
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
              'NOTE: Sub Nodal Officers cannot create further Sub Nodals. '
              'Dashboard is read-only — every stat card is a shortcut into the underlying page.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
