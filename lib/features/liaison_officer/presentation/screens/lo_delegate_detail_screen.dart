import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_semantic_colors.dart';
import '../../../../core/widgets/gradient_app_bar.dart';
import '../../data/models/vip.dart';
import 'lo_delegate_updates_screen.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _fmtDateTime(DateTime d) =>
    '${_fmtDate(d)} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class LoDelegateDetailScreen extends StatelessWidget {
  const LoDelegateDetailScreen({
    super.key,
    required this.vip,
    this.allVips = const [],
  });

  final VIP vip;
  final List<VIP> allVips;

  @override
  Widget build(BuildContext context) {
    final s = context.semantic;

    return Scaffold(
      backgroundColor: s.scaffold,
      appBar: GradientAppBar(
        accent: AppColors.roleLO,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vip.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              vip.designation,
              style: const TextStyle(color: AppColors.goldLight, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Travel updates',
            icon: const Icon(Icons.flight_takeoff, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoDelegateUpdatesScreen(
                    vips: allVips.isEmpty ? [vip] : allVips,
                    initialDelegateName: vip.name,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionCard(
            title: 'Delegate Profile',
            icon: Icons.badge_outlined,
            children: [
              _DetailRow(label: 'Full Name', value: vip.name),
              _DetailRow(label: 'Salutation', value: vip.salutation),
              _DetailRow(label: 'Gender', value: vip.gender),
              _DetailRow(label: 'Designation', value: vip.designation),
              _DetailRow(
                label: 'Protocol Equivalence',
                value: vip.protocolEquivalence,
              ),
              _DetailRow(label: 'Contact', value: vip.contact),
              _DetailRow(label: 'Email', value: vip.email),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Organisation / Ministry',
            icon: Icons.account_balance_outlined,
            children: [
              _DetailRow(label: 'Organisation', value: vip.organisation),
              _DetailRow(label: 'Ministry', value: vip.ministry),
            ],
          ),
          if (vip.isForeign ||
              (vip.passportNumber != null &&
                  vip.passportNumber!.trim().isNotEmpty)) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Passport Details',
              icon: Icons.menu_book_outlined,
              children: [
                _DetailRow(label: 'Nationality', value: vip.nationality ?? '—'),
                _DetailRow(
                  label: 'Passport Number',
                  value: vip.passportNumber ?? '—',
                ),
                _DetailRow(
                  label: 'Passport Validity',
                  value: vip.passportValidity != null
                      ? _fmtDate(vip.passportValidity!)
                      : '—',
                ),
                _DetailRow(label: 'Visa Status', value: vip.visaStatus ?? '—'),
                _DetailRow(
                  label: 'Security Clearance',
                  value: vip.securityClearanceStatus ?? '—',
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Family Members',
            icon: Icons.family_restroom_outlined,
            children: vip.familyMembers.isEmpty
                ? [
                    Text(
                      'No accompanying family members listed.',
                      style: TextStyle(color: s.textMuted, fontSize: 13),
                    ),
                  ]
                : vip.familyMembers
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: s.inputFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: s.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${m.salutation} ${m.fullName}'.trim(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: s.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${m.relation} · ${m.gender}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: s.textSecondary,
                                ),
                              ),
                              if (m.passportNumber != null &&
                                  m.passportNumber!.isNotEmpty)
                                Text(
                                  'Passport: ${m.passportNumber}'
                                  '${m.passportValidity != null ? ' · Valid till ${_fmtDate(m.passportValidity!)}' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: s.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Event Nominations',
            icon: Icons.event_available_outlined,
            children: vip.eventNominations.isEmpty
                ? [
                    Text(
                      'No event nominations yet.',
                      style: TextStyle(color: s.textMuted, fontSize: 13),
                    ),
                  ]
                : vip.eventNominations
                    .map(
                      (e) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.celebration_outlined,
                            color: s.accent),
                        title: Text(
                          e.eventName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: s.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${_fmtDateTime(e.dateTime)}\n${e.venue}',
                          style: TextStyle(
                            fontSize: 12,
                            color: s.textSecondary,
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Vehicle / Transport',
            icon: Icons.directions_car_outlined,
            children: [
              _DetailRow(
                label: 'Vehicle Type',
                value: vip.transport.vehicleType,
              ),
              _DetailRow(
                label: 'Vehicle Number',
                value: vip.transport.vehicleNumber,
              ),
              _DetailRow(
                label: 'Driver Name',
                value: vip.transport.driverName,
              ),
              _DetailRow(
                label: 'Driver Contact',
                value: vip.transport.driverContact,
              ),
              _DetailRow(label: 'Status', value: vip.transport.status),
              if (vip.transport.flightNumber != null &&
                  vip.transport.flightNumber!.isNotEmpty)
                _DetailRow(
                  label: 'Arrival Flight',
                  value: vip.transport.flightNumber!,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Accommodation',
            icon: Icons.hotel_outlined,
            children: [
              _DetailRow(label: 'Hotel', value: vip.hotel.name),
              _DetailRow(label: 'Room', value: vip.hotel.roomNumber),
              _DetailRow(label: 'Stay', value: vip.hotel.stayDuration),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final s = context.semantic;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: s.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: s.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final s = context.semantic;
    final display = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: s.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              display,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: s.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
