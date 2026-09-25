import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_itinerary.dart';
import 'package:liaison_officer/features/liaison_officer/domain/models/lo_movement.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_issue_report_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_travel_editor.dart';
import 'package:liaison_officer/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class LoDelegateDetailScreen extends StatelessWidget {
  const LoDelegateDetailScreen({super.key, required this.delegate});

  final MyLoAssignmentDto delegate;

  @override
  Widget build(BuildContext context) {
    final assignmentId = delegate.assignmentId;
    return Scaffold(
      appBar: AppBar(
        title: Text(delegate.fullName ?? 'Delegate'),
        actions: [
          IconButton(
            tooltip: 'Report issue',
            icon: const Icon(Icons.report_problem_outlined),
            onPressed: () {
              final bloc = context.read<LoPortalBloc>();
              Navigator.of(context).push(
                AppPageFadeRoute<void>(
                  page: BlocProvider.value(
                    value: bloc,
                    child: LoIssueReportScreen(
                      assignmentId: assignmentId,
                      delegateName: delegate.fullName,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<LoPortalBloc, LoPortalState>(
        builder: (context, state) {
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
              : state.departureConnectingByAssignment[assignmentId] ??
                  const [];
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

          return RefreshIndicator(
            onRefresh: () async {
              if (assignmentId != null) {
                context
                    .read<LoPortalBloc>()
                    .add(LoPortalDelegateExtrasRequested(assignmentId));
              }
              context.read<LoPortalBloc>().add(LoPortalLoadRequested());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle(context, 'Profile'),
                Text(
                  live.fullName ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                _detailKv('Designation', live.designation),
                _detailKv('Organisation', live.organisation),
                _detailKv('Ministry', live.ministry),
                _detailKv('Gender', live.gender),
                _detailKv('Protocol', live.protocolEquiv),
                _detailKv('VIP category', live.vipCategory),
                _detailKv('Country', live.countryName),
                _detailLinkKv(
                  context,
                  'Email',
                  live.email,
                  () => _launchUri(Uri(scheme: 'mailto', path: live.email)),
                ),
                _detailLinkKv(
                  context,
                  'Mobile',
                  live.mobileNumber,
                  () => _launchUri(Uri(scheme: 'tel', path: live.mobileNumber)),
                ),
                if (live.family.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _sectionTitle(context, 'Family'),
                  ...live.family.map(
                    (f) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(f.fullName ?? ''),
                      subtitle: Text(
                        [f.relation, f.gender]
                            .whereType<String>()
                            .where((e) => e.isNotEmpty)
                            .join(' · '),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _sectionTitle(context, 'Itinerary'),
                if (itinerary.isEmpty)
                  const Text('No itinerary items yet.')
                else
                  ...itinerary.map((item) => _ItineraryTile(item: item)),
                const SizedBox(height: 16),
                _sectionTitle(context, 'Transport'),
                if (vehicles.isEmpty)
                  const Text('No vehicles assigned.')
                else
                  ...vehicles.map((v) => _TransportCard(vehicle: v)),
                const SizedBox(height: 16),
                _sectionTitle(context, 'Travel & movement'),
                Text(
                  'Arrival: ${live.arrivalFlight ?? '—'} · ${live.arrivalDate ?? ''} ${live.arrivalTime ?? ''}',
                ),
                Text(
                  'Departure: ${live.departureFlight ?? '—'} · ${live.departureDate ?? ''} ${live.departureTime ?? ''}',
                ),
                if (arrivalConnecting.isNotEmpty)
                  Text(
                    'Arrival connecting: ${arrivalConnecting.map((c) => c.flightNumber).where((e) => e.isNotEmpty).join(', ')}',
                  ),
                if (departureConnecting.isNotEmpty)
                  Text(
                    'Departure connecting: ${departureConnecting.map((c) => c.flightNumber).where((e) => e.isNotEmpty).join(', ')}',
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => LoTravelEditor.open(
                        context,
                        live,
                        arrivalConnecting,
                        departureConnecting,
                      ),
                      icon: const Icon(Icons.flight_takeoff_outlined),
                      label: const Text('Update travel'),
                    ),
                    FilledButton.icon(
                      onPressed: assignmentId == null
                          ? null
                          : () => _openMovementSheet(context, live),
                      icon: const Icon(Icons.directions_walk_outlined),
                      label: const Text('Log movement'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }

  Future<void> _openMovementSheet(
    BuildContext context,
    MyLoAssignmentDto d,
  ) async {
    var kind = LoMovementKind.arrival;
    final flight = TextEditingController(
      text: d.arrivalFlight ?? '',
    );
    final terminal = TextEditingController(text: d.arrivalTerminal ?? '');
    final date = TextEditingController(text: d.arrivalDate ?? '');
    final time = TextEditingController(text: d.arrivalTime ?? '');
    final notes = TextEditingController();
    final location = TextEditingController();

    final ok = await showAppFormSheet(
      context: context,
      title: 'Delegate movement',
      confirmLabel: 'Save movement',
      builder: (ctx, setLocal) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<LoMovementKind>(
            initialValue: kind,
            decoration: const InputDecoration(labelText: 'Movement type'),
            items: LoMovementKind.values
                .map(
                  (k) => DropdownMenuItem(value: k, child: Text(k.label)),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setLocal(() {
                kind = v;
                if (v == LoMovementKind.departure) {
                  flight.text = d.departureFlight ?? '';
                  terminal.text = d.departureTerminal ?? '';
                  date.text = d.departureDate ?? '';
                  time.text = d.departureTime ?? '';
                } else if (v == LoMovementKind.arrival) {
                  flight.text = d.arrivalFlight ?? '';
                  terminal.text = d.arrivalTerminal ?? '';
                  date.text = d.arrivalDate ?? '';
                  time.text = d.arrivalTime ?? '';
                }
              });
            },
          ),
          TextField(
            controller: flight,
            decoration: const InputDecoration(labelText: 'Flight (optional)'),
          ),
          TextField(
            controller: terminal,
            decoration: const InputDecoration(labelText: 'Terminal / gate'),
          ),
          TextField(
            controller: date,
            decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
          ),
          TextField(
            controller: time,
            decoration: const InputDecoration(labelText: 'Time (HH:mm)'),
          ),
          TextField(
            controller: location,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          TextField(
            controller: notes,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 2,
          ),
        ],
      ),
    );

    if (ok == true && context.mounted && d.assignmentId != null) {
      context.read<LoPortalBloc>().add(
            LoPortalMovementUpdated(
              assignmentId: d.assignmentId!,
              movement: LoMovementUpdate(
                kind: kind,
                flight: flight.text.trim().isEmpty ? null : flight.text.trim(),
                terminal:
                    terminal.text.trim().isEmpty ? null : terminal.text.trim(),
                date: date.text.trim().isEmpty ? null : date.text.trim(),
                time: time.text.trim().isEmpty ? null : time.text.trim(),
                notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                location:
                    location.text.trim().isEmpty ? null : location.text.trim(),
              ),
            ),
          );
    }
    flight.dispose();
    terminal.dispose();
    date.dispose();
    time.dispose();
    notes.dispose();
    location.dispose();
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

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                AppStatusPalette.forLabel(item.kind.name).withValues(alpha: 0.15),
            child: Icon(_icon, size: 18, color: AppTheme.activeAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((item.subtitle ?? '').isNotEmpty)
                  Text(item.subtitle!, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  [
                    if ((item.date ?? '').isNotEmpty) item.date,
                    if ((item.time ?? '').isNotEmpty) item.time,
                    if ((item.venue ?? '').isNotEmpty) item.venue,
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppStatusChip(label: item.kind.name),
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
    final number = vehicle['vehicleNumber']?.toString() ?? '—';
    final type = vehicle['vehicleType']?.toString() ?? 'Vehicle';
    final driver = vehicle['driverName']?.toString();
    final contact = vehicle['driverContact']?.toString();
    final pickup = vehicle['pickupTime']?.toString() ??
        vehicle['pickupSchedule']?.toString() ??
        vehicle['schedule']?.toString();

    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$type · $number',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (driver != null && driver.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Driver: $driver'),
          ],
          if (contact != null && contact.isNotEmpty)
            InkWell(
              onTap: () => _launchUri(Uri(scheme: 'tel', path: contact)),
              child: Text(
                contact,
                style: TextStyle(
                  color: AppTheme.activeAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          if (pickup != null && pickup.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Pickup: $pickup',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _detailKv(String k, String? v) {
  if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

Widget _detailLinkKv(
  BuildContext context,
  String k,
  String? v,
  VoidCallback onTap,
) {
  if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Text(
              v,
              style: TextStyle(
                color: AppTheme.activeAccent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _launchUri(Uri uri) async {
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
