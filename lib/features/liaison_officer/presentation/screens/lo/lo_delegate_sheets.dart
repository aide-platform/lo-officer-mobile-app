import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/utils/lo_contact_actions.dart';
import 'package:liaison_officer/core/utils/lo_display_format.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Modal bottom sheets that mirror the four action icons on aide-ui's
/// `MyLoDelegatesPage`:
///   * [openDelegateViewSheet]        — Eye icon: read-only profile + family.
///   * [openDelegateNominationsSheet] — CalendarClock icon: event nominations.
///   * [openDelegateVehiclesSheet]    — Car icon: vehicle allocations.
///
/// The fourth (travel edit) stays on `LoTravelEditor.open` because it is a
/// write surface and already matches aide-ui's travel dialog.

Future<void> openDelegateViewSheet(
  BuildContext context,
  MyLoAssignmentDto delegate,
) {
  return _showSheet(
    context: context,
    builder: (ctx) => _DelegateViewSheet(delegate: delegate),
  );
}

Future<void> openDelegateNominationsSheet(
  BuildContext context,
  MyLoAssignmentDto delegate,
) {
  final bloc = context.read<LoPortalBloc>();
  final id = delegate.assignmentId;
  if (id != null) bloc.add(LoPortalDelegateExtrasRequested(id));
  return _showSheet(
    context: context,
    builder: (ctx) => BlocProvider.value(
      value: bloc,
      child: _DelegateNominationsSheet(delegate: delegate),
    ),
  );
}

Future<void> openDelegateVehiclesSheet(
  BuildContext context,
  MyLoAssignmentDto delegate,
) {
  final bloc = context.read<LoPortalBloc>();
  final id = delegate.assignmentId;
  if (id != null) bloc.add(LoPortalDelegateExtrasRequested(id));
  return _showSheet(
    context: context,
    builder: (ctx) => BlocProvider.value(
      value: bloc,
      child: _DelegateVehiclesSheet(delegate: delegate),
    ),
  );
}

Future<void> _showSheet({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) =>
          _SheetShell(scrollController: scrollController, child: builder(ctx)),
    ),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.scrollController, required this.child});
  final ScrollController scrollController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: PrimaryScrollController(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          child: child,
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _CircleIcon(icon: icon, size: 44),
          const SizedBox(width: 12),
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
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (count != null && count! > 0) ...[
                      const SizedBox(width: 8),
                      _CountBadge(count: count!),
                    ],
                  ],
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: colors.accent.withValues(alpha: 0.1),
              foregroundColor: colors.textPrimary,
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

// ─── Eye icon ────────────────────────────────────────────────────────────
class _DelegateViewSheet extends StatelessWidget {
  const _DelegateViewSheet({required this.delegate});
  final MyLoAssignmentDto delegate;

  @override
  Widget build(BuildContext context) {
    final d = delegate;
    final colors = context.semantic;
    final name = (d.fullName ?? '').trim().isEmpty ? 'Delegate' : d.fullName!;
    final hasEmail = (d.email ?? '').trim().isNotEmpty;
    final hasPhone = LoContactActions.normalizePhone(d.mobileNumber) != null;
    final arrival = LoDisplayFormat.dateAndTime(d.arrivalDate, d.arrivalTime);
    final departure = LoDisplayFormat.dateAndTime(
      d.departureDate,
      d.departureTime,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetHeader(
          icon: Icons.visibility_outlined,
          title: 'Delegate Details',
        ),
        _Section(
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.accent.withValues(alpha: 0.12),
                ),
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [d.salutation, name]
                          .whereType<String>()
                          .where((s) => s.trim().isNotEmpty)
                          .join(' '),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    if ((d.designation ?? '').trim().isNotEmpty)
                      Text(
                        d.designation!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (hasEmail || hasPhone) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasEmail)
                Expanded(
                  child: _ContactAction(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    onTap: () => LoContactActions.email(d.email),
                  ),
                ),
              if (hasPhone) ...[
                Expanded(
                  child: _ContactAction(
                    icon: Icons.call_outlined,
                    label: 'Call',
                    onTap: () => LoContactActions.call(d.mobileNumber),
                  ),
                ),
                Expanded(
                  child: _ContactAction(
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp',
                    onTap: () => LoContactActions.whatsApp(d.mobileNumber),
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 12),
        _Section(
          title: 'Personal',
          icon: Icons.person_outline,
          child: _KvGrid(
            entries: [
              ('Full Name', d.fullName),
              ('Designation', d.designation),
              ('Organisation', d.organisation),
              ('Country', d.countryName),
              ('Protocol / Category', d.protocolEquiv ?? d.vipCategory),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Contact',
          icon: Icons.contact_phone_outlined,
          child: _KvGrid(
            entries: [('Email', d.email), ('Mobile', d.mobileNumber)],
            emptyText: 'No contact details.',
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Travel',
          icon: Icons.flight_outlined,
          child: Column(
            spacing: 8,
            children: [
              _TravelRow(
                icon: Icons.flight_land_rounded,
                label: 'Arrival',
                when: arrival,
                flight: _joinFlight(d.arrivalFlight, d.arrivalTerminal),
              ),
              _TravelRow(
                icon: Icons.flight_takeoff_rounded,
                label: 'Departure',
                when: departure,
                flight: _joinFlight(d.departureFlight, d.departureTerminal),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Family Members',
          icon: Icons.group_outlined,
          count: d.family.length,
          child: d.family.isEmpty
              ? Text(
                  'No family members recorded.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Column(
                  spacing: 8,
                  children: [for (final f in d.family) _FamilyCard(member: f)],
                ),
        ),
      ],
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.member});
  final MyLoFamilyDto member;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final f = member;
    final name = [
      f.salutation,
      f.fullName,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
    return _ItemCard(
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? '—' : name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if ((f.relation ?? '').trim().isNotEmpty)
                Flexible(
                  child: _Pill(label: f.relation!, color: colors.accent),
                ),
            ],
          ),
          const SizedBox(height: 6),
          _MetaLine(icon: Icons.wc_outlined, text: f.gender),
          _MetaLine(
            icon: Icons.badge_outlined,
            text: [
              if ((f.passportNumber ?? '').trim().isNotEmpty)
                'Passport ${f.passportNumber}',
              if ((f.passportValidity ?? '').trim().isNotEmpty)
                'valid till ${f.passportValidity}',
            ].join(' · '),
          ),
        ],
      ),
    );
  }
}

// ─── CalendarClock icon ──────────────────────────────────────────────────
class _DelegateNominationsSheet extends StatelessWidget {
  const _DelegateNominationsSheet({required this.delegate});
  final MyLoAssignmentDto delegate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        final colors = context.semantic;
        final id = delegate.assignmentId;
        final rows = id == null
            ? const <Map<String, dynamic>>[]
            : state.nominationsByAssignment[id] ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              icon: Icons.calendar_month_outlined,
              title: 'Event Nominations',
              subtitle: delegate.fullName,
              count: rows.length,
            ),
            if (rows.isEmpty)
              const _EmptyBlock(
                icon: Icons.event_note_outlined,
                message: 'No event nominations yet.',
              )
            else
              Column(
                spacing: 10,
                children: [
                  for (final n in rows)
                    _ItemCard(
                      icon: Icons.event_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n['eventName']?.toString() ?? '—',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _MetaLine(
                            icon: Icons.calendar_today_outlined,
                            text:
                                [
                                      n['eventDate']?.toString(),
                                      _hhmm(n['eventTime']?.toString()),
                                    ]
                                    .whereType<String>()
                                    .where((s) => s.isNotEmpty && s != '—')
                                    .join(' · '),
                          ),
                          _MetaLine(
                            icon: Icons.place_outlined,
                            text: n['venue']?.toString(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

// ─── Car icon ────────────────────────────────────────────────────────────
class _DelegateVehiclesSheet extends StatelessWidget {
  const _DelegateVehiclesSheet({required this.delegate});
  final MyLoAssignmentDto delegate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        final id = delegate.assignmentId;
        final rows = id == null
            ? const <Map<String, dynamic>>[]
            : state.vehiclesByAssignment[id] ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              icon: Icons.directions_car_outlined,
              title: 'Vehicles / Transport',
              subtitle: delegate.fullName,
              count: rows.length,
            ),
            if (rows.isEmpty)
              const _EmptyBlock(
                icon: Icons.directions_car_outlined,
                message: 'No vehicle allocations yet.',
              )
            else
              Column(
                spacing: 10,
                children: [for (final v in rows) _VehicleCard(vehicle: v)],
              ),
          ],
        );
      },
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});
  final Map<String, dynamic> vehicle;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final v = vehicle;
    final type = v['vehicleType']?.toString();
    final number = (v['vehicleNumber']?.toString() ?? '').trim();
    final category = (v['vehicleCategoryName']?.toString() ?? '').trim();
    final driver = v['driverName']?.toString();
    final phone = (v['driverPhone'] ?? v['driverContact'])?.toString();
    final canCall = LoContactActions.normalizePhone(phone) != null;
    return _ItemCard(
      icon: Icons.directions_car_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (type ?? '').trim().isEmpty ? 'Vehicle' : type!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (category.isNotEmpty)
                Flexible(child: _Pill(label: category, color: colors.accent)),
            ],
          ),
          if (number.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.textPrimary, width: 1.2),
              ),
              child: Text(
                number.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetaLine(icon: Icons.person_outline, text: driver),
                    _MetaLine(icon: Icons.phone_outlined, text: phone),
                    _MetaLine(
                      icon: Icons.notes_rounded,
                      text: v['remarks']?.toString(),
                    ),
                  ],
                ),
              ),
              if (canCall)
                IconButton.filled(
                  tooltip: 'Call ${driver ?? 'driver'}',
                  onPressed: () => LoContactActions.call(phone),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.indiaGreen,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.call_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared bits ─────────────────────────────────────────────────────────
class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, this.size = 36});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = context.semantic.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.1),
      ),
      child: Icon(icon, size: size * 0.5, color: accent),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: context.semantic.accent,
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
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Rounded tinted block used for each section of a sheet.
class _Section extends StatelessWidget {
  const _Section({required this.child, this.title, this.icon, this.count});
  final Widget child;
  final String? title;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  _CircleIcon(icon: icon!, size: 30),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: 8),
                  _CountBadge(count: count!),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// White card with a leading circle icon, used for list items.
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.icon, required this.child});
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CircleIcon(icon: icon, size: 40),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});
  final IconData icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final v = (text ?? '').trim();
    if (v.isEmpty) return const SizedBox.shrink();
    final colors = context.semantic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: colors.textMuted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              v,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CircleIcon(icon: icon, size: 44),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelRow extends StatelessWidget {
  const _TravelRow({
    required this.icon,
    required this.label,
    required this.when,
    required this.flight,
  });
  final IconData icon;
  final String label;
  final String when;
  final String flight;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                Text(
                  when.isEmpty ? '—' : when,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (flight.isNotEmpty)
            Flexible(
              child: _Pill(label: flight, color: colors.accent),
            ),
        ],
      ),
    );
  }
}

class _KvGrid extends StatelessWidget {
  const _KvGrid({required this.entries, this.emptyText});
  final List<(String, String?)> entries;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final visible = entries
        .where((e) => (e.$2 ?? '').trim().isNotEmpty)
        .toList(growable: false);
    if (visible.isEmpty) {
      return Text(
        emptyText ?? '—',
        style: TextStyle(color: colors.textSecondary),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final twoCol = c.maxWidth >= 300;
        final colW = twoCol ? (c.maxWidth - 16) / 2 : c.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final e in visible)
              SizedBox(
                width: colW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.$1.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.6,
                        color: colors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.$2!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          _CircleIcon(icon: icon, size: 64),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .take(2)
      .map((s) => s[0].toUpperCase())
      .join();
  return parts.isEmpty ? '?' : parts;
}

String _joinFlight(String? flight, String? terminal) {
  final f = (flight ?? '').trim();
  final t = (terminal ?? '').trim();
  if (f.isEmpty && t.isEmpty) return '';
  if (t.isEmpty) return f;
  if (f.isEmpty) return 'T$t';
  return '$f · T$t';
}

String _hhmm(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return '—';
  if (v.length >= 5) return v.substring(0, 5);
  return v;
}
