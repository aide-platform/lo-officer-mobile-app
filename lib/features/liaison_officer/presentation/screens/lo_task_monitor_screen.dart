import 'package:flutter/material.dart';

import '../../data/models/lo_assignment.dart';
import 'lo_notifications_screen.dart';
import 'package:liaison_officer/core/notifications/mock_email_notifier.dart';

class LoTaskMonitoringScreen extends StatefulWidget {
  const LoTaskMonitoringScreen({super.key});

  @override
  State<LoTaskMonitoringScreen> createState() => _LoTaskMonitoringScreenState();
}

class _LoTaskMonitoringScreenState extends State<LoTaskMonitoringScreen> {
  List<LoTaskAssignment> _tasks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await LoTaskAssignment.getAll();
    if (!mounted) return;
    setState(() => _tasks = tasks);
  }

  Future<void> _updateStatus(LoTaskAssignment task, String status) async {
    await LoTaskAssignment.updateStatus(
      delegateName: task.delegateName,
      assignedLoEmail: task.assignedLoEmail,
      taskTitle: task.taskTitle,
      status: status,
    );
    if (!mounted) return;
    await _load();
    // notify the LO and nodal officer about status change
    LoNotificationStore.instance.add(LoNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Task Status Updated',
      body: 'Task "${task.taskTitle}" for ${task.delegateName} marked $status by ${task.assignedLoEmail}.',
      type: LoNotifType.task,
      timestamp: DateTime.now(),
    ));
    await MockEmailNotifier.send(
      to: task.assignedLoEmail,
      subject: 'Task status updated',
      body: 'Task "${task.taskTitle}" for ${task.delegateName} marked $status.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Monitoring')),
        body: Center(child: Text('No tasks assigned yet.')),
      );
    }

    final grouped = <String, List<LoTaskAssignment>>{};
    for (final task in _tasks) {
      grouped.putIfAbsent(task.delegateName, () => []).add(task);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Task Monitoring')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: grouped.entries.map((entry) {
            final delegate = entry.key;
            final tasks = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delegate,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...tasks.map((task) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).dividerColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(task.taskTitle, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DropdownButton<String>(
                                      value: task.status,
                                      items: const [
                                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                        DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                                        DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                                      ],
                                      onChanged: (value) async {
                                        if (value == null) return;
                                        await _updateStatus(task, value);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(task.description),
                                const SizedBox(height: 4),
                                Text('LO: ${task.assignedLoEmail}'),
                                Text('Source: ${task.taskSource}'),
                                Text('Date: ${task.scheduledDate.day}/${task.scheduledDate.month}/${task.scheduledDate.year}'),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}