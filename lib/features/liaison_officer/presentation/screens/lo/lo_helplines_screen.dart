import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';
import 'package:liaison_officer/core/services/lo_monitoring_events.dart';
import 'package:liaison_officer/core/utils/lo_contact_actions.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/theme/app_theme.dart';

/// LO portal directory from `GET /app/lo-help-lines/active`.
/// Matches the web Help Line Numbers page: label, then tappable numbers.
class LoHelplinesScreen extends StatelessWidget {
  const LoHelplinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        final lines = LoHelplineDto.visible(state.helplines);
        final loading = state.status == LoPortalStatus.loading && lines.isEmpty;
        return RefreshIndicator(
          onRefresh: () async {
            context.read<LoPortalBloc>().add(LoPortalLoadRequested());
            await context.read<LoPortalBloc>().stream.firstWhere(
              (s) =>
                  s.status == LoPortalStatus.ready ||
                  s.status == LoPortalStatus.failure,
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Reach out to any of these numbers if you need support during the event. Tap a number to call.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: AppLoading(label: 'Loading help lines…'),
                )
              else if (lines.isEmpty)
                const AppEmptyState(
                  icon: Icons.phone_in_talk_outlined,
                  message:
                      'No help lines published yet. Please check back later.',
                )
              else
                for (var i = 0; i < lines.length; i++)
                  AppStagger(
                    index: i,
                    child: _HelplineRow(index: i + 1, line: lines[i]),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _HelplineRow extends StatelessWidget {
  const _HelplineRow({required this.index, required this.line});

  final int index;
  final LoHelplineDto line;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index',
                style: TextStyle(fontWeight: FontWeight.w700, color: muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  line.label.trim().isEmpty
                      ? 'Committee / Contact Type'
                      : line.label.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final contact in line.contacts)
                _NumberChip(number: contact.contactNumber),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberChip extends StatelessWidget {
  const _NumberChip({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.royalBlue.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.royalBlue.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _call(context, number),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone, size: 16, color: AppTheme.royalBlue),
              const SizedBox(width: 6),
              Text(
                number.trim(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _call(BuildContext context, String phone) async {
    LoFirebaseMonitor.instance.logFeature(LoMonitoringEvents.featureHelplineCall);
    final ok = await LoContactActions.call(phone);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start the call.')),
      );
    }
  }
}
