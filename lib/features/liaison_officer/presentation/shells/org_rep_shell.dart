import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/session/auth_logout.dart';
import 'package:liaison_officer/core/themes/presentation/bloc/theme_cubit.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/org_rep_bloc.dart';

class OrgRepShell extends StatefulWidget {
  const OrgRepShell({
    super.key,
    required this.email,
    required this.roleLabel,
  });

  final String email;
  final String roleLabel;

  @override
  State<OrgRepShell> createState() => _OrgRepShellState();
}

class _OrgRepShellState extends State<OrgRepShell> {
  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Organisation Portal',
      actions: [
        IconButton(
          onPressed: () => context.read<ThemeCubit>().toggle(),
          icon: const Icon(Icons.brightness_6_rounded, color: Colors.white),
        ),
        IconButton(
          onPressed: () => performLogout(context),
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nominate(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nominate LO'),
      ),
      body: BlocBuilder<OrgRepBloc, OrgRepState>(
        builder: (context, state) {
          if (state.status == OrgRepStatus.loading ||
              state.status == OrgRepStatus.initial) {
            return const AppLoading(label: 'Loading organisation…');
          }
          if (state.status == OrgRepStatus.failure && state.los.isEmpty) {
            return AppErrorView(
              message: state.errorMessage ?? 'Failed to load',
              onRetry: () =>
                  context.read<OrgRepBloc>().add(OrgRepLoadRequested()),
            );
          }
          final orgName =
              state.organisation?['orgName']?.toString() ?? 'Organisation';
          return Column(
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orgName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(widget.email),
                    Text(widget.roleLabel),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => context
                              .read<OrgRepBloc>()
                              .add(OrgRepBulkReminderRequested()),
                          child: const Text('Remind incomplete'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => _downloadTemplate(context),
                          child: const Text('Import template'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => _bulkImportDemo(context),
                          child: const Text('Bulk import demo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.los.isEmpty
                    ? const AppEmptyState(
                        message: 'No LOs nominated yet.',
                      )
                    : StaggeredList(
                        itemCount: state.los.length,
                        itemBuilder: (context, i) {
                          final lo = state.los[i];
                          return AppCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(lo.displayName),
                              subtitle: Text(
                                '${lo.officialEmail ?? ''}\n'
                                'Status: ${lo.profileStatus ?? '—'}',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                tooltip: 'Send reminder',
                                onPressed: lo.id == null
                                    ? null
                                    : () => context.read<OrgRepBloc>().add(
                                          OrgRepReminderRequested(lo.id!),
                                        ),
                                icon: const Icon(Icons.notifications_active_outlined),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _nominate(BuildContext context) async {
    final first = TextEditingController();
    final last = TextEditingController();
    final email = TextEditingController();
    final mobile = TextEditingController();
    final salutation = TextEditingController(text: 'Mr');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nominate LO'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: salutation,
                  decoration: const InputDecoration(labelText: 'Salutation')),
              TextField(
                  controller: first,
                  decoration: const InputDecoration(labelText: 'First name')),
              TextField(
                  controller: last,
                  decoration: const InputDecoration(labelText: 'Last name')),
              TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Primary email')),
              TextField(
                  controller: mobile,
                  decoration:
                      const InputDecoration(labelText: 'Primary mobile')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      context.read<OrgRepBloc>().add(
            OrgRepNominateRequested({
              'salutation': salutation.text.trim(),
              'firstName': first.text.trim(),
              'lastName': last.text.trim(),
              'primaryEmail': email.text.trim(),
              'primaryMobile': mobile.text.trim(),
            }),
          );
    }
  }

  void _downloadTemplate(BuildContext context) {
    context.read<OrgRepBloc>().add(OrgRepImportTemplateRequested());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Downloading LO import Excel template…'),
      ),
    );
  }

  void _bulkImportDemo(BuildContext context) {
    final csv =
        'firstName,lastName,primaryEmail,primaryMobile\nAsha,Rao,asha@example.com,+919111111111\n';
    context.read<OrgRepBloc>().add(
          OrgRepBulkImportRequested(
            bytes: csv.codeUnits,
            filename: 'lo-import-demo.csv',
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Demo bulk import submitted'),
      ),
    );
  }
}
