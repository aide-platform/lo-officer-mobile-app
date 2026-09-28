import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/utils/lo_contact_actions.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';

/// Label, phone icon, then number. Tapping the row dials via the phone app.
class HelplineNumbersCard extends StatelessWidget {
  const HelplineNumbersCard({super.key, required this.helplines});

  final List<LoHelplineDto> helplines;

  @override
  Widget build(BuildContext context) {
    final visible = LoHelplineDto.visible(helplines);
    if (visible.isEmpty) return const SizedBox.shrink();
    final iconColor = Theme.of(context).colorScheme.primary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Helplines',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          for (final line in visible)
            InkWell(
              onTap: () => _call(context, line.phone),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    if (line.label.trim().isNotEmpty) ...[
                      Flexible(
                        child: Text(
                          line.label.trim(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.phone, size: 20, color: iconColor),
                    const SizedBox(width: 6),
                    Flexible(child: Text(line.phone.trim())),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> _call(BuildContext context, String phone) async {
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
