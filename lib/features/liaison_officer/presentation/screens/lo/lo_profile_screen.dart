import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liaison_officer/core/design/app_semantic_colors.dart';
import 'package:liaison_officer/core/services/pick_services.dart';
import 'package:liaison_officer/core/utils/lo_contact_actions.dart';
import 'package:liaison_officer/core/utils/lo_display_format.dart';
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
  static final _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
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
    final digits = value.replaceAll(' ', '');
    if (!RegExp(r'^\d{12}$').hasMatch(digits)) {
      return 'Aadhaar must be 12 digits (spaces allowed).';
    }
    return null;
  }

  static String? emailError(String raw, {String label = 'Personal email'}) {
    final value = raw.trim();
    if (value.isEmpty) return '$label is required.';
    if (!_emailPattern.hasMatch(value)) return '$label is invalid.';
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

  /// Role / responsibilities is required only when at least one row exists.
  static String? experiencesError({
    required bool hasPrevious,
    required List<LoExperienceDto> experiences,
    int? currentYear,
  }) {
    if (!hasPrevious || experiences.isEmpty) return null;
    for (var i = 0; i < experiences.length; i++) {
      final row = experiences[i];
      final error = experienceRowError(
        index: i,
        eventName: row.eventName,
        role: row.roleResponsibilities,
        year: row.year,
        currentYear: currentYear,
      );
      if (error != null) return error;
    }
    return null;
  }

  @override
  State<LoProfileScreen> createState() => _LoProfileScreenState();
}

class _LoProfileScreenState extends State<LoProfileScreen> {
  static const _salutations = ['Mr', 'Ms', 'Mrs', 'Dr', 'Prof'];
  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LoPortalBloc>().add(LoPortalLanguageLookupsRequested());
      context.read<LoPortalBloc>().add(LoPortalGenderLookupsRequested());
    });
  }

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
  final Map<LoUploadKind, Uint8List> _uploadBytes = {};
  bool _profileSaveDialogVisible = false;
  static final _phoneInput = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
    LengthLimitingTextInputFormatter(30),
  ];
  static final _aadhaarInput = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
    LengthLimitingTextInputFormatter(14),
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
    return LoProfileScreen.formatDobIso(_dob!);
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
      _uploadBytes[kind] = file.bytes;
    });
    context.read<LoPortalBloc>().add(
      LoPortalUploadRequested(
        kind: kind,
        bytes: file.bytes,
        filename: file.filename,
      ),
    );
  }

  String? _serverFileId(LoUploadKind kind, LiaisonOfficerDto? profile) {
    return switch (kind) {
      LoUploadKind.photo => profile?.photoFileId,
      LoUploadKind.signature => profile?.signatureFileId,
      LoUploadKind.aadhaarFront => profile?.aadhaarFrontId,
      LoUploadKind.aadhaarBack => profile?.aadhaarBackId,
      LoUploadKind.orgBadgeFront => profile?.orgBadgeFrontId,
      LoUploadKind.orgBadgeBack => profile?.orgBadgeBackId,
    };
  }

  String? _serverFileName(LoUploadKind kind, LiaisonOfficerDto? profile) {
    return switch (kind) {
      LoUploadKind.photo => profile?.photoFileName,
      LoUploadKind.signature => profile?.signatureFileName,
      LoUploadKind.aadhaarFront => profile?.aadhaarFrontFileName,
      LoUploadKind.aadhaarBack => profile?.aadhaarBackFileName,
      LoUploadKind.orgBadgeFront => profile?.orgBadgeFrontFileName,
      LoUploadKind.orgBadgeBack => profile?.orgBadgeBackFileName,
    };
  }

  void _viewDocument({
    required String filename,
    Uint8List? bytes,
    String? fileId,
  }) {
    if (bytes != null && bytes.isNotEmpty) {
      _showImagePreview(bytes, filename);
      return;
    }
    final id = fileId?.trim() ?? '';
    if (id.isEmpty) {
      _showError('File is not available yet.');
      return;
    }
    context.read<LoPortalBloc>().add(
      LoPortalDocumentFetchRequested(
        fileId: id,
        filename: filename,
        share: false,
      ),
    );
  }

  void _downloadDocument({
    required String filename,
    Uint8List? bytes,
    String? fileId,
  }) {
    if (bytes != null && bytes.isNotEmpty) {
      context.read<LoPortalBloc>().add(
        LoPortalLocalFileShareRequested(bytes: bytes, filename: filename),
      );
      return;
    }
    final id = fileId?.trim() ?? '';
    if (id.isEmpty) {
      _showError('File is not available yet.');
      return;
    }
    context.read<LoPortalBloc>().add(
      LoPortalDocumentFetchRequested(
        fileId: id,
        filename: filename,
        share: true,
      ),
    );
  }

  Future<void> _showImagePreview(Uint8List bytes, String filename) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                filename,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadRow(
    LoUploadKind kind,
    String label,
    LiaisonOfficerDto? profile,
  ) {
    final localName = _uploadNames[kind];
    final serverName = _serverFileName(kind, profile);
    final serverId = _serverFileId(kind, profile);
    final uploaded =
        (localName ?? '').isNotEmpty ||
        (serverId ?? '').trim().isNotEmpty ||
        (serverName ?? '').trim().isNotEmpty;
    final filename = (localName ?? '').isNotEmpty
        ? localName!
        : ((serverName ?? '').trim().isNotEmpty ? serverName! : 'Uploaded');
    final bytes = _uploadBytes[kind];

    return _documentCard(
      label: label,
      uploaded: uploaded,
      filename: filename,
      bytes: bytes,
      onAdd: uploaded ? null : () => _pickUpload(kind, label),
      onReplace: uploaded ? () => _pickUpload(kind, label) : null,
      onView: uploaded
          ? () => _viewDocument(
              filename: filename,
              bytes: bytes,
              fileId: serverId,
            )
          : null,
      onDownload: uploaded
          ? () => _downloadDocument(
              filename: filename,
              bytes: bytes,
              fileId: serverId,
            )
          : null,
    );
  }

  Widget _documentCard({
    required String label,
    required bool uploaded,
    required String filename,
    Uint8List? bytes,
    VoidCallback? onAdd,
    VoidCallback? onReplace,
    VoidCallback? onView,
    VoidCallback? onDownload,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final hasThumb = bytes != null && bytes.isNotEmpty;
    Widget action(String tooltip, IconData icon, VoidCallback onPressed) {
      return IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: hasThumb
                  ? Image.memory(bytes, fit: BoxFit.cover)
                  : ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        uploaded
                            ? Icons.description_outlined
                            : Icons.add_photo_alternate_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  uploaded ? filename : 'Not uploaded',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  uploaded ? 'Uploaded' : 'Not uploaded',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: uploaded ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!uploaded && onAdd != null)
            action('Add', Icons.add, onAdd)
          else ...[
            if (onView != null) action('View', Icons.visibility_outlined, onView),
            if (onDownload != null)
              action('Download', Icons.download_outlined, onDownload),
            if (onReplace != null)
              action('Replace', Icons.swap_horiz, onReplace),
          ],
        ],
      ),
    );
  }

  String _experienceSubtitle(LoExperienceDto row) {
    final role = (row.roleResponsibilities ?? '').trim();
    final details = (row.delegateDetails ?? '').trim();
    return [
      if (row.year != null) '${row.year}',
      if (role.isNotEmpty) role else 'Role / responsibilities missing',
      if (details.isNotEmpty) details,
    ].join(' · ');
  }

  Future<void> _addExperience([LoExperienceDto? existing]) async {
    final editing = (existing?.id ?? '').isNotEmpty;
    final eventName = TextEditingController(text: existing?.eventName ?? '');
    final year = TextEditingController(
      text: existing?.year?.toString() ?? '',
    );
    final role = TextEditingController(
      text: existing?.roleResponsibilities ?? '',
    );
    final delegateDetails = TextEditingController(
      text: existing?.delegateDetails ?? '',
    );
    String? eventError;
    String? roleError;
    String? yearError;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(editing ? 'Edit experience' : 'Add experience'),
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
              child: Text(editing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      final body = {
        'eventName': eventName.text.trim(),
        'eventYear': int.tryParse(year.text.trim()),
        'roleResp': role.text.trim(),
        'delegateDetails': delegateDetails.text.trim(),
      };
      final bloc = context.read<LoPortalBloc>();
      if (editing) {
        bloc.add(LoPortalExperienceReplaced(id: existing!.id!, body: body));
      } else {
        bloc.add(LoPortalExperienceAdded(body));
      }
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

  Future<void> _showProfileSavedDialog() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Profile updated',
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, _, _) {
        return SafeArea(
          child: Center(
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.elasticOut,
                    builder: (context, value, _) => Transform.scale(
                      scale: value,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2E7D32),
                        size: 72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Profile updated successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your profile is now complete. Thank you!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (!mounted) return;
    _profileSaveDialogVisible = false;
    final route = ModalRoute.of(context);
    if (route is PageRoute && route.fullscreenDialog) {
      Navigator.of(context).maybePop();
    }
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
        LoProfileScreen.emailError(
          _officialEmail.text.trim().isEmpty
              ? widget.email
              : _officialEmail.text,
          label: 'Official email',
        ) ??
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
    return LoProfileScreen.experiencesError(
      hasPrevious: _hasPrevLoExp,
      experiences: experiences,
    );
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
    final halves = value * 2;
    if ((halves - halves.round()).abs() > 0.001) {
      return '$group — $label must be a whole number or half-inch (e.g. 32.5).';
    }
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
        if (state.profileSaveAck &&
            !widget.readOnly &&
            !_profileSaveDialogVisible) {
          _profileSaveDialogVisible = true;
          _showProfileSavedDialog();
        }
        final preview = state.documentPreviewBytes;
        if (preview != null && preview.isNotEmpty) {
          final name = state.documentPreviewName ?? 'Document';
          final bytes = Uint8List.fromList(preview);
          context.read<LoPortalBloc>().add(LoPortalClearDocumentPreview());
          _showImagePreview(bytes, name);
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
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton.icon(
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      shape: const StadiumBorder(),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
            body: SafeArea(child: _buildOverview(state, p, age)),
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
                Builder(builder: (ctx) {
                  final opts = state.genderOptions;
                  final names = opts.isNotEmpty
                      ? opts.map((o) => o.name).toList()
                      : _genders;
                  if (opts.isNotEmpty && _genderId == null) {
                    final match = opts.where(
                      (o) => o.name.toLowerCase() == _gender.toLowerCase(),
                    );
                    if (match.isNotEmpty) {
                      _genderId = match.first.id;
                      _gender = match.first.name;
                    } else {
                      _genderId = opts.first.id;
                      _gender = opts.first.name;
                    }
                  }
                  return DropdownButtonFormField<String>(
                    key: ValueKey('gender-$_gender'),
                    initialValue: names.contains(_gender) ? _gender : null,
                    decoration: InputDecoration(
                      labelText: 'Gender *',
                      helperText: opts.isEmpty ? 'Loading options…' : null,
                    ),
                    items: names
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: opts.isEmpty
                        ? null
                        : (v) {
                            if (v == null) return;
                            final picked = opts.firstWhere(
                              (o) => o.name == v,
                              orElse: () => opts.first,
                            );
                            setState(() {
                              _gender = picked.name;
                              _genderId = picked.id;
                            });
                          },
                  );
                }),
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
                Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date of birth'),
                    subtitle: Text(
                      age == null ? _dobLabel() : '${_dobLabel()} · Age $age',
                    ),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _pickDob,
                  ),
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
                        items: state.languageOptions
                            .where(
                              (o) => !_draftLanguages.any(
                                (l) => l.toLowerCase() == o.name.toLowerCase(),
                              ),
                            )
                            .map(
                              (o) => DropdownMenuItem(
                                value: o.name,
                                child: Text(o.name),
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
                if (state.languageOptions.isEmpty)
                  Text(
                    'No languages available to add.',
                    style: Theme.of(context).textTheme.bodySmall,
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
                const SizedBox(height: 4),
                Text(
                  'JPEG, JPG or PNG only.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _uploadRow(LoUploadKind.photo, 'Passport Size Photo *', p),
                _uploadRow(LoUploadKind.signature, 'Specimen Signature *', p),
                _uploadRow(LoUploadKind.aadhaarFront, 'Aadhaar (Front) *', p),
                _uploadRow(LoUploadKind.aadhaarBack, 'Aadhaar (Back) *', p),
                _uploadRow(
                  LoUploadKind.orgBadgeFront,
                  'Org Badge (Front) *',
                  p,
                ),
                _uploadRow(LoUploadKind.orgBadgeBack, 'Org Badge (Back) *', p),
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
                  'Enter each measurement in inches. Half-inches (e.g. 32.5) are allowed. Refer to the diagram if you are unsure where each measurement is taken from — tap it for a larger view.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'How to measure',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _openMeasurementGuide,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/dress_measurements_guide.jpg',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                    (e) => Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.eventName ?? 'Event'),
                      subtitle: Text(_experienceSubtitle(e)),
                      trailing: e.id == null
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _addExperience(e),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      context.read<LoPortalBloc>().add(
                                        LoPortalExperienceDeleted(e.id!),
                                      ),
                                ),
                              ],
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
                              ? Theme.of(context).colorScheme.primary
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

  static const _profileDocs = <(String, LoUploadKind)>[
    ('Passport Size Photo', LoUploadKind.photo),
    ('Specimen Signature', LoUploadKind.signature),
    ('Aadhaar (Front)', LoUploadKind.aadhaarFront),
    ('Aadhaar (Back)', LoUploadKind.aadhaarBack),
    ('Org Badge (Front)', LoUploadKind.orgBadgeFront),
    ('Org Badge (Back)', LoUploadKind.orgBadgeBack),
  ];

  Widget _buildOverview(LoPortalState state, LiaisonOfficerDto? p, int? age) {
    final colors = context.semantic;
    final name = (p?.fullName ?? '${_first.text} ${_last.text}').trim();
    final rank = (p?.rank ?? _rank.text).trim();
    final passId = (p?.currentPassId ?? '').trim();
    final passNumber = (p?.currentPassNumber ?? '').trim();
    final hasExp = p?.hasPrevLoExp ?? _hasPrevLoExp;
    final status = p?.profileStatus ?? 'SUBMITTED';
    final completed = status.trim().toUpperCase() == 'COMPLETED';
    final uploaded =
        _profileDocs.where((d) => _isUploaded(d.$2, p)).length;
    final allUploaded = uploaded == _profileDocs.length;

    final contacts = <Widget>[
      ?_contactRow(
        Icons.mail_outline,
        'Official email',
        p?.officialEmail,
        Icons.copy_rounded,
        'Copy',
        () => _copyToClipboard('Official email', p?.officialEmail),
      ),
      ?_contactRow(
        Icons.mail_outline,
        'Personal email',
        p?.personalEmail,
        Icons.copy_rounded,
        'Copy',
        () => _copyToClipboard('Personal email', p?.personalEmail),
      ),
      ?_contactRow(
        Icons.call_outlined,
        'Official contact',
        p?.officialContact,
        Icons.call_outlined,
        'Call',
        () => LoContactActions.call(p?.officialContact),
      ),
      ?_contactRow(
        Icons.phone_iphone,
        'Personal contact',
        p?.personalContact,
        Icons.call_outlined,
        'Call',
        () => LoContactActions.call(p?.personalContact),
      ),
      ?_contactRow(
        Icons.chat_outlined,
        'WhatsApp',
        p?.whatsappNumber,
        Icons.message_outlined,
        'WhatsApp',
        () => LoContactActions.whatsApp(p?.whatsappNumber),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _ProfileHero(
          initials: _initials(name),
          name: name.isEmpty ? 'Liaison Officer' : name,
          email: widget.email,
          org: p?.orgName,
          status: status,
          verified: completed,
        ),
        const SizedBox(height: 8),
        if (passId.isNotEmpty)
          AppCard(
            child: Row(
              children: [
                const _ProfileIconBadge(icon: Icons.badge_outlined, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Badge',
                        style: TextStyle(fontSize: 12, color: colors.textMuted),
                      ),
                      Text(
                        passNumber.isEmpty ? '—' : passNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => context.read<LoPortalBloc>().add(
                    LoPortalBadgeDownloadRequested(
                      passId: passId,
                      filename:
                          'badge-${passNumber.isEmpty ? passId : passNumber}.pdf',
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download'),
                ),
              ],
            ),
          ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: age?.toString() ?? '—',
                  ),
                ),
                VerticalDivider(width: 1, color: colors.border),
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.military_tech_outlined,
                    label: 'Rank',
                    value: rank.isEmpty ? '—' : rank,
                  ),
                ),
                VerticalDivider(width: 1, color: colors.border),
                Expanded(
                  child: _ProfileStat(
                    icon: Icons.translate,
                    label: 'Languages',
                    value: '${state.languages.length}',
                  ),
                ),
              ],
            ),
          ),
        ),
        _ProfileSection(
          icon: Icons.person_outline,
          title: 'Personal details',
          subtitle:
              'This is what your organisation, the LO Committee and '
              'downstream committees see about you.',
          collapsible: true,
          child: _ProfileKvGrid(
            entries: [
              ('Salutation', _salutation),
              ('Full name', name),
              ('Gender', p?.genderName ?? _gender),
              (
                'Date of birth',
                _dob == null
                    ? (p?.dateOfBirth?.trim().isNotEmpty == true
                          ? LoDisplayFormat.date(p!.dateOfBirth)
                          : _dobLabel())
                    : _dobLabel(),
              ),
              ('Designation', p?.designation ?? _designation.text),
              ('Org ID number', p?.orgIdNumber ?? _orgId.text),
              ('Organisation name', p?.orgName),
              ('Organisation type', p?.orgTypeName),
              ('Aadhaar', _maskAadhaar(p?.aadhaarNumber ?? _aadhaar.text)),
            ],
          ),
        ),
        _ProfileSection(
          icon: Icons.contact_phone_outlined,
          title: 'Contact',
          collapsible: true,
          child: contacts.isEmpty
              ? Text(
                  'No contact details added. Tap Edit to add them.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : Column(
                  children: [
                    for (var i = 0; i < contacts.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: colors.border),
                      contacts[i],
                    ],
                  ],
                ),
        ),
        _ProfileSection(
          icon: Icons.straighten,
          title: 'Dress measurements',
          subtitle: 'All lengths are in inches, measured on a relaxed body.',
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              _MeasurementTile(
                icon: Icons.straighten,
                label: 'Trouser waist',
                value: _fmtInches(p?.trouserWaist),
              ),
              _MeasurementTile(
                icon: Icons.height,
                label: 'Trouser length',
                value: _fmtInches(p?.trouserLength),
              ),
              _MeasurementTile(
                icon: Icons.checkroom_outlined,
                label: 'Blazer chest',
                value: _fmtInches(p?.blazerChest),
              ),
              _MeasurementTile(
                icon: Icons.checkroom_outlined,
                label: 'Blazer sleeve',
                value: _fmtInches(p?.blazerSleeve),
              ),
            ],
          ),
        ),
        _ProfileSection(
          icon: Icons.translate,
          title: 'Languages known',
          child: state.languages.isEmpty
              ? Text(
                  'No languages added. Tap Edit to add languages.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final l in state.languages)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          l,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        _ProfileSection(
          icon: Icons.folder_outlined,
          title: 'Documents',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                allUploaded ? Icons.check_circle : Icons.pending_outlined,
                size: 16,
                color: allUploaded ? AppTheme.indiaGreen : colors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '$uploaded/${_profileDocs.length} Uploaded',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: allUploaded
                      ? AppTheme.indiaGreen
                      : colors.textSecondary,
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: uploaded / _profileDocs.length,
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
                color: AppTheme.indiaGreen,
                backgroundColor: colors.border,
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < _profileDocs.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.border),
                _docStatusRow(_profileDocs[i].$1, _profileDocs[i].$2, p),
              ],
            ],
          ),
        ),
        _ProfileSection(
          icon: Icons.workspace_premium_outlined,
          title: 'Prior LO experience',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileKvGrid(
                entries: [('Has LO experience', hasExp ? 'Yes' : 'No')],
              ),
              const SizedBox(height: 8),
              if (state.experiences.isEmpty)
                Text(
                  hasExp
                      ? 'No experience rows yet. Tap Edit to add them.'
                      : 'No prior LO experience recorded.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...state.experiences.map(
                  (e) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
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
                        Text(_experienceSubtitle(e)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (completed) const _ProfileCompleteBanner(),
      ],
    );
  }

  Widget? _contactRow(
    IconData icon,
    String label,
    String? value,
    IconData actionIcon,
    String actionTooltip,
    VoidCallback onAction,
  ) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final colors = context.semantic;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            tooltip: actionTooltip,
            onPressed: onAction,
            icon: Icon(actionIcon, size: 20, color: colors.accent),
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard(String label, String? value) async {
    final v = (value ?? '').trim();
    if (v.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: v));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label copied')));
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    return parts.isEmpty ? 'LO' : parts;
  }

  String? _maskAadhaar(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length <= 4) return digits;
    return 'XXXX XXXX ${digits.substring(digits.length - 4)}';
  }

  bool _isUploaded(LoUploadKind kind, LiaisonOfficerDto? profile) {
    return (_serverFileId(kind, profile) ?? '').trim().isNotEmpty ||
        (_serverFileName(kind, profile) ?? '').trim().isNotEmpty ||
        (_uploadNames[kind] ?? '').isNotEmpty;
  }

  void _openMeasurementGuide() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Image.asset(
                    'assets/images/dress_measurements_guide.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'All lengths are taken in inches, measured on a relaxed body.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _docStatusRow(
    String label,
    LoUploadKind kind,
    LiaisonOfficerDto? profile,
  ) {
    final fileName = _serverFileName(kind, profile);
    final fileId = _serverFileId(kind, profile);
    final localName = _uploadNames[kind];
    final uploaded = _isUploaded(kind, profile);
    final filename = (localName ?? '').isNotEmpty
        ? localName!
        : ((fileName ?? '').trim().isNotEmpty ? fileName! : 'Uploaded');
    final bytes = _uploadBytes[kind];
    final colors = context.semantic;
    final statusColor = uploaded ? AppTheme.indiaGreen : AppTheme.saffron;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent.withValues(alpha: 0.1),
            ),
            child: bytes != null && bytes.isNotEmpty
                ? Image.memory(bytes, fit: BoxFit.cover)
                : Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: colors.accent,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  uploaded ? filename : 'Not uploaded',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              uploaded ? 'Uploaded' : 'Pending',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          if (uploaded) ...[
            IconButton(
              tooltip: 'View',
              visualDensity: VisualDensity.compact,
              onPressed: () => _viewDocument(
                filename: filename,
                bytes: bytes,
                fileId: fileId,
              ),
              icon: Icon(Icons.visibility_outlined, color: colors.textPrimary),
            ),
            IconButton(
              tooltip: 'Download',
              visualDensity: VisualDensity.compact,
              onPressed: () => _downloadDocument(
                filename: filename,
                bytes: bytes,
                fileId: fileId,
              ),
              icon: Icon(Icons.download_outlined, color: colors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.initials,
    required this.name,
    required this.email,
    required this.org,
    required this.status,
    required this.verified,
  });

  final String initials;
  final String name;
  final String email;
  final String? org;
  final String status;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = theme.appBarTheme.backgroundColor ?? AppTheme.navy;
    final orgName = (org ?? '').trim();
    final muted = Colors.white.withValues(alpha: 0.85);

    Widget infoRow(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
          colors: [
            top,
            top == AppTheme.navy
                ? AppTheme.royalBlue
                : Color.lerp(top, Colors.white, 0.28)!,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _HeroWavePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (verified)
                    Positioned(
                      right: 0,
                      bottom: 2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.indiaGreen,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              infoRow(Icons.mail_outline, email),
              if (orgName.isNotEmpty) ...[
                const SizedBox(height: 4),
                infoRow(Icons.apartment_outlined, orgName),
              ],
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppStatusChip(label: status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final back = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.30, h * 0.48, w * 0.60, h * 0.66)
      ..quadraticBezierTo(w * 0.85, h * 0.80, w, h * 0.55)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final front = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.40, h * 0.66, w * 0.70, h * 0.86)
      ..quadraticBezierTo(w * 0.88, h * 0.96, w, h * 0.78)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas
      ..drawPath(back, Paint()..color = Colors.white.withValues(alpha: 0.06))
      ..drawPath(front, Paint()..color = Colors.white.withValues(alpha: 0.08));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileSection extends StatefulWidget {
  const _ProfileSection({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.collapsible = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool collapsible;
  final Widget child;

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        _ProfileIconBadge(icon: widget.icon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        ?widget.trailing,
        if (widget.collapsible)
          AnimatedRotation(
            turns: _open ? 0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: context.semantic.textSecondary,
            ),
          ),
      ],
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.collapsible)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _open = !_open),
              child: header,
            )
          else
            header,
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _open
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 14),
                      widget.child,
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ProfileIconBadge extends StatelessWidget {
  const _ProfileIconBadge({required this.icon, this.size = 32});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = context.semantic.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(icon, size: size * 0.55, color: accent),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: colors.accent),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: colors.textMuted)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final hasValue = value.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: hasValue ? value : '—',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colors.accent,
                        ),
                      ),
                      if (hasValue)
                        TextSpan(
                          text: ' in',
                          style: TextStyle(fontSize: 12, color: colors.accent),
                        ),
                    ],
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileKvGrid extends StatelessWidget {
  const _ProfileKvGrid({required this.entries});

  final List<(String, String?)> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    final visible = entries
        .where((e) => (e.$2 ?? '').trim().isNotEmpty)
        .toList(growable: false);
    Widget kv((String, String?) e) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          e.$1.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: colors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(e.$2!.trim(), style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
    Widget column(List<(String, String?)> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: [for (final e in items) kv(e)],
    );

    final left = [for (var i = 0; i < visible.length; i += 2) visible[i]];
    final right = [for (var i = 1; i < visible.length; i += 2) visible[i]];
    if (right.isEmpty) return column(left);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: column(left)),
          VerticalDivider(width: 24, color: colors.border),
          Expanded(child: column(right)),
        ],
      ),
    );
  }
}

class _ProfileCompleteBanner extends StatelessWidget {
  const _ProfileCompleteBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.semantic;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your profile is complete!',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'All information has been successfully submitted.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.indiaGreen,
            ),
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
