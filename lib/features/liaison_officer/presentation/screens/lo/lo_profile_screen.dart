import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Accepts `dd-mm-yyyy` and `yyyy-mm-dd` (including an ISO time suffix).
  static DateTime? parseDob(String raw) {
    final trimmed = raw.trim();
    final dmy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(trimmed);
    if (dmy != null) {
      return _calendarDate(
        int.parse(dmy.group(3)!),
        int.parse(dmy.group(2)!),
        int.parse(dmy.group(1)!),
      );
    }
    final iso = DateTime.tryParse(trimmed);
    if (iso == null) return null;
    final local = iso.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime? _calendarDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static String formatDob(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }

  /// Value stored by the portal (`yyyy-mm-dd`).
  static String formatDobIso(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static final _salutationPattern = RegExp(r'^[A-Za-z][A-Za-z .]{0,59}$');
  static final _personName = RegExp(r"^[A-Za-z][A-Za-z .,'\-]{0,199}$");
  static final _rankPattern = RegExp(
    r"^[A-Za-z0-9][A-Za-z0-9 .,'()\-_/&]{0,99}$",
  );
  static final _designationPattern = RegExp(
    r"^[A-Za-z0-9][A-Za-z0-9 .,'()\-_/&]{0,199}$",
  );
  static final _orgIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9 /_\-]{0,99}$');
  static final _aadhaarPattern = RegExp(r'^[0-9][0-9 ]{11,19}$');
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phonePattern = RegExp(r'^[+0-9][0-9 \-]{4,29}$');

  static String? salutationError(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Salutation is required.';
    if (!_salutationPattern.hasMatch(value)) {
      return 'Salutation may only contain letters, spaces, and dots (e.g. Mr., Dr., Capt.)';
    }
    return null;
  }

  static String? personNameError(String raw, {required String label}) {
    final value = raw.trim();
    if (value.isEmpty) return '$label is required.';
    if (!_personName.hasMatch(value)) {
      return '$label may only contain letters, spaces and . , \' -';
    }
    return null;
  }

  static String? rankError(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (!_rankPattern.hasMatch(value)) {
      return 'Rank contains invalid characters.';
    }
    return null;
  }

  static String? designationError(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Designation is required.';
    if (!_designationPattern.hasMatch(value)) {
      return 'Designation contains invalid characters.';
    }
    return null;
  }

  static String? orgIdError(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Organisation ID number is required.';
    if (!_orgIdPattern.hasMatch(value)) {
      return 'Organisation ID may only contain letters, digits, spaces and / _ -';
    }
    return null;
  }

  static String? aadhaarError(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Aadhaar number is required.';
    if (!_aadhaarPattern.hasMatch(value)) {
      return 'Aadhaar must be 12 digits (spaces allowed).';
    }
    return null;
  }

  static String? emailError(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Personal email is required.';
    if (!_emailPattern.hasMatch(value)) return 'Personal email is invalid.';
    return null;
  }

  static String? phoneError(
    String raw, {
    required bool required,
    required String emptyMessage,
    required String invalidMessage,
  }) {
    final value = raw.trim();
    if (value.isEmpty) return required ? emptyMessage : null;
    if (!_phonePattern.hasMatch(value)) return invalidMessage;
    return null;
  }

  static bool isAllowedProfileImage({String? filename, String? mimeType}) {
    const mimes = {'image/jpeg', 'image/jpg', 'image/png'};
    final mime = mimeType?.trim().toLowerCase() ?? '';
    final mimeOk = mimes.contains(mime);
    final extOk = RegExp(
      r'\.(jpe?g|png)$',
      caseSensitive: false,
    ).hasMatch(filename ?? '');
    return mimeOk || extOk;
  }

  static String? experienceRowError({
    required int index,
    required String? eventName,
    required String? role,
    required int? year,
    int? currentYear,
  }) {
    final row = index + 1;
    if ((eventName ?? '').trim().isEmpty) {
      return 'Row $row: Event name is required.';
    }
    if ((role ?? '').trim().isEmpty) {
      return 'Row $row: Role / responsibilities is required.';
    }
    final maxYear = currentYear ?? DateTime.now().year;
    if (year == null) return 'Row $row: Year is required.';
    if (year < 1990 || year > maxYear) {
      return 'Row $row: Year must be between 1990 and $maxYear.';
    }
    return null;
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
  final _trouserWaist = TextEditingController();
  final _trouserLength = TextEditingController();
  final _blazerChest = TextEditingController();
  final _blazerSleeve = TextEditingController();

  String _salutation = 'Mr';
  String _gender = 'Male';
  String? _genderId;
  final Map<String, String> _genderIdByName = {};
  DateTime? _dob;

  /// null = custom WhatsApp; 'official' or 'personal' = mirror that contact.
  String? _whatsappSameAs;
  bool _hasPrevLoExp = false;
  bool _seeded = false;
  int _step = 0; // 0 Personal, 1 Documents, 2 Dress, 3 Prior Experience
  List<String> _draftLanguages = [];
  String? _languagePick;
  bool _languagesSeeded = false;

  final Map<LoUploadKind, String> _uploadNames = {};
  Uint8List? _pendingPhotoBytes;
  static final _phoneInput = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
    LengthLimitingTextInputFormatter(30),
  ];
  static final _aadhaarInput = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
    LengthLimitingTextInputFormatter(20),
  ];

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
    _trouserWaist.dispose();
    _trouserLength.dispose();
    _blazerChest.dispose();
    _blazerSleeve.dispose();
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
    _trouserWaist.text = _fmtInches(p.trouserWaist);
    _trouserLength.text = _fmtInches(p.trouserLength);
    _blazerChest.text = _fmtInches(p.blazerChest);
    _blazerSleeve.text = _fmtInches(p.blazerSleeve);
    if (p.salutationName != null && _salutations.contains(p.salutationName)) {
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
      _dob = LoProfileScreen.parseDob(p.dateOfBirth!);
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
    return LoProfileScreen.formatDob(_dob!);
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
    if (!LoProfileScreen.isAllowedProfileImage(
      filename: file.filename,
      mimeType: file.mimeType,
    )) {
      _showError('Only JPEG / JPG / PNG images are allowed.');
      return;
    }
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
    String? yearError;

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
                  decoration: InputDecoration(
                    labelText: 'Year *',
                    errorText: yearError,
                  ),
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
                final yearText = year.text.trim();
                final parsedYear = int.tryParse(yearText);
                final maxYear = DateTime.now().year;
                setLocal(() {
                  eventError = name.isEmpty ? 'Event name is required.' : null;
                  roleError = roleText.isEmpty
                      ? 'Role / responsibilities is required.'
                      : null;
                  if (yearText.isEmpty) {
                    yearError = 'Year is required.';
                  } else if (parsedYear == null ||
                      parsedYear < 1990 ||
                      parsedYear > maxYear) {
                    yearError =
                        'Year must be a 4-digit year between 1990 and $maxYear.';
                  } else {
                    yearError = null;
                  }
                });
                if (name.isEmpty ||
                    roleText.isEmpty ||
                    yearText.isEmpty ||
                    parsedYear == null ||
                    parsedYear < 1990 ||
                    parsedYear > maxYear) {
                  return;
                }
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  String? _validatePersonal() {
    return LoProfileScreen.salutationError(_salutation) ??
        LoProfileScreen.personNameError(_first.text, label: 'First name') ??
        LoProfileScreen.personNameError(_last.text, label: 'Last name') ??
        ((_genderId ?? '').trim().isEmpty ? 'Gender is required.' : null) ??
        (_dob == null ? 'Date of birth is required.' : null) ??
        LoProfileScreen.rankError(_rank.text) ??
        LoProfileScreen.designationError(_designation.text) ??
        LoProfileScreen.orgIdError(_orgId.text) ??
        LoProfileScreen.aadhaarError(_aadhaar.text) ??
        LoProfileScreen.emailError(_personalEmail.text) ??
        LoProfileScreen.phoneError(
          _personalContact.text,
          required: true,
          emptyMessage: 'Personal contact number is required.',
          invalidMessage: 'Personal contact is invalid.',
        ) ??
        LoProfileScreen.phoneError(
          _officialContact.text,
          required: true,
          emptyMessage: 'Mobile number (from nomination) is required.',
          invalidMessage: 'Mobile number (from nomination) is invalid.',
        ) ??
        LoProfileScreen.phoneError(
          _whatsapp.text,
          required: false,
          emptyMessage: '',
          invalidMessage: 'WhatsApp number is invalid.',
        );
  }

  String? _validateDocuments(LiaisonOfficerDto? profile) {
    final missing = <String>[];
    void need(LoUploadKind kind, String label, String? fileId) {
      final onServer = (fileId ?? '').trim().isNotEmpty;
      if (!onServer && !_uploadNames.containsKey(kind)) missing.add(label);
    }

    need(LoUploadKind.photo, 'Photo', profile?.photoFileId);
    need(
      LoUploadKind.signature,
      'Specimen Signature',
      profile?.signatureFileId,
    );
    need(LoUploadKind.aadhaarFront, 'Aadhaar (Front)', profile?.aadhaarFrontId);
    need(LoUploadKind.aadhaarBack, 'Aadhaar (Back)', profile?.aadhaarBackId);
    need(
      LoUploadKind.orgBadgeFront,
      'Org Badge (Front)',
      profile?.orgBadgeFrontId,
    );
    need(
      LoUploadKind.orgBadgeBack,
      'Org Badge (Back)',
      profile?.orgBadgeBackId,
    );
    if (missing.isEmpty) return null;
    return 'Please upload: ${missing.join(', ')}.';
  }

  String? _validateExperiences(List<LoExperienceDto> experiences) {
    if (!_hasPrevLoExp) return null;
    for (var i = 0; i < experiences.length; i++) {
      final row = experiences[i];
      final error = LoProfileScreen.experienceRowError(
        index: i,
        eventName: row.eventName,
        role: row.roleResponsibilities,
        year: row.year,
      );
      if (error != null) return error;
    }
    return null;
  }

  String? _validateProfile(LoPortalState state) {
    return _validatePersonal() ??
        _validateDocuments(state.profile) ??
        _validateMeasurements() ??
        _validateExperiences(state.experiences);
  }

  static const _steps = [
    'Personal Details',
    'Document Uploads',
    'Dress Measurements',
    'Prior LO Experience',
  ];

  String _fmtInches(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  String? _validateMeasurements() {
    return _inchError(_trouserWaist.text, 'Trousers', 'Waist', 10, 80) ??
        _inchError(_trouserLength.text, 'Trousers', 'Length', 20, 60) ??
        _inchError(_blazerChest.text, 'Blazer', 'Chest', 20, 80) ??
        _inchError(_blazerSleeve.text, 'Blazer', 'Sleeve Length', 15, 50);
  }

  String? _inchError(
    String raw,
    String group,
    String label,
    double min,
    double max,
  ) {
    if (raw.trim().isEmpty) return '$group — $label is required.';
    final value = double.tryParse(raw.trim());
    if (value == null) return '$group — $label must be a number.';
    if (value < min || value > max) {
      return '$group — $label must be between ${min.toInt()} and ${max.toInt()} inches.';
    }
    return null;
  }

  double _inches(TextEditingController controller) =>
      double.parse(controller.text.trim());

  void _goNext(LoPortalState state) {
    final error = switch (_step) {
      0 => _validatePersonal(),
      1 => _validateDocuments(state.profile),
      2 => _validateMeasurements(),
      _ => null,
    };
    if (error != null) {
      _showError(error);
      return;
    }
    setState(() => _step++);
  }

  void _submit(LoPortalState state) {
    final validationError = _validateProfile(state);
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
        'dateOfBirth': LoProfileScreen.formatDobIso(_dob!),
        'rank': _rank.text.trim(),
        'designation': _designation.text.trim(),
        'orgIdNumber': _orgId.text.trim(),
        'aadhaarNumber': _aadhaar.text.trim(),
        'officialEmail': _officialEmail.text.trim(),
        'personalEmail': _personalEmail.text.trim(),
        'officialContact': _officialContact.text.trim(),
        'personalContact': _personalContact.text.trim(),
        'whatsappNumber': _whatsapp.text.trim(),
        'trouserWaist': _inches(_trouserWaist),
        'trouserLength': _inches(_trouserLength),
        'blazerChest': _inches(_blazerChest),
        'blazerSleeve': _inches(_blazerSleeve),
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
            !widget.readOnly &&
            Navigator.of(context).canPop()) {
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
                        Text(
                          p?.fullName ?? '${_first.text} ${_last.text}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
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
                        _detailKv(
                          'Date of birth',
                          _dob == null
                              ? (p?.dateOfBirth?.trim().isNotEmpty == true
                                    ? p!.dateOfBirth!.trim()
                                    : _dobLabel())
                              : _dobLabel(),
                        ),
                        if (age != null) _detailKv('Age', '$age'),
                        _detailKv('Organisation name', p?.orgName),
                        _detailKv('Organisation type', p?.orgTypeName),
                        _detailKv('Rank', p?.rank ?? _rank.text),
                        _detailKv(
                          'Designation',
                          p?.designation ?? _designation.text,
                        ),
                        _detailKv(
                          'Org ID number',
                          p?.orgIdNumber ?? _orgId.text,
                        ),
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
                          'Dress measurements',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All lengths are in inches, measured on a relaxed body.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        _detailKv('Trouser waist', _fmtInches(p?.trouserWaist)),
                        _detailKv(
                          'Trouser length',
                          _fmtInches(p?.trouserLength),
                        ),
                        _detailKv('Blazer chest', _fmtInches(p?.blazerChest)),
                        _detailKv('Blazer sleeve', _fmtInches(p?.blazerSleeve)),
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
                                            visualDensity:
                                                VisualDensity.compact,
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
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Rank',
                    counterText: '',
                  ),
                ),
                TextField(
                  controller: _designation,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Designation',
                    counterText: '',
                  ),
                ),
                TextField(
                  controller: _orgId,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Organisation / Service ID',
                    counterText: '',
                  ),
                ),
                TextField(
                  controller: _aadhaar,
                  keyboardType: TextInputType.number,
                  inputFormatters: _aadhaarInput,
                  decoration: const InputDecoration(
                    labelText: 'Aadhaar number',
                    hintText: '12-digit Aadhaar',
                  ),
                ),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Email (from Nomination)',
                    helperText: 'Used to log in — cannot be changed',
                  ),
                  child: Text(
                    _officialEmail.text.trim().isEmpty
                        ? widget.email
                        : _officialEmail.text.trim(),
                  ),
                ),
                TextField(
                  controller: _personalEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Personal email',
                  ),
                ),
                TextField(
                  controller: _officialContact,
                  keyboardType: TextInputType.phone,
                  inputFormatters: _phoneInput,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number (from Nomination)',
                    hintText: '+91 9xxxxxxxxx',
                  ),
                ),
                TextField(
                  controller: _personalContact,
                  keyboardType: TextInputType.phone,
                  inputFormatters: _phoneInput,
                  decoration: const InputDecoration(
                    labelText: 'Personal contact',
                    hintText: '+91 9xxxxxxxxx',
                  ),
                ),
                TextField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  inputFormatters: _phoneInput,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp number',
                    hintText: '+91 9xxxxxxxxx',
                  ),
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
                              (o) => DropdownMenuItem(value: o, child: Text(o)),
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
                const Text(
                  'Documents',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
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
        } else if (_step == 2) {
          stepBody = AppCard(
            child: AppFormColumn(
              children: [
                const Text(
                  'Dress measurements',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'All lengths are taken in inches, measured on a relaxed body.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Text(
                  'Trousers',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextField(
                  controller: _trouserWaist,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Waist',
                    suffixText: 'in',
                    helperText: '10–80 inches',
                  ),
                ),
                TextField(
                  controller: _trouserLength,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Length',
                    suffixText: 'in',
                    helperText: '20–60 inches',
                  ),
                ),
                const Text(
                  'Blazer',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextField(
                  controller: _blazerChest,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Chest',
                    suffixText: 'in',
                    helperText: '20–80 inches',
                  ),
                ),
                TextField(
                  controller: _blazerSleeve,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Sleeve length',
                    suffixText: 'in',
                    helperText: '15–50 inches',
                  ),
                ),
              ],
            ),
          );
        } else {
          stepBody = AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prior LO experience',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
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
                    children: List.generate(_steps.length, (i) {
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
                  _steps[_step],
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
                        if (_step < _steps.length - 1)
                          FilledButton(
                            onPressed: () => _goNext(state),
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
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
                : (widget.readOnly
                      ? 'Missing — tap Update Details'
                      : 'Missing'),
          ),
        ],
      ),
    );
  }
}
