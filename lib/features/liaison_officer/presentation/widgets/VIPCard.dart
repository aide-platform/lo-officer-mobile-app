import 'package:liaison_officer/features/liaison_officer/presentation/widgets/vip_wallet_pass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../widgets/layouts/glassCard.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_asset_manager.dart';
import '../../../../../core/design/contrast.dart';
import '../../data/models/engagement.dart';
import '../../data/models/guestActivity.dart';
import '../../data/models/vip.dart';
import '../screens/lo_delegate_detail_screen.dart';

// ═══════════════════════════════════════════════════════════════
// VIP CARD
// ═══════════════════════════════════════════════════════════════

class VIPCard extends StatefulWidget {
  final VIP vip;
  final ValueChanged<VIP> onUpdate;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onOpenDetail;
  final List<VIP> allVips;

  const VIPCard({
    super.key,
    required this.vip,
    required this.onUpdate,
    this.onToggle,
    this.onOpenDetail,
    this.allVips = const [],
  });

  @override
  State<VIPCard> createState() => _VIPCardState();
}

class _VIPCardState extends State<VIPCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _toggle(bool open) {
    setState(() => _expanded = open);
    widget.onToggle?.call(open);
  }

  @override
  Widget build(BuildContext context) {
    final vip = widget.vip;
    final progress = vip.progressPercent;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GlassCard(
      child: Column(
        children: [
          // ── Header ────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggle(!_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(children: [
                // Progress ring + avatar
                Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: theme.dividerColor,
                      color: progress == 1 ? AppColors.success : cs.primary,
                    ),
                  ),
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: cs.surface,
                    child: vip.imagePath != null
                        ? ClipOval(
                            child: SafeAssetImage(
                              assetPath: vip.imagePath!,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              fallback: Icon(Icons.person, color: cs.primary),
                            ),
                          )
                        : Icon(Icons.person, color: cs.primary),
                  ),
                ]),

                const SizedBox(width: 12),

                // Name + designation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(
                            vip.displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        if (vip.isForeign)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.public,
                                        size: 10,
                                        color: Contrast.onSolid(
                                            AppColors.danger)),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Foreign',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: Contrast.onSolid(
                                              AppColors.danger),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ]),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (vip.organisation.isNotEmpty) vip.organisation,
                          vip.designation,
                        ].where((e) => e.trim().isNotEmpty).join(' · '),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 4),
                      // Mini progress bar
                      Row(children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: context.semantic.border,
                              color: progress == 1
                                  ? AppColors.success
                                  : cs.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: progress == 1
                                  ? AppColors.success
                                  : cs.primary),
                        ),
                      ]),
                    ],
                  ),
                ),

                // Transport status chip + dossier
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _StatusPill(vip.transport.status),
                  const SizedBox(height: 4),
                  IconButton(
                    tooltip: 'View assignment details',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.folder_shared_outlined,
                        size: 20, color: cs.primary),
                    onPressed: () {
                      if (widget.onOpenDetail != null) {
                        widget.onOpenDetail!();
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LoDelegateDetailScreen(
                            vip: vip,
                            allVips: widget.allVips.isEmpty
                                ? [vip]
                                : widget.allVips,
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.expand_more,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ]),
              ]),
            ),
          ),

          // ── Expanded body ──────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(children: [
              Divider(height: 1, color: context.semantic.border),

              // Tab bar
              TabBar(
                controller: _tabCtrl,
                isScrollable: false,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Schedule'),
                  Tab(text: 'Notes'),
                  Tab(text: 'Activity'),
                ],
              ),

              SizedBox(
                height: 480,
                child: TabBarView(
                  controller: _tabCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _OverviewTab(vip: widget.vip, onUpdate: widget.onUpdate),
                    _ScheduleTab(vip: widget.vip, onUpdate: widget.onUpdate),
                    _NotesTab(vip: widget.vip, onUpdate: widget.onUpdate),
                    _ActivityTab(vip: widget.vip),
                  ],
                ),
              ),

              // Pass download
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: VipWalletPassCard(vip: widget.vip),
                //VipPassDownloadButton(vip: widget.vip),
              ),
            ]),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 1 – OVERVIEW
// ═══════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final VIP vip;
  final ValueChanged<VIP> onUpdate;
  const _OverviewTab({required this.vip, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ── Contact ────────────────────────────────
        _SectionHeader(
          icon: Icons.contact_phone,
          cs: cs,
          title: 'Contact',
        ),
        _InfoTile(
            icon: Icons.phone,
            label: 'Mobile',
            value: vip.contact,
            copyable: true),
        if (vip.isForeign) ...[
          _InfoTile(
              icon: Icons.flag,
              label: 'Nationality',
              value: vip.nationality ?? '—'),
          _InfoTile(
              icon: Icons.badge,
              label: 'Passport',
              value: vip.passportNumber ?? '—',
              copyable: true),
          _InfoTile(
              icon: Icons.language,
              label: 'Language',
              value: vip.language ?? '—'),
          _InfoTile(
              icon: Icons.public,
              label: 'Time Zone',
              value: vip.timeZone ?? '—'),
          _InfoTile(
              icon: Icons.verified,
              label: 'Visa Status',
              value: vip.visaStatus ?? '—',
              highlight:
                  vip.visaStatus?.toLowerCase().contains('approved') ?? false),
          _InfoTile(
              icon: Icons.security,
              label: 'Security Clearance',
              value: vip.securityClearanceStatus ?? '—',
              highlight: vip.securityClearanceStatus
                      ?.toLowerCase()
                      .contains('cleared') ??
                  false),
        ],

        const SizedBox(height: 12),

        // ── Hotel ──────────────────────────────────
        _SectionHeader(
          icon: Icons.hotel,
          cs: cs,
          title: 'Accommodation',
        ),
        _EditableHotelTile(vip: vip, onUpdate: onUpdate),

        const SizedBox(height: 12),

        // ── Transport ──────────────────────────────
        _SectionHeader(
          icon: Icons.directions_car,
          cs: cs,
          title: 'Transport',
        ),
        _EditableTransportTile(vip: vip, onUpdate: onUpdate),
        if (vip.transport.flightNumber != null) ...[
          _InfoTile(
              icon: Icons.flight_land,
              label: 'Flight',
              value: vip.transport.flightNumber ?? '—'),
          _InfoTile(
              icon: Icons.access_time,
              label: 'Arrival',
              value: vip.transport.arrivalTime != null
                  ? _fmtDT(vip.transport.arrivalTime!)
                  : '—'),
          _InfoTile(
              icon: Icons.airline_seat_recline_normal,
              label: 'Terminal',
              value: vip.transport.arrivalTerminal ?? '—'),
          _InfoTile(
              icon: Icons.place,
              label: 'Location',
              value: vip.transport.arrivalLocation ?? '—'),
        ],

        if (vip.foodPreferences != null) ...[
          const SizedBox(height: 12),
          _SectionHeader(
            icon: Icons.restaurant,
            cs: cs,
            title: 'Dietary',
          ),
          _InfoTile(
              icon: Icons.restaurant_menu,
              label: 'Food Preferences',
              value: vip.foodPreferences!),
        ],

        // ── Special Requests ───────────────────────
        if (vip.specialRequests.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionHeader(
            icon: Icons.priority_high,
            cs: cs,
            title: 'Special Requests',
          ),
          ...vip.specialRequests.map((r) => _SpecialRequestTile(request: r)),
        ],
      ],
    );
  }

  String _fmtDT(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo ${dt.year} · $h:$min';
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 2 – SCHEDULE / ENGAGEMENTS
// ═══════════════════════════════════════════════════════════════

class _ScheduleTab extends StatefulWidget {
  final VIP vip;
  final ValueChanged<VIP> onUpdate;
  const _ScheduleTab({required this.vip, required this.onUpdate});

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  void _addEngagement(BuildContext context) {
    final nameCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    DateTime picked = DateTime.now();
    String rsvp = 'Pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Engagement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Event Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              // Date & time picker
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                    'Date: ${picked.day}/${picked.month}/${picked.year}  ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}'),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: picked,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d == null) return;
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(picked),
                  );
                  if (t == null) return;
                  setSt(() => picked =
                      DateTime(d.year, d.month, d.day, t.hour, t.minute));
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: rsvp,
                decoration: const InputDecoration(
                    labelText: 'RSVP Status', border: OutlineInputBorder()),
                items: ['Pending', 'Confirmed', 'Declined']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setSt(() => rsvp = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'LO Comments (optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    widget.vip.engagements.add(
                      Engagement(
                        eventName: nameCtrl.text.trim(),
                        dateTime: picked,
                        rsvpStatus: rsvp,
                        comments: commentCtrl.text.trim(),
                      ),
                    );
                    widget.onUpdate(widget.vip);
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final engagements = widget.vip.engagements;
    final confirmed = engagements
        .where((e) => e.rsvpStatus.toLowerCase() == 'confirmed')
        .length;
    final pending = engagements
        .where((e) => e.rsvpStatus.toLowerCase() == 'pending')
        .length;
    final declined = engagements
        .where((e) => e.rsvpStatus.toLowerCase() == 'declined')
        .length;

    return Column(
      children: [
        // ── Summary strip ──────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: cs.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _EngStat(
                  label: 'Total', value: engagements.length, color: cs.primary),
              _EngStat(
                  label: 'Confirmed',
                  value: confirmed,
                  color: AppColors.success),
              _EngStat(
                  label: 'Pending', value: pending, color: AppColors.warning),
              _EngStat(
                  label: 'Declined', value: declined, color: AppColors.danger),
            ],
          ),
        ),

        Expanded(
          child: engagements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy,
                          size: 40, color: context.semantic.border),
                      const SizedBox(height: 8),
                      Text('No engagements yet',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  itemCount: engagements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final e = engagements[i];
                    return _EngagementCard(
                      engagement: e,
                      onCommentSaved: (c) {
                        e.comments = c;
                        widget.onUpdate(widget.vip);
                        setState(() {});
                      },
                      onRsvpChanged: (r) {
                        e.rsvpStatus = r;
                        widget.onUpdate(widget.vip);
                        setState(() {});
                      },
                      onDelete: () {
                        widget.vip.engagements.removeAt(i);
                        widget.onUpdate(widget.vip);
                        setState(() {});
                      },
                    );
                  },
                ),
        ),

        // ── Add button ─────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Engagement'),
            onPressed: () => _addEngagement(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Engagement card ──────────────────────────────────────────

class _EngagementCard extends StatefulWidget {
  final Engagement engagement;
  final ValueChanged<String> onCommentSaved;
  final ValueChanged<String> onRsvpChanged;
  final VoidCallback onDelete;

  const _EngagementCard({
    required this.engagement,
    required this.onCommentSaved,
    required this.onRsvpChanged,
    required this.onDelete,
  });

  @override
  State<_EngagementCard> createState() => _EngagementCardState();
}

class _EngagementCardState extends State<_EngagementCard> {
  bool _editingComment = false;
  late TextEditingController _commentCtrl;

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController(text: widget.engagement.comments);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Color _rsvpColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.success;
      case 'declined':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _fmtDT(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year} · $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engagement;
    final rsvpC = _rsvpColor(e.rsvpStatus);
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: rsvpC.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rsvpC.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
            child: Row(children: [
              Icon(Icons.event, size: 16, color: rsvpC),
              const SizedBox(width: 8),
              Expanded(
                child: Text(e.eventName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              // RSVP dropdown
              DropdownButton<String>(
                value: e.rsvpStatus,
                underline: const SizedBox(),
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: rsvpC),
                items: ['Pending', 'Confirmed', 'Declined']
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: TextStyle(color: _rsvpColor(s)))))
                    .toList(),
                onChanged: (v) => widget.onRsvpChanged(v!),
              ),
              // Delete
              IconButton(
                icon: Icon(Icons.close, size: 16, color: context.semantic.textSecondary),
                onPressed: widget.onDelete,
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _fmtDT(e.dateTime),
              style:
                  TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),

          // LO comment
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: _editingComment
                ? Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        autofocus: true,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Add LO comment…',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        widget.onCommentSaved(_commentCtrl.text.trim());
                        setState(() => _editingComment = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Save',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ])
                : GestureDetector(
                    onTap: () => setState(() => _editingComment = true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.comments.isEmpty
                            ? 'Tap to add LO comment…'
                            : e.comments,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: e.comments.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: e.comments.isEmpty
                              ? context.semantic.textMuted
                              : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 3 – NOTES / REMARKS / SPECIAL REQUESTS
// ═══════════════════════════════════════════════════════════════

class _NotesTab extends StatefulWidget {
  final VIP vip;
  final ValueChanged<VIP> onUpdate;
  const _NotesTab({required this.vip, required this.onUpdate});

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  final _remarkCtrl = TextEditingController();
  // Track escalation status per special request index
  late final List<bool> _escalated;

  @override
  void initState() {
    super.initState();
    _escalated = List.filled(widget.vip.specialRequests.length, false);
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vip = widget.vip;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ── Add remark ─────────────────────────────
        _SectionHeader(
          icon: Icons.edit_note,
          cs: cs,
          title: 'Log Remark',
        ),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _remarkCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. "Protocol team notified at 14:00"',
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: AppColors.inputFill(
                    Theme.of(context).brightness == Brightness.dark),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            onPressed: () {
              final txt = _remarkCtrl.text.trim();
              if (txt.isEmpty) return;
              vip.remarks.add(txt);
              _remarkCtrl.clear();
              widget.onUpdate(widget.vip);
              setState(() {});
            },
            child: const Icon(Icons.send, size: 18),
          ),
        ]),

        const SizedBox(height: 12),

        // ── Existing remarks ───────────────────────
        _SectionHeader(
          icon: Icons.notes,
          cs: cs,
          title: 'Remarks',
        ),
        if (vip.remarks.isEmpty)
          _EmptyState(msg: 'No remarks yet', icon: Icons.notes_outlined)
        else
          ...List.generate(
            vip.remarks.length,
            (i) => Dismissible(
              key: ValueKey('remark_${vip.name}_${vip.remarks[i]}_$i'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: AppColors.danger,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                vip.remarks.removeAt(i);
                widget.onUpdate(widget.vip);
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.semantic.border),
                  ),
                  child: Row(children: [
                    Icon(Icons.chevron_right, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(vip.remarks[i],
                            style: const TextStyle(fontSize: 13))),
                  ]),
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),

        // ── Special requests ───────────────────────
        _SectionHeader(
          icon: Icons.priority_high,
          cs: cs,
          title: 'Special Requests',
        ),
        if (vip.specialRequests.isEmpty)
          _EmptyState(
              msg: 'No special requests', icon: Icons.check_circle_outline)
        else
          ...List.generate(
            vip.specialRequests.length,
            (i) {
              final esc = i < _escalated.length ? _escalated[i] : false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: esc
                            ? AppColors.danger
                            : AppColors.warning.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: esc
                                ? AppColors.danger
                                : Colors.orange.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.priority_high,
                            size: 14,
                            color: esc ? AppColors.danger : AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vip.specialRequests[i],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (i < _escalated.length) {
                        _escalated[i] = !_escalated[i];
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: esc ? AppColors.danger : AppColors.warning,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        esc ? 'Escalated' : 'Escalate',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ]),
              );
            },
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 4 – ACTIVITY LOG
// ═══════════════════════════════════════════════════════════════

class _ActivityTab extends StatelessWidget {
  final VIP vip;
  const _ActivityTab({required this.vip});

  List<GuestActivity> _buildLog() {
    final log = <GuestActivity>[];
    log.add(GuestActivity('Entry Created', DateTime.now()));
    log.add(GuestActivity('LO Assigned', DateTime.now()));
    if (vip.hotel.name.isNotEmpty) {
      log.add(GuestActivity(
          'Hotel Assigned: ${vip.hotel.name} (${vip.hotel.roomNumber})',
          DateTime.now()));
    }
    if (vip.transport.status.toLowerCase() == 'completed') {
      log.add(GuestActivity(
          'Transport Completed (${vip.transport.carType})', DateTime.now()));
    }
    if (vip.transport.arrivalTime != null) {
      log.add(GuestActivity(
          'Expected Arrival: ${vip.transport.arrivalLocation}',
          vip.transport.arrivalTime!));
    }
    if (vip.foodPreferences != null) {
      log.add(GuestActivity(
          'Catering Notified: ${vip.foodPreferences}', DateTime.now()));
    }
    for (final e in vip.engagements) {
      log.add(GuestActivity(
          'Engagement: ${e.eventName} (${e.rsvpStatus})', e.dateTime));
    }
    for (final r in vip.remarks) {
      log.add(GuestActivity('Remark: $r', DateTime.now()));
    }
    if (vip.isForeign &&
        (vip.visaStatus?.toLowerCase().contains('approved') ?? false)) {
      log.add(GuestActivity('Visa Approved', DateTime.now()));
    }
    if (vip.isForeign &&
        (vip.securityClearanceStatus?.toLowerCase().contains('cleared') ??
            false)) {
      log.add(GuestActivity('Security Clearance Granted', DateTime.now()));
    }
    return log;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final log = _buildLog();

    if (log.isEmpty) {
      return const _EmptyState(
          msg: 'No activity recorded', icon: Icons.history);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      itemCount: log.length,
      itemBuilder: (_, i) {
        final entry = log[i];
        final isLast = i == log.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Timeline line + dot ────────────
              Column(children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: context.semantic.border,
                    ),
                  ),
              ]),

              const SizedBox(width: 12),

              // ── Content ────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        _fmtDT(entry.time),
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.45)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtDT(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year} · $h:$mi';
  }
}

// ═══════════════════════════════════════════════════════════════
// INLINE EDIT TILES
// ═══════════════════════════════════════════════════════════════

class _EditableHotelTile extends StatelessWidget {
  final VIP vip;
  final ValueChanged<VIP> onUpdate;
  const _EditableHotelTile({required this.vip, required this.onUpdate});

  /* void _edit(BuildContext context) {
    final nc = TextEditingController(text: vip.hotel.name);
    final rc = TextEditingController(text: vip.hotel.roomNumber);
    final dc = TextEditingController(text: vip.hotel.stayDuration);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Hotel'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nc, decoration: const InputDecoration(labelText: 'Hotel Name')),
          TextField(controller: rc, decoration: const InputDecoration(labelText: 'Room Number')),
          TextField(controller: dc, decoration: const InputDecoration(labelText: 'Stay Duration')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              vip.hotel.name = nc.text;
              vip.hotel.roomNumber = rc.text;
              vip.hotel.stayDuration = dc.text;
              onUpdate(vip);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) => _InfoTile(
        icon: Icons.hotel,
        label: 'Hotel',
        value:
            '${vip.hotel.name} · Room ${vip.hotel.roomNumber} · ${vip.hotel.stayDuration}',
        //onEdit: () => _edit(context),
      );
}

class _EditableTransportTile extends StatelessWidget {
  final VIP vip;
  final ValueChanged<VIP> onUpdate;
  const _EditableTransportTile({required this.vip, required this.onUpdate});

  void _edit(BuildContext context) {
    final cc = TextEditingController(text: vip.transport.carType);
    final dc = TextEditingController(text: vip.transport.driverName);
    final dcc = TextEditingController(text: vip.transport.driverContact);
    String status = vip.transport.status;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Update Transport'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: cc,
                decoration: const InputDecoration(labelText: 'Car Type')),
            TextField(
                controller: dc,
                decoration: const InputDecoration(labelText: 'Driver Name')),
            TextField(
                controller: dcc,
                decoration: const InputDecoration(labelText: 'Driver Contact')),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ['Pending', 'In Progress', 'Completed']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setSt(() => status = v!),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                vip.transport.carType = cc.text;
                vip.transport.driverName = dc.text;
                vip.transport.driverContact = dcc.text;
                vip.transport.status = status;
                onUpdate(vip);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _InfoTile(
        icon: Icons.directions_car,
        label: 'Transport',
        value:
            '${vip.transport.carType} · ${vip.transport.driverName} · ${vip.transport.status}',
        onEdit: () => _edit(context),
      );
}

// ═══════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final ColorScheme cs;
  const _SectionHeader(
      {required this.title, required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: cs.primary)),
        ]),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final bool highlight;
  final VoidCallback? onEdit;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.highlight = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon,
            size: 15,
            color: highlight ? AppColors.success : cs.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Row(children: [
            Text('$label: ',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            Flexible(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: highlight ? AppColors.success : cs.onSurface)),
            ),
          ]),
        ),
        if (copyable)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Copied'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: Icon(Icons.copy,
                size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
          ),
        /*  if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: Icon(Icons.edit,
                size: 14,
                color: cs.onSurface
                    .withValues(alpha: 0.3)),
          ),*/
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  Color get _color {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'in progress':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color.withValues(alpha: 0.4)),
        ),
        child: Text(status,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: _color)),
      );
}

class _SpecialRequestTile extends StatelessWidget {
  final String request;
  const _SpecialRequestTile({required this.request});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          const Icon(Icons.priority_high, size: 14, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(child: Text(request, style: const TextStyle(fontSize: 12))),
        ]),
      );
}

class _EngStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _EngStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: context.semantic.textSecondary)),
        ],
      );
}

class _EmptyState extends StatelessWidget {
  final String msg;
  final IconData icon;
  const _EmptyState({required this.msg, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(children: [
          Icon(icon, size: 18, color: context.semantic.border),
          const SizedBox(width: 8),
          Text(msg, style: TextStyle(fontSize: 12, color: context.semantic.textMuted)),
        ]),
      );
}
