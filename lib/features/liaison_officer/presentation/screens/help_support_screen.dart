import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liaison_officer/core/network/api_error_message.dart';
import 'package:liaison_officer/core/services/device_downloads.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';
import 'package:liaison_officer/core/services/lo_monitoring_events.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/widgets/helpline_numbers_card.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Keeps the portal bloc available when Help is pushed above the app navigator.
///
/// Pass [bloc] when the drawer will close before this push; [Navigator.pop]
/// would otherwise remove the help route if it is pushed first.
void openHelpSupport(BuildContext context, {LoPortalBloc? bloc}) {
  var resolved = bloc;
  if (resolved == null) {
    try {
      resolved = context.read<LoPortalBloc>();
    } catch (_) {}
  }
  final portal = resolved;
  LoFirebaseMonitor.instance.logFeature(LoMonitoringEvents.featureHelp);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => portal == null
          ? const HelpSupportScreen()
          : BlocProvider.value(value: portal, child: const HelpSupportScreen()),
    ),
  );
}

/// The downloadable user manual as PDF bytes.
@visibleForTesting
Future<Uint8List> buildHelpManualPdf() => _HelpSupportScreenState.buildManualPdf();

/// Help & Support — portal-aligned LO walkthrough (mirrors CAP web guide).
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _logoAsset = 'assets/images/aero-india-logo.png';

  late final Map<String, GlobalKey> _sectionKeys = {
    for (final s in _sections) s.id: GlobalKey(),
  };
  final _helplinesKey = GlobalKey();
  final _gettingStartedKey = GlobalKey();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static bool _matches(_HelpSection s, String q) {
    final hay = [
      s.title,
      s.purpose,
      s.whereToFind,
      s.note ?? '',
      ...s.steps,
      for (final f in s.fields) '${f.$1} ${f.$3}',
      for (final a in s.actions) '${a.$1} ${a.$2}',
    ].join(' ').toLowerCase();
    return hay.contains(q);
  }

  int _helplineCount(BuildContext context) {
    try {
      final state = context.read<LoPortalBloc>().state;
      return LoHelplineDto.visible(state.helplines).length;
    } catch (_) {
      return 0;
    }
  }

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
      'Open My Profile and complete the four-step wizard (Personal Details, Document Uploads, Dress Measurements, Prior LO Experience), then Submit.',
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
          'Your first job as an LO is to complete your own record. My Profile opens in a read-only view; use the header CTA to enter a four-step wizard covering Personal Details, Document Uploads, Dress Measurements and Prior LO Experience. Nothing is written to the backend until you press Submit on the final step.',
      whereToFind:
          'Liaison Officer login → My Profile → Complete Profile / Update Details.\nMobile: Avatar menu → My Profile.',
      fields: [
        (
          'First Name / Last Name',
          'Required',
          'Personal Details — your legal name.',
        ),
        (
          'Mobile Number (from Nomination)',
          'Required',
          'Pre-filled from nomination; editable here.',
        ),
        (
          'Aadhaar Number',
          'Required',
          '12 digits (spaces allowed while typing).',
        ),
        ('Languages Known', 'Optional', 'Chip list — pick a language and Add.'),
        (
          'Photo & Specimen Signature',
          'Required',
          'Document Uploads — JPEG / JPG / PNG only.',
        ),
        (
          'Prior LO Experience rows',
          'Optional',
          'Event, Year, Role / Responsibilities, Delegates Handled.',
        ),
      ],
      actions: [
        (
          'Complete Profile / Update Details',
          'Header action on the view screen — opens the wizard.',
        ),
        (
          'Stepper',
          'Jump between Personal Details, Document Uploads, Dress Measurements and Prior LO Experience without losing entered data.',
        ),
        (
          'Back / Next',
          'Wizard navigation. Each step validates required fields before advancing.',
        ),
        (
          'Choose File / Replace / Clear',
          'Document Uploads controls. Clear is only for pending (unsaved) files.',
        ),
        (
          'Submit',
          'Only on the final step. Commits every change across all four steps — the only moment data reaches the server.',
        ),
      ],
      steps: [
        'Personal Details — Salutation, gender, name, DOB, rank / designation, organisation ID, Aadhaar, personal email / contact, WhatsApp and Languages Known.',
        'Document Uploads — Photo, Specimen Signature, Aadhaar (Front & Back) and Organisation Badge (Front & Back). All six are mandatory; JPEG / JPG / PNG only.',
        'Dress Measurements — Trouser waist and length, blazer chest and sleeve length, in inches.',
        'Prior LO Experience — Answer Has LO Experience? If Yes, add rows, then Submit to persist the entire profile.',
      ],
      note:
          'Nothing writes between steps — closing before Submit loses the session. Nomination email is read-only. Document preview “Load failed” on the read-only view is a preview issue, not a missing upload.',
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
          'Opens delegate details — profile, contacts, arrival / departure.',
        ),
        (
          'Events (calendar)',
          'Opens itinerary / event nominations for the assignment.',
        ),
        ('Vehicles (car)', 'Opens vehicles allocated to the delegate.'),
        (
          'Update actual arrival (plane)',
          'Opens the travel / arrival editor for the row.',
        ),
        (
          'Search',
          'Search across name, type, country / category, arrival and departure.',
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
        (
          'Save',
          'Persists arrival details; the delegate row updates immediately.',
        ),
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
          'Pick Pending, In Progress or Completed. Saved as soon as you confirm.',
        ),
      ],
      actions: [
        (
          'Per-row status action',
          'Opens a status picker (optional remarks). Update is immediate.',
        ),
        ('Mark In Progress', 'When you actively start working on the task.'),
        ('Mark Completed', 'When done — status badge turns green.'),
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
          'Top-bar notification bell, and your nomination-email inbox.\nMobile: AppBar bell → notification inbox; Alerts tab for local notices / reminders.',
      actions: [
        (
          'Notification bell',
          'Opens the in-portal notification centre with recent updates.',
        ),
        (
          'Email inbox',
          'The same events are emailed to your nomination address.',
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
          'Saves a PDF copy of this guide to your Downloads folder for offline reference.',
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

  bool _downloading = false;

  /// Builds the manual PDF from the same content shown on this screen
  /// (aide-ui also generates its Help PDF client-side) and saves it to
  /// Downloads like the e-badge.
  Future<void> _downloadManual() async {
    if (_downloading) return;
    _downloading = true;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Preparing user manual…'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final bytes = await buildManualPdf();
      const name = 'lo-officer-user-manual.pdf';
      if (kIsWeb) {
        // No Downloads channel on web; share_plus downloads the bytes.
        await Share.shareXFiles([
          XFile.fromData(bytes, name: name, mimeType: 'application/pdf'),
        ]);
        return;
      }
      final handle = await DeviceDownloads.save(bytes: bytes, filename: name);
      if (!mounted || !Platform.isAndroid) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: const Text('Saved to Downloads: $name'),
            action: handle == null
                ? null
                : SnackBarAction(
                    label: 'Open',
                    onPressed: () async {
                      bool opened;
                      try {
                        opened = await DeviceDownloads.open(handle);
                      } catch (_) {
                        opened = false;
                      }
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
    } catch (e) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              apiErrorMessage(e, fallback: 'Could not download the manual.'),
            ),
          ),
        );
    } finally {
      _downloading = false;
    }
  }

  @visibleForTesting
  static Future<Uint8List> buildManualPdf() async {
    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load(_logoAsset);
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    const accent = PdfColor.fromInt(0xFF1E3A8A);
    const muted = PdfColor.fromInt(0xFF475569);
    final h2 = pw.TextStyle(
      fontSize: 15,
      fontWeight: pw.FontWeight.bold,
      color: accent,
    );
    final label = pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold);
    const body = pw.TextStyle(fontSize: 10, lineSpacing: 2);

    pw.Widget table(List<String> headers, List<List<String>> rows) {
      return pw.TableHelper.fromTextArray(
        headers: headers.map(_pdfText).toList(),
        data: [
          for (final r in rows) r.map(_pdfText).toList(),
        ],
        headerStyle: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: accent),
        headerAlignment: pw.Alignment.centerLeft,
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.all(4),
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      );
    }

    pw.Widget block(String title, pw.Widget child) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: label),
          pw.SizedBox(height: 3),
          child,
        ],
      ),
    );

    final doc = pw.Document(
      title: 'Liaison Officer User Manual',
      author: 'Aero India LO Committee',
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: muted),
          ),
        ),
        build: (ctx) => [
          pw.Row(
            children: [
              if (logo != null) ...[
                pw.Image(logo, width: 48, height: 48),
                pw.SizedBox(width: 12),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Help & Support',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    pw.Text(
                      'Liaison Officer - User Manual',
                      style: const pw.TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.Divider(color: accent, thickness: 1.2),
          pw.Text('Quick Overview', style: h2),
          pw.SizedBox(height: 4),
          for (final o in _overview)
            pw.Bullet(
              text: _pdfText('${o.$1}: ${o.$2}'),
              style: body,
            ),
          pw.SizedBox(height: 10),
          pw.Text('End-to-end workflow', style: h2),
          pw.SizedBox(height: 4),
          table(
            ['Step', 'Screen'],
            [for (final w in _workflow) [w.$1, w.$2]],
          ),
          for (final s in _sections) ...[
            pw.SizedBox(height: 14),
            pw.Text(_pdfText(s.title), style: h2),
            block('Purpose', pw.Text(_pdfText(s.purpose), style: body)),
            block(
              'Where to find it',
              pw.Text(_pdfText(s.whereToFind), style: body),
            ),
            if (s.steps.isNotEmpty)
              block(
                'Step-by-step',
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < s.steps.length; i++)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text(
                          '${i + 1}. ${_pdfText(s.steps[i])}',
                          style: body,
                        ),
                      ),
                  ],
                ),
              ),
            if (s.fields.isNotEmpty)
              block(
                'Fields',
                table(
                  ['Field', 'Required', 'Description'],
                  [for (final f in s.fields) [f.$1, f.$2, f.$3]],
                ),
              ),
            if (s.actions.isNotEmpty)
              block(
                'Available actions',
                table(
                  ['Action', 'Description'],
                  [for (final a in s.actions) [a.$1, a.$2]],
                ),
              ),
            if ((s.note ?? '').trim().isNotEmpty)
              block('Note', pw.Text(_pdfText(s.note!), style: body)),
          ],
          pw.SizedBox(height: 16),
          pw.Text(
            'Made for LO Committee - Aero India. Content mirrors the live application.',
            style: const pw.TextStyle(fontSize: 9, color: muted),
          ),
        ],
      ),
    );
    return doc.save();
  }

  /// Built-in PDF fonts only cover Latin-1: swap arrows and dashes, drop
  /// anything else they cannot draw.
  static String _pdfText(String s) => s
      .replaceAll('→', '->')
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('‘', "'")
      .replaceAll('’', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('…', '...')
      .replaceAll(RegExp(r'[^\x09\x0A\x0D\x20-\xFF]'), '');

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
          onPressed: _downloadManual,
          icon: const Icon(Icons.download_outlined, color: Colors.white),
        ),
      ],
      body: Builder(
        builder: (context) {
          final colors = context.semantic;
          final q = _query.trim().toLowerCase();
          final searching = q.isNotEmpty;
          final topics = searching
              ? _sections.where((s) => _matches(s, q)).toList()
              : _sections;
          final helplines = _helplineCount(context);
          // Non-lazy so quick tiles can ensureVisible() any section.
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HelpHero(
                  controller: _searchController,
                  query: _query,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
                if (!searching) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Row(
                      spacing: 8,
                      children: [
                        if (helplines > 0)
                          Expanded(
                            child: _QuickTile(
                              icon: Icons.phone_in_talk_outlined,
                              label: 'Helplines',
                              onTap: () => _scrollTo(_helplinesKey),
                            ),
                          ),
                        Expanded(
                          child: _QuickTile(
                            icon: Icons.download_outlined,
                            label: 'User manual',
                            onTap: _downloadManual,
                          ),
                        ),
                        Expanded(
                          child: _QuickTile(
                            icon: Icons.rocket_launch_outlined,
                            label: 'Getting started',
                            onTap: () => _scrollTo(_gettingStartedKey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  KeyedSubtree(
                    key: _helplinesKey,
                    child: const HelplineNumbersSection(),
                  ),
                  KeyedSubtree(
                    key: _gettingStartedKey,
                    child: const _SectionHeading(
                      icon: Icons.rocket_launch_outlined,
                      title: 'Quick Overview',
                      subtitle:
                          'The whole LO Committee flow, in the order you\'ll use it.',
                    ),
                  ),
                  AppCard(child: _Timeline(items: _overview)),
                  const _SectionHeading(
                    icon: Icons.account_tree_outlined,
                    title: 'End-to-end workflow',
                    subtitle:
                        'How the LO screens connect from login through follow-up.',
                  ),
                  AppCard(
                    child: Column(
                      spacing: 8,
                      children: [
                        for (final w in _workflow)
                          _WorkflowChip(step: w.$1, label: w.$2),
                      ],
                    ),
                  ),
                ],
                _SectionHeading(
                  icon: Icons.menu_book_outlined,
                  title: searching ? 'Search results' : 'Help topics',
                  count: topics.length,
                ),
                if (topics.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AppEmptyState(
                      icon: Icons.search_off_rounded,
                      message: 'No help topics match "${_query.trim()}".',
                    ),
                  )
                else
                  for (final s in topics)
                    KeyedSubtree(
                      key: _sectionKeys[s.id],
                      child: _HelpSectionCard(
                        key: ValueKey('${s.id}-$searching'),
                        section: s,
                        initiallyExpanded: searching,
                      ),
                    ),
                if (!searching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _InfoNote(
                      text:
                          'NOTE: This app is for Liaison Officers only. '
                          'Use Delegates · Tasks · Alerts, plus Profile, Help, and Theme from the account menu. '
                          'Content mirrors the live Help & Support guide.',
                      color: colors.accent,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: FilledButton.icon(
                    onPressed: _downloadManual,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download user manual'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HelpHero extends StatelessWidget {
  const _HelpHero({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    final pill = BorderRadius.circular(28);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.06),
            accent.withValues(alpha: 0.16),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.support_agent_rounded, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How can we help?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Guides for the Liaison Officer app and portal.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                height: 52,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Icon(
                        Icons.help_rounded,
                        size: 44,
                        color: accent.withValues(alpha: 0.3),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        size: 24,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search help topics…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: onClear,
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: colors.surface,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: pill,
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: pill,
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: pill,
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: AppTheme.glassCardDecoration(radius: 16, isDark: isDark),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent.withValues(alpha: 0.1),
                  ),
                  child: Icon(icon, color: colors.accent),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    this.subtitle,
    this.count,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 19, color: colors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                        child: Text(
                          items[i].$1.split(' · ').first,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      if (i < items.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: accent.withValues(alpha: 0.25),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < items.length - 1 ? 14 : 0,
                      top: 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].$1.contains(' · ')
                              ? items[i].$1.split(' · ').skip(1).join(' · ')
                              : items[i].$1,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$2,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colors.textPrimary,
              ),
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
    final colors = context.semantic;
    final accent = colors.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
            child: Text(
              step,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: colors.textPrimary,
              ),
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
  const _HelpSectionCard({
    super.key,
    required this.section,
    this.initiallyExpanded = false,
  });

  final _HelpSection section;
  final bool initiallyExpanded;

  String get _summary {
    final p = section.purpose.trim();
    final dot = p.indexOf('. ');
    return dot > 0 ? p.substring(0, dot + 1) : p;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    final muted = colors.textSecondary;
    final body = TextStyle(
      fontSize: 13,
      height: 1.45,
      color: colors.textPrimary,
    );
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: colors.textPrimary,
          collapsedIconColor: colors.textPrimary,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          childrenPadding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.1),
            ),
            child: Icon(section.icon, size: 20, color: accent),
          ),
          title: Text(
            section.title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            _summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: muted),
          ),
          children: [
            Divider(height: 1, color: colors.border),
            const SizedBox(height: 12),
            _label(context, 'PURPOSE'),
            Text(section.purpose, style: body),
            const SizedBox(height: 12),
            _label(context, 'WHERE TO FIND IT'),
            Text(section.whereToFind, style: body),
            if (section.fields.isNotEmpty) ...[
              const SizedBox(height: 12),
              _label(context, 'FIELDS'),
              for (final f in section.fields)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              f.$1,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ReqBadge(label: f.$2),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(f.$3, style: TextStyle(color: muted, fontSize: 13)),
                    ],
                  ),
                ),
            ],
            if (section.actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _label(context, 'AVAILABLE ACTIONS'),
              for (final a in section.actions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.touch_app_outlined,
                          size: 16,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.$1,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              a.$2,
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (section.steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              _label(context, 'STEP-BY-STEP'),
              for (var i = 0; i < section.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(section.steps[i], style: body)),
                    ],
                  ),
                ),
            ],
            if ((section.note ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoNote(text: section.note!, color: AppTheme.saffron),
            ],
          ],
        ),
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
          color: context.semantic.accent,
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
    final color = required
        ? const Color(0xFFC62828)
        : Theme.of(context).colorScheme.primary;
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
