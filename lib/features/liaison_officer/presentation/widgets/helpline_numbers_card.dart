import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/services/lo_firebase_monitor.dart';
import 'package:liaison_officer/core/services/lo_monitoring_events.dart';
import 'package:liaison_officer/core/utils/lo_contact_actions.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';

/// One label, then each contact with a phone icon before the number.
class HelplineNumbersCard extends StatelessWidget {
  const HelplineNumbersCard({super.key, required this.helplines});

  final List<LoHelplineDto> helplines;

  @override
  Widget build(BuildContext context) {
    final visible = LoHelplineDto.visible(helplines);
    if (visible.isEmpty) return const SizedBox.shrink();
    final colors = context.semantic;
    final accent = colors.accent;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.phone_in_talk_outlined,
                  size: 19,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Helplines',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${visible.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final line in visible) ...[
            if (line.label.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Text(
                  line.label.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final contact in line.contacts)
                  if (contact.contactNumber.trim().isNotEmpty)
                    Material(
                      color: accent.withValues(alpha: 0.1),
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () => _call(context, contact.contactNumber),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.call, size: 16, color: accent),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  contact.contactNumber.trim(),
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
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> _call(BuildContext context, String phone) async {
    LoFirebaseMonitor.instance.logFeature(
      LoMonitoringEvents.featureHelplineCall,
    );
    final ok = await LoContactActions.call(phone);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start the call.')),
      );
    }
  }
}

/// Portal helplines when a [LoPortalBloc] is in scope. Hidden on the login help screen.
class HelplineNumbersSection extends StatelessWidget {
  const HelplineNumbersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = _blocOrNull(context);
    if (bloc == null) return const SizedBox.shrink();
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      bloc: bloc,
      builder: (context, state) =>
          HelplineNumbersCard(helplines: state.helplines),
    );
  }

  static LoPortalBloc? _blocOrNull(BuildContext context) {
    try {
      return context.read<LoPortalBloc>();
    } catch (_) {
      return null;
    }
  }
}
