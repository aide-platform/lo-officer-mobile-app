import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_asset_manager.dart';
import 'package:liaison_officer/core/utils/lo_display_format.dart';
import 'package:liaison_officer/core/widgets/app_motion.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';

/// Alerts tab: alert lead time + local operational alerts.
class LoNotificationsScreen extends StatelessWidget {
  const LoNotificationsScreen({super.key});

  static const _leadOptions = [15, 30, 60, 120];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoPortalBloc, LoPortalState>(
      builder: (context, state) {
        final lead = _leadOptions.contains(state.alertLeadMinutes)
            ? state.alertLeadMinutes
            : 60;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<LoPortalBloc>().add(LoPortalAlertsRefreshRequested());
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              AppStagger(
                index: 0,
                child: AppCard(
                  child: Row(
                    children: [
                      const SafeAssetImage(
                        assetPath: AppAssetManager.iconAlert,
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Alert lead time',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DropdownButton<int>(
                        value: lead,
                        items: _leadOptions
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text('$m min'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          context.read<LoPortalBloc>().add(
                            LoPortalAlertLeadMinutesChanged(v),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: () {
                          context.read<LoPortalBloc>().add(
                            LoPortalAlertsRefreshRequested(),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              const AppSectionHeader(
                title: 'Local alerts',
                asset: AppAssetManager.iconAlert,
              ),
              if (state.alerts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: AppEmptyState(
                    message: 'No local alerts yet.',
                    imageAsset: AppAssetManager.iconAlert,
                  ),
                )
              else
                ...state.alerts.asMap().entries.map((entry) {
                  final a = entry.value;
                  final title = a['title']?.toString() ?? 'Alert';
                  final body = a['body']?.toString() ?? '';
                  final at = a['at']?.toString() ?? a['createdAt']?.toString();
                  return AppStagger(
                    index: 1 + entry.key,
                    child: AppCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const SafeAssetImage(
                          assetPath: AppAssetManager.iconAlert,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          [
                            body,
                            if (at != null && at.isNotEmpty)
                              LoDisplayFormat.when(at),
                          ].where((e) => e.toString().isNotEmpty).join('\n'),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
