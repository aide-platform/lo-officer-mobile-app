// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/contrast.dart';
import '../../../../core/widgets/gradient_app_bar.dart';
import '../../data/models/vip.dart';

// ═══════════════════════════════════════════════════════════════
// ISSUE REPORTING  (#11)
//
// Two ways to trigger:
//   A) Bottom sheet (from any screen):
//      LoIssueReportSheet.show(context, vips: vips)
//
//   B) Full page (add to LO nav or drawer):
//      LoIssueReportPage(vips: vips)
// ═══════════════════════════════════════════════════════════════

// ── Saved issues (in-memory; swap for Hive/API in production) ──
final List<LoIssue> _savedIssues = [];

class LoIssueReportSheet {
  static void show(
      BuildContext context, {
        required List<VIP> vips,
        VIP? preselectedVip,
      }) {
    showModalBottomSheet(
      context:         context,
      isScrollControlled: true,
      useSafeArea:     true,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _IssueFormSheet(
        vips:           vips,
        preselectedVip: preselectedVip,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FULL PAGE  (use as Stats/Profile tab replacement or new tab)
// ═══════════════════════════════════════════════════════════════

class LoIssueReportPage extends StatefulWidget {
  final List<VIP> vips;
  const LoIssueReportPage({super.key, required this.vips});

  @override
  State<LoIssueReportPage> createState() =>
      _LoIssueReportPageState();
}

class _LoIssueReportPageState
    extends State<LoIssueReportPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
  TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GradientAppBar(
        accent: AppColors.roleLO,
        centerTitle: false,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.report_problem,
                color: Color(0xFFFF8A80), size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Issue Reporting',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                Text('Log and track coordination issues',
                    style:
                        TextStyle(color: AppColors.goldLight, fontSize: 11)),
              ],
            ),
          ),
        ]),
        actions: [
          _IssueStat(
            count: _savedIssues
                .where((i) => i.status == IssueStatus.open)
                .length,
            label: 'Open',
            color: AppColors.danger,
          ),
          const SizedBox(width: 8),
          _IssueStat(
            count: _savedIssues
                .where((i) => i.status == IssueStatus.resolved)
                .length,
            label: 'Resolved',
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Report Issue'),
            Tab(text: 'Issue Log'),
          ],
        ),
      ),
      body: RoleScaffoldBackground(
        accent: AppColors.roleLO,
        child: TabBarView(
              controller: _tabs,
              children: [
                // Tab 0 — form
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _IssueForm(
                    vips: widget.vips,
                    onSubmit: (issue) {
                      setState(() =>
                          _savedIssues.insert(0, issue));
                      _tabs.animateTo(1);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                        content:
                        const Text('Issue reported'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                  ),
                ),

                // Tab 1 — log
                _savedIssues.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size:  52,
                          color: AppColors.success),
                      const SizedBox(height: 10),
                      Text('No issues reported',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _savedIssues.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (_, i) => _IssueCard(
                    issue:     _savedIssues[i],
                    onResolve: () => setState(() {
                      _savedIssues[i] = _savedIssues[i]
                          .copyWith(
                          status:
                          IssueStatus.resolved);
                    }),
                    onEscalate: () => setState(() {
                      _savedIssues[i] = _savedIssues[i]
                          .copyWith(
                          priority:
                          IssuePriority.critical);
                    }),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ISSUE FORM (shared by sheet + page)
// ═══════════════════════════════════════════════════════════════

class _IssueForm extends StatefulWidget {
  final List<VIP>           vips;
  final ValueChanged<LoIssue> onSubmit;
  final VIP?                preselectedVip;

  const _IssueForm({
    required this.vips,
    required this.onSubmit,
    this.preselectedVip,
  });

  @override
  State<_IssueForm> createState() => _IssueFormState();
}

class _IssueFormState extends State<_IssueForm> {
  final _titleCtrl   = TextEditingController();
  final _detailCtrl  = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  IssueCategory _category  = IssueCategory.transport;
  IssuePriority _priority  = IssuePriority.medium;
  VIP?          _selectedVip;

  @override
  void initState() {
    super.initState();
    _selectedVip = widget.preselectedVip ??
        (widget.vips.isNotEmpty ? widget.vips.first : null);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── VIP selector ──────────────────────────────────
          if (widget.vips.isNotEmpty) ...[
            _FieldLabel('Related Delegate'),
            const SizedBox(height: 6),
            DropdownButtonFormField<VIP>(
              value: _selectedVip,
              decoration: _inputDeco(
                  prefixIcon: Icons.person),
              items: [
                const DropdownMenuItem<VIP>(
                  value: null,
                  child: Text('General (no delegate)'),
                ),
                ...widget.vips.map((v) =>
                    DropdownMenuItem(
                      value: v,
                      child: Text(v.name),
                    )),
              ],
              onChanged: (v) =>
                  setState(() => _selectedVip = v),
            ),
            const SizedBox(height: 14),
          ],

          // ── Category ──────────────────────────────────────
          _FieldLabel('Issue Category'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: IssueCategory.values.map((c) {
              final active = _category == c;
              return GestureDetector(
                onTap: () =>
                    setState(() => _category = c),
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: active
                        ? _catColor(c).withValues(alpha: 0.12)
                        : AppColors.inputFill(isDark),
                    borderRadius:
                    BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? _catColor(c)
                          : context.semantic.border,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_catIcon(c),
                          size:  13,
                          color: active
                              ? _catColor(c)
                              : muted),
                      const SizedBox(width: 5),
                      Text(_catLabel(c),
                          style: TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? _catColor(c)
                                  : muted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // ── Priority ──────────────────────────────────────
          _FieldLabel('Priority'),
          const SizedBox(height: 6),
          Row(
            children: IssuePriority.values.map((p) {
              final active = _priority == p;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: active
                            ? _priColor(p)
                            .withValues(alpha: 0.1)
                            : AppColors.inputFill(isDark),
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                            color: active
                                ? _priColor(p)
                                : context.semantic.border,
                            width: active ? 1.5 : 1),
                      ),
                      child: Column(children: [
                        Icon(_priIcon(p),
                            size:  16,
                            color: active
                                ? _priColor(p)
                                : muted),
                        const SizedBox(height: 3),
                        Text(_priLabel(p),
                            style: TextStyle(
                                fontSize:   9,
                                fontWeight: FontWeight.bold,
                                color: active
                                    ? _priColor(p)
                                    : muted)),
                      ]),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // ── Title ─────────────────────────────────────────
          _FieldLabel('Issue Title'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleCtrl,
            decoration: _inputDeco(
              hint:       'Brief description of the issue',
              prefixIcon: Icons.title,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter a title'
                : null,
          ),

          const SizedBox(height: 14),

          // ── Details ───────────────────────────────────────
          _FieldLabel('Details'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _detailCtrl,
            maxLines:   4,
            decoration: _inputDeco(
              hint: 'Provide full context — what happened, '
                  'when, who is affected and what action '
                  'is needed.',
              prefixIcon: Icons.description,
            ),
          ),

          const SizedBox(height: 20),

          // ── Submit ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon:  const Icon(Icons.send, size: 16),
              label: const Text('Submit Issue Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                HapticFeedback.mediumImpact();
                final issue = LoIssue(
                  id:          DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(),
                  title:       _titleCtrl.text.trim(),
                  details:     _detailCtrl.text.trim(),
                  category:    _category,
                  priority:    _priority,
                  status:      IssueStatus.open,
                  relatedVip:  _selectedVip?.name,
                  reportedAt:  DateTime.now(),
                );
                widget.onSubmit(issue);
                _titleCtrl.clear();
                _detailCtrl.clear();
                setState(() {
                  _category = IssueCategory.transport;
                  _priority = IssuePriority.medium;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({
    String? hint,
    required IconData prefixIcon,
  }) =>
      InputDecoration(
        hintText:     hint,
        prefixIcon:   Icon(prefixIcon,
            size: 18, color: context.semantic.textSecondary),
        filled:       true,
        fillColor:    context.semantic.inputFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            BorderSide(color: AppColors.inputBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            BorderSide(color: context.semantic.accent, width: 2)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        hintStyle: TextStyle(
            color: context.semantic.textMuted, fontSize: 13),
      );
}

// ═══════════════════════════════════════════════════════════════
// ISSUE CARD
// ═══════════════════════════════════════════════════════════════

class _IssueCard extends StatelessWidget {
  final LoIssue       issue;
  final VoidCallback  onResolve;
  final VoidCallback  onEscalate;

  const _IssueCard({
    required this.issue,
    required this.onResolve,
    required this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolved =
        issue.status == IssueStatus.resolved;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surfaceCard(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: resolved
              ? AppColors.success.withValues(alpha: 0.2)
              : _priColor(issue.priority)
              .withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(children: [
            // Category icon
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color:        _catColor(issue.category)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_catIcon(issue.category),
                  size:  14,
                  color: _catColor(issue.category)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(issue.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize:   13,
                      decoration: resolved
                          ? TextDecoration.lineThrough
                          : null,
                      color: resolved
                          ? context.semantic.textMuted
                          : null)),
            ),
            // Priority badge
            _PriorityBadge(priority: issue.priority),
          ]),

          if (issue.relatedVip != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.person,
                  size: 11, color: context.semantic.textMuted),
              const SizedBox(width: 4),
              Text(issue.relatedVip!,
                  style: TextStyle(
                      fontSize: 11,
                      color:    context.semantic.textMuted)),
            ]),
          ],

          if (issue.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(issue.details,
                maxLines:  2,
                overflow:  TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    color:    context.semantic.textSecondary)),
          ],

          const SizedBox(height: 10),

          // Footer
          Row(children: [
            Text(_fmtDate(issue.reportedAt),
                style: TextStyle(
                    fontSize: 10,
                    color:    context.semantic.border)),
            const Spacer(),
            if (!resolved) ...[
              _ActionBtn(
                label: 'Escalate',
                color: AppColors.warning,
                icon:  Icons.arrow_upward,
                onTap: onEscalate,
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                label: 'Resolve',
                color: AppColors.success,
                icon:  Icons.check,
                onTap: onResolve,
              ),
            ] else
              const _ResolvedBadge(),
          ]),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} · $h:$mi';
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM SHEET WRAPPER
// ═══════════════════════════════════════════════════════════════

class _IssueFormSheet extends StatefulWidget {
  final List<VIP> vips;
  final VIP?      preselectedVip;

  const _IssueFormSheet(
      {required this.vips, this.preselectedVip});

  @override
  State<_IssueFormSheet> createState() =>
      _IssueFormSheetState();
}

class _IssueFormSheetState
    extends State<_IssueFormSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left:   20,
        right:  20,
        top:    20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color:        context.semantic.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        AppColors.danger
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.report_problem,
                    color: AppColors.danger, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Report an Issue',
                      style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.bold)),
                  Text('Coordination / protocol / logistics',
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ],
              ),
            ]),
            const SizedBox(height: 20),
            _IssueForm(
              vips:           widget.vips,
              preselectedVip: widget.preselectedVip,
              onSubmit: (issue) {
                _savedIssues.insert(0, issue);
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(
                  content:
                  Text('Issue "${issue.title}" reported'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════

class _IssueStat extends StatelessWidget {
  final int    count;
  final String label;
  final Color  color;
  const _IssueStat(
      {required this.count,
        required this.label,
        required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color:        color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$count',
          style: TextStyle(
              color:      color,
              fontWeight: FontWeight.bold,
              fontSize:   13)),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              color:   color.withValues(alpha: 0.7),
              fontSize: 10)),
    ]),
  );
}

class _PriorityBadge extends StatelessWidget {
  final IssuePriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color:        _priColor(priority).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
          color: _priColor(priority).withValues(alpha: 0.4)),
    ),
    child: Text(_priLabel(priority),
        style: TextStyle(
            fontSize:   9,
            fontWeight: FontWeight.bold,
            color:      _priColor(priority))),
  );
}

class _ActionBtn extends StatelessWidget {
  final String       label;
  final Color        color;
  final IconData     icon;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize:   10,
                fontWeight: FontWeight.bold,
                color:      color)),
      ]),
    ),
  );
}

class _ResolvedBadge extends StatelessWidget {
  const _ResolvedBadge();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.check_circle,
          size: 13, color: AppColors.success),
      const SizedBox(width: 4),
      const Text('Resolved',
          style: TextStyle(
              fontSize:   10,
              fontWeight: FontWeight.bold,
              color:      AppColors.success)),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.bold,
          color:      context.semantic.accent));
}

// ═══════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════

enum IssueCategory {
  transport, accommodation, protocol,
  catering, communication, security, other
}

enum IssuePriority { low, medium, high, critical }
enum IssueStatus   { open, inProgress, resolved }

class LoIssue {
  final String        id;
  final String        title;
  final String        details;
  final IssueCategory category;
  final IssuePriority priority;
  final IssueStatus   status;
  final String?       relatedVip;
  final DateTime      reportedAt;

  const LoIssue({
    required this.id,
    required this.title,
    required this.details,
    required this.category,
    required this.priority,
    required this.status,
    this.relatedVip,
    required this.reportedAt,
  });

  LoIssue copyWith({
    IssueStatus? status,
    IssuePriority? priority,
  }) =>
      LoIssue(
        id:         id,
        title:      title,
        details:    details,
        category:   category,
        priority:   priority ?? this.priority,
        status:     status   ?? this.status,
        relatedVip: relatedVip,
        reportedAt: reportedAt,
      );
}

// ═══════════════════════════════════════════════════════════════
// UTILITY
// ═══════════════════════════════════════════════════════════════

Color _catColor(IssueCategory c) => switch (c) {
  IssueCategory.transport     => AppColors.sky,
  IssueCategory.accommodation => AppColors.roleDelegate,
  IssueCategory.protocol      => AppColors.gold,
  IssueCategory.catering      => AppColors.warning,
  IssueCategory.communication => AppColors.roleLO,
  IssueCategory.security      => AppColors.danger,
  IssueCategory.other         => Colors.grey,
};

IconData _catIcon(IssueCategory c) => switch (c) {
  IssueCategory.transport     => Icons.directions_car,
  IssueCategory.accommodation => Icons.hotel,
  IssueCategory.protocol      => Icons.military_tech,
  IssueCategory.catering      => Icons.restaurant,
  IssueCategory.communication => Icons.chat,
  IssueCategory.security      => Icons.security,
  IssueCategory.other         => Icons.more_horiz,
};

String _catLabel(IssueCategory c) => switch (c) {
  IssueCategory.transport     => 'Transport',
  IssueCategory.accommodation => 'Hotel',
  IssueCategory.protocol      => 'Protocol',
  IssueCategory.catering      => 'Catering',
  IssueCategory.communication => 'Comms',
  IssueCategory.security      => 'Security',
  IssueCategory.other         => 'Other',
};

Color _priColor(IssuePriority p) => switch (p) {
  IssuePriority.low      => Colors.grey,
  IssuePriority.medium   => AppColors.warning,
  IssuePriority.high     => AppColors.warning,
  IssuePriority.critical => AppColors.danger,
};

IconData _priIcon(IssuePriority p) => switch (p) {
  IssuePriority.low      => Icons.arrow_downward,
  IssuePriority.medium   => Icons.remove,
  IssuePriority.high     => Icons.arrow_upward,
  IssuePriority.critical => Icons.priority_high,
};

String _priLabel(IssuePriority p) => switch (p) {
  IssuePriority.low      => 'Low',
  IssuePriority.medium   => 'Medium',
  IssuePriority.high     => 'High',
  IssuePriority.critical => 'Critical',
};