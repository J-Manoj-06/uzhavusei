import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../models/marketplace_surplus_model.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/equipment_translation_service.dart';
import '../../../services/marketplace_service.dart';
import '../../../utils/localized_text.dart';
import '../../location/services/city_service.dart';

const Color _green = Color(0xFF4CAF50);
const Color _darkGreen = Color(0xFF2E7D32);
const Color _lightGreen = Color(0xFFE8F5E9);
const Color _bg = Color(0xFFF6F8FA);

class SurplusFormPage extends StatefulWidget {
  const SurplusFormPage({
    super.key,
    required this.ownerId,
    required this.ownerName,
    this.existing,
  });

  final String ownerId;
  final String ownerName;
  final MarketplaceSurplusModel? existing;

  @override
  State<SurplusFormPage> createState() => _SurplusFormPageState();
}

class _SurplusFormPageState extends State<SurplusFormPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _service = MarketplaceService();
  final _cloudinary = CloudinaryService();
  final _translationService = EquipmentTranslationService();

  int _step = 0;
  static const int _totalSteps = 8;

  // ── Categories ────────────────────────────────────────────────
  static const List<Map<String, String>> _categories = [
    {'emoji': '🌾', 'label': 'Grains'},
    {'emoji': '🥕', 'label': 'Vegetables'},
    {'emoji': '🍎', 'label': 'Fruits'},
    {'emoji': '🥥', 'label': 'Coconut'},
    {'emoji': '🌱', 'label': 'Seeds'},
    {'emoji': '🌿', 'label': 'Organic Products'},
    {'emoji': '🥛', 'label': 'Dairy Products'},
    {'emoji': '📦', 'label': 'Others'},
  ];

  static const List<String> _suggestedTags = [
    '🌾 Fresh Harvest', '🌱 Local', '🌿 Organic',
    '💧 Pure', '🚚 Delivery', '📦 Bulk',
  ];

  static const List<String> _units = ['Kg', 'Gram', 'Ton', 'Litre', 'Piece', 'Dozen', 'Bag'];
  static const List<String> _grades = ['Grade A (Premium)', 'Grade B (Standard)', 'Grade C (Fair)', 'Mixed Quality'];

  // ── Controllers ────────────────────────────────────────────────
  late TextEditingController _title, _description;
  late TextEditingController _quantity, _pricePerUnit;
  late TextEditingController _titleEn, _titleTa, _titleHi;
  late TextEditingController _descriptionEn, _descriptionTa, _descriptionHi;
  late TextEditingController _locationCtrl;

  String _inputLanguage = 'en';
  String _selectedCategoryEmoji = '🌾';
  String _selectedCategoryLabel = 'Grains';
  String _selectedUnit = 'Kg';
  String _selectedGrade = 'Grade A (Premium)';
  bool _isOrganic = false;
  DateTime? _harvestDate;

  String _status = 'published';
  String _location = '';
  double _lat = 0, _lng = 0;
  bool _deliveryAvailable = false;
  double _deliveryRadius = 10;

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
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _progressAnim = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut);

    _loadCities();
    final e = widget.existing;
    final titleMap = normalizeLocalizedField(e?.titleLocalized ?? {}, fallback: '');
    final descMap = normalizeLocalizedField(e?.descriptionLocalized ?? {}, fallback: '');

    _title = TextEditingController(text: titleMap['en'] ?? '');
    _description = TextEditingController(text: descMap['en'] ?? '');
    _quantity = TextEditingController(text: (e?.quantity ?? 0) > 0 ? e!.quantity.toStringAsFixed(e.quantity.truncateToDouble() == e.quantity ? 0 : 2) : '');
    _pricePerUnit = TextEditingController(text: (e?.pricePerUnit ?? 0) > 0 ? e!.pricePerUnit.toString() : '');
    _titleEn = TextEditingController(text: titleMap['en'] ?? '');
    _titleTa = TextEditingController(text: titleMap['ta'] ?? '');
    _titleHi = TextEditingController(text: titleMap['hi'] ?? '');
    _descriptionEn = TextEditingController(text: descMap['en'] ?? '');
    _descriptionTa = TextEditingController(text: descMap['ta'] ?? '');
    _descriptionHi = TextEditingController(text: descMap['hi'] ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');

    if (e != null) {
      _selectedCategoryLabel = e.categoryLocalized['en'] ?? 'Grains';
      final catMatch = _categories.firstWhere((c) => c['label'] == _selectedCategoryLabel, orElse: () => _categories.first);
      _selectedCategoryEmoji = catMatch['emoji']!;
      _selectedUnit = e.unit.isNotEmpty ? e.unit : 'Kg';
      _selectedGrade = e.qualityGrade.isNotEmpty ? e.qualityGrade : 'Grade A (Premium)';
      _isOrganic = e.isOrganic;
      _harvestDate = e.harvestDate;
      _location = e.location;
      _lat = e.latitude;
      _lng = e.longitude;
      _deliveryAvailable = e.deliveryAvailable;
      _deliveryRadius = e.deliveryRadius > 0 ? e.deliveryRadius : 10;
      _status = e.status.toLowerCase() == 'draft' ? 'draft' : 'published';
      _existingImages.addAll(e.imageUrls);
      _existingImagePublicIds.addAll(e.imagePublicIds);
      _tags.addAll(e.tags);
    }
    _updateProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_languageSyncedFromApp || widget.existing != null) return;
    final appLanguage = context.read<LocaleProvider>().languageCode;
    if (['ta', 'hi', 'en'].contains(appLanguage)) {
      _inputLanguage = appLanguage;
      _syncLocalizedControllersToCurrentInput();
    }
    _languageSyncedFromApp = true;
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    for (final c in [_title, _description, _quantity, _pricePerUnit, _titleEn, _titleTa, _titleHi, _descriptionEn, _descriptionTa, _descriptionHi, _locationCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateProgress() => _progressCtrl.animateTo((_step / (_totalSteps - 1)).clamp(0.0, 1.0));

  void _goToStep(int step) {
    setState(() => _step = step);
    _updateProgress();
  }

  Future<void> _loadCities() async {
    final cities = await CityService.getCities();
    if (mounted) setState(() { _cities = cities; _isLoadingCities = false; });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_step == _totalSteps) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text('Sell Surplus', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.w700)),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_step < _totalSteps - 1)
          TextButton(
            onPressed: _saving ? null : () => _save(isDraft: true),
            child: const Text('Save Draft', style: TextStyle(color: _darkGreen, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: AnimatedBuilder(
        animation: _progressAnim,
        builder: (context, _) => ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progressAnim.value,
            minHeight: 6,
            backgroundColor: _lightGreen,
            valueColor: const AlwaysStoppedAnimation<Color>(_green),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildStep0Category();
      case 1: return _buildStep1Details();
      case 2: return _buildStep2Pricing();
      case 3: return _buildStep3Quality();
      case 4: return _buildStep4Photos();
      case 5: return _buildStep5Location();
      case 6: return _buildStep6Delivery();
      case 7: return _buildStep7Preview();
      default: return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  UI Helpers
  // ─────────────────────────────────────────────────────────────
  Widget _stepHeader({required String emoji, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_darkGreen, _green], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
  );

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFEBEBEB)),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
  );

  // ─────────────────────────────────────────────────────────────
  //  STEP 0 – Category
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep0Category() {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📦', title: 'What are you selling?', subtitle: 'Select the category that best fits your surplus.'),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
            ),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = _selectedCategoryLabel == cat['label'];
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategoryLabel = cat['label']!;
                  _selectedCategoryEmoji = cat['emoji']!;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: sel ? _lightGreen : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? _green : const Color(0xFFEEEEEE), width: sel ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat['emoji']!, style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(cat['label']!, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w800 : FontWeight.w600, color: sel ? _darkGreen : const Color(0xFF555555))),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 1 – Details
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep1Details() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📝', title: 'Product Details', subtitle: 'Give your product a clear title and description.'),
          const SizedBox(height: 20),
          _fieldLabel('Product Title'),
          Container(
            decoration: _cardDecor(),
            child: TextField(
              controller: _title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(hintText: 'e.g. Fresh Basmati Rice, Organic Tomatoes', border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
              onChanged: (_) => _syncCurrentInputToLocalizedControllers(),
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel('Description'),
          Container(
            decoration: _cardDecor(),
            child: TextField(
              controller: _description,
              minLines: 4, maxLines: 6,
              decoration: const InputDecoration(hintText: 'Describe the quality, packaging, and any other details...', border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
              onChanged: (_) => _syncCurrentInputToLocalizedControllers(),
            ),
          ),
          const SizedBox(height: 20),
          _fieldLabel('Language Options'),
          const SizedBox(height: 8),
          Row(
            children: [
              _langChip('English', 'en'), const SizedBox(width: 8),
              _langChip('தமிழ்', 'ta'), const SizedBox(width: 8),
              _langChip('हिन्दी', 'hi'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _translating ? null : _generateTranslations,
              icon: _translating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(_translating ? 'Translating...' : '✨ Generate Translations'),
              style: ElevatedButton.styleFrom(backgroundColor: _darkGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 24),
          _fieldLabel('Tags (Max 20)'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ..._suggestedTags.map((t) {
                final added = _tags.contains(t);
                return GestureDetector(
                  onTap: () => setState(() => added ? _tags.remove(t) : (_tags.length < 20 ? _tags.add(t) : _showSnack('Max 20 tags'))),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: added ? _lightGreen : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: added ? _green : const Color(0xFFDDDDDD), width: added ? 1.5 : 1)),
                    child: Text(t, style: TextStyle(fontSize: 13, color: added ? _darkGreen : Colors.grey.shade700, fontWeight: added ? FontWeight.w600 : FontWeight.w400)),
                  ),
                );
              }),
              GestureDetector(
                onTap: _showAddCustomTagDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _green, width: 1.5)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16, color: _green), SizedBox(width: 4), Text('Add Custom Tag', style: TextStyle(fontSize: 13, color: _green, fontWeight: FontWeight.w600))]),
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
                backgroundColor: _lightGreen, deleteIconColor: _darkGreen, side: const BorderSide(color: _green),
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
        content: TextField(controller: tc, decoration: const InputDecoration(hintText: 'e.g. Bulk Discount', border: OutlineInputBorder()), autofocus: true, onSubmitted: (val) { _addCustomTag(val); Navigator.pop(ctx); }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { _addCustomTag(tc.text); Navigator.pop(ctx); }, child: const Text('Add')),
        ],
      ),
    );
  }

  void _addCustomTag(String raw) {
    final val = raw.trim();
    if (val.isEmpty) return;
    if (_tags.length >= 20) return _showSnack('Maximum 20 tags allowed');
    if (_tags.any((t) => t.toLowerCase() == val.toLowerCase())) return;
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
        decoration: BoxDecoration(color: isSelected ? _green : const Color(0xFFF4F4F4), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade700)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 2 – Quantity & Pricing
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep2Pricing() {
    final qty = double.tryParse(_quantity.text.trim()) ?? 0;
    final price = double.tryParse(_pricePerUnit.text.trim()) ?? 0;
    final total = qty * price;

    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '⚖️', title: 'Quantity & Price', subtitle: 'How much are you selling and for what price?'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Available Quantity'),
                    Container(
                      decoration: _cardDecor(),
                      child: TextField(
                        controller: _quantity,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(hintText: '0', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        onChanged: (_) => setState((){}),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Unit'),
                    Container(
                      decoration: _cardDecor(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUnit,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _fieldLabel('Price per $_selectedUnit'),
          Container(
            decoration: _cardDecor(),
            child: Row(
              children: [
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('₹', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _darkGreen))),
                Expanded(
                  child: TextField(
                    controller: _pricePerUnit,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(hintText: '0', border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16), suffix: Text('/ $_selectedUnit', style: TextStyle(fontSize: 16, color: Colors.grey.shade500))),
                    onChanged: (_) => setState((){}),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (total > 0)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(total),
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_darkGreen, _green], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('💰', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 10),
                        Text('Estimated Total Value', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('₹${_formatAmount(total)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('${_formatAmount(qty)} $_selectedUnit × ₹${_formatAmount(price)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 3 – Quality Info
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep3Quality() {
    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '✨', title: 'Quality Info', subtitle: 'Buyers pay more for high-quality, verified products.'),
          const SizedBox(height: 24),
          _fieldLabel('Quality Grade'),
          const SizedBox(height: 8),
          ..._grades.map((g) {
            final sel = _selectedGrade == g;
            return GestureDetector(
              onTap: () => setState(() => _selectedGrade = g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sel ? _lightGreen : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? _green : const Color(0xFFEBEBEB), width: sel ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: sel ? _green : Colors.grey),
                    const SizedBox(width: 12),
                    Text(g, style: TextStyle(fontSize: 15, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? _darkGreen : const Color(0xFF333333))),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          _fieldLabel('Is this an Organic Product?'),
          GestureDetector(
            onTap: () => setState(() => _isOrganic = !_isOrganic),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecor().copyWith(color: _isOrganic ? _lightGreen : Colors.white, border: Border.all(color: _isOrganic ? _green : const Color(0xFFEBEBEB))),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _isOrganic ? _green : Colors.grey.shade200, shape: BoxShape.circle),
                    child: Icon(Icons.eco_rounded, color: _isOrganic ? Colors.white : Colors.grey.shade500),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Certified Organic', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('Grown without synthetic chemicals', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOrganic,
                    onChanged: (v) => setState(() => _isOrganic = v),
                    activeColor: _green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _fieldLabel('Harvest / Manufacturing Date'),
          GestureDetector(
            onTap: _pickHarvestDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecor(),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: _green),
                  const SizedBox(width: 12),
                  Text(_harvestDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_harvestDate!), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _harvestDate == null ? Colors.grey : const Color(0xFF1A1A1A))),
                  const Spacer(),
                  if (_harvestDate != null) const Icon(Icons.check_circle_rounded, color: _green, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickHarvestDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: _harvestDate ?? now, firstDate: DateTime(now.year - 2), lastDate: now);
    if (d != null) setState(() => _harvestDate = d);
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 4 – Photos
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep4Photos() {
    final combinedItems = <Map<String, dynamic>>[];
    for (var i = 0; i < _existingImages.length; i++) combinedItems.add({'type': 'existing', 'url': _existingImages[i], 'id': _existingImagePublicIds[i]});
    for (var i = 0; i < _newImages.length; i++) combinedItems.add({'type': 'new', 'file': _newImages[i]});

    return SingleChildScrollView(
      key: const ValueKey('step4'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📸', title: 'Product Photos', subtitle: 'Clear photos build trust with buyers.'),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              if (combinedItems.length >= 10) return _showSnack('Max 10 images');
              _showPhotoSourceSheet();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _green.withValues(alpha: 0.4), width: 2)),
              child: Column(
                children: [
                  Container(width: 72, height: 72, decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.add_photo_alternate_rounded, size: 36, color: _green)),
                  const SizedBox(height: 16),
                  const Text('Tap to Add Photos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('At least 1 photo required (Max 10)', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
          ),
          if (combinedItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 16/9),
              itemCount: combinedItems.length,
              itemBuilder: (_, i) {
                final item = combinedItems[i];
                final isFirst = i == 0;
                final imgWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: item['type'] == 'existing' ? Image.network(item['url'], fit: BoxFit.cover, width: double.infinity, height: double.infinity) : Image.file(item['file'], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                );
                return LongPressDraggable<int>(
                  data: i,
                  feedback: Material(elevation: 8, borderRadius: BorderRadius.circular(14), child: SizedBox(width: 160, height: 90, child: Opacity(opacity: 0.8, child: imgWidget))),
                  childWhenDragging: Container(decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14))),
                  child: DragTarget<int>(
                    onAcceptWithDetails: (d) => _reorderImages(d.data, i, combinedItems),
                    builder: (ctx, cand, rej) => Stack(
                      fit: StackFit.expand,
                      children: [
                        imgWidget,
                        if (cand.isNotEmpty) Container(decoration: BoxDecoration(color: _green.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(14), border: Border.all(color: _green, width: 3))),
                        if (isFirst) Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(8)), child: const Text('COVER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
                        Positioned(top: 6, right: 6, child: GestureDetector(
                          onTap: () => setState(() {
                            if (item['type'] == 'existing') {
                              final idx = _existingImages.indexOf(item['url']);
                              _existingImages.removeAt(idx); _existingImagePublicIds.removeAt(idx);
                            } else {
                              _newImages.remove(item['file']);
                            }
                          }),
                          child: Container(width: 26, height: 26, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)),
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ]
        ],
      ),
    );
  }

  void _reorderImages(int oldIdx, int newIdx, List<Map<String, dynamic>> combined) {
    if (oldIdx == newIdx) return;
    setState(() {
      final item = combined.removeAt(oldIdx);
      combined.insert(newIdx, item);
      _existingImages.clear(); _existingImagePublicIds.clear(); _newImages.clear();
      for (final c in combined) {
        if (c['type'] == 'existing') { _existingImages.add(c['url']); _existingImagePublicIds.add(c['id']); }
        else { _newImages.add(c['file']); }
      }
    });
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(20), child: Text('Select Photo Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(leading: const Icon(Icons.camera_alt_rounded, color: _green), title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)), onTap: () { Navigator.pop(context); _pickAndCropImage(ImageSource.camera); }),
      ListTile(leading: const Icon(Icons.photo_library_rounded, color: _green), title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)), onTap: () { Navigator.pop(context); _pickAndCropImage(ImageSource.gallery); }),
    ])));
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Crop Photo', toolbarColor: _green, toolbarWidgetColor: Colors.white, lockAspectRatio: true),
        IOSUiSettings(title: 'Crop Photo', aspectRatioLockEnabled: true),
      ],
    );
    if (cropped != null) setState(() => _newImages.add(File(cropped.path)));
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 5 – Location
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep5Location() {
    return SingleChildScrollView(
      key: const ValueKey('step5'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📍', title: 'Location', subtitle: 'Where is this surplus located?'),
          const SizedBox(height: 24),
          _fieldLabel('City / Village / District'),
          Autocomplete<String>(
            optionsBuilder: (tv) => tv.text.isEmpty ? const Iterable<String>.empty() : _cities.where((c) => c.toLowerCase().contains(tv.text.toLowerCase())),
            onSelected: (sel) => setState(() => _location = sel),
            fieldViewBuilder: (ctx, ctrl, fn, _) {
              if (_locationCtrl.text.isEmpty && _location.isNotEmpty) ctrl.text = _location;
              _locationCtrl = ctrl;
              return Container(
                decoration: _cardDecor(),
                child: TextField(
                  controller: ctrl,
                  focusNode: fn,
                  decoration: const InputDecoration(hintText: 'Search location...', prefixIcon: Icon(Icons.search, color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.all(16)),
                  onChanged: (v) => setState(() => _location = v),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          if (_location.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(16), border: Border.all(color: _green)),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: _green),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Location selected: $_location', style: const TextStyle(fontWeight: FontWeight.w600, color: _darkGreen))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 6 – Delivery
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep6Delivery() {
    return SingleChildScrollView(
      key: const ValueKey('step6'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '🚚', title: 'Delivery Options', subtitle: 'Can you deliver, or is it pick-up only?'),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _deliveryAvailable = !_deliveryAvailable),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecor().copyWith(color: _deliveryAvailable ? _lightGreen : Colors.white, border: Border.all(color: _deliveryAvailable ? _green : const Color(0xFFEBEBEB))),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: _deliveryAvailable ? _green : Colors.grey.shade200, shape: BoxShape.circle),
                    child: Icon(Icons.local_shipping_rounded, color: _deliveryAvailable ? Colors.white : Colors.grey.shade500),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('I can deliver this', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Offer delivery to nearby buyers', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Switch(value: _deliveryAvailable, onChanged: (v) => setState(() => _deliveryAvailable = v), activeColor: _green),
                ],
              ),
            ),
          ),
          if (_deliveryAvailable) ...[
            const SizedBox(height: 24),
            _fieldLabel('Maximum Delivery Radius (Km)'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: _cardDecor(),
              child: Column(
                children: [
                  Text('${_deliveryRadius.toInt()} Km', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _darkGreen)),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(activeTrackColor: _green, thumbColor: _darkGreen, overlayColor: _green.withValues(alpha: 0.15)),
                    child: Slider(value: _deliveryRadius, min: 5, max: 100, divisions: 19, onChanged: (v) => setState(() => _deliveryRadius = v)),
                  ),
                  const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('5 Km', style: TextStyle(color: Colors.grey, fontSize: 12)), Text('100 Km', style: TextStyle(color: Colors.grey, fontSize: 12))]),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
              child: const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: Colors.deepOrange),
                  SizedBox(width: 12),
                  Expanded(child: Text('Buyers will have to come to your location to pick up the product.', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600, fontSize: 13))),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  STEP 7 – Preview
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep7Preview() {
    final qty = double.tryParse(_quantity.text.trim()) ?? 0;
    final price = double.tryParse(_pricePerUnit.text.trim()) ?? 0;
    final combined = [..._existingImages, ..._newImages];

    return SingleChildScrollView(
      key: const ValueKey('step7'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '👁️', title: 'Preview Listing', subtitle: 'This is how buyers will see your product.'),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)]),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (combined.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16/9,
                    child: combined.first is String ? Image.network(combined.first as String, fit: BoxFit.cover) : Image.file(combined.first as File, fit: BoxFit.cover),
                  )
                else
                  AspectRatio(aspectRatio: 16/9, child: Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)))),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(_title.text.isEmpty ? 'Product Title' : _title.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(10)), child: Text('₹${_formatAmount(price)} / $_selectedUnit', style: const TextStyle(color: _darkGreen, fontWeight: FontWeight.w800, fontSize: 15))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _previewChip(Icons.inventory_2_rounded, '${_formatAmount(qty)} $_selectedUnit available'),
                          _previewChip(Icons.category_rounded, _selectedCategoryLabel),
                          _previewChip(Icons.star_rounded, _selectedGrade),
                          if (_isOrganic) _previewChip(Icons.eco_rounded, 'Organic', color: Colors.green.shade700, bg: Colors.green.shade50),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(_location.isEmpty ? 'Location not set' : _location, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(_deliveryAvailable ? Icons.local_shipping_rounded : Icons.storefront_rounded, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(_deliveryAvailable ? 'Delivery up to ${_deliveryRadius.toInt()} Km' : 'Pick-up only', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _save(isDraft: false),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4),
              child: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('Publish Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewChip(IconData icon, String label, {Color? color, Color? bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg ?? Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? Colors.grey.shade800)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Validation & Save
  // ─────────────────────────────────────────────────────────────
  bool _validateCurrentStep() {
    if (_step == 1) {
      if (_title.text.trim().isEmpty) { _showSnack('Title is required'); return false; }
      if (_description.text.trim().isEmpty) { _showSnack('Description is required'); return false; }
    } else if (_step == 2) {
      final q = double.tryParse(_quantity.text.trim()) ?? 0;
      final p = double.tryParse(_pricePerUnit.text.trim()) ?? 0;
      if (q <= 0) { _showSnack('Quantity must be greater than 0'); return false; }
      if (p <= 0) { _showSnack('Price must be greater than 0'); return false; }
    } else if (_step == 4) {
      if (_existingImages.isEmpty && _newImages.isEmpty) { _showSnack('At least 1 photo is required'); return false; }
    } else if (_step == 5) {
      if (_location.trim().isEmpty) { _showSnack('Location is required'); return false; }
    }
    return true;
  }

  Future<void> _save({required bool isDraft}) async {
    if (!isDraft && !_validateCurrentStep()) return;
    setState(() => _saving = true);
    try {
      _syncCurrentInputToLocalizedControllers();
      final Map<String, String> finalTitle = {
        'en': _titleEn.text.trim().isNotEmpty ? _titleEn.text.trim() : _title.text.trim(),
        'ta': _titleTa.text.trim().isNotEmpty ? _titleTa.text.trim() : _title.text.trim(),
        'hi': _titleHi.text.trim().isNotEmpty ? _titleHi.text.trim() : _title.text.trim(),
      };
      final Map<String, String> finalDesc = {
        'en': _descriptionEn.text.trim().isNotEmpty ? _descriptionEn.text.trim() : _description.text.trim(),
        'ta': _descriptionTa.text.trim().isNotEmpty ? _descriptionTa.text.trim() : _description.text.trim(),
        'hi': _descriptionHi.text.trim().isNotEmpty ? _descriptionHi.text.trim() : _description.text.trim(),
      };
      final Map<String, String> finalCat = {
        'en': _selectedCategoryLabel,
        'ta': _selectedCategoryLabel,
        'hi': _selectedCategoryLabel,
      };

      final uploadedUrls = List<String>.from(_existingImages);
      final uploadedIds = List<String>.from(_existingImagePublicIds);
      for (final file in _newImages) {
        final res = await _cloudinary.uploadImageWithMetadata(file);
        uploadedUrls.add(res.secureUrl);
        uploadedIds.add(res.publicId);
      }

      final surplus = MarketplaceSurplusModel(
        surplusId: widget.existing?.surplusId ?? '',
        ownerId: widget.ownerId,
        ownerName: widget.ownerName,
        titleLocalized: finalTitle,
        categoryLocalized: finalCat,
        descriptionLocalized: finalDesc,
        pricePerUnit: double.tryParse(_pricePerUnit.text.trim()) ?? 0,
        quantity: double.tryParse(_quantity.text.trim()) ?? 0,
        unit: _selectedUnit,
        qualityGrade: _selectedGrade,
        isOrganic: _isOrganic,
        harvestDate: _harvestDate,
        location: _location,
        latitude: _lat,
        longitude: _lng,
        deliveryAvailable: _deliveryAvailable,
        deliveryRadius: _deliveryAvailable ? _deliveryRadius : 0,
        imageUrls: uploadedUrls,
        imagePublicIds: uploadedIds,
        tags: _tags,
        status: isDraft ? 'draft' : 'published',
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existing == null) {
        await _service.addSurplusRecord(surplus.toMap());
      } else {
        await _service.updateSurplus(surplusId: widget.existing!.surplusId, updates: surplus.toMap());
      }

      if (isDraft) {
        if (mounted) { _showSnack('Draft saved successfully'); Navigator.pop(context); }
      } else {
        setState(() => _step = _totalSteps);
      }
    } catch (e) {
      _showSnack('Error saving: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  Translations & Sync
  // ─────────────────────────────────────────────────────────────
  void _syncCurrentInputToLocalizedControllers() {
    switch (_inputLanguage) {
      case 'ta': _titleTa.text = _title.text; _descriptionTa.text = _description.text; break;
      case 'hi': _titleHi.text = _title.text; _descriptionHi.text = _description.text; break;
      case 'en': default: _titleEn.text = _title.text; _descriptionEn.text = _description.text; break;
    }
  }

  void _syncLocalizedControllersToCurrentInput() {
    switch (_inputLanguage) {
      case 'ta': _title.text = _titleTa.text; _description.text = _descriptionTa.text; break;
      case 'hi': _title.text = _titleHi.text; _description.text = _descriptionHi.text; break;
      case 'en': default: _title.text = _titleEn.text; _description.text = _descriptionEn.text; break;
    }
  }

  Future<void> _generateTranslations() async {
    _syncCurrentInputToLocalizedControllers();
    if (_titleEn.text.trim().isEmpty && _descriptionEn.text.trim().isEmpty) return;
    setState(() => _translating = true);
    try {
      final res = await _translationService.translateEquipmentFields(
        baseLanguage: 'en',
        title: _titleEn.text,
        description: _descriptionEn.text,
        category: _selectedCategoryLabel,
      );
      
      _titleTa.text = res['title']?['ta'] ?? '';
      _titleHi.text = res['title']?['hi'] ?? '';
      _descriptionTa.text = res['description']?['ta'] ?? '';
      _descriptionHi.text = res['description']?['hi'] ?? '';

      _syncLocalizedControllersToCurrentInput();
      _showSnack('Translations generated!');
    } catch (e) {
      _showSnack('Translation failed: $e');
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
      child: SafeArea(
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _goToStep(_step - 1),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: _green, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('Back', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            if (_step > 0) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _saving ? null : () {
                  if (_validateCurrentStep()) {
                    if (_step == _totalSteps - 1) _save(isDraft: false);
                    else _goToStep(_step + 1);
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: Text(_step == _totalSteps - 1 ? 'Publish Listing' : 'Next Step', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: _green,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 80)),
              const SizedBox(height: 32),
              const Text('Surplus Listed! 🎉', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const Text('Your product is now live on the marketplace\nand visible to buyers nearby.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _darkGreen, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Back to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final intAmt = amount.toInt();
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
}
