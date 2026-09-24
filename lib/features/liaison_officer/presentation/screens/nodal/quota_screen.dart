import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/nodal_lo_bloc.dart';

/// Read-only Badge & Vehicle Pass Quota (manual §7 / web `/lo-nodal/badge-quota`).
class QuotaScreen extends StatelessWidget {
  const QuotaScreen({super.key});

  List<Map<String, dynamic>> _asMaps(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  int _sum(List<Map<String, dynamic>> rows, String key) {
    var t = 0;
    for (final r in rows) {
      final v = r[key];
      if (v is num) {
        t += v.toInt();
      } else if (v is String) {
        t += int.tryParse(v) ?? 0;
      }
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badge & Vehicle Pass Quota')),
      body: BlocBuilder<NodalLoBloc, NodalLoState>(
        builder: (context, state) {
          final q = state.badgeQuota ?? const <String, dynamic>{};
          // Live CAP: badgeLines[{name,total,assigned,available}]
          // Mock/legacy: categories / allocated / used / remaining
          final badgeLines = _asMaps(q['badgeLines']).isNotEmpty
              ? _asMaps(q['badgeLines'])
              : _asMaps(q['categories']);
          final vehicleLines = _asMaps(q['vehiclePassLines']).isNotEmpty
              ? _asMaps(q['vehiclePassLines'])
              : _asMaps(q['parkingAreas']).isNotEmpty
                  ? _asMaps(q['parkingAreas'])
                  : _asMaps(q['vehiclePassQuota']);

          final total = q['allocated'] ??
              q['total'] ??
              (badgeLines.isEmpty ? null : _sum(badgeLines, 'total'));
          final used = q['used'] ??
              q['assigned'] ??
              (badgeLines.isEmpty ? null : _sum(badgeLines, 'assigned'));
          final available = q['remaining'] ??
              state.badgeRemaining ??
              (badgeLines.isEmpty ? null : _sum(badgeLines, 'available'));

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q['committeeName']?.toString() ?? 'Badges',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(label: 'Total ${total ?? '—'}'),
                        StatusChip(label: 'Assigned ${used ?? '—'}'),
                        StatusChip(label: 'Available ${available ?? '—'}'),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 12, 4, 6),
                child: Text(
                  'By badge category',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (badgeLines.isEmpty)
                const AppEmptyState(message: 'No badge quota lines returned.')
              else
                ...badgeLines.map(
                  (c) => AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        c['badgeCatName']?.toString() ??
                            c['name']?.toString() ??
                            'Category',
                      ),
                      subtitle: Text(
                        'Total ${c['allocated'] ?? c['total'] ?? '—'} · '
                        'Assigned ${c['used'] ?? c['assigned'] ?? '—'} · '
                        'Available ${c['remaining'] ?? c['available'] ?? '—'}',
                      ),
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 12, 4, 6),
                child: Text(
                  'Vehicle passes / parking',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (vehicleLines.isEmpty)
                const AppEmptyState(
                  message:
                      'No parking / vehicle-pass quota rows returned. '
                      'Ask Invitation Committee if allocation is missing.',
                )
              else
                ...vehicleLines.map(
                  (p) => AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        p['parkingAreaName']?.toString() ??
                            p['name']?.toString() ??
                            'Parking area',
                      ),
                      subtitle: Text(
                        'Total ${p['allocated'] ?? p['total'] ?? '—'} · '
                        'Assigned ${p['used'] ?? p['assigned'] ?? '—'} · '
                        'Available ${p['remaining'] ?? p['available'] ?? '—'}',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'This page is read-only. Assign badges from Liaison Officers → Badges.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
