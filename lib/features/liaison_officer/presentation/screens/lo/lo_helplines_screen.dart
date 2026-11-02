import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';
import 'package:liaison_officer/core/services/lo_monitoring_events.dart';
import 'package:liaison_officer/core/utils/lo_contact_actions.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';

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
              const _HelpHero(),
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

Future<void> _callHelpline(BuildContext context, String phone) async {
  LoFirebaseMonitor.instance.logFeature(LoMonitoringEvents.featureHelplineCall);
  final ok = await LoContactActions.call(phone);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to start the call.')),
    );
  }
}

String _helplineTitle(LoHelplineDto line) => line.label.trim().isEmpty
    ? 'Committee / Contact Type'
    : line.label.trim();

IconData _helplineIcon(String label) {
  final l = label.toLowerCase();
  bool has(List<String> words) => words.any(l.contains);
  if (has(['police', 'security', 'cisf', 'guard'])) {
    return Icons.local_police_outlined;
  }
  if (has(['ambulance', 'medical', 'hospital', 'doctor', 'health'])) {
    return Icons.local_hospital_outlined;
  }
  if (has(['fire'])) return Icons.local_fire_department_outlined;
  if (has(['vehicle', 'transport', 'car', 'cab', 'taxi', 'driver'])) {
    return Icons.directions_car_outlined;
  }
  if (has(['store', 'shop', 'stall', 'canteen', 'food'])) {
    return Icons.storefront_outlined;
  }
  if (has(['hotel', 'accommodation', 'stay'])) return Icons.hotel_outlined;
  if (has(['airport', 'flight', 'travel'])) return Icons.flight_outlined;
  if (has(['society', 'committee', 'team', 'group', 'protocol'])) {
    return Icons.groups_outlined;
  }
  return Icons.person_outline;
}

class _HelpHero extends StatelessWidget {
  const _HelpHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      clipBehavior: Clip.antiAlias,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reach out to any of these numbers if you need support '
                  'during the event. Tap a number to call.',
                  style: TextStyle(color: colors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            height: 84,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.14),
                    ),
                    child: Icon(Icons.support_agent, size: 48, color: accent),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                        bottomLeft: Radius.circular(3),
                      ),
                    ),
                    child: const Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: Colors.white,
                    ),
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

class _HelplineRow extends StatelessWidget {
  const _HelplineRow({required this.index, required this.line});

  final int index;
  final LoHelplineDto line;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    final title = _helplineTitle(line);
    final numbers = [
      for (final c in line.contacts)
        if (c.contactNumber.trim().isNotEmpty) c.contactNumber.trim(),
    ];

    void openRow() {
      if (numbers.length == 1) {
        _callHelpline(context, numbers.first);
      } else if (numbers.length > 1) {
        _showNumbersSheet(context, title, numbers);
      }
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      onTap: numbers.isEmpty ? null : openRow,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.1),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.1),
            ),
            child: Icon(_helplineIcon(title), color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: colors.textPrimary,
                  ),
                ),
                if (numbers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final n in numbers) _NumberChip(number: n),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (numbers.isNotEmpty)
            Icon(Icons.chevron_right_rounded, color: accent),
        ],
      ),
    );
  }

  static Future<void> _showNumbersSheet(
    BuildContext context,
    String title,
    List<String> numbers,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) {
        final colors = ctx.semantic;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a number to call.',
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final n in numbers)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.call_outlined, color: colors.accent),
                        title: Text(
                          n,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _callHelpline(context, n);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NumberChip extends StatelessWidget {
  const _NumberChip({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final accent = colors.accent;
    return Material(
      color: accent.withValues(alpha: 0.1),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _callHelpline(context, number),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call, size: 16, color: accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  number,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
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
