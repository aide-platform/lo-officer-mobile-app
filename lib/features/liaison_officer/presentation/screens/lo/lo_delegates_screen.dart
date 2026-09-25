import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/screens/lo/lo_delegate_detail_screen.dart';
import 'package:liaison_officer/theme/app_theme.dart';

class LoDelegatesScreen extends StatelessWidget {
  const LoDelegatesScreen({super.key});

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
              : StaggeredList(
                  itemCount: state.delegates.length,
                  itemBuilder: (context, i) {
                    final d = state.delegates[i];
                    return AppCard(
                      onTap: () => _openDetail(context, d),
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
                                label: _foreignDomesticLabel(d.delegateType),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if ((d.designation ?? '').isNotEmpty)
                            Text(d.designation!),
                          if ((d.organisation ?? '').isNotEmpty)
                            Text(
                              d.organisation!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          if ((d.countryName ?? '').isNotEmpty)
                            Text(d.countryName!),
                          const SizedBox(height: 4),
                          Text(
                            'Arr ${d.arrivalDate ?? '—'} · Dep ${d.departureDate ?? '—'}',
                            style: TextStyle(
                              color: AppTheme.activeAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, MyLoAssignmentDto d) {
    final bloc = context.read<LoPortalBloc>();
    final assignmentId = d.assignmentId;
    if (assignmentId != null) {
      bloc.add(LoPortalDelegateExtrasRequested(assignmentId));
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: LoDelegateDetailScreen(delegate: d),
        ),
      ),
    );
  }

  String _foreignDomesticLabel(String? type) {
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
