import 'package:flutter/material.dart';

import '../../data/models/lo_assignment.dart';
import '../../data/models/lo_profile.dart';
import 'lo_notifications_screen.dart';
import 'package:liaison_officer/core/notifications/mock_email_notifier.dart';
import '../../data/models/vip.dart';

class LoDelegateAssignmentScreen extends StatefulWidget {
  const LoDelegateAssignmentScreen({
    super.key,
    required this.vips,
  });

  final List<VIP> vips;

  @override
  State<LoDelegateAssignmentScreen> createState() => _LoDelegateAssignmentScreenState();
}

class _LoDelegateAssignmentScreenState extends State<LoDelegateAssignmentScreen> {
  String _selectedDelegate = '';
  String _selectedLo = '';
  List<LoProfile> _los = const [];
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadLos();
  }

  Future<void> _loadLos() async {
    final profiles = await LoProfile.listSubmittedProfiles();
    if (!mounted) return;
    setState(() {
      _los = profiles;
      if (_los.isNotEmpty) _selectedLo = _los.first.email;
    });
  }

  Future<void> _saveAssignment() async {
    if (_selectedDelegate.isEmpty) {
      setState(() => _message = 'Select a delegate first.');
      return;
    }
    if (_selectedLo.isEmpty) {
      setState(() => _message = 'Select an LO first.');
      return;
    }

    final existing = await LoDelegateAssignment.getAll();
    final updated = [
      ...existing,
      LoDelegateAssignment(
        delegateName: _selectedDelegate,
        assignedLoEmail: _selectedLo,
        createdAt: DateTime.now(),
      ),
    ];
    await LoDelegateAssignment.saveAll(updated);
    if (!mounted) return;
    setState(() => _message = 'Delegate assigned to LO successfully.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delegate assigned to LO.')),
    );
    // Notification for delegate assignment
    LoNotificationStore.instance.add(LoNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Delegate Assigned',
      body: '${_selectedDelegate} assigned to LO ${_selectedLo}.',
      type: LoNotifType.task,
      timestamp: DateTime.now(),
    ));
    await MockEmailNotifier.send(
      to: _selectedLo,
      subject: 'You have been assigned a delegate',
      body: '${_selectedDelegate} has been assigned to you as a delegate. Please review details in the LO portal.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delegate Assignment'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDelegate.isEmpty && widget.vips.isNotEmpty
                    ? widget.vips.first.name
                    : _selectedDelegate,
                decoration: InputDecoration(
                  labelText: 'Delegate',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.vips
                    .map((vip) => DropdownMenuItem(
                          value: vip.name,
                          child: Text(vip.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedDelegate = value ?? '');
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedLo.isEmpty ? null : _selectedLo,
                decoration: InputDecoration(
                  labelText: 'Assigned LO',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _los
                    .map((lo) => DropdownMenuItem(
                          value: lo.email,
                          child: Text('${lo.firstName} ${lo.lastName}'.trim().isEmpty ? lo.email : '${lo.firstName} ${lo.lastName}'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedLo = value ?? ''),
              ),
              const SizedBox(height: 12),
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_message),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveAssignment,
                  icon: const Icon(Icons.assignment_ind),
                  label: const Text('Assign LO to Delegate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
