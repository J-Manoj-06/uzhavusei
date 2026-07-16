import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/equipment_translation_service.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/location_service.dart';
import '../../../utils/localized_text.dart';
import '../../location/services/city_service.dart';

// ─────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────
const Color _green = Color(0xFF4CAF50);
const Color _darkGreen = Color(0xFF2E7D32);
const Color _lightGreen = Color(0xFFE8F5E9);
const Color _bg = Color(0xFFF6F8FA);

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

class _EquipmentFormPageState extends State<EquipmentFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _service = MarketplaceService();
  final _cloudinary = CloudinaryService();
  final _translationService = EquipmentTranslationService();

  int _step = 0; // 0=Basic, 1=Pricing, 2=Availability, 3=Images, 4=Success
  static const int _totalSteps = 4;

  // ── Category presets ──────────────────────────────────────────
  static const List<Map<String, String>> _categories = [
    {'emoji': '🚜', 'label': 'Tractor'},
    {'emoji': '🌾', 'label': 'Harvester'},
    {'emoji': '🚿', 'label': 'Sprayer'},
    {'emoji': '🌱', 'label': 'Seeder'},
    {'emoji': '🔧', 'label': 'Rotavator'},
    {'emoji': '💧', 'label': 'Pump Set'},
    {'emoji': '🌿', 'label': 'Cultivator'},
    {'emoji': '🏗️', 'label': 'Other'},
  ];

  // ── Condition options ─────────────────────────────────────────
  static const List<Map<String, String>> _conditionOpts = [
    {'emoji': '✨', 'label': 'Like New'},
    {'emoji': '✅', 'label': 'Excellent'},
    {'emoji': '🔧', 'label': 'Good'},
    {'emoji': '⚠️', 'label': 'Fair'},
  ];

  // ── Suggested tags ────────────────────────────────────────────
  static const List<String> _suggestedTags = [
    '🚜 Tractor', '🌾 Paddy', '🌱 Farming',
    '🚿 Sprayer', '🌽 Harvesting', '💧 Irrigation',
  ];

  // ── Controllers ────────────────────────────────────────────────
  late TextEditingController _title, _category, _description;
  late TextEditingController _price, _minDuration;
  late TextEditingController _tagInput, _videoUrl;
  late TextEditingController _titleEn, _titleTa, _titleHi;
  late TextEditingController _categoryEn, _categoryTa, _categoryHi;
  late TextEditingController _descriptionEn, _descriptionTa, _descriptionHi;
  late TextEditingController _locationCtrl;

  String _inputLanguage = 'en';
  String _selectedCondition = 'Good';
  String _selectedCategoryEmoji = '🚜';
  String _priceType = 'hour';
  String _minDurationType = 'hours';
  String _status = 'published';

  // ── Income calculator state ────────────────────────────────────
  int _demandLevel = 1;   // 0=Low(10), 1=Medium(20), 2=High(26)
  int _hoursPerDay = 4;   // only used when _priceType == 'hour'

  static const List<int> _rentalDays = [10, 20, 26];
  static const List<String> _demandLabels = ['Low', 'Medium', 'High'];
  static const List<String> _demandEmojis = ['🌱', '🚜', '📈'];
  static const List<String> _demandSubs = ['10 days/month', '20 days/month', '26 days/month'];

  DateTime? _availabilityFrom;
  DateTime? _availabilityTo;

  String _location = '';
  double _lat = 0, _lng = 0;
  String _detectedArea = '';
  String _detectedCity = '';
  String _detectedState = '';
  String _detectedCountry = '';
  double _locationAccuracy = 0;
  DateTime? _locationCapturedAt;
  bool _detectingLocation = false;
  String? _locationError;

  final List<String> _tags = [];
  bool _saving = false;
  bool _translating = false;
  bool _languageSyncedFromApp = false;

  List<String> _cities = [];
  bool _isLoadingCities = true;

  final List<File> _newImages = [];
  final List<String> _existingImages = [];
  final List<String> _existingImagePublicIds = [];

  late final AnimationController _progressCtrl;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnim = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut);

    _loadCities();
    final e = widget.existing;
    final titleMap = normalizeLocalizedField(e?.titleLocalized ?? e?.equipmentName, fallback: e?.equipmentName ?? '');
    final categoryMap = normalizeLocalizedField(e?.categoryLocalized ?? e?.category, fallback: e?.category ?? '');
    final descriptionMap = normalizeLocalizedField(e?.descriptionLocalized ?? e?.description, fallback: e?.description ?? '');

    _title       = TextEditingController(text: titleMap['en'] ?? '');
    _category    = TextEditingController(text: categoryMap['en'] ?? '');
    _description = TextEditingController(text: descriptionMap['en'] ?? '');

    final initialPriceType = widget.existing != null 
        ? ((e?.priceType ?? 'hour').toLowerCase() == 'day' ? 'day' : 'hour')
        : 'hour';
    final initialPrice = initialPriceType == 'day' ? (e?.pricePerDay ?? 0) : (e?.pricePerHour ?? 0);
    _price       = TextEditingController(text: initialPrice > 0 ? initialPrice.toString() : '');
    _minDuration = TextEditingController(
      text: (e?.minRentalDuration ?? 0) > 0
          ? e!.minRentalDuration.toStringAsFixed(e.minRentalDuration.truncateToDouble() == e.minRentalDuration ? 0 : 1)
          : '',
    );
    _tagInput  = TextEditingController();
    _videoUrl  = TextEditingController(text: e?.videoUrl ?? '');
    _titleEn   = TextEditingController(text: titleMap['en'] ?? '');
    _titleTa   = TextEditingController(text: titleMap['ta'] ?? '');
    _titleHi   = TextEditingController(text: titleMap['hi'] ?? '');
    _categoryEn = TextEditingController(text: categoryMap['en'] ?? '');
    _categoryTa = TextEditingController(text: categoryMap['ta'] ?? '');
    _categoryHi = TextEditingController(text: categoryMap['hi'] ?? '');
    _descriptionEn = TextEditingController(text: descriptionMap['en'] ?? '');
    _descriptionTa = TextEditingController(text: descriptionMap['ta'] ?? '');
    _descriptionHi = TextEditingController(text: descriptionMap['hi'] ?? '');
    _locationCtrl  = TextEditingController(text: e?.location ?? '');

    _selectedCondition = _conditionOpts.any((c) => c['label'] == e?.condition)
        ? (e?.condition ?? 'Good') : 'Good';
    _priceType = initialPriceType;
    _minDurationType = widget.existing != null 
        ? ((e?.minRentalDurationType ?? 'hours').toLowerCase() == 'days' ? 'days' : 'hours')
        : 'hours';
    _status = (e?.status ?? 'published').toLowerCase() == 'draft' ? 'draft' : 'published';
    _availabilityFrom = e?.availabilityFrom;
    _availabilityTo   = e?.availabilityTo;
    _location = e?.location ?? '';
    _lat = e?.latitude  ?? 0;
    _lng = e?.longitude ?? 0;
    _detectedArea = e?.area ?? '';
    _detectedCity = e?.city ?? '';
    _detectedState = e?.state ?? '';
    _detectedCountry = e?.country ?? '';
    _locationAccuracy = e?.locationAccuracy ?? 0.0;
    _locationCapturedAt = e?.locationCapturedAt;
    if (e != null) {
      _existingImages.addAll(e.imageUrls);
      _existingImagePublicIds.addAll(e.imagePublicIds);
      _tags.addAll(e.tags);
    }
    _inputLanguage = _resolveInitialLanguage(titleMap, descriptionMap, categoryMap);
    _updateProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_languageSyncedFromApp || widget.existing != null) return;
    final appLanguage = context.read<LocaleProvider>().languageCode;
    if (appLanguage == 'ta' || appLanguage == 'hi' || appLanguage == 'en') {
      _inputLanguage = appLanguage;
      _syncLocalizedControllersToCurrentInput();
    }
    _languageSyncedFromApp = true;
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    for (final c in [_title, _category, _description, _price, _minDuration, _tagInput, _videoUrl,
      _titleEn, _titleTa, _titleHi, _categoryEn, _categoryTa, _categoryHi,
      _descriptionEn, _descriptionTa, _descriptionHi, _locationCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateProgress() {
    _progressCtrl.animateTo((_step / _totalSteps).clamp(0.0, 1.0));
  }

  void _goToStep(int step) {
    setState(() {
      _step = step;
      if (_step == 2 && widget.existing == null && _location.isEmpty) {
        _detectLocation();
      }
    });
    _updateProgress();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _detectingLocation = true;
      _locationError = null;
    });

    final result = await LocationService.instance.getCurrentLocation();

    if (!mounted) return;

    if (result is LocationSuccess) {
      final loc = result.location;
      setState(() {
        _lat = loc.latitude;
        _lng = loc.longitude;
        _detectedArea = loc.area ?? '';
        _detectedCity = loc.city ?? '';
        _detectedState = loc.state ?? '';
        _detectedCountry = loc.country ?? '';
        _locationAccuracy = loc.accuracy ?? 0.0;
        _locationCapturedAt = loc.timestamp;
        _location = [
          if (_detectedArea.isNotEmpty) _detectedArea,
          if (_detectedCity.isNotEmpty) _detectedCity,
          if (_detectedState.isNotEmpty) _detectedState,
        ].join(', ');
        _locationCtrl.text = _location;
        _detectingLocation = false;
      });
    } else if (result is LocationFailure) {
      setState(() {
        _locationError = result.reason;
        _detectingLocation = false;
      });
    }
  }

  Future<void> _loadCities() async {
    final cities = await CityService.getCities();
    if (mounted) setState(() { _cities = cities; _isLoadingCities = false; });
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    if (_step == _totalSteps) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(isEdit),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isEdit) {
    final stepLabels = ['Basic Info', 'Pricing', 'Availability', 'Photos'];
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? 'Edit Equipment' : 'List Equipment for Rent',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            'Step ${_step + 1} of $_totalSteps  ·  ${stepLabels[_step.clamp(0, 3)]}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFEEEEEE)),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (i) {
              final done = i < _step;
              final active = i == _step;
              return Expanded(
                child: GestureDetector(
                  onTap: i < _step ? () => _goToStep(i) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: done ? _darkGreen : (active ? _green : const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildStep1BasicInfo();
      case 1: return _buildStep2Pricing();
      case 2: return _buildStep3Availability();
      case 3: return _buildStep4Photos();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar() {
    final isLast = _step == _totalSteps - 1;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
        ),
        child: Row(
          children: [
            if (_step > 0) ...[
              OutlinedButton(
                onPressed: () => _goToStep(_step - 1),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _green),
                  foregroundColor: _darkGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _onNextPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        isLast ? 'Publish Listing 🚀' : 'Continue →',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNextPressed() {
    if (_step < _totalSteps - 1) {
      if (!_validateCurrentStep()) return;
      _goToStep(_step + 1);
    } else {
      _save();
    }
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        if (_title.text.trim().isEmpty) { _showSnack('Please enter an equipment name'); return false; }
        if (_category.text.trim().isEmpty) { _category.text = _selectedCategoryEmoji; }
        return true;
      case 1:
        final p = double.tryParse(_price.text.trim());
        if (p == null || p <= 0) { _showSnack('Please enter a valid price'); return false; }
        return true;
      case 2:
        if (_availabilityFrom == null || _availabilityTo == null) { _showSnack('Please select availability dates'); return false; }
        if (_location.trim().isEmpty) { _showSnack('Please verify your location'); return false; }
        if (_lat == 0 || _lng == 0) { _showSnack('A verified GPS location is required to list an item.'); return false; }
        return true;
      case 3:
        if (_existingImages.isEmpty && _newImages.isEmpty) { _showSnack('Please upload at least one photo'); return false; }
        return true;
      default:
        return true;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 1 – Basic Info
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📋', title: 'Basic Information', subtitle: 'Tell us about your equipment'),
          const SizedBox(height: 20),

          // Equipment Name
          _fieldLabel('Equipment Name'),
          _textField(_title, hint: 'e.g. Mahindra 575 DI Tractor'),
          const SizedBox(height: 20),

          // Category picker
          _fieldLabel('Category'),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final isSelected = _category.text == cat['label'];
              return GestureDetector(
                onTap: () => setState(() {
                  _category.text = cat['label']!;
                  _selectedCategoryEmoji = cat['emoji']!;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? _lightGreen : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _green : const Color(0xFFE0E0E0),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [BoxShadow(color: _green.withValues(alpha: 0.2), blurRadius: 8)] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat['emoji']!, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 6),
                      Text(
                        cat['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? _darkGreen : const Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Condition
          _fieldLabel('Equipment Condition'),
          const SizedBox(height: 10),
          Row(
            children: _conditionOpts.map((opt) {
              final isSelected = _selectedCondition == opt['label'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCondition = opt['label']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: opt != _conditionOpts.last ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _lightGreen : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? _green : const Color(0xFFE0E0E0),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(opt['emoji']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          opt['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? _darkGreen : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Description
          _fieldLabel('Description'),
          Container(
            decoration: _cardDecor(),
            child: TextField(
              controller: _description,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Describe your equipment — year, features, capacity, fuel type...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Language
          _fieldLabel('Language & Translations'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecor(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _langChip('English', 'en'),
                    const SizedBox(width: 8),
                    _langChip('தமிழ்', 'ta'),
                    const SizedBox(width: 8),
                    _langChip('हिन्दी', 'hi'),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _translating ? null : _generateTranslations,
                    icon: _translating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(_translating ? 'Translating...' : '✨ Generate Translations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _fieldLabel('Tags (Max 20)'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ..._suggestedTags.map((t) {
                final added = _tags.contains(t);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (added) _tags.remove(t);
                    else if (_tags.length < 20) _tags.add(t);
                    else _showSnack('Maximum 20 tags allowed');
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: added ? _lightGreen : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: added ? _green : const Color(0xFFDDDDDD), width: added ? 1.5 : 1),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 13, color: added ? _darkGreen : Colors.grey.shade700, fontWeight: added ? FontWeight.w600 : FontWeight.w400)),
                  ),
                );
              }),
              GestureDetector(
                onTap: _showAddCustomTagDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _green, width: 1.5, style: BorderStyle.solid),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: _green),
                      SizedBox(width: 4),
                      Text('Add Custom Tag', style: TextStyle(fontSize: 13, color: _green, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_tags.where((t) => !_suggestedTags.contains(t)).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Custom Tags', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _tags.where((t) => !_suggestedTags.contains(t)).map((t) => InputChip(
                label: Text(t, style: const TextStyle(fontSize: 13, color: _darkGreen, fontWeight: FontWeight.w600)),
                onDeleted: () => setState(() => _tags.remove(t)),
                backgroundColor: _lightGreen,
                deleteIconColor: _darkGreen,
                side: const BorderSide(color: _green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddCustomTagDialog() {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Tag'),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(hintText: 'e.g. Rotavator', border: OutlineInputBorder()),
          autofocus: true,
          onSubmitted: (val) {
            _addCustomTag(val);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _addCustomTag(tc.text);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addCustomTag(String raw) {
    final val = raw.trim();
    if (val.isEmpty) return;
    if (_tags.length >= 20) {
      _showSnack('Maximum 20 tags allowed');
      return;
    }
    final normalized = val.toLowerCase();
    if (_tags.any((t) => t.toLowerCase() == normalized)) return; // No duplicates
    setState(() => _tags.add(val));
  }

  Widget _langChip(String label, String code) {
    final isSelected = _inputLanguage == code;
    return GestureDetector(
      onTap: () => setState(() {
        _syncCurrentInputToLocalizedControllers();
        _inputLanguage = code;
        _syncLocalizedControllersToCurrentInput();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _green : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade700)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 2 – Pricing
  // ─────────────────────────────────────────────────────────────
  // ── Income calculator helpers ────────────────────────────────
  double _calcMonthly(double price) {
    if (price <= 0) return 0;
    final days = _rentalDays[_demandLevel];
    switch (_priceType) {
      case 'hour': return price * _hoursPerDay * days;
      case 'week': return price * 4;
      case 'day':
      default:     return price * days;
    }
  }

  String _calcFormula(double price) {
    if (price <= 0) return '';
    final days = _rentalDays[_demandLevel];
    switch (_priceType) {
      case 'hour': return '₹${price.toStringAsFixed(0)} × $_hoursPerDay hrs × $days days';
      case 'week': return '₹${price.toStringAsFixed(0)} × 4 weeks';
      default:     return '₹${price.toStringAsFixed(0)} × $days days';
    }
  }

  Widget _buildStep2Pricing() {
    final price = double.tryParse(_price.text.trim()) ?? 0;
    final monthly = _calcMonthly(price);
    final annual  = monthly * 12;

    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '💰', title: 'Set Your Rental Price', subtitle: 'Earn extra income from idle machinery'),
          const SizedBox(height: 20),

          // ── Pricing type cards ─────────────────────────────────
          _fieldLabel('Pricing Type'),
          const SizedBox(height: 10),
          Row(
            children: [
              {'type': 'hour', 'emoji': '⏰', 'label': 'Per Hour'},
              {'type': 'day',  'emoji': '📅', 'label': 'Per Day'},
              {'type': 'week', 'emoji': '📆', 'label': 'Per Week'},
            ].map((opt) {
              final sel = _priceType == opt['type'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _priceType = opt['type']!;
                    if (_priceType == 'hour') _minDurationType = 'hours';
                    else if (_priceType == 'day') _minDurationType = 'days';
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: sel ? _lightGreen : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: sel ? _green : const Color(0xFFE0E0E0), width: sel ? 2 : 1),
                    ),
                    child: Column(
                      children: [
                        Text(opt['emoji']!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(opt['label']!,
                            style: TextStyle(fontSize: 12,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel ? _darkGreen : Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Price input ────────────────────────────────────────
          _fieldLabel('Rental Price'),
          Container(
            decoration: _cardDecor(),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('₹', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _darkGreen)),
                ),
                Expanded(
                  child: TextField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 24),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      suffix: Text('/ $_priceType',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Hours per day slider (per-hour only) ───────────────
          if (_priceType == 'hour') ...[
            _fieldLabel('Expected Usage Per Day'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: _cardDecor(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 Hour', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(20)),
                        child: Text('$_hoursPerDay Hour${_hoursPerDay > 1 ? 's' : ''} / Day',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: _darkGreen, fontSize: 13)),
                      ),
                      Text('8 Hours', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _green,
                      inactiveTrackColor: const Color(0xFFE0E0E0),
                      thumbColor: _darkGreen,
                      overlayColor: _green.withValues(alpha: 0.15),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: _hoursPerDay.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      onChanged: (v) => setState(() => _hoursPerDay = v.round()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Expected demand cards ──────────────────────────────
          _fieldLabel('Expected Demand'),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (i) {
              final sel = _demandLevel == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _demandLevel = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: sel ? _lightGreen : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: sel ? _green : const Color(0xFFE0E0E0),
                        width: sel ? 2 : 1,
                      ),
                      boxShadow: sel
                          ? [BoxShadow(color: _green.withValues(alpha: 0.18), blurRadius: 10)]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(_demandEmojis[i], style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 8),
                        Text(_demandLabels[i],
                            style: TextStyle(
                              fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                              fontSize: 13,
                              color: sel ? _darkGreen : const Color(0xFF1A1A1A),
                            )),
                        const SizedBox(height: 4),
                        Text(_demandSubs[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: sel ? _darkGreen.withValues(alpha: 0.7) : Colors.grey.shade500,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // ── Income card ────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Container(
              key: ValueKey('$monthly-$_priceType-$_demandLevel-$_hoursPerDay'),
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('💰', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Potential Monthly Income',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(
                            monthly > 0 ? '₹${_formatAmount(monthly)}' : '₹0',
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (price > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _calcFormula(price),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text('📈  Annual: ₹${_formatAmount(annual)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Estimated earnings based on your rental price and expected demand.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Min duration ───────────────────────────────────────
          _fieldLabel('Minimum Rental Duration'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: _cardDecor(),
                  child: TextField(
                    controller: _minDuration,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        hintText: 'Duration', border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: _cardDecor(),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _minDurationType,
                      onChanged: (v) => setState(() => _minDurationType = v ?? 'days'),
                      items: const [
                        DropdownMenuItem(value: 'hours', child: Text('Hours')),
                        DropdownMenuItem(value: 'days',  child: Text('Days')),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format large numbers: 50000 → 50,000 | 600000 → 6,00,000
  String _formatAmount(double amount) {
    final intAmt = amount.toInt();
    // Indian number format
    final s = intAmt.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buffer = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buffer.write(',');
      buffer.write(rest[i]);
    }
    return '${buffer.toString()},$last3';
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 3 – Availability & Location
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep3Availability() {
    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📅', title: 'Availability & Location', subtitle: 'When and where is your equipment?'),
          const SizedBox(height: 20),

          _fieldLabel('Available Period'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _datePicker(
                  label: _availabilityFrom == null ? 'From Date' : _formatDate(_availabilityFrom!),
                  icon: Icons.calendar_today_rounded,
                  onTap: _pickAvailabilityFrom,
                  isSet: _availabilityFrom != null,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: _datePicker(
                  label: _availabilityTo == null ? 'To Date' : _formatDate(_availabilityTo!),
                  icon: Icons.event_available_rounded,
                  onTap: _pickAvailabilityTo,
                  isSet: _availabilityTo != null,
                ),
              ),
            ],
          ),
          if (_availabilityFrom != null && _availabilityTo != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: _green, size: 16),
                const SizedBox(width: 8),
                Text('${_formatDate(_availabilityFrom!)} → ${_formatDate(_availabilityTo!)}',
                    style: const TextStyle(color: _darkGreen, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
          const SizedBox(height: 24),

          _fieldLabel('Location'),
          const SizedBox(height: 10),
          if (_detectingLocation)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: _green),
                    SizedBox(height: 12),
                    Text('Detecting location automatically...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (_locationError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                      SizedBox(width: 8),
                      Text('Location Detection Failed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(_locationError!, style: const TextStyle(fontSize: 13, color: Color(0xFF795548))),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _detectLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          else if (_location.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEBEFF0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: _green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.existing != null ? 'Listing Location' : '📍 Current Location',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _green, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_detectedArea.isNotEmpty)
                    Text(
                      _detectedArea,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (_detectedCity.isNotEmpty) _detectedCity,
                      if (_detectedState.isNotEmpty) _detectedState,
                    ].join(', '),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.existing != null ? 'Stored location coordinates: $_lat, $_lng' : 'Detected automatically',
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _detectLocation,
                      icon: const Icon(Icons.my_location, size: 14),
                      label: Text(widget.existing != null ? 'Update to Current Location' : 'Refresh Location'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _green),
                        foregroundColor: _darkGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Center(
              child: ElevatedButton.icon(
                onPressed: _detectLocation,
                icon: const Icon(Icons.location_on),
                label: const Text('Detect Current Location'),
                style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _datePicker({required String label, required IconData icon, required VoidCallback onTap, required bool isSet}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSet ? _lightGreen : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSet ? _green : const Color(0xFFE0E0E0), width: isSet ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSet ? _darkGreen : Colors.grey),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSet ? FontWeight.w600 : FontWeight.w400, color: isSet ? _darkGreen : Colors.grey.shade600))),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 4 – Photos
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep4Photos() {
    final totalImages = _existingImages.length + _newImages.length;

    // Build combined list for drag & drop reordering
    final combinedItems = <Map<String, dynamic>>[];
    for (var i = 0; i < _existingImages.length; i++) {
      combinedItems.add({'type': 'existing', 'url': _existingImages[i], 'id': _existingImagePublicIds[i]});
    }
    for (var i = 0; i < _newImages.length; i++) {
      combinedItems.add({'type': 'new', 'file': _newImages[i]});
    }

    return SingleChildScrollView(
      key: const ValueKey('step4'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📸', title: 'Equipment Photos', subtitle: 'Good photos attract 3× more bookings'),
          const SizedBox(height: 20),

          // Upload area
          GestureDetector(
            onTap: () {
              if (totalImages >= 10) {
                _showSnack('Maximum 10 images allowed.');
                return;
              }
              _showPhotoSourceSheet();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _green.withValues(alpha: 0.4), width: 2, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.add_photo_alternate_rounded, size: 36, color: _green),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tap to Add Equipment Photos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 6),
                  Text('At least 1 photo required (Max 10)', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
          ),
          if (totalImages > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text('$totalImages photo${totalImages > 1 ? 's' : ''} added', style: const TextStyle(fontWeight: FontWeight.w600, color: _darkGreen)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (totalImages >= 10) {
                      _showSnack('Maximum 10 images allowed.');
                      return;
                    }
                    _showPhotoSourceSheet();
                  },
                  child: const Text('+ Add more', style: TextStyle(color: _green, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 16/9,
              ),
              itemCount: combinedItems.length,
              itemBuilder: (_, i) {
                final item = combinedItems[i];
                final isExisting = item['type'] == 'existing';
                final isFirst = i == 0;

                Widget imageWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: isExisting
                      ? Image.network(item['url'], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      : Image.file(item['file'], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                );

                return LongPressDraggable<int>(
                  data: i,
                  feedback: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 160, height: 90,
                      child: Opacity(opacity: 0.8, child: imageWidget),
                    ),
                  ),
                  childWhenDragging: Container(
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
                  ),
                  child: DragTarget<int>(
                    onAcceptWithDetails: (details) {
                      _reorderImages(details.data, i, combinedItems);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          imageWidget,
                          if (candidateData.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: _green.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _green, width: 3),
                              ),
                            ),
                          if (isFirst)
                            Positioned(
                              top: 6, left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(8)),
                                child: const Text('COVER PHOTO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              ),
                            ),
                          Positioned(
                            top: 6, right: 6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isExisting) {
                                    final urlIdx = _existingImages.indexOf(item['url']);
                                    _existingImages.removeAt(urlIdx);
                                    _existingImagePublicIds.removeAt(urlIdx);
                                  } else {
                                    _newImages.remove(item['file']);
                                  }
                                });
                              },
                              child: Container(
                                width: 26, height: 26,
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _reorderImages(int oldIndex, int newIndex, List<Map<String, dynamic>> combinedItems) {
    if (oldIndex == newIndex) return;
    setState(() {
      final item = combinedItems.removeAt(oldIndex);
      combinedItems.insert(newIndex, item);

      _existingImages.clear();
      _existingImagePublicIds.clear();
      _newImages.clear();

      for (final c in combinedItems) {
        if (c['type'] == 'existing') {
          _existingImages.add(c['url']);
          _existingImagePublicIds.add(c['id']);
        } else {
          _newImages.add(c['file']);
        }
      }
    });
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text('Select Photo Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _lightGreen, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: _green),
              ),
              title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndCropImage(ImageSource.camera);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _lightGreen, shape: BoxShape.circle),
                child: const Icon(Icons.photo_library_rounded, color: _green),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndCropImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.center_focus_strong_rounded, color: _green),
              SizedBox(width: 10),
              Text('Camera Guide'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _green, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.aspect_ratio_rounded, size: 48, color: _green),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Place the equipment completely inside the frame for best results.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
              child: const Text('Open Camera'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Equipment Photo',
          toolbarColor: _green,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (cropped != null) {
      setState(() => _newImages.add(File(cropped.path)));
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  SUCCESS SCREEN
  // ─────────────────────────────────────────────────────────────
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(color: _lightGreen, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: _green, size: 72),
              ),
              const SizedBox(height: 32),
              const Text('Equipment Ready for Listing! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 12),
              Text('Your equipment is now visible to nearby farmers looking for machinery.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('View My Listings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _step = 0;
                      _title.clear(); _category.clear(); _description.clear();
                      _price.clear(); _newImages.clear();
                      _availabilityFrom = null; _availabilityTo = null;
                      _location = ''; _locationCtrl.clear();
                      _tags.clear();
                    });
                    _updateProgress();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _green),
                    foregroundColor: _darkGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Create Another Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SHARED WIDGETS
  // ─────────────────────────────────────────────────────────────
  Widget _stepHeader({required String emoji, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 4, top: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A1A))),
  );

  Widget _textField(TextEditingController ctrl, {required String hint}) {
    return Container(
      decoration: _cardDecor(),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE8E8E8)),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
  );

  // ─────────────────────────────────────────────────────────────
  //  LOGIC (unchanged from original)
  // ─────────────────────────────────────────────────────────────
  String _resolveInitialLanguage(Map<String, String> title, Map<String, String> description, Map<String, String> category) {
    for (final code in const <String>['en', 'ta', 'hi']) {
      if ((title[code] ?? '').trim().isNotEmpty || (description[code] ?? '').trim().isNotEmpty || (category[code] ?? '').trim().isNotEmpty) return code;
    }
    return 'en';
  }

  void _syncCurrentInputToLocalizedControllers() {
    switch (_inputLanguage) {
      case 'ta': _titleTa.text = _title.text.trim(); _descriptionTa.text = _description.text.trim(); _categoryTa.text = _category.text.trim(); break;
      case 'hi': _titleHi.text = _title.text.trim(); _descriptionHi.text = _description.text.trim(); _categoryHi.text = _category.text.trim(); break;
      default:   _titleEn.text = _title.text.trim(); _descriptionEn.text = _description.text.trim(); _categoryEn.text = _category.text.trim();
    }
  }

  void _syncLocalizedControllersToCurrentInput() {
    switch (_inputLanguage) {
      case 'ta': _title.text = _titleTa.text; _description.text = _descriptionTa.text; _category.text = _categoryTa.text; break;
      case 'hi': _title.text = _titleHi.text; _description.text = _descriptionHi.text; _category.text = _categoryHi.text; break;
      default:   _title.text = _titleEn.text; _description.text = _descriptionEn.text; _category.text = _categoryEn.text;
    }
  }

  Future<void> _generateTranslations() async {
    final l10n = AppLocalizations.of(context);
    if (_title.text.trim().isEmpty || _description.text.trim().isEmpty || _category.text.trim().isEmpty) {
      _showSnack(l10n.tr('translation_input_required')); return;
    }
    _syncCurrentInputToLocalizedControllers();
    setState(() => _translating = true);
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
      _descriptionEn.text = translated['description']?['en'] ?? _descriptionEn.text;
      _descriptionTa.text = translated['description']?['ta'] ?? _descriptionTa.text;
      _descriptionHi.text = translated['description']?['hi'] ?? _descriptionHi.text;
      _categoryEn.text = translated['category']?['en'] ?? _categoryEn.text;
      _categoryTa.text = translated['category']?['ta'] ?? _categoryTa.text;
      _categoryHi.text = translated['category']?['hi'] ?? _categoryHi.text;
      _syncLocalizedControllersToCurrentInput();
      _showSnack(l10n.tr('translation_generated'));
    } catch (error) {
      _showSnack('${l10n.tr('translation_failed')}: $error');
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  Map<String, String> _buildLocalizedMap(TextEditingController en, TextEditingController ta, TextEditingController hi, String fallback) {
    final enText = en.text.trim(); final taText = ta.text.trim(); final hiText = hi.text.trim();
    final fb = enText.isNotEmpty ? enText : fallback.trim();
    return {
      'en': enText.isNotEmpty ? enText : fb,
      'ta': taText.isNotEmpty ? taText : (enText.isNotEmpty ? enText : fb),
      'hi': hiText.isNotEmpty ? hiText : (enText.isNotEmpty ? enText : fb),
    };
  }

  Future<void> _pickAvailabilityFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _availabilityFrom ?? now, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 10));
    if (picked == null) return;
    setState(() {
      _availabilityFrom = DateTime(picked.year, picked.month, picked.day);
      if (_availabilityTo != null && _availabilityTo!.isBefore(_availabilityFrom!)) _availabilityTo = _availabilityFrom;
    });
  }

  Future<void> _pickAvailabilityTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _availabilityTo ?? _availabilityFrom ?? now, firstDate: _availabilityFrom ?? DateTime(now.year - 1), lastDate: DateTime(now.year + 10));
    if (picked == null) return;
    setState(() => _availabilityTo = DateTime(picked.year, picked.month, picked.day));
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _save() async {
    _syncCurrentInputToLocalizedControllers();
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null || authUid.trim().isEmpty) { _showSnack('Please login again'); return; }

    setState(() => _saving = true);
    try {
      final uploaded = _newImages.isEmpty ? const <CloudinaryUploadResult>[] : await _cloudinary.uploadImagesWithMetadata(_newImages);
      final images = [..._existingImages, ...uploaded.map((e) => e.secureUrl)];
      final imagePublicIds = [..._existingImagePublicIds, ...uploaded.map((e) => e.publicId)];
      final nowUtc = DateTime.now().toUtc();
      final createdAtUtc = (widget.existing?.createdAt ?? nowUtc).toUtc();
      final parsedPrice = double.tryParse(_price.text.trim()) ?? 0;
      final parsedMinDuration = double.tryParse(_minDuration.text.trim()) ?? 1;
      final titleMap    = _buildLocalizedMap(_titleEn, _titleTa, _titleHi, _title.text);
      final categoryMap = _buildLocalizedMap(_categoryEn, _categoryTa, _categoryHi, _category.text);
      final descMap     = _buildLocalizedMap(_descriptionEn, _descriptionTa, _descriptionHi, _description.text);

      final payload = <String, dynamic>{
        'title': titleMap,
        'equipmentName': titleMap['en'],
        'category': categoryMap,
        'description': descMap,
        'condition': _selectedCondition,
        'price': parsedPrice,
        'price_type': _priceType,
        'min_rental_duration': parsedMinDuration,
        'min_rental_duration_type': _minDurationType,
        'location': _location.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'area': _detectedArea,
        'city': _detectedCity,
        'state': _detectedState,
        'country': _detectedCountry,
        'locationCapturedAt': _locationCapturedAt != null ? Timestamp.fromDate(_locationCapturedAt!) : null,
        'locationAccuracy': _locationAccuracy,
        'availability': {
          'from': _availabilityFrom!.toUtc().toIso8601String(),
          'to':   _availabilityTo!.toUtc().toIso8601String(),
        },
        'images': images,
        'image_public_ids': imagePublicIds,
        'documents': const <String>[],
        'owner_user_id': authUid,
        'input_language': _inputLanguage,
        'status': _status,
        'videoUrl': _videoUrl.text.trim(),
        'tags': _tags,
        'created_at': Timestamp.fromDate(createdAtUtc),
        'updated_at': Timestamp.fromDate(nowUtc),
      };

      if (widget.existing == null) {
        await _service.addEquipmentRecord(payload);
      } else {
        await _service.updateEquipment(equipmentId: widget.existing!.equipmentId, updates: payload);
      }

      if (!mounted) return;
      _goToStep(_totalSteps); // Show success screen
    } catch (error) {
      if (!mounted) return;
      _showSnack('Unable to save equipment: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
