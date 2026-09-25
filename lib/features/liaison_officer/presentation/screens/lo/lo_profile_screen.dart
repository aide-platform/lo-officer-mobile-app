import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/services/pick_services.dart';
import 'package:liaison_officer/core/widgets/app_ui_kit.dart';
import 'package:liaison_officer/core/widgets/mobile_ux_kit.dart';
import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:liaison_officer/features/liaison_officer/presentation/bloc/lo_portal_bloc.dart';
import 'package:liaison_officer/theme/app_theme.dart';

class LoProfileScreen extends StatefulWidget {
  const LoProfileScreen({
    super.key,
    required this.email,
    this.readOnly = false,
  });
  final String email;
  final bool readOnly;

  static int calcAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  State<LoProfileScreen> createState() => _LoProfileScreenState();
}

class _LoProfileScreenState extends State<LoProfileScreen> {
  static const _salutations = ['Mr', 'Ms', 'Mrs', 'Dr', 'Prof'];
  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const _languageOptions = [
    'English',
    'Hindi',
    'Kannada',
    'Tamil',
    'Telugu',
    'Malayalam',
    'Marathi',
    'Gujarati',
  ];

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _designation = TextEditingController();
  final _rank = TextEditingController();
  final _officialEmail = TextEditingController();
  final _personalEmail = TextEditingController();
  final _personalContact = TextEditingController();
  final _officialContact = TextEditingController();
  final _whatsapp = TextEditingController();
  final _aadhaar = TextEditingController();
  final _orgId = TextEditingController();

  String _salutation = 'Mr';
  String _gender = 'Male';
  DateTime? _dob;
  /// null = custom WhatsApp; 'official' or 'personal' = mirror that contact.
  String? _whatsappSameAs;
  bool _hasPrevLoExp = false;
  bool _seeded = false;
  int _step = 0; // 0 Personal, 1 Documents, 2 Prior Experience

  final Map<LoUploadKind, String> _uploadNames = {};
  Uint8List? _pendingPhotoBytes;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _designation.dispose();
    _rank.dispose();
    _officialEmail.dispose();
    _personalEmail.dispose();
    _personalContact.dispose();
    _officialContact.dispose();
    _whatsapp.dispose();
    _aadhaar.dispose();
    _orgId.dispose();
    super.dispose();
  }

  void _seed(LiaisonOfficerDto? p) {
    if (_seeded || p == null) return;
    _first.text = p.firstName ?? '';
    _last.text = p.lastName ?? '';
    _designation.text = p.designation ?? '';
    _rank.text = p.rank ?? '';
    _officialEmail.text = p.officialEmail ?? widget.email;
    _personalEmail.text = p.personalEmail ?? '';
    _personalContact.text = p.personalContact ?? '';
    _officialContact.text = p.officialContact ?? '';
    _whatsapp.text = p.whatsappNumber ?? '';
    _aadhaar.text = p.aadhaarNumber ?? '';
    _orgId.text = p.orgIdNumber ?? '';
    if (p.salutationName != null &&
        _salutations.contains(p.salutationName)) {
      _salutation = p.salutationName!;
    }
    if (p.genderName != null && _genders.contains(p.genderName)) {
      _gender = p.genderName!;
    }
    if (p.dateOfBirth != null && p.dateOfBirth!.isNotEmpty) {
      _dob = DateTime.tryParse(p.dateOfBirth!);
    }
    _hasPrevLoExp = p.hasPrevLoExp ?? false;
    if (_whatsapp.text.isNotEmpty) {
      if (_whatsapp.text == _officialContact.text) {
        _whatsappSameAs = 'official';
      } else if (_whatsapp.text == _personalContact.text) {
        _whatsappSameAs = 'personal';
      }
    }
    _seeded = true;
  }

  void _syncWhatsappFromSource() {
    // Kept for future WhatsApp mirror UI.
    if (_whatsappSameAs == 'official') {
      _whatsapp.text = _officialContact.text;
    } else if (_whatsappSameAs == 'personal') {
      _whatsapp.text = _personalContact.text;
    }
  }

  // ignore: unused_element
  void _applyWhatsappMirror() => _syncWhatsappFromSource();

  String _dobLabel() {
    if (_dob == null) return 'Select date of birth';
    final d = _dob!;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _dob = picked);
  }

  Future<void> _pickUpload(LoUploadKind kind, String label) async {
    final file = await ImagePickService.pickImageWithChooser(context);
    if (file == null || !mounted) return;
    // Defer API upload until final Submit (wizard / edit).
    setState(() {
      _uploadNames[kind] = file.filename;
      if (kind == LoUploadKind.photo) {
        _pendingPhotoBytes = file.bytes;
      }
    });
    context.read<LoPortalBloc>().add(
          LoPortalUploadRequested(
            kind: kind,
            bytes: file.bytes,
            filename: file.filename,
          ),
        );
  }

  Widget _uploadRow(LoUploadKind kind, String label) {
    return AppImageThumbRow(
      label: label,
      bytes: kind == LoUploadKind.photo ? _pendingPhotoBytes : null,
      onPick: () => _pickUpload(kind, label),
      onClear: () => setState(() {
        _uploadNames.remove(kind);
        if (kind == LoUploadKind.photo) {
          _pendingPhotoBytes = null;
        }
      }),
    );
  }

  Future<void> _addExperience() async {
    final eventName = TextEditingController();
    final year = TextEditingController();
    final role = TextEditingController();
    final delegateDetails = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add experience'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: eventName,
                decoration: const InputDecoration(labelText: 'Event name'),
              ),
              TextField(
                controller: year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
              TextField(
                controller: role,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              TextField(
                controller: delegateDetails,
                decoration:
                    const InputDecoration(labelText: 'Delegate details'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      context.read<LoPortalBloc>().add(
            LoPortalExperienceAdded({
              'eventName': eventName.text.trim(),
              'year': int.tryParse(year.text.trim()),
              'roleResponsibilities': role.text.trim(),
              'delegateDetails': delegateDetails.text.trim(),
            }),
          );
    }

    eventName.dispose();
    year.dispose();
    role.dispose();
    delegateDetails.dispose();
  }

  void _saveLanguages(List<String> selected) {
    context.read<LoPortalBloc>().add(LoPortalLanguagesSaved(selected));
  }

  void _submit(LoPortalState state) {
    final selected = List<String>.from(state.languages);
    _saveLanguages(selected);
    context.read<LoPortalBloc>().add(
          LoPortalProfileSaved({
            'salutation': _salutation,
            'firstName': _first.text.trim(),
            'lastName': _last.text.trim(),
            'genderName': _gender,
            'dateOfBirth': _dob == null ? null : _dobLabel(),
            'rank': _rank.text.trim(),
            'designation': _designation.text.trim(),
            'orgIdNumber': _orgId.text.trim(),
            'aadhaarNumber': _aadhaar.text.trim(),
            'officialEmail': _officialEmail.text.trim(),
            'personalEmail': _personalEmail.text.trim(),
            'officialContact': _officialContact.text.trim(),
            'personalContact': _personalContact.text.trim(),
            'whatsappNumber': _whatsapp.text.trim(),
            'hasPrevLoExp': _hasPrevLoExp,
            'profileStatus': 'SUBMITTED',
            'profileComplete': true,
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoPortalBloc, LoPortalState>(
      listener: (context, state) {
        if (state.status == LoPortalStatus.ready &&
            state.profile?.profileComplete == true &&
            !widget.readOnly) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Profile saved'),
            ),
          );
          Navigator.of(context).maybePop();
        }
        if (state.status == LoPortalStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(state.errorMessage!),
            ),
          );
        }
      },
      builder: (context, state) {
        _seed(state.profile);
        final p = state.profile;
        final age = _dob == null ? null : LoProfileScreen.calcAge(_dob!);

        if (widget.readOnly) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Profile'),
              actions: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        fullscreenDialog: true,
                        builder: (_) => BlocProvider.value(
                          value: context.read<LoPortalBloc>(),
                          child: LoProfileScreen(
                            email: widget.email,
                            readOnly: false,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p?.fullName ?? '${_first.text} ${_last.text}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      Text(widget.email),
                      Text('Org: ${p?.orgName ?? '—'}'),
                      const SizedBox(height: 8),
                      AppStatusChip(label: p?.profileStatus ?? 'SUBMITTED'),
                      if (p?.currentPassId != null &&
                          p!.currentPassId!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        if (p.currentPassNumber != null)
                          Text('Badge: ${p.currentPassNumber}'),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: () => context.read<LoPortalBloc>().add(
                                LoPortalBadgeDownloadRequested(
                                  passId: p.currentPassId!,
                                  filename:
                                      'badge-${p.currentPassNumber ?? p.currentPassId}.pdf',
                                ),
                              ),
                          icon: const Icon(Icons.badge_outlined),
                          label: const Text('Download badge'),
                        ),
                      ],
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Personal',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      _detailKv('Designation', p?.designation ?? _designation.text),
                      _detailKv('Rank', p?.rank ?? _rank.text),
                      _detailKv('Gender', p?.genderName ?? _gender),
                      _detailKv('DOB', p?.dateOfBirth ?? _dobLabel()),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      _detailKv('Official email', p?.officialEmail),
                      _detailKv('Personal email', p?.personalEmail),
                      _detailKv('Official contact', p?.officialContact),
                      _detailKv('Personal contact', p?.personalContact),
                      _detailKv('WhatsApp', p?.whatsappNumber),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Languages',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      Wrap(
                        spacing: 8,
                        children: state.languages
                            .map((l) => AppStatusChip(label: l))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Documents',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _uploadNames.entries
                            .map((e) => Chip(label: Text(e.value)))
                            .toList(),
                      ),
                      if (_uploadNames.isEmpty)
                        const Text('No documents uploaded yet.'),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        Widget stepBody;
        if (_step == 0) {
          stepBody = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('salutation-$_salutation'),
                  initialValue: _salutation,
                  decoration: const InputDecoration(labelText: 'Salutation'),
                  items: _salutations
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _salutation = v);
                  },
                ),
                TextField(
                  controller: _first,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
                TextField(
                  controller: _last,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey('gender-$_gender'),
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _gender = v);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date of birth'),
                  subtitle: Text(
                    age == null ? _dobLabel() : '${_dobLabel()} · Age $age',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDob,
                ),
                TextField(
                  controller: _rank,
                  decoration: const InputDecoration(labelText: 'Rank'),
                ),
                TextField(
                  controller: _designation,
                  decoration: const InputDecoration(labelText: 'Designation'),
                ),
                TextField(
                  controller: _orgId,
                  decoration: const InputDecoration(
                    labelText: 'Organisation / Service ID',
                  ),
                ),
                TextField(
                  controller: _aadhaar,
                  decoration: const InputDecoration(labelText: 'Aadhaar number'),
                ),
                TextField(
                  controller: _officialEmail,
                  decoration:
                      const InputDecoration(labelText: 'Official email'),
                ),
                TextField(
                  controller: _personalEmail,
                  decoration:
                      const InputDecoration(labelText: 'Personal email'),
                ),
                TextField(
                  controller: _officialContact,
                  decoration:
                      const InputDecoration(labelText: 'Official contact'),
                ),
                TextField(
                  controller: _personalContact,
                  decoration:
                      const InputDecoration(labelText: 'Personal contact'),
                ),
                TextField(
                  controller: _whatsapp,
                  decoration:
                      const InputDecoration(labelText: 'WhatsApp number'),
                ),
                const SizedBox(height: 8),
                const Text('Languages',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Wrap(
                  spacing: 8,
                  children: _languageOptions.map((lang) {
                    final selected = state.languages.contains(lang);
                    return FilterChip(
                      label: Text(lang),
                      selected: selected,
                      onSelected: (on) {
                        final next = List<String>.from(state.languages);
                        if (on) {
                          if (!next.contains(lang)) next.add(lang);
                        } else {
                          next.remove(lang);
                        }
                        _saveLanguages(next);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        } else if (_step == 1) {
          stepBody = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Documents',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.photo, 'Photo'),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.signature, 'Signature'),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.orgBadgeFront, 'Org badge (front)'),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.orgBadgeBack, 'Org badge (back)'),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.aadhaarFront, 'Aadhaar (front)'),
                const SizedBox(height: 8),
                _uploadRow(LoUploadKind.aadhaarBack, 'Aadhaar (back)'),
              ],
            ),
          );
        } else {
          stepBody = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prior LO experience',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('I have previous LO experience'),
                  value: _hasPrevLoExp,
                  onChanged: (v) => setState(() => _hasPrevLoExp = v),
                ),
                if (_hasPrevLoExp) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _addExperience,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ),
                  ...state.experiences.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.eventName ?? 'Event'),
                      subtitle: Text(
                        [
                          if (e.year != null) '${e.year}',
                          e.roleResponsibilities,
                        ]
                            .whereType<String>()
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final active = i == _step;
                    return Container(
                      width: active ? 12 : 8,
                      height: active ? 12 : 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? AppTheme.activeAccent
                            : Colors.grey.shade400,
                      ),
                    );
                  }),
                ),
              ),
              Text(
                ['Personal', 'Documents', 'Prior Experience'][_step],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Expanded(child: ListView(children: [stepBody])),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (_step > 0)
                        TextButton(
                          onPressed: () => setState(() => _step--),
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      if (_step < 2)
                        FilledButton(
                          onPressed: () => setState(() => _step++),
                          child: const Text('Next'),
                        )
                      else
                        FilledButton(
                          onPressed: state.status == LoPortalStatus.saving
                              ? null
                              : () => _submit(state),
                          child: const Text('Submit'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailKv(String k, String? v) {
    if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
