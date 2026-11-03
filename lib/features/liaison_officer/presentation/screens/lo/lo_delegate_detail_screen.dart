import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';
import 'package:liaison_officer/core/services/lo_monitoring_events.dart';
import 'package:liaison_officer/core/utils/lo_contact_actions.dart';
import 'package:liaison_officer/core/utils/lo_display_format.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_itinerary.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_movement.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_travel_editor.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// Optional section to scroll into view when opening delegate detail.
enum LoDelegateFocusSection { profile, itinerary, transport, travel }

class LoDelegateDetailScreen extends StatefulWidget {
  const LoDelegateDetailScreen({
    super.key,
    required this.delegate,
    this.focusSection,
  });

  final MyLoAssignmentDto delegate;
  final LoDelegateFocusSection? focusSection;

  @override
  State<LoDelegateDetailScreen> createState() => _LoDelegateDetailScreenState();
}

class _LoDelegateDetailScreenState extends State<LoDelegateDetailScreen> {
  final _itineraryKey = GlobalKey();
  final _transportKey = GlobalKey();
  final _travelKey = GlobalKey();
  bool _didScrollToFocus = false;

  MyLoAssignmentDto get delegate => widget.delegate;

  @override
  void initState() {
    super.initState();
    LoFirebaseMonitor.instance.logFeature(
      LoMonitoringEvents.featureDelegateDetail,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleFocusScroll();
  }

  void _scheduleFocusScroll() {
    final focus = widget.focusSection;
    if (_didScrollToFocus || focus == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didScrollToFocus) return;
      final key = switch (focus) {
        LoDelegateFocusSection.itinerary => _itineraryKey,
        LoDelegateFocusSection.transport => _transportKey,
        LoDelegateFocusSection.travel => _travelKey,
        LoDelegateFocusSection.profile => null,
      };
      final ctx = key?.currentContext;
      if (ctx != null) {
        _didScrollToFocus = true;
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignmentId = delegate.assignmentId;
    return Scaffold(
      appBar: AppBar(title: Text(delegate.fullName ?? 'Delegate')),
      body: BlocBuilder<LoPortalBloc, LoPortalState>(
        builder: (context, state) {
          _scheduleFocusScroll();
          final live = () {
            if (assignmentId == null) return delegate;
            for (final e in state.delegates) {
              if (e.assignmentId == assignmentId) return e;
            }
            return delegate;
          }();
          final arrivalConnecting = assignmentId == null
              ? const <ConnectingFlightDraft>[]
              : state.arrivalConnectingByAssignment[assignmentId] ?? const [];
          final departureConnecting = assignmentId == null
              ? const <ConnectingFlightDraft>[]
              : state.departureConnectingByAssignment[assignmentId] ?? const [];
          final vehicles = assignmentId == null
              ? const <Map<String, dynamic>>[]
              : state.vehiclesByAssignment[assignmentId] ?? const [];
          final nominations = assignmentId == null
              ? const <Map<String, dynamic>>[]
              : state.nominationsByAssignment[assignmentId] ?? const [];
          final itinerary = assignmentId == null
              ? LoItineraryItem.compose(
                  assignment: live,
                  nominations: nominations,
                  vehicles: vehicles,
                )
              : state.itineraryByAssignment[assignmentId] ??
                    LoItineraryItem.compose(
                      assignment: live,
                      nominations: nominations,
                      vehicles: vehicles,
                    );
          final colors = context.semantic;
          final hasEmail = _hasContact(live.email);
          final hasPhone =
              LoContactActions.normalizePhone(live.mobileNumber) != null;

          return RefreshIndicator(
            onRefresh: () async {
              if (assignmentId != null) {
                context.read<LoPortalBloc>().add(
                  LoPortalDelegateExtrasRequested(assignmentId),
                );
              }
              await refreshPortal(context);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _ProfileHeader(delegate: live),
                if (hasEmail || hasPhone) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (hasEmail)
                        Expanded(
                          child: _RoundAction(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            onTap: () => LoContactActions.email(live.email),
                          ),
                        ),
                      if (hasPhone) ...[
                        Expanded(
                          child: _RoundAction(
                            icon: Icons.call_outlined,
                            label: 'Call',
                            onTap: () =>
                                LoContactActions.call(live.mobileNumber),
                          ),
                        ),
                        Expanded(
                          child: _RoundAction(
                            icon: Icons.sms_outlined,
                            label: 'SMS',
                            onTap: () =>
                                LoContactActions.sms(live.mobileNumber),
                          ),
                        ),
                        Expanded(
                          child: _RoundAction(
                            icon: Icons.chat_outlined,
                            label: 'WhatsApp',
                            onTap: () =>
                                LoContactActions.whatsApp(live.mobileNumber),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _Section(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  child: _KvGrid(
                    entries: [
                      ('Designation', live.designation),
                      ('Organisation', live.organisation),
                      ('Ministry', live.ministry),
                      ('Gender', live.gender),
                      ('Protocol', live.protocolEquiv),
                      ('VIP category', live.vipCategory),
                      ('Country', live.countryName),
                      ('Email', live.email),
                      ('Mobile', live.mobileNumber),
                    ],
                  ),
                ),
                if (live.family.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Section(
                    icon: Icons.group_outlined,
                    title: 'Family',
                    count: live.family.length,
                    child: Column(
                      spacing: 8,
                      children: [
                        for (final f in live.family)
                          _ItemCard(
                            icon: Icons.person_outline,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.fullName ?? '—',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      if ((f.gender ?? '').trim().isNotEmpty)
                                        Text(
                                          f.gender!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if ((f.relation ?? '').trim().isNotEmpty)
                                  Flexible(
                                    child: _Pill(
                                      label: f.relation!,
                                      color: colors.accent,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: _itineraryKey,
                  child: _Section(
                    icon: Icons.route_outlined,
                    title: 'Itinerary',
                    count: itinerary.length,
                    child: itinerary.isEmpty
                        ? const _EmptyText('No itinerary items yet.')
                        : Column(
                            spacing: 8,
                            children: [
                              for (final item in itinerary)
                                _ItineraryTile(item: item),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: _transportKey,
                  child: _Section(
                    icon: Icons.directions_car_outlined,
                    title: 'Transport',
                    count: vehicles.length,
                    child: vehicles.isEmpty
                        ? const _EmptyText('No vehicles assigned.')
                        : Column(
                            spacing: 8,
                            children: [
                              for (final v in vehicles)
                                _TransportCard(vehicle: v),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: _travelKey,
                  child: _Section(
                    icon: Icons.flight_outlined,
                    title: 'Travel & movement',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: [
                        _TravelRow(
                          icon: Icons.flight_land_rounded,
                          label: 'Arrival',
                          when: LoDisplayFormat.dateAndTime(
                            live.arrivalDate,
                            live.arrivalTime,
                          ),
                          flight: live.arrivalFlight,
                          connecting: arrivalConnecting,
                        ),
                        _TravelRow(
                          icon: Icons.flight_takeoff_rounded,
                          label: 'Departure',
                          when: LoDisplayFormat.dateAndTime(
                            live.departureDate,
                            live.departureTime,
                          ),
                          flight: live.departureFlight,
                          connecting: departureConnecting,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                // Travel saves against the assignment; without
                                // one the sheet would save nothing.
                                onPressed: assignmentId == null
                                    ? null
                                    : () => LoTravelEditor.open(
                                        context,
                                        live,
                                        arrivalConnecting,
                                        departureConnecting,
                                      ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  side: BorderSide(color: colors.border),
                                  foregroundColor: colors.textPrimary,
                                ),
                                icon: const Icon(
                                  Icons.edit_calendar_outlined,
                                  size: 18,
                                ),
                                label: const Text('Update travel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: assignmentId == null
                                    ? null
                                    : () => _openMovementSheet(context, live),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.directions_walk_outlined,
                                  size: 18,
                                ),
                                label: const Text('Log movement'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _hasContact(String? v) => v != null && v.trim().isNotEmpty;

  Future<void> _openMovementSheet(
    BuildContext context,
    MyLoAssignmentDto d,
  ) async {
    var kind = LoMovementKind.arrival;
    final flight = TextEditingController(text: d.arrivalFlight ?? '');
    final terminal = TextEditingController(text: d.arrivalTerminal ?? '');
    final date = TextEditingController(
      text: LoDisplayFormat.date(d.arrivalDate),
    );
    final time = TextEditingController(
      text: LoDisplayFormat.time(d.arrivalTime),
    );
    final notes = TextEditingController();
    final location = TextEditingController();

    // Shown inside the sheet: a page snackbar would sit behind it.
    String? formError;
    bool validate() {
      if (kind == LoMovementKind.departure &&
          date.text.trim().isEmpty &&
          notes.text.trim().isEmpty) {
        formError = 'Departure needs a date or notes';
        return false;
      }
      formError = null;
      return true;
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final colors = ctx.semantic;
          final buttonShape = RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          );
          void selectKind(LoMovementKind v) {
            setLocal(() {
              kind = v;
              if (v == LoMovementKind.departure) {
                flight.text = d.departureFlight ?? '';
                terminal.text = d.departureTerminal ?? '';
                date.text = LoDisplayFormat.date(d.departureDate);
                time.text = LoDisplayFormat.time(d.departureTime);
              } else if (v == LoMovementKind.arrival) {
                flight.text = d.arrivalFlight ?? '';
                terminal.text = d.arrivalTerminal ?? '';
                date.text = LoDisplayFormat.date(d.arrivalDate);
                time.text = LoDisplayFormat.time(d.arrivalTime);
              }
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _CircleIcon(
                        icon: Icons.directions_walk_rounded,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delegate movement',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            if ((d.fullName ?? '').trim().isNotEmpty)
                              Text(
                                d.fullName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(ctx, false),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.accent.withValues(alpha: 0.1),
                          foregroundColor: colors.textPrimary,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Movement type',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3.2,
                    children: [
                      for (final k in LoMovementKind.values)
                        _KindChip(
                          kind: k,
                          selected: kind == k,
                          onTap: () => selectKind(k),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _pair(
                    TextField(
                      controller: flight,
                      decoration: const InputDecoration(
                        labelText: 'Flight (optional)',
                      ),
                    ),
                    TextField(
                      controller: terminal,
                      decoration: const InputDecoration(
                        labelText: 'Terminal / gate',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _pair(
                    _pickerField(ctx, date, 'Date', isDate: true),
                    _pickerField(ctx, time, 'Time', isDate: false),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: location,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    maxLines: 2,
                  ),
                  if (formError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      formError!,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: buttonShape,
                            foregroundColor: colors.textPrimary,
                            side: BorderSide(color: colors.border),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            if (validate()) {
                              Navigator.pop(ctx, true);
                            } else {
                              setLocal(() {});
                            }
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: buttonShape,
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Save movement'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (ok == true && context.mounted && d.assignmentId != null) {
      context.read<LoPortalBloc>().add(
        LoPortalMovementUpdated(
          assignmentId: d.assignmentId!,
          movement: LoMovementUpdate(
            kind: kind,
            flight: flight.text.trim().isEmpty ? null : flight.text.trim(),
            terminal: terminal.text.trim().isEmpty
                ? null
                : terminal.text.trim(),
            date: date.text.trim().isEmpty
                ? null
                : LoDisplayFormat.date(date.text.trim()),
            time: time.text.trim().isEmpty
                ? null
                : LoDisplayFormat.toApiTime(time.text.trim()),
            notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
            location: location.text.trim().isEmpty
                ? null
                : location.text.trim(),
          ),
        ),
      );
    }
    // The sheet's fields still read these during the close animation;
    // disposing now throws "used after being disposed".
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      flight.dispose();
      terminal.dispose();
      date.dispose();
      time.dispose();
      notes.dispose();
      location.dispose();
    });
  }

  static Widget _pair(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ],
    );
  }

  static Widget _pickerField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    required bool isDate,
  }) {
    Future<void> pick() async {
      if (isDate) {
        final first = DateTime(2020);
        final last = DateTime(2035);
        var initial = DateTime.tryParse(controller.text) ?? DateTime.now();
        // showDatePicker asserts when initialDate is outside the range.
        if (initial.isBefore(first)) initial = first;
        if (initial.isAfter(last)) initial = last;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: first,
          lastDate: last,
        );
        if (picked == null) return;
        final y = picked.year.toString().padLeft(4, '0');
        final m = picked.month.toString().padLeft(2, '0');
        final dd = picked.day.toString().padLeft(2, '0');
        controller.text = '$y-$m-$dd';
      } else {
        var initial = TimeOfDay.now();
        final parsed = LoDisplayFormat.tryParseTime(controller.text);
        if (parsed != null) {
          initial = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
        }
        if (!context.mounted) return;
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked == null) return;
        final h = picked.hour.toString().padLeft(2, '0');
        final m = picked.minute.toString().padLeft(2, '0');
        controller.text = LoDisplayFormat.time('$h:$m:00');
      }
    }

    return TextField(
      controller: controller,
      readOnly: true,
      onTap: pick,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(
          isDate ? Icons.calendar_today_outlined : Icons.access_time,
        ),
      ),
    );
  }
}

String _typeLabel(String? type) {
  final t = (type ?? '').toUpperCase();
  if (t.contains('FOREIGN') ||
      t.contains('INTL') ||
      t.contains('INTERNATIONAL')) {
    return 'Foreign';
  }
  if (t.contains('DOMESTIC') || t.contains('INDIA') || t.contains('NATIONAL')) {
    return 'Domestic';
  }
  return t.isEmpty ? '' : type!;
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.delegate});
  final MyLoAssignmentDto delegate;

  @override
  Widget build(BuildContext context) {
    final d = delegate;
    final colors = context.semantic;
    final accent = colors.accent;
    final name = (d.fullName ?? '').trim().isEmpty ? 'Delegate' : d.fullName!;
    final type = _typeLabel(d.delegateType);
    final typeColor = switch (type) {
      'Domestic' => AppTheme.indiaGreen,
      'Foreign' => AppTheme.saffron,
      _ => accent,
    };
    final countryCategory = [
      d.countryName,
      d.vipCategory,
    ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' · ');
    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: colors.surface, width: 2),
            ),
            child: Text(
              _initials(name),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                if ((d.designation ?? '').trim().isNotEmpty)
                  Text(
                    d.designation!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                if ((d.organisation ?? '').trim().isNotEmpty)
                  Text(
                    d.organisation!,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (type.isNotEmpty) _Pill(label: type, color: typeColor),
                    if (countryCategory.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 15,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              countryCategory,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.kind,
    required this.selected,
    required this.onTap,
  });
  final LoMovementKind kind;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (kind) {
    LoMovementKind.arrival => Icons.flight_land_rounded,
    LoMovementKind.transfer => Icons.swap_horiz_rounded,
    LoMovementKind.venueEntry => Icons.meeting_room_outlined,
    LoMovementKind.departure => Icons.flight_takeoff_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.12)
            : colors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? accent : colors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  _icon,
                  size: 20,
                  color: selected ? accent : colors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kind.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, size: 18, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItineraryTile extends StatelessWidget {
  const _ItineraryTile({required this.item});
  final LoItineraryItem item;

  IconData get _icon => switch (item.kind) {
    LoItineraryKind.arrival => Icons.flight_land,
    LoItineraryKind.departure => Icons.flight_takeoff,
    LoItineraryKind.transport => Icons.directions_car_outlined,
    LoItineraryKind.event => Icons.event_available_outlined,
  };

  String get _kindLabel => switch (item.kind) {
    LoItineraryKind.arrival => 'Arrival',
    LoItineraryKind.departure => 'Departure',
    LoItineraryKind.transport => 'Transport',
    LoItineraryKind.event => 'Event',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final venue = (item.venue ?? '').trim();
    final when = [
      if ((item.date ?? '').isNotEmpty) LoDisplayFormat.date(item.date),
      if ((item.time ?? '').isNotEmpty) LoDisplayFormat.time(item.time),
    ].join(' · ');
    return _ItemCard(
      icon: _icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Pill(label: _kindLabel, color: colors.accent),
            ],
          ),
          if ((item.subtitle ?? '').isNotEmpty)
            Text(
              item.subtitle!,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          const SizedBox(height: 4),
          _MetaLine(icon: Icons.calendar_today_outlined, text: when),
          _MetaLine(icon: Icons.place_outlined, text: venue),
          if (venue.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => LoContactActions.openMaps(venue),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Navigate'),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransportCard extends StatelessWidget {
  const _TransportCard({required this.vehicle});
  final Map<String, dynamic> vehicle;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final number = vehicle['vehicleNumber']?.toString() ?? '—';
    final type = vehicle['vehicleType']?.toString() ?? 'Vehicle';
    final driver = vehicle['driverName']?.toString();
    final contact = vehicle['driverContact']?.toString();
    final pickup =
        vehicle['pickupTime']?.toString() ??
        vehicle['pickupSchedule']?.toString() ??
        vehicle['schedule']?.toString();
    final pickupLoc =
        vehicle['pickupLocation']?.toString() ??
        vehicle['location']?.toString() ??
        vehicle['pickupPoint']?.toString();
    final phoneOk = LoContactActions.normalizePhone(contact) != null;
    final mapsQuery = (pickupLoc ?? '').trim().isNotEmpty
        ? pickupLoc
        : (number != '—' ? 'Vehicle $number pickup' : null);
    final hasMaps = (mapsQuery ?? '').trim().isNotEmpty;

    return _ItemCard(
      icon: Icons.directions_car_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          if (number != '—') ...[
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
          _MetaLine(icon: Icons.person_outline, text: driver),
          _MetaLine(icon: Icons.phone_outlined, text: contact),
          _MetaLine(
            icon: Icons.schedule_outlined,
            text: (pickup ?? '').isEmpty
                ? null
                : 'Pickup: ${LoDisplayFormat.when(pickup)}',
          ),
          _MetaLine(icon: Icons.place_outlined, text: pickupLoc),
          if (phoneOk || hasMaps) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (phoneOk) ...[
                  Expanded(
                    child: _RoundAction(
                      icon: Icons.call_outlined,
                      label: 'Call',
                      size: 38,
                      onTap: () => LoContactActions.call(contact),
                    ),
                  ),
                  Expanded(
                    child: _RoundAction(
                      icon: Icons.sms_outlined,
                      label: 'SMS',
                      size: 38,
                      onTap: () => LoContactActions.sms(
                        contact,
                        body: 'Hello, regarding pickup for Aero India.',
                      ),
                    ),
                  ),
                  Expanded(
                    child: _RoundAction(
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp',
                      size: 38,
                      onTap: () => LoContactActions.whatsApp(
                        contact,
                        text: 'Hello, regarding pickup for Aero India.',
                      ),
                    ),
                  ),
                ],
                if (hasMaps)
                  Expanded(
                    child: _RoundAction(
                      icon: Icons.map_outlined,
                      label: 'Navigate',
                      size: 38,
                      onTap: () => LoContactActions.openMaps(mapsQuery),
                    ),
                  ),
              ],
            ),
          ],
        ],
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
    required this.connecting,
  });
  final IconData icon;
  final String label;
  final String when;
  final String? flight;
  final List<ConnectingFlightDraft> connecting;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final legs = connecting
        .map((c) => c.flightNumber)
        .where((e) => e.isNotEmpty)
        .toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              if ((flight ?? '').trim().isNotEmpty)
                Flexible(
                  child: _Pill(label: flight!, color: colors.accent),
                ),
            ],
          ),
          if (legs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  Icons.connecting_airports_rounded,
                  size: 16,
                  color: colors.textMuted,
                ),
                for (final l in legs) _Pill(label: l, color: colors.accent),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.count,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIcon(icon: icon, size: 32),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (count != null && count! > 0) ...[
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

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

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CircleIcon(icon: icon, size: size),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
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

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.semantic.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _KvGrid extends StatelessWidget {
  const _KvGrid({required this.entries});
  final List<(String, String?)> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final visible = entries
        .where((e) => (e.$2 ?? '').trim().isNotEmpty)
        .toList(growable: false);
    if (visible.isEmpty) return const _EmptyText('No profile details.');
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
