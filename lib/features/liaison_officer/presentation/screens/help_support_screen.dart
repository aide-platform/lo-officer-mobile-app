import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Help & Support — portal-aligned LO walkthrough (mirrors CAP web guide).
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _manualAsset =
      'assets/docs/lo-help-and-support-manual.md';

  late final Map<String, GlobalKey> _sectionKeys = {
    for (final s in _sections) s.id: GlobalKey(),
  };

  static const _overview = <(String, String)>[
    (
      '1 · Nomination',
      'You are nominated as a Liaison Officer by your Organisation Representative and receive an email with the LO portal link.',
    ),
    (
      '2 · Sign in',
      'Sign in with Email OTP — no password is stored anywhere in the system. On mobile: email → CAPTCHA → OTP.',
    ),
    (
      '3 · Complete profile',
      'Open My Profile and complete the three-step wizard (Personal Details, Document Uploads, Prior LO Experience), then Submit.',
    ),
    (
      '4 · Assigned delegates',
      'Once the LO Committee assigns delegates to you, they appear under My Delegates (Delegates tab) with arrival, departure and event details.',
    ),
    (
      '5 · Record arrival',
      'When a delegate lands, record their actual arrival flight, terminal, date and time — the update is visible to the LO Committee.',
    ),
    (
      '6 · Track tasks',
      'Track work under My Tasks: each task is grouped by delegate and can be flipped between Pending, In Progress and Completed.',
    ),
    (
      '7 · Notifications',
      'Email and in-portal notifications keep you posted on new task assignments, delegate updates and schedule changes.',
    ),
  ];

  static const _workflow = <(String, String)>[
    ('1', 'Login — Email OTP'),
    ('2', 'Complete Profile — 3-step wizard'),
    ('3', 'See Delegates — assigned VIPs'),
    ('4', 'Update Travel — actual arrival'),
    ('5', 'Handle Tasks — Pending / In Progress / Done'),
    ('6', 'Get Notifications — bell + email'),
  ];

  static const _sections = <_HelpSection>[
    _HelpSection(
      id: 'login',
      title: '1. Access & Login',
      icon: Icons.lock_outline,
      purpose:
          'You are nominated as a Liaison Officer by your Organisation Representative. Once the nomination is saved, the system emails you the LO portal link. Sign in through Email OTP — no password is ever asked for or stored.',
      whereToFind:
          'Portal URL from the nomination email → Liaison Officer login.\nMobile: App launch → Login screen (email → CAPTCHA → OTP).',
      steps: [
        'Enter the email your Organisation Representative nominated you on. This email is your login identifier and cannot be changed from inside the portal.',
        'Verify the OTP sent to that email to complete sign-in. If your profile is incomplete, My Profile opens first (same as the web portal); after Submit you use Delegates, Tasks and Alerts.',
      ],
      note:
          'If you did not receive the portal link, check spam and then ask your Organisation Representative to re-send it. OTP is required on every sign-in. On mobile, CAPTCHA is required before requesting OTP.',
    ),
    _HelpSection(
      id: 'profile',
      title: '2. Complete & Submit Your Profile',
      icon: Icons.badge_outlined,
      purpose:
          'Your first job as an LO is to complete your own record. My Profile opens in a read-only view; use the header CTA to enter a three-step wizard covering Personal Details, Document Uploads and Prior LO Experience. Nothing is written to the backend until you press Submit on the final step.',
      whereToFind:
          'Liaison Officer login → My Profile → Complete Profile / Update Details.\nMobile: Avatar menu → My Profile.',
      fields: [
        ('First Name / Last Name', 'Required', 'Personal Details — your legal name.'),
        (
          'Mobile Number (from Nomination)',
          'Required',
          'Pre-filled from nomination; editable here.'
        ),
        (
          'Aadhaar Number',
          'Required',
          '12 digits (spaces allowed while typing).'
        ),
        ('Languages Known', 'Optional', 'Chip list — pick a language and Add.'),
        (
          'Photo & Specimen Signature',
          'Required',
          'Document Uploads — JPEG / JPG / PNG only.'
        ),
        (
          'Prior LO Experience rows',
          'Optional',
          'Event, Year, Role / Responsibilities, Delegates Handled.'
        ),
      ],
      actions: [
        (
          'Complete Profile / Update Details',
          'Header action on the view screen — opens the wizard.'
        ),
        (
          'Stepper',
          'Jump between Personal Details, Document Uploads and Prior LO Experience without losing entered data.'
        ),
        (
          'Back / Next',
          'Wizard navigation. Each step validates required fields before advancing.'
        ),
        (
          'Choose File / Replace / Clear',
          'Document Uploads controls. Clear is only for pending (unsaved) files.'
        ),
        (
          'Submit',
          'Only on the final step. Commits every change across all three steps — the only moment data reaches the server.'
        ),
      ],
      steps: [
        'Personal Details — Salutation, gender, name, DOB, rank / designation, organisation ID, Aadhaar, personal email / contact, WhatsApp and Languages Known.',
        'Document Uploads — Photo, Specimen Signature, Aadhaar (Front & Back) and Organisation Badge (Front & Back). All six are mandatory; JPEG / JPG / PNG only.',
        'Prior LO Experience — Answer Has LO Experience? If Yes, add rows, then Submit to persist the entire profile.',
      ],
      note:
          'Nothing writes between steps — closing before Submit loses the session. Nomination email is read-only. Document preview “Load failed” on the read-only view is a CAP preview issue, not a missing upload.',
    ),
    _HelpSection(
      id: 'delegates',
      title: '3. View Assigned Delegates and Event Details',
      icon: Icons.groups_outlined,
      purpose:
          'Once the LO Committee assigns delegates to you, they show up on My Delegates with category, arrival and departure information. Use action icons for events, vehicles and actual arrival / departure details.',
      whereToFind:
          'Liaison Officer login → My Delegates.\nMobile: Bottom nav → Delegates tab → tap a row (or use row action icons).',
      actions: [
        (
          'View (eye)',
          'Opens delegate details — profile, contacts, arrival / departure.'
        ),
        (
          'Events (calendar)',
          'Opens itinerary / event nominations for the assignment.'
        ),
        (
          'Vehicles (car)',
          'Opens vehicles allocated to the delegate.'
        ),
        (
          'Update actual arrival (plane)',
          'Opens the travel / arrival editor for the row.'
        ),
        (
          'Search',
          'Search across name, type, country / category, arrival and departure.'
        ),
      ],
      note:
          'Columns: Delegate, Type (Foreign / Domestic), Country / Category, Arrival, Departure and Actions. If a delegate does not appear, they have not yet been assigned to you.',
    ),
    _HelpSection(
      id: 'travel',
      title: '4. Update Delegate Travel Details',
      icon: Icons.flight_land_outlined,
      purpose:
          'When your delegate lands, capture the real arrival flight details from My Delegates. The update is saved immediately and is visible to authorised LO Committee users.',
      whereToFind:
          'My Delegates → Actions → Update actual arrival.\nMobile: Delegates → plane / arrival action, or delegate detail → Update travel / Log movement.',
      fields: [
        ('Flight #', 'Optional', 'Actual arrival flight number.'),
        ('Terminal', 'Optional', 'Arrival terminal.'),
        ('Arrival Date', 'Optional', 'Actual arrival date.'),
        ('Arrival Time', 'Optional', 'Actual arrival time (HH:MM).'),
      ],
      actions: [
        ('Save', 'Persists arrival details; the delegate row updates immediately.'),
        ('Cancel', 'Closes without saving.'),
      ],
      note:
          'Update as soon as the delegate lands. Mobile also supports movement kinds (arrival / transfer / venue entry / departure); failed writes can queue offline.',
    ),
    _HelpSection(
      id: 'tasks',
      title: '5. Manage Your Tasks',
      icon: Icons.task_alt_outlined,
      purpose:
          'My Tasks lists every task the LO Committee has assigned to you. Each row shows title, description, linked delegate, scheduled date/time, location and a status badge.',
      whereToFind:
          'Liaison Officer login → My Tasks.\nMobile: Bottom nav → Tasks tab.',
      fields: [
        (
          'New Status',
          'Required',
          'Pick Pending, In Progress or Completed. Saved as soon as you confirm.'
        ),
      ],
      actions: [
        (
          'Per-row status action',
          'Opens a status picker (optional remarks). Update is immediate.'
        ),
        (
          'Mark In Progress',
          'When you actively start working on the task.'
        ),
        (
          'Mark Completed',
          'When done — status badge turns green.'
        ),
      ],
      note:
          'Stat cards at the top show Pending / In Progress / Completed counts. Tasks are grouped by delegate. Use search by title, description or delegate name. Mobile queues status updates offline when needed.',
    ),
    _HelpSection(
      id: 'notifications',
      title: '6. Notifications & Updates',
      icon: Icons.campaign_outlined,
      purpose:
          'The portal notifies you when something relevant changes — through the in-portal bell and email on your nomination address.',
      whereToFind:
          'Top-bar notification bell, and your nomination-email inbox.\nMobile: AppBar bell → CAP inbox; Alerts tab for local notices / reminders.',
      actions: [
        (
          'Notification bell',
          'Opens the in-portal notification centre with recent updates.'
        ),
        (
          'Email inbox',
          'The same events are emailed to your nomination address.'
        ),
      ],
      note:
          'You receive notifications for new tasks, task updates, delegate changes, travel / event changes, and upcoming scheduled tasks. Optional FCM push is a follow-up; local OS reminders cover task lead times.',
    ),
    _HelpSection(
      id: 'help',
      title: '7. Help & Support',
      icon: Icons.support_agent_outlined,
      purpose:
          'This page — a quick reference for the Liaison Officer portal and mobile app.',
      whereToFind:
          'Liaison Officer login → Help & Support.\nMobile: Avatar menu → Help & Support.',
      actions: [
        (
          'Download User Manual',
          'Web downloads a PDF; mobile shares a markdown copy via the device share sheet.'
        ),
      ],
    ),
    _HelpSection(
      id: 'appendix',
      title: 'Appendix — Mobile app map',
      icon: Icons.phone_android_outlined,
      purpose:
          'How Help sections map to mobile surfaces, plus mobile-only extras.',
      whereToFind: 'This Help screen · Avatar menu · Bottom tabs.',
      steps: [
        'Access & Login → Login screen (email + CAPTCHA + OTP); incomplete profiles open My Profile first',
        'Profile → Avatar → My Profile (3-step wizard)',
        'Delegates → Delegates tab → detail / row actions',
        'Travel → Arrival / movement sheets from list or detail',
        'Tasks → Tasks tab',
        'Notifications → AppBar bell + Alerts tab',
        'Help → Avatar → Help & Support',
      ],
      note:
          'Mobile extras (not in web Help 1–7): Issue reporting, Theme toggle, offline queues for task status and travel writes. Accommodation is out of scope.',
    ),
  ];

  Future<void> _shareManual() async {
    try {
      final markdown = await rootBundle.loadString(_manualAsset);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lo-officer-user-manual.md');
      await file.writeAsString(markdown);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Liaison Officer user manual',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('User manual ready to share.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(apiErrorMessage(e)),
        ),
      );
    }
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Help & Support',
      actions: [
        IconButton(
          tooltip: 'Download user manual',
          onPressed: _shareManual,
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
                  'The whole LO Committee flow, in the order you\'ll use it.',
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
                  'End-to-end workflow',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'How the LO screens connect from login through follow-up.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    for (var i = 0; i < _workflow.length; i++) ...[
                      _WorkflowChip(
                        step: _workflow[i].$1,
                        label: _workflow[i].$2,
                      ),
                      if (i < _workflow.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                    ],
                  ],
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
                ..._sections.map(
                  (s) => InkWell(
                    onTap: () => _scrollTo(_sectionKeys[s.id]!),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(s.icon, size: 18, color: AppTheme.activeAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.title,
                              style: TextStyle(
                                color: AppTheme.activeAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._sections.map(
            (s) => KeyedSubtree(
              key: _sectionKeys[s.id],
              child: _HelpSectionCard(section: s),
            ),
          ),
          AppCard(
            child: Text(
              'NOTE: This app is for Liaison Officers only. '
              'Use Delegates · Tasks · Alerts, plus Profile, Help, and Theme from the account menu. '
              'Content mirrors the live CAP Help & Support guide.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowChip extends StatelessWidget {
  const _WorkflowChip({required this.step, required this.label});

  final String step;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.activeAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.activeAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.activeAccent,
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection {
  const _HelpSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.purpose,
    required this.whereToFind,
    this.fields = const [],
    this.actions = const [],
    this.steps = const [],
    this.note,
  });

  final String id;
  final String title;
  final IconData icon;
  final String purpose;
  final String whereToFind;
  final List<(String, String, String)> fields;
  final List<(String, String)> actions;
  final List<String> steps;
  final String? note;
}

class _HelpSectionCard extends StatelessWidget {
  const _HelpSectionCard({required this.section});

  final _HelpSection section;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: AppTheme.activeAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label(context, 'PURPOSE'),
          Text(section.purpose),
          const SizedBox(height: 10),
          _label(context, 'WHERE TO FIND IT'),
          Text(section.whereToFind),
          if (section.fields.isNotEmpty) ...[
            const SizedBox(height: 10),
            _label(context, 'FIELDS'),
            ...section.fields.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            f.$1,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _ReqBadge(label: f.$2),
                      ],
                    ),
                    Text(f.$3, style: TextStyle(color: muted, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
          if (section.actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _label(context, 'AVAILABLE ACTIONS'),
            ...section.actions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.$1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(a.$2, style: TextStyle(color: muted, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
          if (section.steps.isNotEmpty) ...[
            const SizedBox(height: 10),
            _label(context, 'STEP-BY-STEP'),
            ...section.steps.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppTheme.activeAccent,
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value)),
                      ],
                    ),
                  ),
                ),
          ],
          if ((section.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Text(
                section.note!,
                style: const TextStyle(
                  color: Color(0xFF5D4037),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppTheme.activeAccent,
        ),
      ),
    );
  }
}

class _ReqBadge extends StatelessWidget {
  const _ReqBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final required = label.toLowerCase().contains('required');
    final color = required ? const Color(0xFFC62828) : AppTheme.activeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
