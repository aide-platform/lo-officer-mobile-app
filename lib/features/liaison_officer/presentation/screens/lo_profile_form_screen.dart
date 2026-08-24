import 'package:flutter/material.dart';

import '../../data/models/lo_profile.dart';

class LoProfileFormScreen extends StatefulWidget {
  const LoProfileFormScreen({super.key, required this.email});

  final String email;

  @override
  State<LoProfileFormScreen> createState() => _LoProfileFormScreenState();
}

class _LoProfileFormScreenState extends State<LoProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _passportPhotoController = TextEditingController();
  final TextEditingController _organisationIdController = TextEditingController();
  final TextEditingController _organisationIdFrontController = TextEditingController();
  final TextEditingController _organisationIdBackController = TextEditingController();
  final TextEditingController _aadhaarNumberController = TextEditingController();
  final TextEditingController _aadhaarFrontController = TextEditingController();
  final TextEditingController _aadhaarBackController = TextEditingController();
  final TextEditingController _officialEmailController = TextEditingController();
  final TextEditingController _personalEmailController = TextEditingController();
  final TextEditingController _officialContactController = TextEditingController();
  final TextEditingController _personalContactController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _experienceRoleController = TextEditingController();
  final TextEditingController _delegateDetailsController = TextEditingController();

  final List<String> _salutations = ['Mr', 'Ms', 'Mrs', 'Dr', 'Prof'];
  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _languages = [
    'English',
    'Hindi',
    'Kannada',
    'Tamil',
    'Telugu',
    'Malayalam',
    'Marathi',
    'Gujarati',
  ];

  String _salutation = 'Mr';
  String _gender = 'Male';
  bool _hasPreviousExperience = false;
  String _message = '';
  DateTime? _dob;
  DateTime? _availableFrom;
  DateTime? _availableTo;
  List<String> _selectedLanguages = [];
  List<LoPreviousExperience> _previousExperiences = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await LoProfile.load(email: widget.email);
    if (!mounted || profile == null) {
      return;
    }

    setState(() {
      _salutation = profile.salutation.isNotEmpty ? profile.salutation : _salutations.first;
      _gender = profile.gender.isNotEmpty ? profile.gender : _genders.first;
      _hasPreviousExperience = profile.hasPreviousExperience;
      _dob = profile.dateOfBirth;
      _availableFrom = profile.availableFrom;
      _availableTo = profile.availableTo;
      _selectedLanguages = [...profile.languagesKnown];
      _previousExperiences = [...profile.previousExperiences];

      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _rankController.text = profile.rank;
      _designationController.text = profile.designation;
      _passportPhotoController.text = profile.passportPhoto;
      _organisationIdController.text = profile.organisationIdNumber;
      _organisationIdFrontController.text = profile.organisationIdBadgeFront;
      _organisationIdBackController.text = profile.organisationIdBadgeBack;
      _aadhaarNumberController.text = profile.aadhaarNumber;
      _aadhaarFrontController.text = profile.aadhaarFront;
      _aadhaarBackController.text = profile.aadhaarBack;
      _officialEmailController.text = profile.officialEmail;
      _personalEmailController.text = profile.personalEmail;
      _officialContactController.text = profile.officialContactNumber;
      _personalContactController.text = profile.personalContactNumber;
      _whatsappController.text = profile.whatsappNumber;
      _signatureController.text = profile.signature;
    });
  }

  int get _age {
    if (_dob == null) return 0;
    final now = DateTime.now();
    var age = now.year - _dob!.year;
    if (now.month < _dob!.month ||
        (now.month == _dob!.month && now.day < _dob!.day)) {
      age--;
    }
    return age;
  }

  LoProfile _buildProfile({required String status}) {
    return LoProfile(
      email: widget.email,
      status: status,
      salutation: _salutation,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      gender: _gender,
      dateOfBirth: _dob,
      rank: _rankController.text.trim(),
      designation: _designationController.text.trim(),
      passportPhoto: _passportPhotoController.text.trim(),
      organisationName: 'Parent Organisation',
      organisationType: 'Government',
      organisationIdNumber: _organisationIdController.text.trim(),
      organisationIdBadgeFront: _organisationIdFrontController.text.trim(),
      organisationIdBadgeBack: _organisationIdBackController.text.trim(),
      aadhaarNumber: _aadhaarNumberController.text.trim(),
      aadhaarFront: _aadhaarFrontController.text.trim(),
      aadhaarBack: _aadhaarBackController.text.trim(),
      officialEmail: _officialEmailController.text.trim(),
      personalEmail: _personalEmailController.text.trim(),
      officialContactNumber: _officialContactController.text.trim(),
      personalContactNumber: _personalContactController.text.trim(),
      whatsappNumber: _whatsappController.text.trim(),
      signature: _signatureController.text.trim(),
      hasPreviousExperience: _hasPreviousExperience,
      previousExperiences: _previousExperiences,
      availableFrom: _availableFrom,
      availableTo: _availableTo,
      languagesKnown: _selectedLanguages,
    );
  }

  Future<void> _saveProfile({required String status}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profile = _buildProfile(status: status);
    await profile.save();
    if (!mounted) return;

    setState(() => _message = status == 'Submitted'
        ? 'Profile submitted successfully.'
        : 'Profile saved as draft.');

    if (status == 'Submitted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile submitted successfully.')),
      );
      Navigator.maybePop(context);
    }
  }

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final initialDate = (isFrom ? _availableFrom : _availableTo) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _availableFrom = picked;
      } else {
        _availableTo = picked;
      }
    });
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _dob = picked);
  }

  void _addExperience() {
    setState(() {
      _previousExperiences.add(
        const LoPreviousExperience(),
      );
    });
  }

  void _updateExperience(int index, {String? eventName, String? year, String? role, String? delegateDetails}) {
    final current = _previousExperiences[index];
    _previousExperiences[index] = current.copyWith(
      eventName: eventName,
      year: year,
      role: role,
      delegateDetails: delegateDetails,
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int? maxLength,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLength: maxLength,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LO Profile Form'),
        backgroundColor: isDark ? Colors.black87 : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _salutations.contains(_salutation) ? _salutation : _salutations.first,
                        decoration: InputDecoration(
                          labelText: 'Salutation',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: _salutations
                            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                            .toList(),
                        onChanged: (value) => setState(() => _salutation = value ?? _salutations.first),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(label: 'First Name', controller: _firstNameController, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                      _buildTextField(label: 'Last Name', controller: _lastNameController, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                      DropdownButtonFormField<String>(
                        value: _genders.contains(_gender) ? _gender : _genders.first,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: _genders
                            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                            .toList(),
                        onChanged: (value) => setState(() => _gender = value ?? _genders.first),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDob,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          child: Text(
                            _dob == null ? 'Select date' : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Age'),
                            Text('$_age years', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(label: 'Rank', controller: _rankController),
                      _buildTextField(label: 'Designation', controller: _designationController),
                      _buildTextField(label: 'Recent Passport Size Photograph (path/placeholder)', controller: _passportPhotoController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Organisation Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(label: 'Organisation Name', controller: TextEditingController(text: 'Parent Organisation'), readOnly: true),
                      _buildTextField(label: 'Organisation Type', controller: TextEditingController(text: 'Government'), readOnly: true),
                      _buildTextField(label: 'Organisation ID / Service ID Number', controller: _organisationIdController),
                      _buildTextField(label: 'Organisation ID Badge Front Photo', controller: _organisationIdFrontController),
                      _buildTextField(label: 'Organisation ID Badge Back Photo', controller: _organisationIdBackController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Identity Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(label: 'Aadhaar Number', controller: _aadhaarNumberController, keyboardType: TextInputType.number),
                      _buildTextField(label: 'Aadhaar Card Front Photo', controller: _aadhaarFrontController),
                      _buildTextField(label: 'Aadhaar Card Back Photo', controller: _aadhaarBackController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(label: 'Official Email ID', controller: _officialEmailController, keyboardType: TextInputType.emailAddress),
                      _buildTextField(label: 'Personal Email ID', controller: _personalEmailController, keyboardType: TextInputType.emailAddress),
                      _buildTextField(label: 'Official Contact Number', controller: _officialContactController, keyboardType: TextInputType.phone),
                      _buildTextField(label: 'Personal Contact Number', controller: _personalContactController, keyboardType: TextInputType.phone),
                      _buildTextField(label: 'WhatsApp Number', controller: _whatsappController, keyboardType: TextInputType.phone),
                      _buildTextField(label: 'Signature (path/placeholder)', controller: _signatureController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Previous LO Experience',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Has the LO served before?'),
                          const SizedBox(width: 8),
                          Switch(
                            value: _hasPreviousExperience,
                            onChanged: (value) => setState(() => _hasPreviousExperience = value),
                          ),
                        ],
                      ),
                      if (_hasPreviousExperience) ...[
                        const SizedBox(height: 12),
                        ...List.generate(_previousExperiences.length, (index) {
                          final experience = _previousExperiences[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).dividerColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  initialValue: experience.eventName,
                                  decoration: const InputDecoration(labelText: 'Event Name'),
                                  onChanged: (value) => _updateExperience(index, eventName: value),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: experience.year,
                                  decoration: const InputDecoration(labelText: 'Year'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => _updateExperience(index, year: value),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: experience.role,
                                  decoration: const InputDecoration(labelText: 'Role / Responsibilities'),
                                  onChanged: (value) => _updateExperience(index, role: value),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: experience.delegateDetails,
                                  maxLines: 3,
                                  decoration: const InputDecoration(labelText: 'Delegate Details'),
                                  onChanged: (value) => _updateExperience(index, delegateDetails: value),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _addExperience,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Experience'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Availability',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _pickDate(context, isFrom: true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Available From',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          child: Text(
                            _availableFrom == null ? 'Select date' : '${_availableFrom!.day}/${_availableFrom!.month}/${_availableFrom!.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _pickDate(context, isFrom: false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Available To',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          child: Text(
                            _availableTo == null ? 'Select date' : '${_availableTo!.day}/${_availableTo!.month}/${_availableTo!.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Languages Known'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _languages.map((lang) {
                          final selected = _selectedLanguages.contains(lang);
                          return FilterChip(
                            label: Text(lang),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                if (selected) {
                                  _selectedLanguages.remove(lang);
                                } else {
                                  _selectedLanguages.add(lang);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_message),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _saveProfile(status: 'Draft'),
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _saveProfile(status: 'Submitted'),
                      child: const Text('Submit Profile'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _rankController.dispose();
    _designationController.dispose();
    _passportPhotoController.dispose();
    _organisationIdController.dispose();
    _organisationIdFrontController.dispose();
    _organisationIdBackController.dispose();
    _aadhaarNumberController.dispose();
    _aadhaarFrontController.dispose();
    _aadhaarBackController.dispose();
    _officialEmailController.dispose();
    _personalEmailController.dispose();
    _officialContactController.dispose();
    _personalContactController.dispose();
    _whatsappController.dispose();
    _signatureController.dispose();
    _eventNameController.dispose();
    _yearController.dispose();
    _experienceRoleController.dispose();
    _delegateDetailsController.dispose();
    super.dispose();
  }
}
