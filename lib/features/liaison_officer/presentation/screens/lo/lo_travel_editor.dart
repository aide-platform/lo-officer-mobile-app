import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';
import 'package:liaison_officer/core/services/lo_monitoring_events.dart';
import 'package:liaison_officer/core/utils/lo_display_format.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';

/// Travel details editor sheet (arrival / departure + connecting flights).
class LoTravelEditor {
  LoTravelEditor._();

  static Future<void> open(
    BuildContext context,
    MyLoAssignmentDto d,
    List<ConnectingFlightDraft> seededArrival,
    List<ConnectingFlightDraft> seededDeparture,
  ) async {
    LoFirebaseMonitor.instance.logFeature(
      LoMonitoringEvents.featureTravelEditor,
    );
    final arrivalFlight = TextEditingController(text: d.arrivalFlight);
    final arrivalTerminal = TextEditingController(text: d.arrivalTerminal);
    final arrivalDate = TextEditingController(
      text: LoDisplayFormat.date(d.arrivalDate),
    );
    final arrivalTime = TextEditingController(
      text: LoDisplayFormat.time(d.arrivalTime),
    );
    final departureFlight = TextEditingController(text: d.departureFlight);
    final departureTerminal = TextEditingController(text: d.departureTerminal);
    final departureDate = TextEditingController(
      text: LoDisplayFormat.date(d.departureDate),
    );
    final departureTime = TextEditingController(
      text: LoDisplayFormat.time(d.departureTime),
    );

    var arrivalFlights = seededArrival
        .map(
          (e) => ConnectingFlightDraft(
            flightNumber: e.flightNumber,
            terminal: e.terminal,
            date: e.date,
            time: e.time,
          ),
        )
        .toList();
    var departureFlights = seededDeparture
        .map(
          (e) => ConnectingFlightDraft(
            flightNumber: e.flightNumber,
            terminal: e.terminal,
            date: e.date,
            time: e.time,
          ),
        )
        .toList();

    final saved = await showModalBottomSheet<bool>(
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
                      _circleIcon(ctx, Icons.flight_rounded, 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Travel details',
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
                  _travelCard(
                    context: ctx,
                    icon: Icons.flight_land_rounded,
                    title: 'Arrival',
                    children: [
                      _pair(
                        TextField(
                          controller: arrivalFlight,
                          decoration: const InputDecoration(
                            labelText: 'Flight',
                          ),
                        ),
                        TextField(
                          controller: arrivalTerminal,
                          decoration: const InputDecoration(
                            labelText: 'Terminal',
                          ),
                        ),
                      ),
                      _pair(
                        _dateTimeField(
                          context: ctx,
                          controller: arrivalDate,
                          label: 'Date',
                          isDate: true,
                        ),
                        _dateTimeField(
                          context: ctx,
                          controller: arrivalTime,
                          label: 'Time',
                          isDate: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _travelCard(
                    context: ctx,
                    icon: Icons.flight_takeoff_rounded,
                    title: 'Departure',
                    children: [
                      _pair(
                        TextField(
                          controller: departureFlight,
                          decoration: const InputDecoration(
                            labelText: 'Flight',
                          ),
                        ),
                        TextField(
                          controller: departureTerminal,
                          decoration: const InputDecoration(
                            labelText: 'Terminal',
                          ),
                        ),
                      ),
                      _pair(
                        _dateTimeField(
                          context: ctx,
                          controller: departureDate,
                          label: 'Date',
                          isDate: true,
                        ),
                        _dateTimeField(
                          context: ctx,
                          controller: departureTime,
                          label: 'Time',
                          isDate: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _connectingSection(
                    title: 'Arrival connecting flights',
                    flights: arrivalFlights,
                    onChanged: (v) => arrivalFlights = v,
                    setLocal: setLocal,
                    context: ctx,
                  ),
                  const SizedBox(height: 12),
                  _connectingSection(
                    title: 'Departure connecting flights',
                    flights: departureFlights,
                    onChanged: (v) => departureFlights = v,
                    setLocal: setLocal,
                    context: ctx,
                  ),
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
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: buttonShape,
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Save'),
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

    if (saved == true && context.mounted && d.assignmentId != null) {
      context.read<LoPortalBloc>().add(
        LoPortalTravelUpdated(
          assignmentId: d.assignmentId!,
          body: {
            'arrivalFlight': arrivalFlight.text.trim(),
            'arrivalTerminal': arrivalTerminal.text.trim(),
            'arrivalDate': LoDisplayFormat.date(arrivalDate.text.trim()),
            'arrivalTime': LoDisplayFormat.toApiTime(arrivalTime.text.trim()),
            'departureFlight': departureFlight.text.trim(),
            'departureTerminal': departureTerminal.text.trim(),
            'departureDate': LoDisplayFormat.date(departureDate.text.trim()),
            'departureTime': LoDisplayFormat.toApiTime(
              departureTime.text.trim(),
            ),
            'arrivalConnectingFlights': arrivalFlights
                .map((e) => e.toJson())
                .toList(),
            'departureConnectingFlights': departureFlights
                .map((e) => e.toJson())
                .toList(),
          },
        ),
      );
    }

    arrivalFlight.dispose();
    arrivalTerminal.dispose();
    arrivalDate.dispose();
    arrivalTime.dispose();
    departureFlight.dispose();
    departureTerminal.dispose();
    departureDate.dispose();
    departureTime.dispose();
  }

  static Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final existing = DateTime.tryParse(controller.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: existing ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    final y = picked.year.toString().padLeft(4, '0');
    final m = picked.month.toString().padLeft(2, '0');
    final d = picked.day.toString().padLeft(2, '0');
    controller.text = '$y-$m-$d';
  }

  static Future<void> _pickTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    TimeOfDay initial = TimeOfDay.now();
    final parsed = LoDisplayFormat.tryParseTime(controller.text);
    if (parsed != null) {
      initial = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final h = picked.hour.toString().padLeft(2, '0');
    final m = picked.minute.toString().padLeft(2, '0');
    controller.text = LoDisplayFormat.time('$h:$m:00');
  }

  static Widget _circleIcon(BuildContext context, IconData icon, double size) {
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

  static Widget _travelCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colors = context.semantic;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            children: [
              _circleIcon(context, icon, 30),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  static Widget _dateTimeField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool isDate,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(
          isDate ? Icons.calendar_today_outlined : Icons.access_time,
        ),
      ),
      onTap: () => isDate
          ? _pickDate(context, controller)
          : _pickTime(context, controller),
    );
  }

  static Widget _connectingSection({
    required String title,
    required List<ConnectingFlightDraft> flights,
    required void Function(List<ConnectingFlightDraft>) onChanged,
    required void Function(void Function()) setLocal,
    required BuildContext context,
  }) {
    final colors = context.semantic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _circleIcon(context, Icons.connecting_airports_rounded, 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                setLocal(() {
                  onChanged([...flights, const ConnectingFlightDraft()]);
                });
              },
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(0, 36),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (flights.isEmpty)
          Text(
            'No connecting flights.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ...List.generate(flights.length, (i) {
          final f = flights[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Leg ${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () {
                          setLocal(() {
                            onChanged([...flights]..removeAt(i));
                          });
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: f.flightNumber,
                            decoration: const InputDecoration(
                              labelText: 'Flight number',
                            ),
                            onChanged: (v) {
                              final next = [...flights];
                              next[i] = ConnectingFlightDraft(
                                flightNumber: v,
                                terminal: flights[i].terminal,
                                date: flights[i].date,
                                time: flights[i].time,
                              );
                              onChanged(next);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            initialValue: f.terminal,
                            decoration: const InputDecoration(
                              labelText: 'Terminal',
                            ),
                            onChanged: (v) {
                              final next = [...flights];
                              next[i] = ConnectingFlightDraft(
                                flightNumber: flights[i].flightNumber,
                                terminal: v,
                                date: flights[i].date,
                                time: flights[i].time,
                              );
                              onChanged(next);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
