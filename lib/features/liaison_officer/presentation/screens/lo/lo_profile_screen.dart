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
    'Odia',
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
  String? _genderId;
  final Map<String, String> _genderIdByName = {};
  DateTime? _dob;
  /// null = custom WhatsApp; 'official' or 'personal' = mirror that contact.
  String? _whatsappSameAs;
  bool _hasPrevLoExp = false;
  bool _seeded = false;
  int _step = 0; // 0 Personal, 1 Documents, 2 Prior Experience
  List<String> _draftLanguages = [];
  String? _languagePick;
  bool _languagesSeeded = false;

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
    if ((p.genderId ?? '').trim().isNotEmpty) {
      _genderId = p.genderId!.trim();
      if ((p.genderName ?? '').trim().isNotEmpty) {
        _genderIdByName[p.genderName!.trim()] = _genderId!;
      }
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
    String? eventError;
    String? roleError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add experience'),
          content: SingleChildScrollView(
            child: AppFormColumn(
              children: [
                TextField(
                  controller: eventName,
                  decoration: InputDecoration(
                    labelText: 'Event name *',
                    errorText: eventError,
                  ),
                ),
                TextField(
                  controller: year,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Year'),
                ),
                TextField(
                  controller: role,
                  decoration: InputDecoration(
                    labelText: 'Role / responsibilities *',
                    errorText: roleError,
                  ),
                ),
                TextField(
                  controller: delegateDetails,
                  decoration: const InputDecoration(
                    labelText: 'Delegate details (optional)',
                  ),
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
              onPressed: () {
                final name = eventName.text.trim();
                final roleText = role.text.trim();
                setLocal(() {
                  eventError =
                      name.isEmpty ? 'Event name is required.' : null;
                  roleError =
                      roleText.isEmpty ? 'Role is required.' : null;
                });
                if (name.isEmpty || roleText.isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
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

  void _seedDraftLanguages(List<String> fromState) {
    if (_languagesSeeded) return;
    _draftLanguages = List<String>.from(fromState);
    _languagesSeeded = true;
  }

  void _addLanguage() {
    final pick = _languagePick;
    if (pick == null || pick.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Pick a language first.'),
        ),
      );
      return;
    }
    final exists = _draftLanguages.any(
      (l) => l.toLowerCase() == pick.toLowerCase(),
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('You have already added this language.'),
        ),
      );
      return;
    }
    setState(() {
      _draftLanguages = [..._draftLanguages, pick];
      _languagePick = null;
    });
  }

  void _removeLanguage(String lang) {
    setState(() {
      _draftLanguages = _draftLanguages
          .where((l) => l.toLowerCase() != lang.toLowerCase())
          .toList();
    });
  }

  String? _validateProfile() {
    if (_first.text.trim().isEmpty) return 'First name is required.';
    if (_last.text.trim().isEmpty) return 'Last name is required.';
    if ((_genderId ?? '').trim().isEmpty) {
      return 'Gender is required. Re-select gender or reload your profile.';
    }
    if (_dob == null) return 'Date of birth is required.';
    if (_designation.text.trim().isEmpty) return 'Designation is required.';
    if (_orgId.text.trim().isEmpty) {
      return 'Organisation ID number is required.';
    }
    if (_aadhaar.text.trim().isEmpty) return 'Aadhaar number is required.';
    if (_personalEmail.text.trim().isEmpty) {
      return 'Personal email is required.';
    }
    if (_personalContact.text.trim().isEmpty) {
      return 'Personal contact is required.';
    }
    return null;
  }

  void _submit(LoPortalState state) {
    final validationError = _validateProfile();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(validationError),
        ),
      );
      return;
    }
    context.read<LoPortalBloc>().add(
          LoPortalLanguagesSaved(List<String>.from(_draftLanguages)),
        );
    context.read<LoPortalBloc>().add(
          LoPortalProfileSaved({
            'salutation': _salutation,
            'firstName': _first.text.trim(),
            'lastName': _last.text.trim(),
            'genderId': _genderId,
            'genderName': _gender,
            'dateOfBirth': _dobLabel(),
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
            state.infoMessage == 'Profile saved' &&
            !widget.readOnly) {
          // Shell already toasts infoMessage when gating; avoid duplicate when embedded.
          if (Navigator.of(context).canPop()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Profile saved'),
              ),
            );
            Navigator.of(context).maybePop();
          }
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
        _seedDraftLanguages(state.languages);
        final p = state.profile;
        final age = _dob == null ? null : LoProfileScreen.calcAge(_dob!);

        if (widget.readOnly) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Profile'),
              actions: [
                TextButton.icon(
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
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  label: const Text(
                    'Update Details',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
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
                      const Text(
                        'Personal details',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is what your organisation, the LO Committee and '
                        'downstream committees see about you.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      _detailKv('Salutation', _salutation),
                      _detailKv(
                        'Full name',
                        p?.fullName ?? '${_first.text} ${_last.text}'.trim(),
                      ),
                      _detailKv('Gender', p?.genderName ?? _gender),
                      _detailKv('Date of birth', p?.dateOfBirth ?? _dobLabel()),
                      if (age != null) _detailKv('Age', '$age'),
                      _detailKv('Organisation name', p?.orgName),
                      _detailKv('Organisation type', p?.orgTypeName),
                      _detailKv('Rank', p?.rank ?? _rank.text),
                      _detailKv(
                        'Designation',
                        p?.designation ?? _designation.text,
                      ),
                      _detailKv('Org ID number', p?.orgIdNumber ?? _orgId.text),
                      _detailKv('Aadhaar', p?.aadhaarNumber ?? _aadhaar.text),
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
                      const Text(
                        'Languages known',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (state.languages.isEmpty)
                        Text(
                          'No languages added. Tap Update Details to add languages.',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.languages
                              .map((l) => Chip(label: Text(l)))
                              .toList(),
                        ),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Document uploads',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      _docStatusRow(
                        'Photograph',
                        p?.photoFileName,
                        p?.photoFileId,
                      ),
                      _docStatusRow(
                        'Signature',
                        p?.signatureFileName,
                        p?.signatureFileId,
                      ),
                      _docStatusRow(
                        'Aadhaar (Front)',
                        p?.aadhaarFrontFileName,
                        p?.aadhaarFrontId,
                      ),
                      _docStatusRow(
                        'Aadhaar (Back)',
                        p?.aadhaarBackFileName,
                        p?.aadhaarBackId,
                      ),
                      _docStatusRow(
                        'Org Badge (Front)',
                        p?.orgBadgeFrontFileName,
                        p?.orgBadgeFrontId,
                      ),
                      _docStatusRow(
                        'Org Badge (Back)',
                        p?.orgBadgeBackFileName,
                        p?.orgBadgeBackId,
                      ),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prior LO experience',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      _detailKv(
                        'Has LO experience',
                        (p?.hasPrevLoExp ?? _hasPrevLoExp) ? 'Yes' : 'No',
                      ),
                      if (state.experiences.isEmpty)
                        Text(
                          (p?.hasPrevLoExp ?? _hasPrevLoExp)
                              ? 'No experience rows yet. Tap Update Details to add them.'
                              : 'No prior LO experience recorded.',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        ...state.experiences.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          e.eventName ?? 'Event',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (e.year != null)
                                        Chip(
                                          label: Text('${e.year}'),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                  if ((e.roleResponsibilities ?? '')
                                      .isNotEmpty)
                                    Text('Role: ${e.roleResponsibilities}'),
                                  if ((e.delegateDetails ?? '').isNotEmpty)
                                    Text('Delegates: ${e.delegateDetails}'),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          );
        }

        Widget stepBody;
        if (_step == 0) {
          stepBody = AppCard(
            child: AppFormColumn(
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
                  decoration: const InputDecoration(labelText: 'Gender *'),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _gender = v;
                      _genderId = _genderIdByName[v];
                    });
                  },
                ),
                if ((p?.orgName ?? '').isNotEmpty)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Organisation name',
                      helperText: 'From your parent organisation record.',
                    ),
                    child: Text(p!.orgName!),
                  ),
                if ((p?.orgTypeName ?? '').isNotEmpty)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Organisation type',
                      helperText: 'From your parent organisation record.',
                    ),
                    child: Text(p!.orgTypeName!),
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
                const Text(
                  'Languages known',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_draftLanguages.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _draftLanguages
                        .map(
                          (lang) => InputChip(
                            label: Text(lang),
                            onDeleted: () => _removeLanguage(lang),
                          ),
                        )
                        .toList(),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(
                          'lang-pick-$_languagePick-${_draftLanguages.length}',
                        ),
                        initialValue: _languagePick,
                        decoration: const InputDecoration(
                          labelText: 'Pick a language',
                        ),
                        items: _languageOptions
                            .where(
                              (o) => !_draftLanguages.any(
                                (l) => l.toLowerCase() == o.toLowerCase(),
                              ),
                            )
                            .map(
                              (o) => DropdownMenuItem(
                                value: o,
                                child: Text(o),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _languagePick = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _addLanguage,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                Text(
                  'Added languages are saved when you Submit on the final step.',
                  style: Theme.of(context).textTheme.bodySmall,
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
                    child: FilledButton.icon(
                      onPressed: _addExperience,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Experience'),
                    ),
                  ),
                  Text(
                    'New rows are saved when you Submit below.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  ...state.experiences.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.eventName ?? 'Event'),
                      subtitle: Text(
                        [
                          if (e.year != null) '${e.year}',
                          e.roleResponsibilities,
                          e.delegateDetails,
                        ]
                            .whereType<String>()
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                      ),
                      trailing: e.id == null
                          ? null
                          : IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => context.read<LoPortalBloc>().add(
                                    LoPortalExperienceDeleted(e.id!),
                                  ),
                            ),
                    ),
                  ),
                ] else
                  Text(
                    'Any recorded event rows will be removed when you Submit.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFEF6C00),
                        ),
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: SafeArea(
            child: Column(
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

  Widget _docStatusRow(String label, String? fileName, String? fileId) {
    final uploaded =
        (fileId ?? '').trim().isNotEmpty || (fileName ?? '').trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  uploaded
                      ? (fileName?.trim().isNotEmpty == true
                          ? fileName!
                          : 'Uploaded')
                      : 'Not uploaded',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          AppStatusChip(
            label: uploaded
                ? 'Uploaded'
                : (widget.readOnly ? 'Missing — tap Update Details' : 'Missing'),
          ),
        ],
      ),
    );
  }
}
