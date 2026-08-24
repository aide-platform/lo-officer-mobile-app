import 'package:flutter/material.dart';

import '../../data/models/lo_profile.dart';

class LoProfileReviewScreen extends StatefulWidget {
  const LoProfileReviewScreen({super.key});

  @override
  State<LoProfileReviewScreen> createState() => _LoProfileReviewScreenState();
}

class _LoProfileReviewScreenState extends State<LoProfileReviewScreen> {
  List<LoProfile> _profiles = [];
  String _statusFilter = 'All';
  String _query = '';

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

  List<LoProfile> get _filteredProfiles {
    final q = _query.trim().toLowerCase();
    return _profiles.where((profile) {
      final matchesQuery = q.isEmpty ||
          profile.email.toLowerCase().contains(q) ||
          profile.firstName.toLowerCase().contains(q) ||
          profile.lastName.toLowerCase().contains(q) ||
          profile.organisationName.toLowerCase().contains(q);
      final matchesStatus = _statusFilter == 'All' ||
          profile.status.toLowerCase() == _statusFilter.toLowerCase();
      return matchesQuery && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _filteredProfiles;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LO Profile Review'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search organisation or LO',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Submitted'].map((filter) {
                    final selected = _statusFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: selected,
                        onSelected: (_) => setState(() => _statusFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: profiles.isEmpty
                    ? const Center(child: Text('No submitted LO profiles found.'))
                    : ListView.separated(
                        itemCount: profiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final profile = profiles[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${profile.firstName.isNotEmpty ? profile.firstName[0] : 'L'}'),
                              ),
                              title: Text('${profile.firstName} ${profile.lastName}'.trim()),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(profile.email),
                                  Text(profile.organisationName),
                                  Text('Type: ${profile.organisationType}'),
                                  Text('Languages: ${profile.languagesKnown.join(', ')}'),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('LO Profile Details'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Name: ${profile.firstName} ${profile.lastName}'),
                                          Text('Email: ${profile.email}'),
                                          Text('Organisation: ${profile.organisationName}'),
                                          Text('Organisation Type: ${profile.organisationType}'),
                                          Text('Gender: ${profile.gender}'),
                                          Text('Age: ${profile.age}'),
                                          Text('Designation: ${profile.designation}'),
                                          Text('Official Contact: ${profile.officialContactNumber}'),
                                          Text('Languages: ${profile.languagesKnown.join(', ')}'),
                                          Text('Status: ${profile.status}'),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
