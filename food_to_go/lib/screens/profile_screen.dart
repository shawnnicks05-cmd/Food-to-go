import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/food_stall.dart';
import '../services/app_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.email,
    required this.profileMetadata,
    required this.appData,
    this.stall,
  });

  final String email;
  final Map<String, dynamic> profileMetadata;
  final AppData appData;
  final FoodStall? stall;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _personalFormKey = GlobalKey<FormState>();
  final _stallFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _stallNameController;
  late final TextEditingController _stallDescriptionController;
  late final TextEditingController _stallPhoneController;
  late final TextEditingController _stallEmailController;

  String? _avatarUrl;
  Uint8List? _selectedAvatar;
  String? _selectedAvatarName;
  bool _removeAvatar = false;
  bool _pickingAvatar = false;
  bool _savingPersonal = false;
  bool _savingStall = false;

  bool get _hasStallProfile => widget.stall != null;

  @override
  void initState() {
    super.initState();
    final metadata = widget.profileMetadata;
    _nameController = TextEditingController(
      text: _metadataString(metadata, 'full_name'),
    );
    _phoneController = TextEditingController(
      text: _metadataString(metadata, 'phone'),
    );
    _avatarUrl = _validImageUrl(_metadataString(metadata, 'avatar_url'));
    _stallNameController = TextEditingController(
      text: widget.stall?.name ?? '',
    );
    _stallDescriptionController = TextEditingController(
      text: widget.stall?.description ?? '',
    );
    _stallPhoneController = TextEditingController(
      text: widget.stall?.contactPhone ?? '',
    );
    _stallEmailController = TextEditingController(
      text: widget.stall?.contactEmail ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _stallNameController.dispose();
    _stallDescriptionController.dispose();
    _stallPhoneController.dispose();
    _stallEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    setState(() => _pickingAvatar = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      );
      if (result.isEmpty || !mounted) return;

      final file = result.single;
      final size = await file.length();
      if (size == null || size == 0 || size > 5 * 1024 * 1024) {
        throw const FormatException('Choose an image between 1 byte and 5 MB.');
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedAvatar = bytes;
        _selectedAvatarName = file.name;
        _removeAvatar = false;
      });
    } catch (error) {
      if (mounted) _showMessage('Unable to select profile photo: $error');
    } finally {
      if (mounted) setState(() => _pickingAvatar = false);
    }
  }

  Future<void> _savePersonalProfile() async {
    if (!_personalFormKey.currentState!.validate()) return;
    setState(() => _savingPersonal = true);
    try {
      var avatarUrl = _avatarUrl;
      if (_selectedAvatar != null && _selectedAvatarName != null) {
        avatarUrl = await widget.appData.uploadProfileImage(
          fileName: _selectedAvatarName!,
          bytes: _selectedAvatar!,
        );
      } else if (_removeAvatar) {
        avatarUrl = null;
      }

      await widget.appData.updatePersonalProfile(
        fullName: _nameController.text,
        phone: _phoneController.text,
        avatarUrl: avatarUrl,
      );
      if (!mounted) return;
      setState(() {
        _avatarUrl = avatarUrl;
        _selectedAvatar = null;
        _selectedAvatarName = null;
        _removeAvatar = false;
      });
      _showMessage('Personal profile saved.');
    } catch (error) {
      if (mounted) _showMessage('Unable to save personal profile: $error');
    } finally {
      if (mounted) setState(() => _savingPersonal = false);
    }
  }

  Future<void> _saveStallProfile() async {
    if (!_stallFormKey.currentState!.validate()) return;
    final stall = widget.stall;
    if (stall == null) return;

    setState(() => _savingStall = true);
    try {
      await widget.appData.updateStallProfile(
        stallId: stall.id,
        name: _stallNameController.text,
        description: _stallDescriptionController.text,
        contactPhone: _stallPhoneController.text,
        contactEmail: _stallEmailController.text,
      );
      if (mounted) _showMessage('Storefront profile saved.');
    } catch (error) {
      if (mounted) _showMessage('Unable to save storefront profile: $error');
    } finally {
      if (mounted) setState(() => _savingStall = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static final _phoneCharacters = RegExp(r'[0-9+() -]');
  static final _phoneNumber = RegExp(r'^\+?[0-9() -]*[0-9][0-9() -]*$');

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    return phone.isEmpty || _phoneNumber.hasMatch(phone)
        ? null
        : 'Enter a valid phone number.';
  }

  ImageProvider? get _avatarImage {
    if (_selectedAvatar != null) return MemoryImage(_selectedAvatar!);
    if (!_removeAvatar && _avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }
    return null;
  }

  String _metadataString(Map<String, dynamic> metadata, String key) {
    final value = metadata[key];
    return value is String ? value : '';
  }

  String? _validImageUrl(String value) {
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final stall = widget.stall;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _personalFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Personal details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: _avatarImage,
                            child: _avatarImage == null
                                ? const Icon(Icons.person, size: 48)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: (_savingPersonal || _pickingAvatar)
                                    ? null
                                    : _pickAvatar,
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: const Text('Change photo'),
                              ),
                              if (_avatarImage != null)
                                TextButton(
                                  onPressed: (_savingPersonal || _pickingAvatar)
                                      ? null
                                      : () => setState(() {
                                          _selectedAvatar = null;
                                          _selectedAvatarName = null;
                                          _removeAvatar = true;
                                        }),
                                  child: const Text('Remove'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_savingPersonal,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your name.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: widget.email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Account email',
                        helperText: 'Contact support if you need to change it.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_savingPersonal,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(_phoneCharacters),
                      ],
                      validator: _validatePhone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: (_savingPersonal || _pickingAvatar)
                          ? null
                          : _savePersonalProfile,
                      child: _savingPersonal
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save personal profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_hasStallProfile) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _stallFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Storefront details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This updates ${stall!.name}. Your assigned storefront cannot be changed here.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _stallNameController,
                        enabled: !_savingStall,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Storefront name',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a storefront name.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _stallDescriptionController,
                        enabled: !_savingStall,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _stallPhoneController,
                        enabled: !_savingStall,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(_phoneCharacters),
                        ],
                        validator: _validatePhone,
                        decoration: const InputDecoration(
                          labelText: 'Business phone',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _stallEmailController,
                        enabled: !_savingStall,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Business contact email',
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isNotEmpty &&
                              !RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(email)) {
                            return 'Enter a valid contact email.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _savingStall ? null : _saveStallProfile,
                        child: _savingStall
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save storefront details'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
