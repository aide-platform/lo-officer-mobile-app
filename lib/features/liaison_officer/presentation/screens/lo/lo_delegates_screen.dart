import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_delegate_detail_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_travel_editor.dart';
import 'package:liaison_officer/theme/app_theme.dart';

class LoDelegatesScreen extends StatefulWidget {
  const LoDelegatesScreen({super.key});

  @override
  State<LoDelegatesScreen> createState() => _LoDelegatesScreenState();
}

class _LoDelegatesScreenState extends State<LoDelegatesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MyLoAssignmentDto> _filtered(List<MyLoAssignmentDto> delegates) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return delegates;
    return delegates.where((d) {
      final hay = [
        d.fullName,
        d.delegateType,
        _foreignDomesticLabel(d.delegateType),
        d.countryName,
        d.vipCategory,
        d.designation,
        d.organisation,
        d.arrivalDate,
        d.arrivalTime,
        d.departureDate,
        d.departureTime,
        d.email,
        d.mobileNumber,
      ].whereType<String>().join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        if (state.status == LoPortalStatus.loading &&
            state.delegates.isEmpty) {
          return const AppLoading(label: 'Loading delegates…');
        }
        return RefreshIndicator(
          onRefresh: () async {
            context.read<LoPortalBloc>().add(LoPortalLoadRequested());
            await context.read<LoPortalBloc>().stream.firstWhere(
                  (s) =>
                      s.status == LoPortalStatus.ready ||
                      s.status == LoPortalStatus.failure,
                );
          },
          child: state.delegates.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    AppEmptyState(
                      message: 'No delegates assigned yet.',
                      icon: Icons.person_off_outlined,
                    ),
                  ],
                )
              : Builder(
                  builder: (context) {
                    final filtered = _filtered(state.delegates);
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filtered.isEmpty
                          ? 2
                          : filtered.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search across all columns…',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear',
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _query = '');
                                        },
                                        icon: const Icon(Icons.clear),
                                      ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          );
                        }
                        if (filtered.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 48),
                            child: AppEmptyState(
                              message: 'No delegates match your search.',
                              icon: Icons.search_off_outlined,
                            ),
                          );
                        }
                        final d = filtered[i - 1];
                        return _DelegateCard(
                          delegate: d,
                          onOpenDetail: () => _openDetail(context, d),
                          onOpenEvents: () => _openDetail(
                            context,
                            d,
                            focus: LoDelegateFocusSection.itinerary,
                          ),
                          onOpenVehicles: () => _openDetail(
                            context,
                            d,
                            focus: LoDelegateFocusSection.transport,
                          ),
                          onOpenArrival: () => _openArrival(context, state, d),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  void _openDetail(
    BuildContext context,
    MyLoAssignmentDto d, {
    LoDelegateFocusSection? focus,
  }) {
    final bloc = context.read<LoPortalBloc>();
    final assignmentId = d.assignmentId;
    if (assignmentId != null) {
      bloc.add(LoPortalDelegateExtrasRequested(assignmentId));
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: LoDelegateDetailScreen(
            delegate: d,
            focusSection: focus,
          ),
        ),
      ),
    );
  }

  Future<void> _openArrival(
    BuildContext context,
    LoPortalState state,
    MyLoAssignmentDto d,
  ) async {
    final bloc = context.read<LoPortalBloc>();
    final assignmentId = d.assignmentId;
    if (assignmentId != null) {
      bloc.add(LoPortalDelegateExtrasRequested(assignmentId));
    }
    final arrival = assignmentId == null
        ? const <ConnectingFlightDraft>[]
        : state.arrivalConnectingByAssignment[assignmentId] ?? const [];
    final departure = assignmentId == null
        ? const <ConnectingFlightDraft>[]
        : state.departureConnectingByAssignment[assignmentId] ?? const [];
    await LoTravelEditor.open(context, d, arrival, departure);
  }

  static String _foreignDomesticLabel(String? type) {
    final t = (type ?? '').toUpperCase();
    if (t.contains('FOREIGN') ||
        t.contains('INTL') ||
        t.contains('INTERNATIONAL')) {
      return 'Foreign';
    }
    if (t.contains('DOMESTIC') ||
        t.contains('INDIA') ||
        t.contains('NATIONAL')) {
      return 'Domestic';
    }
    return t.isEmpty ? 'Delegate' : type!;
  }
}

class _DelegateCard extends StatelessWidget {
  const _DelegateCard({
    required this.delegate,
    required this.onOpenDetail,
    required this.onOpenEvents,
    required this.onOpenVehicles,
    required this.onOpenArrival,
  });

  final MyLoAssignmentDto delegate;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenVehicles;
  final VoidCallback onOpenArrival;

  @override
  Widget build(BuildContext context) {
    final d = delegate;
    final countryCategory = [
      d.countryName,
      d.vipCategory,
    ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' · ');
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final arr = [
      d.arrivalDate,
      if ((d.arrivalTime ?? '').trim().isNotEmpty) d.arrivalTime,
    ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' - ');
    final dep = [
      d.departureDate,
      if ((d.departureTime ?? '').trim().isNotEmpty) d.departureTime,
    ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' - ');

    return AppCard(
      onTap: onOpenDetail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.fullName ?? 'Delegate',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              AppStatusChip(
                label: _LoDelegatesScreenState._foreignDomesticLabel(
                  d.delegateType,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if ((d.designation ?? '').isNotEmpty) Text(d.designation!),
          if ((d.organisation ?? '').isNotEmpty)
            Text(
              d.organisation!,
              style: TextStyle(color: muted),
            ),
          if (countryCategory.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              countryCategory,
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Arr ${arr.isEmpty ? '—' : arr}',
            style: TextStyle(
              color: AppTheme.activeAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Dep ${dep.isEmpty ? '—' : dep}',
            style: TextStyle(
              color: AppTheme.activeAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                tooltip: 'View',
                onPressed: onOpenDetail,
                icon: Icon(
                  Icons.visibility_outlined,
                  color: AppTheme.activeAccent,
                ),
              ),
              IconButton(
                tooltip: 'Events / itinerary',
                onPressed: onOpenEvents,
                icon: Icon(
                  Icons.calendar_month_outlined,
                  color: AppTheme.activeAccent,
                ),
              ),
              IconButton(
                tooltip: 'Vehicles',
                onPressed: onOpenVehicles,
                icon: Icon(
                  Icons.directions_car_outlined,
                  color: AppTheme.activeAccent,
                ),
              ),
              IconButton(
                tooltip: 'Update arrival / travel',
                onPressed: onOpenArrival,
                icon: Icon(
                  Icons.flight_land_outlined,
                  color: AppTheme.activeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
