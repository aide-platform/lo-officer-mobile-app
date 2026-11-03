import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/utils/lo_display_format.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_delegate_detail_screen.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_delegate_sheets.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_travel_editor.dart';
import 'package:liaison_officer/theme/app_theme.dart';

enum _TypeFilter { all, domestic, foreign }

class LoDelegatesScreen extends StatefulWidget {
  const LoDelegatesScreen({super.key});

  @override
  State<LoDelegatesScreen> createState() => _LoDelegatesScreenState();
}

class _LoDelegatesScreenState extends State<LoDelegatesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _TypeFilter _filter = _TypeFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MyLoAssignmentDto> _filtered(List<MyLoAssignmentDto> delegates) {
    final q = _query.trim().toLowerCase();
    return delegates.where((d) {
      final label = _foreignDomesticLabel(d.delegateType);
      final matchesType = switch (_filter) {
        _TypeFilter.all => true,
        _TypeFilter.domestic => label == 'Domestic',
        _TypeFilter.foreign => label == 'Foreign',
      };
      if (!matchesType) return false;
      if (q.isEmpty) return true;
      final hay = [
        d.fullName,
        d.delegateType,
        label,
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

  void _toggleFilter(_TypeFilter f) {
    setState(() => _filter = _filter == f ? _TypeFilter.all : f);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        if (state.status == LoPortalStatus.loading && state.delegates.isEmpty) {
          return const AppLoading(label: 'Loading delegates…');
        }
        // Offline on first launch: show the error, not "No delegates".
        if (state.status == LoPortalStatus.failure &&
            state.delegates.isEmpty &&
            state.tasks.isEmpty) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load delegates',
            onRetry: () =>
                context.read<LoPortalBloc>().add(LoPortalLoadRequested()),
          );
        }
        return RefreshIndicator(
          onRefresh: () => refreshPortal(context),
          child: state.delegates.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const _DelegatesHero(),
                    AppEmptyStateCard(
                      illustration: AppEmptyIllustration(
                        icon: Icons.groups_rounded,
                        badges: [
                          Positioned(
                            right: 26,
                            bottom: 30,
                            child: AppEmptyIllustration.badge(
                              context,
                              icon: Icons.flight_rounded,
                              color: AppTheme.saffron,
                              size: 32,
                            ),
                          ),
                          Positioned(
                            left: 58,
                            bottom: 22,
                            child: AppEmptyIllustration.badge(
                              context,
                              icon: Icons.badge_outlined,
                              iconColor: context.semantic.accent,
                            ),
                          ),
                        ],
                      ),
                      title: 'No delegates assigned yet',
                      message:
                          'Once the LO Committee assigns delegates to you, they '
                          'will appear here with arrival, departure and event '
                          'details.',
                      tip:
                          'Pull down or tap Refresh to check for new assignments.',
                      loading: state.status == LoPortalStatus.loading,
                      onRefresh: () => context.read<LoPortalBloc>().add(
                        LoPortalLoadRequested(),
                      ),
                    ),
                  ],
                )
              : Builder(
                  builder: (context) {
                    final filtered = _filtered(state.delegates);
                    final all = state.delegates;
                    final domestic = all
                        .where(
                          (d) =>
                              _foreignDomesticLabel(d.delegateType) ==
                              'Domestic',
                        )
                        .length;
                    final foreign = all
                        .where(
                          (d) =>
                              _foreignDomesticLabel(d.delegateType) ==
                              'Foreign',
                        )
                        .length;
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filtered.isEmpty ? 2 : filtered.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _DelegatesHero(),
                              _DelegateSummary(
                                total: all.length,
                                domestic: domestic,
                                foreign: foreign,
                                filter: _filter,
                                onTap: _toggleFilter,
                              ),
                              _SearchField(
                                controller: _searchController,
                                query: _query,
                                onChanged: (v) => setState(() => _query = v),
                                onClear: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                            ],
                          );
                        }
                        if (filtered.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 48),
                            child: AppEmptyState(
                              icon: Icons.search_off_rounded,
                              message: 'No delegates match your search.',
                            ),
                          );
                        }
                        final d = filtered[i - 1];
                        return AppStagger(
                          index: i - 1,
                          child: _DelegateCard(
                            delegate: d,
                            onOpenDetail: () =>
                                openDelegateViewSheet(context, d),
                            onOpenEvents: () =>
                                openDelegateNominationsSheet(context, d),
                            onOpenVehicles: () =>
                                openDelegateVehiclesSheet(context, d),
                            onOpenArrival: () =>
                                _openArrival(context, state, d),
                            onOpenFullProfile: () => _openDetail(context, d),
                          ),
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
          child: LoDelegateDetailScreen(delegate: d, focusSection: focus),
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

  static Color _typeColor(BuildContext context, String label) {
    return switch (label) {
      'Domestic' => AppTheme.indiaGreen,
      'Foreign' => AppTheme.saffron,
      _ => context.semantic.accent,
    };
  }
}

class _DelegatesHero extends StatelessWidget {
  const _DelegatesHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
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
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.groups_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delegates',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your assigned delegates, their travel and transport.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Icon(
                    Icons.groups_2_rounded,
                    size: 56,
                    color: accent.withValues(alpha: 0.35),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surface,
                    ),
                    child: Icon(Icons.flight_rounded, size: 24, color: accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DelegateSummary extends StatelessWidget {
  const _DelegateSummary({
    required this.total,
    required this.domestic,
    required this.foreign,
    required this.filter,
    required this.onTap,
  });

  final int total;
  final int domestic;
  final int foreign;
  final _TypeFilter filter;
  final ValueChanged<_TypeFilter> onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.semantic.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Total',
              count: total,
              color: accent,
              icon: Icons.groups_outlined,
              selected: filter == _TypeFilter.all,
              onTap: () => onTap(_TypeFilter.all),
            ),
          ),
          Expanded(
            child: _SummaryCard(
              label: 'Domestic',
              count: domestic,
              color: AppTheme.indiaGreen,
              icon: Icons.home_work_outlined,
              selected: filter == _TypeFilter.domestic,
              onTap: () => onTap(_TypeFilter.domestic),
            ),
          ),
          Expanded(
            child: _SummaryCard(
              label: 'Foreign',
              count: foreign,
              color: AppTheme.saffron,
              icon: Icons.public_rounded,
              selected: filter == _TypeFilter.foreign,
              onTap: () => onTap(_TypeFilter.foreign),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: color.withValues(alpha: selected ? 0.18 : 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: color.withValues(alpha: selected ? 0.9 : 0.35),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
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

class _SearchField extends StatelessWidget {
  const _SearchField({
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
    final pill = BorderRadius.circular(28);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search name, country, flight, phone…',
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
            borderSide: BorderSide(color: colors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _DelegateCard extends StatelessWidget {
  const _DelegateCard({
    required this.delegate,
    required this.onOpenDetail,
    required this.onOpenEvents,
    required this.onOpenVehicles,
    required this.onOpenArrival,
    required this.onOpenFullProfile,
  });

  final MyLoAssignmentDto delegate;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpenEvents;
  final VoidCallback onOpenVehicles;
  final VoidCallback onOpenArrival;
  final VoidCallback onOpenFullProfile;

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    return parts.isEmpty ? '?' : parts;
  }

  @override
  Widget build(BuildContext context) {
    final d = delegate;
    final colors = context.semantic;
    final accent = colors.accent;
    final name = (d.fullName ?? '').trim().isEmpty ? 'Delegate' : d.fullName!;
    final typeLabel = _LoDelegatesScreenState._foreignDomesticLabel(
      d.delegateType,
    );
    final typeColor = _LoDelegatesScreenState._typeColor(context, typeLabel);
    final countryCategory = [
      d.countryName,
      d.vipCategory,
    ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' · ');
    final arr = LoDisplayFormat.dateAndTime(d.arrivalDate, d.arrivalTime);
    final dep = LoDisplayFormat.dateAndTime(d.departureDate, d.departureTime);

    return AppCard(
      onTap: onOpenFullProfile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _TypePill(label: typeLabel, color: typeColor),
                        ),
                      ],
                    ),
                    if ((d.designation ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        d.designation!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                    if ((d.organisation ?? '').isNotEmpty)
                      Text(
                        d.organisation!,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    if (countryCategory.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 15,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: _TravelBox(
                  icon: Icons.flight_land_rounded,
                  label: 'Arrival',
                  value: arr.isEmpty ? '—' : arr,
                ),
              ),
              Expanded(
                child: _TravelBox(
                  icon: Icons.flight_takeoff_rounded,
                  label: 'Departure',
                  value: dep.isEmpty ? '—' : dep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CardAction(
                  icon: Icons.visibility_outlined,
                  label: 'View',
                  tooltip: 'View',
                  onTap: onOpenDetail,
                ),
              ),
              Expanded(
                child: _CardAction(
                  icon: Icons.calendar_month_outlined,
                  label: 'Events',
                  tooltip: 'Events / itinerary',
                  onTap: onOpenEvents,
                ),
              ),
              Expanded(
                child: _CardAction(
                  icon: Icons.directions_car_outlined,
                  label: 'Vehicles',
                  tooltip: 'Vehicles',
                  onTap: onOpenVehicles,
                ),
              ),
              Expanded(
                child: _CardAction(
                  icon: Icons.flight_land_outlined,
                  label: 'Travel',
                  tooltip: 'Update arrival / travel',
                  onTap: onOpenArrival,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

class _TravelBox extends StatelessWidget {
  const _TravelBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.accent.withValues(alpha: 0.1),
                ),
                child: Icon(icon, size: 20, color: colors.accent),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
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
