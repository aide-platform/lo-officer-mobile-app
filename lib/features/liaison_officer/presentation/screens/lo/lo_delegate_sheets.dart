import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/utils/lo_contact_actions.dart';
import 'package:liaison_officer/core/utils/lo_display_format.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';

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
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => _SheetShell(
        scrollController: scrollController,
        child: builder(ctx),
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
  const _SheetHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 12),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetHeader(title: 'Delegate Details', subtitle: d.fullName),
        _KvGrid(entries: [
          ('Salutation', d.salutation),
          ('Full Name', d.fullName),
          ('Designation', d.designation),
          ('Organisation', d.organisation),
          ('Country', d.countryName),
          ('Protocol / Category', d.protocolEquiv ?? d.vipCategory),
          ('Email', d.email),
          ('Mobile', d.mobileNumber),
          ('Arrival', LoDisplayFormat.dateAndTime(d.arrivalDate, d.arrivalTime)),
          ('Arrival Flight', _joinFlight(d.arrivalFlight, d.arrivalTerminal)),
          ('Departure',
              LoDisplayFormat.dateAndTime(d.departureDate, d.departureTime)),
          ('Departure Flight',
              _joinFlight(d.departureFlight, d.departureTerminal)),
        ]),
        if ((d.email ?? '').trim().isNotEmpty ||
            LoContactActions.normalizePhone(d.mobileNumber) != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if ((d.email ?? '').trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => LoContactActions.email(d.email),
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Email'),
                ),
              if (LoContactActions.normalizePhone(d.mobileNumber) != null) ...[
                OutlinedButton.icon(
                  onPressed: () => LoContactActions.call(d.mobileNumber),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text('Call'),
                ),
                OutlinedButton.icon(
                  onPressed: () => LoContactActions.whatsApp(d.mobileNumber),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('WhatsApp'),
                ),
              ],
            ],
          ),
        ],
        const Divider(height: 32),
        _FamilyPanel(family: d.family),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }
}

class _FamilyPanel extends StatelessWidget {
  const _FamilyPanel({required this.family});
  final List<MyLoFamilyDto> family;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (family.isEmpty) {
      return Row(
        children: [
          Icon(Icons.group_outlined, size: 16, color: muted),
          const SizedBox(width: 6),
          Text('No family members recorded.',
              style: TextStyle(color: muted, fontStyle: FontStyle.italic)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.group_outlined, size: 16, color: muted),
            const SizedBox(width: 6),
            Text(
              'Family Members (${family.length})',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ScrollableDataTable(
          columns: const ['Salutation', 'Name', 'Gender', 'Relation', 'Passport #', 'Passport Validity'],
          rows: [
            for (final f in family)
              [
                f.salutation ?? '—',
                f.fullName ?? '—',
                f.gender ?? '—',
                f.relation ?? '—',
                f.passportNumber ?? '—',
                f.passportValidity ?? '—',
              ],
          ],
        ),
      ],
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
        final id = delegate.assignmentId;
        final rows = id == null
            ? const <Map<String, dynamic>>[]
            : state.nominationsByAssignment[id] ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(
              title: 'Event Nominations',
              subtitle: delegate.fullName,
            ),
            if (rows.isEmpty)
              _EmptyBlock(
                icon: Icons.event_note_outlined,
                message: 'No event nominations yet.',
              )
            else
              _ScrollableDataTable(
                columns: const ['Event Name', 'Date', 'Time', 'Venue'],
                rows: [
                  for (final n in rows)
                    [
                      n['eventName']?.toString() ?? '—',
                      n['eventDate']?.toString() ?? '—',
                      _hhmm(n['eventTime']?.toString()),
                      n['venue']?.toString() ?? '—',
                    ],
                ],
              ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(
              title: 'Vehicles / Transport',
              subtitle: delegate.fullName,
            ),
            if (rows.isEmpty)
              _EmptyBlock(
                icon: Icons.directions_car_outlined,
                message: 'No vehicle allocations yet.',
              )
            else
              _ScrollableDataTable(
                columns: const [
                  'Category',
                  'Vehicle Type',
                  'Vehicle Number',
                  'Driver Name',
                  'Driver Contact',
                  'Remarks',
                ],
                rows: [
                  for (final v in rows)
                    [
                      v['vehicleCategoryName']?.toString() ?? '—',
                      v['vehicleType']?.toString() ?? '—',
                      v['vehicleNumber']?.toString() ?? '—',
                      v['driverName']?.toString() ?? '—',
                      (v['driverPhone'] ?? v['driverContact'])?.toString() ?? '—',
                      v['remarks']?.toString() ?? '—',
                    ],
                ],
              ),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in rows)
                    if (LoContactActions.normalizePhone(
                            (v['driverPhone'] ?? v['driverContact'])
                                ?.toString()) !=
                        null)
                      OutlinedButton.icon(
                        onPressed: () => LoContactActions.call(
                            (v['driverPhone'] ?? v['driverContact'])
                                ?.toString()),
                        icon: const Icon(Icons.call_outlined, size: 16),
                        label: Text(
                          'Call ${v['driverName']?.toString() ?? 'driver'}',
                        ),
                      ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Shared bits ─────────────────────────────────────────────────────────
class _KvGrid extends StatelessWidget {
  const _KvGrid({required this.entries});
  final List<(String, String?)> entries;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final visible = entries
        .where((e) => (e.$2 ?? '').trim().isNotEmpty)
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, c) {
        final twoCol = c.maxWidth >= 420;
        final colW = twoCol ? (c.maxWidth / 2) - 8 : c.maxWidth;
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
                        color: muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.$2!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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

class _ScrollableDataTable extends StatelessWidget {
  const _ScrollableDataTable({required this.columns, required this.rows});
  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.fromBorderSide(border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 36,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 72,
            columnSpacing: 20,
            horizontalMargin: 12,
            columns: [
              for (final c in columns)
                DataColumn(
                  label: Text(
                    c,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
            rows: [
              for (final r in rows)
                DataRow(
                  cells: [
                    for (final v in r)
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(
                            v,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: muted),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: muted)),
          ],
        ),
      ),
    );
  }
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
