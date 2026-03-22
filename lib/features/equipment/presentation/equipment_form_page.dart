import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/equipment_translation_service.dart';
import '../../../services/marketplace_service.dart';
import '../../../utils/localized_text.dart';
import '../../location/presentation/location_picker_page.dart';

class EquipmentFormPage extends StatefulWidget {
  const EquipmentFormPage({
    super.key,
    required this.ownerId,
    required this.ownerName,
    this.existing,
  });

  final String ownerId;
  final String ownerName;
  final MarketplaceEquipmentModel? existing;

  @override
  State<EquipmentFormPage> createState() => _EquipmentFormPageState();
}

class _EquipmentFormPageState extends State<EquipmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = MarketplaceService();
  final _cloudinary = CloudinaryService();
  final _translationService = EquipmentTranslationService();

  static const List<String> _conditions = <String>[
    'New',
    'Good',
    'Used',
  ];

  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _minDuration;
  late final TextEditingController _tagInput;
  late final TextEditingController _videoUrl;
  late final TextEditingController _titleEn;
  late final TextEditingController _titleTa;
  late final TextEditingController _titleHi;
  late final TextEditingController _categoryEn;
  late final TextEditingController _categoryTa;
  late final TextEditingController _categoryHi;
  late final TextEditingController _descriptionEn;
  late final TextEditingController _descriptionTa;
  late final TextEditingController _descriptionHi;

  String _inputLanguage = 'en';
  String _selectedCondition = 'Good';
  String _priceType = 'hour';
  String _minDurationType = 'hours';
  String _status = 'published';

  DateTime? _availabilityFrom;
  DateTime? _availabilityTo;

  String _location = '';
  double _lat = 0;
  double _lng = 0;

  final List<String> _tags = <String>[];
  bool _saving = false;
  bool _translating = false;

  final List<File> _newImages = [];
  final List<String> _existingImages = [];
  final List<String> _existingImagePublicIds = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final titleMap = normalizeLocalizedField(
      e?.titleLocalized ?? e?.equipmentName,
      fallback: e?.equipmentName ?? '',
    );
    final categoryMap = normalizeLocalizedField(
      e?.categoryLocalized ?? e?.category,
      fallback: e?.category ?? '',
    );
    final descriptionMap = normalizeLocalizedField(
      e?.descriptionLocalized ?? e?.description,
      fallback: e?.description ?? '',
    );

    _title = TextEditingController(text: titleMap['en'] ?? '');
    _category = TextEditingController(text: categoryMap['en'] ?? '');
    _description = TextEditingController(text: descriptionMap['en'] ?? '');
    final initialPriceType =
        (e?.priceType ?? 'hour').toLowerCase() == 'day' ? 'day' : 'hour';
    final initialPrice = initialPriceType == 'day'
        ? (e?.pricePerDay ?? 0)
        : (e?.pricePerHour ?? 0);
    _price = TextEditingController(
      text: initialPrice > 0 ? initialPrice.toString() : '',
    );
    _minDuration = TextEditingController(
      text: (e?.minRentalDuration ?? 0) > 0
          ? e!.minRentalDuration.toStringAsFixed(
              e.minRentalDuration.truncateToDouble() == e.minRentalDuration
                  ? 0
                  : 1,
            )
          : '',
    );
    _tagInput = TextEditingController();
    _videoUrl = TextEditingController(text: e?.videoUrl ?? '');
    _titleEn = TextEditingController(text: titleMap['en'] ?? '');
    _titleTa = TextEditingController(text: titleMap['ta'] ?? '');
    _titleHi = TextEditingController(text: titleMap['hi'] ?? '');
    _categoryEn = TextEditingController(text: categoryMap['en'] ?? '');
    _categoryTa = TextEditingController(text: categoryMap['ta'] ?? '');
    _categoryHi = TextEditingController(text: categoryMap['hi'] ?? '');
    _descriptionEn = TextEditingController(text: descriptionMap['en'] ?? '');
    _descriptionTa = TextEditingController(text: descriptionMap['ta'] ?? '');
    _descriptionHi = TextEditingController(text: descriptionMap['hi'] ?? '');
    _selectedCondition =
        _conditions.contains(e?.condition) ? e!.condition : 'Good';
    _priceType = initialPriceType;
    _minDurationType =
        (e?.minRentalDurationType ?? 'hours').toLowerCase() == 'days'
            ? 'days'
            : 'hours';
    _status = (e?.status ?? 'published').toLowerCase() == 'draft'
        ? 'draft'
        : 'published';
    _availabilityFrom = e?.availabilityFrom;
    _availabilityTo = e?.availabilityTo;
    _location = e?.location ?? '';
    _lat = e?.latitude ?? 0;
    _lng = e?.longitude ?? 0;
    if (e != null) {
      _existingImages.addAll(e.imageUrls);
      _existingImagePublicIds.addAll(e.imagePublicIds);
      _tags.addAll(e.tags);
    }

    _inputLanguage =
        _resolveInitialLanguage(titleMap, descriptionMap, categoryMap);
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _description.dispose();
    _price.dispose();
    _minDuration.dispose();
    _tagInput.dispose();
    _videoUrl.dispose();
    _titleEn.dispose();
    _titleTa.dispose();
    _titleHi.dispose();
    _categoryEn.dispose();
    _categoryTa.dispose();
    _categoryHi.dispose();
    _descriptionEn.dispose();
    _descriptionTa.dispose();
    _descriptionHi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Equipment' : 'Add Equipment'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionCard(
              title: l10n.tr('input_language_title'),
              icon: Icons.translate_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _inputLanguage,
                    decoration:
                        _fieldDecoration(l10n.tr('input_language_hint')),
                    items: [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(l10n.tr('english')),
                      ),
                      DropdownMenuItem(
                        value: 'ta',
                        child: Text(l10n.tr('tamil')),
                      ),
                      DropdownMenuItem(
                        value: 'hi',
                        child: Text(l10n.tr('hindi')),
                      ),
                    ].toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _syncCurrentInputToLocalizedControllers();
                        _inputLanguage = value;
                        _syncLocalizedControllersToCurrentInput();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _translating ? null : _generateTranslations,
                      icon: _translating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(l10n.tr('generate_other_languages')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: l10n.tr('equipment_input_section'),
              icon: Icons.edit_note_rounded,
              child: Column(
                children: [
                  TextFormField(
                    controller: _title,
                    textInputAction: TextInputAction.next,
                    decoration:
                        _fieldDecoration(l10n.tr('equipment_title_hint')),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _category,
                    textInputAction: TextInputAction.next,
                    decoration:
                        _fieldDecoration(l10n.tr('equipment_category_hint')),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCondition,
                    decoration: _fieldDecoration('Select condition'),
                    items: _conditions
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedCondition = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 5,
                    decoration:
                        _fieldDecoration(l10n.tr('equipment_description_hint')),
                    validator: _required,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: l10n.tr('translations_edit_title'),
              icon: Icons.language_rounded,
              child: Column(
                children: [
                  _languageEditGroup(
                    label: l10n.tr('english'),
                    title: _titleEn,
                    category: _categoryEn,
                    description: _descriptionEn,
                  ),
                  const SizedBox(height: 12),
                  _languageEditGroup(
                    label: l10n.tr('tamil'),
                    title: _titleTa,
                    category: _categoryTa,
                    description: _descriptionTa,
                  ),
                  const SizedBox(height: 12),
                  _languageEditGroup(
                    label: l10n.tr('hindi'),
                    title: _titleHi,
                    category: _categoryHi,
                    description: _descriptionHi,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Pricing',
              icon: Icons.currency_rupee_rounded,
              child: Column(
                children: [
                  TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _fieldDecoration('Enter price'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Price should be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'hour',
                        label: Text('Hour'),
                      ),
                      ButtonSegment<String>(
                        value: 'day',
                        label: Text('Day'),
                      ),
                    ],
                    selected: <String>{_priceType},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _priceType = selection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Minimum Rental Duration',
              icon: Icons.timelapse_rounded,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minDuration,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _fieldDecoration('Duration'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _minDurationType,
                      decoration: _fieldDecoration('Unit'),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'hours',
                          child: Text('Hours'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'days',
                          child: Text('Days'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _minDurationType = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Availability Window',
              icon: Icons.calendar_today_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickAvailabilityFrom,
                          icon: const Icon(Icons.date_range_rounded),
                          label: Text(_availabilityFrom == null
                              ? 'From Date'
                              : _formatDate(_availabilityFrom!)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickAvailabilityTo,
                          icon: const Icon(Icons.event_available_rounded),
                          label: Text(_availabilityTo == null
                              ? 'To Date'
                              : _formatDate(_availabilityTo!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _availabilityFrom != null && _availabilityTo != null
                        ? 'Available from ${_formatDate(_availabilityFrom!)} to ${_formatDate(_availabilityTo!)}'
                        : 'Select both dates',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Location',
              icon: Icons.location_on_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _location.isEmpty ? 'No location selected' : _location,
                      style: TextStyle(
                        color: _location.isEmpty
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Pick on Map'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Images',
              icon: Icons.image_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _existingImages.length; i++)
                        _imageTile(
                          child: Image.network(
                            _existingImages[i],
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          ),
                          onRemove: () {
                            setState(() {
                              _existingImages.removeAt(i);
                              if (i < _existingImagePublicIds.length) {
                                _existingImagePublicIds.removeAt(i);
                              }
                            });
                          },
                        ),
                      for (var i = 0; i < _newImages.length; i++)
                        _imageTile(
                          child: Image.file(
                            _newImages[i],
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          ),
                          onRemove: () {
                            setState(() {
                              _newImages.removeAt(i);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Upload Images'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'At least one image is required.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Tutorial Video (Optional)',
              icon: Icons.ondemand_video_rounded,
              child: TextFormField(
                controller: _videoUrl,
                decoration: _fieldDecoration('Paste Cloudinary video URL'),
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Tags (Optional)',
              icon: Icons.sell_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagInput,
                          decoration: _fieldDecoration(
                            'Add tags e.g. seeder, farming',
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _addTag,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .map(
                            (tag) => InputChip(
                              label: Text(tag),
                              onDeleted: () {
                                setState(() {
                                  _tags.remove(tag);
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Listing Status',
              icon: Icons.publish_rounded,
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Published'),
                      selected: _status == 'published',
                      onSelected: (_) {
                        setState(() {
                          _status = 'published';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Draft'),
                      selected: _status == 'draft',
                      onSelected: (_) {
                        setState(() {
                          _status = 'draft';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _saving
                    ? 'Saving...'
                    : (isEdit ? 'Update Equipment' : 'Create Equipment'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _resolveInitialLanguage(
    Map<String, String> title,
    Map<String, String> description,
    Map<String, String> category,
  ) {
    for (final code in const <String>['en', 'ta', 'hi']) {
      if ((title[code] ?? '').trim().isNotEmpty ||
          (description[code] ?? '').trim().isNotEmpty ||
          (category[code] ?? '').trim().isNotEmpty) {
        return code;
      }
    }
    return 'en';
  }

  void _syncCurrentInputToLocalizedControllers() {
    final currentTitle = _title.text.trim();
    final currentDescription = _description.text.trim();
    final currentCategory = _category.text.trim();
    switch (_inputLanguage) {
      case 'ta':
        _titleTa.text = currentTitle;
        _descriptionTa.text = currentDescription;
        _categoryTa.text = currentCategory;
        break;
      case 'hi':
        _titleHi.text = currentTitle;
        _descriptionHi.text = currentDescription;
        _categoryHi.text = currentCategory;
        break;
      default:
        _titleEn.text = currentTitle;
        _descriptionEn.text = currentDescription;
        _categoryEn.text = currentCategory;
        break;
    }
  }

  void _syncLocalizedControllersToCurrentInput() {
    switch (_inputLanguage) {
      case 'ta':
        _title.text = _titleTa.text;
        _description.text = _descriptionTa.text;
        _category.text = _categoryTa.text;
        break;
      case 'hi':
        _title.text = _titleHi.text;
        _description.text = _descriptionHi.text;
        _category.text = _categoryHi.text;
        break;
      default:
        _title.text = _titleEn.text;
        _description.text = _descriptionEn.text;
        _category.text = _categoryEn.text;
        break;
    }
  }

  Future<void> _generateTranslations() async {
    final l10n = AppLocalizations.of(context);
    if (_title.text.trim().isEmpty ||
        _description.text.trim().isEmpty ||
        _category.text.trim().isEmpty) {
      _showSnack(l10n.tr('translation_input_required'));
      return;
    }

    _syncCurrentInputToLocalizedControllers();

    setState(() {
      _translating = true;
    });

    try {
      final translated = await _translationService.translateEquipmentFields(
        baseLanguage: _inputLanguage,
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category.text.trim(),
      );

      _titleEn.text = translated['title']?['en'] ?? _titleEn.text;
      _titleTa.text = translated['title']?['ta'] ?? _titleTa.text;
      _titleHi.text = translated['title']?['hi'] ?? _titleHi.text;
      _descriptionEn.text =
          translated['description']?['en'] ?? _descriptionEn.text;
      _descriptionTa.text =
          translated['description']?['ta'] ?? _descriptionTa.text;
      _descriptionHi.text =
          translated['description']?['hi'] ?? _descriptionHi.text;
      _categoryEn.text = translated['category']?['en'] ?? _categoryEn.text;
      _categoryTa.text = translated['category']?['ta'] ?? _categoryTa.text;
      _categoryHi.text = translated['category']?['hi'] ?? _categoryHi.text;
      _syncLocalizedControllersToCurrentInput();
      _showSnack(l10n.tr('translation_generated'));
    } catch (error) {
      _showSnack('${l10n.tr('translation_failed')}: $error');
    } finally {
      if (mounted) {
        setState(() {
          _translating = false;
        });
      }
    }
  }

  Map<String, String> _buildLocalizedMap(
    TextEditingController en,
    TextEditingController ta,
    TextEditingController hi,
    String fallbackValue,
  ) {
    final enText = en.text.trim();
    final taText = ta.text.trim();
    final hiText = hi.text.trim();
    final fallback = enText.isNotEmpty ? enText : fallbackValue.trim();
    return {
      'en': enText.isNotEmpty ? enText : fallback,
      'ta':
          taText.isNotEmpty ? taText : (enText.isNotEmpty ? enText : fallback),
      'hi':
          hiText.isNotEmpty ? hiText : (enText.isNotEmpty ? enText : fallback),
    };
  }

  Widget _languageEditGroup({
    required String label,
    required TextEditingController title,
    required TextEditingController category,
    required TextEditingController description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: title,
            decoration: _fieldDecoration('Title ($label)'),
            validator: _required,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: category,
            decoration: _fieldDecoration('Category ($label)'),
            validator: _required,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: description,
            minLines: 2,
            maxLines: 4,
            decoration: _fieldDecoration('Description ($label)'),
            validator: _required,
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _imageTile({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: child,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 11,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() {
      _newImages.addAll(picked.map((e) => File(e.path)));
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initialLatLng: (_lat == 0 && _lng == 0) ? null : LatLng(_lat, _lng),
          initialAddress: _location,
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _lat = result.latitude;
      _lng = result.longitude;
      _location = _extractCity(result.address);
    });
  }

  Future<void> _pickAvailabilityFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _availabilityFrom ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      _availabilityFrom = DateTime(picked.year, picked.month, picked.day);
      if (_availabilityTo != null &&
          _availabilityTo!.isBefore(_availabilityFrom!)) {
        _availabilityTo = _availabilityFrom;
      }
    });
  }

  Future<void> _pickAvailabilityTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _availabilityTo ?? _availabilityFrom ?? now,
      firstDate: _availabilityFrom ?? DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      _availabilityTo = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _addTag() {
    final raw = _tagInput.text.trim();
    if (raw.isEmpty) return;
    final normalized = raw.toLowerCase();
    if (_tags.any((tag) => tag.toLowerCase() == normalized)) {
      _tagInput.clear();
      return;
    }
    setState(() {
      _tags.add(raw);
      _tagInput.clear();
    });
  }

  bool _validateExtraRules() {
    if (_location.trim().isEmpty) {
      _showSnack('Location is required');
      return false;
    }
    if (_availabilityFrom == null || _availabilityTo == null) {
      _showSnack('Availability from/to dates are required');
      return false;
    }
    if (_availabilityTo!.isBefore(_availabilityFrom!)) {
      _showSnack('Availability end date should be after start date');
      return false;
    }
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      _showSnack('Please upload at least one image');
      return false;
    }
    return true;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _extractCity(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return '';
    final city = trimmed.split(',').first.trim();
    return city.isEmpty ? trimmed : city;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _save() async {
    _syncCurrentInputToLocalizedControllers();
    if (!_formKey.currentState!.validate()) return;
    if (!_validateExtraRules()) return;

    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null || authUid.trim().isEmpty) {
      _showSnack('Please login again to add equipment');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final uploaded = _newImages.isEmpty
          ? const <CloudinaryUploadResult>[]
          : await _cloudinary.uploadImagesWithMetadata(_newImages);
      final images = [
        ..._existingImages,
        ...uploaded.map((e) => e.secureUrl),
      ];
      final imagePublicIds = [
        ..._existingImagePublicIds,
        ...uploaded.map((e) => e.publicId),
      ];
      final nowUtc = DateTime.now().toUtc();
      final createdAtUtc = (widget.existing?.createdAt ?? nowUtc).toUtc();
      final parsedPrice = double.parse(_price.text.trim());
      final parsedMinDuration = double.parse(_minDuration.text.trim());
      final titleMap =
          _buildLocalizedMap(_titleEn, _titleTa, _titleHi, _title.text);
      final categoryMap = _buildLocalizedMap(
        _categoryEn,
        _categoryTa,
        _categoryHi,
        _category.text,
      );
      final descriptionMap = _buildLocalizedMap(
        _descriptionEn,
        _descriptionTa,
        _descriptionHi,
        _description.text,
      );

      final payload = <String, dynamic>{
        'title': titleMap,
        'equipmentName': titleMap['en'],
        'category': categoryMap,
        'description': descriptionMap,
        'condition': _selectedCondition,
        'price': parsedPrice,
        'price_type': _priceType,
        'min_rental_duration': parsedMinDuration,
        'min_rental_duration_type': _minDurationType,
        'location': _location.trim(),
        'availability': {
          'from': _availabilityFrom!.toUtc().toIso8601String(),
          'to': _availabilityTo!.toUtc().toIso8601String(),
        },
        'images': images,
        'image_public_ids': imagePublicIds,
        'documents': const <String>[],
        'owner_user_id': authUid,
        'status': _status,
        'videoUrl': _videoUrl.text.trim(),
        'tags': _tags,
        'created_at': Timestamp.fromDate(createdAtUtc),
        'updated_at': Timestamp.fromDate(nowUtc),
      };

      if (widget.existing == null) {
        await _service.addEquipmentRecord(payload);
      } else {
        await _service.updateEquipment(
          equipmentId: widget.existing!.equipmentId,
          updates: payload,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save equipment: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}
