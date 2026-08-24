import 'package:flutter/material.dart';

import '../../data/models/lo_assignment.dart';
import '../../data/models/lo_profile.dart';
import 'lo_notifications_screen.dart';
import 'package:liaison_officer/core/notifications/mock_email_notifier.dart';
import '../../data/models/vip.dart';

class LoTaskAssignmentScreen extends StatefulWidget {
  const LoTaskAssignmentScreen({
    super.key,
    required this.vips,
  });

  final List<VIP> vips;

  @override
  State<LoTaskAssignmentScreen> createState() => _LoTaskAssignmentScreenState();
}

class _LoTaskAssignmentScreenState extends State<LoTaskAssignmentScreen> {
  List<LoProfile> _los = const [];
  List<VIP> _delegates = const [];
  String _selectedLo = '';
  String _selectedDelegate = '';
  String _taskSource = 'Custom';
  String _taskTitle = '';
  String _taskDescription = '';
  String _location = '';
  DateTime _scheduledDate = DateTime.now();
  String _message = '';

  @override
  void initState() {
    super.initState();
    _delegates = widget.vips;
    _loadLos();
  }

  Future<void> _loadLos() async {
    final profiles = await LoProfile.listSubmittedProfiles();
    if (!mounted) return;
    setState(() {
      _los = profiles;
      if (_los.isNotEmpty) _selectedLo = _los.first.email;
      if (_delegates.isNotEmpty) _selectedDelegate = _delegates.first.name;
    });
  }

  Future<void> _saveTask() async {
    if (_selectedLo.isEmpty || _selectedDelegate.isEmpty) {
      setState(() => _message = 'Please select both an LO and delegate.');
      return;
    }
    if (_taskTitle.trim().isEmpty && _taskSource == 'Custom') {
      setState(() => _message = 'Task title is required.');
      return;
    }

    final existing = await LoTaskAssignment.getAll();
    existing.add(
      LoTaskAssignment(
        taskTitle: _taskTitle.trim().isNotEmpty ? _taskTitle.trim() : 'Custom Task',
        delegateName: _selectedDelegate,
        assignedLoEmail: _selectedLo,
        taskSource: _taskSource,
        description: _taskDescription.trim().isNotEmpty
            ? _taskDescription.trim()
            : 'Task for $_selectedDelegate',
        scheduledDate: _scheduledDate,
        location: _location.trim(),
      ),
    );
    await LoTaskAssignment.saveAll(existing);
    if (!mounted) return;
    setState(() => _message = 'Task assignment saved.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task assignment saved.')),
    );
    // notify assigned LO and committee
    LoNotificationStore.instance.add(LoNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Task Assigned',
      body: 'Task "${_taskTitle.isNotEmpty ? _taskTitle : 'Custom Task'}" assigned to $_selectedLo for $_selectedDelegate.',
      type: LoNotifType.task,
      timestamp: DateTime.now(),
    ));
    // send mock email to the assigned LO
    await MockEmailNotifier.send(
      to: _selectedLo,
      subject: 'New task assigned',
      body: 'A task "${_taskTitle.isNotEmpty ? _taskTitle : 'Custom Task'}" has been assigned to you for delegate $_selectedDelegate.',
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _scheduledDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Assignment'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
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
              DropdownButtonFormField<String>(
                value: _selectedDelegate.isEmpty && _delegates.isNotEmpty
                    ? _delegates.first.name
                    : _selectedDelegate,
                decoration: InputDecoration(
                  labelText: 'Assigned Delegate',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _delegates
                    .map((vip) => DropdownMenuItem(
                          value: vip.name,
                          child: Text(vip.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedDelegate = value ?? ''),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _taskSource,
                decoration: InputDecoration(
                  labelText: 'Task Source',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Custom', child: Text('Create Custom Task')),
                  DropdownMenuItem(value: 'Activity Master', child: Text('Select from Activity Master')),
                ],
                onChanged: (value) => setState(() => _taskSource = value ?? 'Custom'),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _taskTitle = value),
              ),
              const SizedBox(height: 12),
              TextField(
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Task Description',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _taskDescription = value),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _location = value),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Scheduled Date',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_message),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveTask,
                  icon: const Icon(Icons.task_alt),
                  label: const Text('Assign Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
