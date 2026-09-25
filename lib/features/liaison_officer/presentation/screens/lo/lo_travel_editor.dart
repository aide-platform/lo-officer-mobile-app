import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
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
    final arrivalFlight = TextEditingController(text: d.arrivalFlight);
    final arrivalTerminal = TextEditingController(text: d.arrivalTerminal);
    final arrivalDate = TextEditingController(text: d.arrivalDate);
    final arrivalTime = TextEditingController(text: d.arrivalTime);
    final departureFlight = TextEditingController(text: d.departureFlight);
    final departureTerminal = TextEditingController(text: d.departureTerminal);
    final departureDate = TextEditingController(text: d.departureDate);
    final departureTime = TextEditingController(text: d.departureTime);

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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Travel — ${d.fullName ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: arrivalFlight,
                    decoration:
                        const InputDecoration(labelText: 'Arrival flight'),
                  ),
                  TextField(
                    controller: arrivalTerminal,
                    decoration:
                        const InputDecoration(labelText: 'Arrival terminal'),
                  ),
                  _dateTimeField(
                    context: ctx,
                    controller: arrivalDate,
                    label: 'Arrival date',
                    isDate: true,
                  ),
                  _dateTimeField(
                    context: ctx,
                    controller: arrivalTime,
                    label: 'Arrival time',
                    isDate: false,
                  ),
                  TextField(
                    controller: departureFlight,
                    decoration:
                        const InputDecoration(labelText: 'Departure flight'),
                  ),
                  TextField(
                    controller: departureTerminal,
                    decoration: const InputDecoration(
                      labelText: 'Departure terminal',
                    ),
                  ),
                  _dateTimeField(
                    context: ctx,
                    controller: departureDate,
                    label: 'Departure date',
                    isDate: true,
                  ),
                  _dateTimeField(
                    context: ctx,
                    controller: departureTime,
                    label: 'Departure time',
                    isDate: false,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Save'),
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
                'arrivalDate': arrivalDate.text.trim(),
                'arrivalTime': arrivalTime.text.trim(),
                'departureFlight': departureFlight.text.trim(),
                'departureTerminal': departureTerminal.text.trim(),
                'departureDate': departureDate.text.trim(),
                'departureTime': departureTime.text.trim(),
                'arrivalConnectingFlights':
                    arrivalFlights.map((e) => e.toJson()).toList(),
                'departureConnectingFlights':
                    departureFlights.map((e) => e.toJson()).toList(),
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
    final parts = controller.text.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        initial = TimeOfDay(hour: h, minute: m);
      }
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    final h = picked.hour.toString().padLeft(2, '0');
    final m = picked.minute.toString().padLeft(2, '0');
    controller.text = '$h:$m';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setLocal(() {
                  onChanged([...flights, const ConnectingFlightDraft()]);
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        ...List.generate(flights.length, (i) {
          final f = flights[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Leg ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () {
                          setLocal(() {
                            onChanged([...flights]..removeAt(i));
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: f.flightNumber,
                    decoration:
                        const InputDecoration(labelText: 'Flight number'),
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
                  TextFormField(
                    initialValue: f.terminal,
                    decoration: const InputDecoration(labelText: 'Terminal'),
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
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
