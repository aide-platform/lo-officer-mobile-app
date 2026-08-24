import 'package:flutter/material.dart';

import '../../data/models/lo_profile.dart';
import 'lo_notifications_screen.dart';
import 'package:liaison_officer/core/notifications/mock_email_notifier.dart';

class LoBadgeAssignmentScreen extends StatefulWidget {
  const LoBadgeAssignmentScreen({super.key});

  @override
  State<LoBadgeAssignmentScreen> createState() => _LoBadgeAssignmentScreenState();
}

class _LoBadgeAssignmentScreenState extends State<LoBadgeAssignmentScreen> {
  final int _quota = 10;
  List<LoProfile> _profiles = [];
  final Set<String> _selectedEmails = <String>{};
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final profiles = await LoProfile.listSubmittedProfiles();
    if (!mounted) return;
    setState(() => _profiles = profiles);
  }

  Future<void> _assignBadges() async {
    if (_selectedEmails.length > _quota) {
      setState(() => _message = 'Badge quota exceeded. Maximum allowed: $_quota.');
      return;
    }

    if (_selectedEmails.isEmpty) {
      setState(() => _message = 'Select at least one LO to assign a badge.');
      return;
    }

    await LoProfile.saveAssignedBadges(_selectedEmails.toList());
    if (!mounted) return;
    setState(() => _message = 'Badges assigned to ${_selectedEmails.length} LO(s).');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Badges assigned to ${_selectedEmails.length} LO(s).')),
    );
    // Add notification for assigned badges
    LoNotificationStore.instance.add(LoNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Badges Assigned',
      body: 'Badges assigned to ${_selectedEmails.length} LO(s).',
      type: LoNotifType.instruction,
      timestamp: DateTime.now(),
    ));
    // send mock email to organisation/nodal officer
    await MockEmailNotifier.send(
      to: 'nodal_officer@aeroindia.test',
      subject: 'Badges assigned to your committee',
      body: 'Badges assigned to ${_selectedEmails.length} LO(s).',
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedEmails.length;
    final canAssign = selectedCount > 0 && selectedCount <= _quota;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badge Assignment'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Badge quota'),
                      Text('$selectedCount / $_quota selected'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_message),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: _profiles.isEmpty
                    ? const Center(child: Text('No submitted LO profiles to assign badges.'))
                    : ListView.separated(
                        itemCount: _profiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
                          final selected = _selectedEmails.contains(profile.email);
                          return CheckboxListTile(
                            value: selected,
                            title: Text('${profile.firstName} ${profile.lastName}'.trim()),
                            subtitle: Text('${profile.email}\n${profile.organisationName}'),
                            secondary: const Icon(Icons.badge_outlined),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedEmails.add(profile.email);
                                } else {
                                  _selectedEmails.remove(profile.email);
                                }
                                _message = '';
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canAssign ? _assignBadges : null,
                  icon: const Icon(Icons.assignment_turned_in),
                  label: const Text('Assign Badges'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
