import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';

import '../../../models/farm_surplus_exchange_model.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/marketplace_service.dart';
import '../../location/services/city_service.dart';

const Color _green = Color(0xFF4CAF50);
const Color _darkGreen = Color(0xFF2E7D32);
const Color _lightGreen = Color(0xFFE8F5E9);
const Color _bg = Color(0xFFF6F8FA);

class FarmExchangeFormPage extends StatefulWidget {
  const FarmExchangeFormPage({
    super.key,
    required this.ownerId,
    required this.ownerName,
    this.existing,
  });

  final String ownerId;
  final String ownerName;
  final FarmSurplusExchangeModel? existing;

  @override
  State<FarmExchangeFormPage> createState() => _FarmExchangeFormPageState();
}

class _FarmExchangeFormPageState extends State<FarmExchangeFormPage> with TickerProviderStateMixin {
  final _service = MarketplaceService();
  final _cloudinary = CloudinaryService();

  int _step = 0;
  static const int _totalSteps = 10;

  // ── Data ────────────────────────────────────────────────
  static const List<Map<String, String>> _categories = [
    {'emoji': '🌱', 'label': 'Seeds'},
    {'emoji': '🌿', 'label': 'Fertilizers'},
    {'emoji': '🧪', 'label': 'Pesticides'},
    {'emoji': '🍃', 'label': 'Bio-Fertilizers'},
    {'emoji': '🌾', 'label': 'Organic Inputs'},
  ];

  static const List<String> _units = ['Kg', 'Bag', 'Packet', 'Bottle', 'Litre'];
  static const List<String> _reasons = ['Leftover Stock', 'Bought Extra', 'Season End', 'Unused Inventory', 'Project Completed'];
  static const List<Map<String, dynamic>> _conditions = [
    {'label': 'Unopened', 'color': Colors.green},
    {'label': 'Opened but Unused', 'color': Colors.amber},
    {'label': 'Partially Used', 'color': Colors.orange},
    {'label': 'Near Expiry', 'color': Colors.red},
  ];

  // ── Controllers ──────────────────────────────────────────
  late TextEditingController _productName, _brandName, _description;
  late TextEditingController _quantity, _price, _exchangeRequirement;
  late TextEditingController _locationCtrl;

  String _selectedCategoryLabel = 'Seeds';
  String _selectedCategoryEmoji = '🌱';
  String _selectedUnit = 'Kg';
  String _selectedReason = 'Leftover Stock';
  String _selectedCondition = 'Unopened';
  DateTime? _expiryDate;
  
  String _listingType = 'Sell Surplus'; // Sell Surplus, Exchange, Community Giveaway
  String _location = '';
  double _lat = 0, _lng = 0;
  
  bool _saving = false;
  List<String> _cities = [];
  
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
    _productName = TextEditingController(text: e?.productName ?? '');
    _brandName = TextEditingController(text: e?.brandName ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _quantity = TextEditingController(text: (e?.quantity ?? 0) > 0 ? e!.quantity.toStringAsFixed(e.quantity.truncateToDouble() == e.quantity ? 0 : 2) : '');
    _price = TextEditingController(text: (e?.price ?? 0) > 0 ? e!.price.toString() : '');
    _exchangeRequirement = TextEditingController(text: e?.exchangeRequirement ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');

    if (e != null) {
      _selectedCategoryLabel = e.category;
      final catMatch = _categories.firstWhere((c) => c['label'] == _selectedCategoryLabel, orElse: () => _categories.first);
      _selectedCategoryEmoji = catMatch['emoji']!;
      _selectedUnit = e.unitType.isNotEmpty ? e.unitType : 'Kg';
      _selectedReason = e.reasonForSurplus.isNotEmpty ? e.reasonForSurplus : 'Leftover Stock';
      _selectedCondition = e.condition.isNotEmpty ? e.condition : 'Unopened';
      _expiryDate = e.expiryDate;
      _listingType = e.listingType;
      _location = e.location;
      _lat = e.latitude;
      _lng = e.longitude;
      _existingImages.addAll(e.imageUrls);
      _existingImagePublicIds.addAll(e.imagePublicIds);
    }
    _updateProgress();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _productName.dispose(); _brandName.dispose(); _description.dispose();
    _quantity.dispose(); _price.dispose(); _exchangeRequirement.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _updateProgress() => _progressCtrl.animateTo((_step / (_totalSteps - 1)).clamp(0.0, 1.0));

  void _goToStep(int step) {
    setState(() => _step = step);
    _updateProgress();
  }

  Future<void> _loadCities() async {
    final cities = await CityService.getCities();
    if (mounted) setState(() { _cities = cities; });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  bool _isNearExpiry() {
    if (_expiryDate == null) return false;
    final diff = _expiryDate!.difference(DateTime.now()).inDays;
    return diff <= 30; // 30 Days threshold
  }

  void _checkExpiryLogic() {
    if (_isNearExpiry()) {
      setState(() {
        _listingType = 'Community Giveaway';
        _selectedCondition = 'Near Expiry';
      });
    } else {
      if (_listingType == 'Community Giveaway') setState(() => _listingType = 'Sell Surplus');
      if (_selectedCondition == 'Near Expiry') setState(() => _selectedCondition = 'Unopened');
    }
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
      title: const Text('🌱 Farm Surplus Exchange', style: TextStyle(color: _darkGreen, fontSize: 16, fontWeight: FontWeight.w800)),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
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
      case 2: return _buildStep2SurplusInfo();
      case 3: return _buildStep3Condition();
      case 4: return _buildStep4Expiry();
      case 5: return _buildStep5Photos();
      case 6: return _buildStep6Location();
      case 7: return _buildStep7ListingType();
      case 8: return _buildStep8Value();
      case 9: return _buildStep9Preview();
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
  );

  // ─────────────────────────────────────────────────────────────
  //  STEPS
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep0Category() {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📦', title: 'What are you sharing?', subtitle: 'Select the farm input you have in surplus. (No groceries allowed)'),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = _selectedCategoryLabel == cat['label'];
              return GestureDetector(
                onTap: () => setState(() { _selectedCategoryLabel = cat['label']!; _selectedCategoryEmoji = cat['emoji']!; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(color: sel ? _lightGreen : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? _green : const Color(0xFFEEEEEE), width: sel ? 2 : 1)),
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

  Widget _buildStep1Details() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📝', title: 'Product Details', subtitle: 'What exactly is the product?'),
          const SizedBox(height: 20),
          _fieldLabel('Product Name'),
          Container(decoration: _cardDecor(), child: TextField(controller: _productName, decoration: const InputDecoration(hintText: 'e.g. ADT-43 Paddy Seeds, Urea', border: InputBorder.none, contentPadding: EdgeInsets.all(16)))),
          const SizedBox(height: 20),
          _fieldLabel('Brand Name (Optional)'),
          Container(decoration: _cardDecor(), child: TextField(controller: _brandName, decoration: const InputDecoration(hintText: 'e.g. IFFCO, SPIC', border: InputBorder.none, contentPadding: EdgeInsets.all(16)))),
          const SizedBox(height: 20),
          _fieldLabel('Description'),
          Container(decoration: _cardDecor(), child: TextField(controller: _description, minLines: 3, maxLines: 5, decoration: const InputDecoration(hintText: 'Why are you sharing this? How old is it?', border: InputBorder.none, contentPadding: EdgeInsets.all(16)))),
        ],
      ),
    );
  }

  Widget _buildStep2SurplusInfo() {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '⚖️', title: 'Surplus Information', subtitle: 'How much do you have?'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fieldLabel('Available Quantity'),
                Container(decoration: _cardDecor(), child: TextField(controller: _quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700), decoration: const InputDecoration(hintText: '0', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
              ])),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _fieldLabel('Unit'),
                Container(decoration: _cardDecor(), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedUnit, isExpanded: true, items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(), onChanged: (v) => setState(() => _selectedUnit = v!)))),
              ])),
            ],
          ),
          const SizedBox(height: 24),
          _fieldLabel('Reason for Surplus'),
          Container(decoration: _cardDecor(), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedReason, isExpanded: true, items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(), onChanged: (v) => setState(() => _selectedReason = v!)))),
        ],
      ),
    );
  }

  Widget _buildStep3Condition() {
    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '🔍', title: 'Product Condition', subtitle: 'Be honest about the condition of the input.'),
          const SizedBox(height: 24),
          ..._conditions.map((c) {
            final sel = _selectedCondition == c['label'];
            final color = c['color'] as MaterialColor;
            return GestureDetector(
              onTap: () => setState(() => _selectedCondition = c['label']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: sel ? color.shade50 : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: sel ? color : const Color(0xFFEBEBEB), width: sel ? 2 : 1)),
                child: Row(
                  children: [
                    Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: sel ? color : Colors.grey),
                    const SizedBox(width: 16),
                    Text(c['label'], style: TextStyle(fontSize: 16, fontWeight: sel ? FontWeight.w800 : FontWeight.w600, color: sel ? color.shade800 : const Color(0xFF333333))),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep4Expiry() {
    final isNear = _isNearExpiry();
    return SingleChildScrollView(
      key: const ValueKey('step4'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '⏳', title: 'Expiry Date', subtitle: 'Chemical inputs degrade over time.'),
          const SizedBox(height: 24),
          _fieldLabel('Product Expiry Date'),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _expiryDate ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
              if (d != null) {
                setState(() => _expiryDate = d);
                _checkExpiryLogic();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16), decoration: _cardDecor(),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: _green), const SizedBox(width: 12),
                  Text(_expiryDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_expiryDate!), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _expiryDate == null ? Colors.grey : const Color(0xFF1A1A1A))),
                ],
              ),
            ),
          ),
          if (isNear) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade200, width: 2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 10), Text('Near Expiry', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))]),
                  const SizedBox(height: 12),
                  const Text('Because this item expires within 30 days, we are automatically converting this listing to a Community Giveaway to ensure it gets used instead of wasted.', style: TextStyle(color: Colors.red, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), child: const Text('🤝 Community Giveaway', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildStep5Photos() {
    final combined = <Map<String, dynamic>>[];
    for (var i = 0; i < _existingImages.length; i++) combined.add({'type': 'existing', 'url': _existingImages[i], 'id': _existingImagePublicIds[i]});
    for (var i = 0; i < _newImages.length; i++) combined.add({'type': 'new', 'file': _newImages[i]});

    return SingleChildScrollView(
      key: const ValueKey('step5'), padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📸', title: 'Product Photos', subtitle: 'Show the packaging and condition.'),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              if (combined.length >= 10) return _showSnack('Max 10 images');
              _pickAndCropImage(ImageSource.gallery);
            },
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _green.withValues(alpha: 0.4), width: 2)),
              child: Column(children: [
                Container(width: 72, height: 72, decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.add_photo_alternate_rounded, size: 36, color: _green)),
                const SizedBox(height: 16), const Text('Tap to Add Photos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
            ),
          ),
          if (combined.isNotEmpty) ...[
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 16/9),
              itemCount: combined.length,
              itemBuilder: (_, i) {
                final item = combined[i];
                final isFirst = i == 0;
                final imgWidget = ClipRRect(borderRadius: BorderRadius.circular(14), child: item['type'] == 'existing' ? Image.network(item['url'], fit: BoxFit.cover, width: double.infinity, height: double.infinity) : Image.file(item['file'], fit: BoxFit.cover, width: double.infinity, height: double.infinity));
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    imgWidget,
                    if (isFirst) Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(8)), child: const Text('COVER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
                    Positioned(top: 6, right: 6, child: GestureDetector(onTap: () => setState(() {
                      if (item['type'] == 'existing') { final idx = _existingImages.indexOf(item['url']); _existingImages.removeAt(idx); _existingImagePublicIds.removeAt(idx); }
                      else { _newImages.remove(item['file']); }
                    }), child: Container(width: 26, height: 26, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)))),
                  ],
                );
              },
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    final cropped = await ImageCropper().cropImage(sourcePath: picked.path, aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9), uiSettings: [AndroidUiSettings(toolbarTitle: 'Crop Photo', toolbarColor: _green, toolbarWidgetColor: Colors.white, lockAspectRatio: true)]);
    if (cropped != null) setState(() => _newImages.add(File(cropped.path)));
  }

  Widget _buildStep6Location() {
    return SingleChildScrollView(
      key: const ValueKey('step6'), padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📍', title: 'Location', subtitle: 'Where can farmers collect this?'),
          const SizedBox(height: 24),
          _fieldLabel('City / Village / District'),
          Autocomplete<String>(
            optionsBuilder: (tv) => tv.text.isEmpty ? const Iterable<String>.empty() : _cities.where((c) => c.toLowerCase().contains(tv.text.toLowerCase())),
            onSelected: (sel) => setState(() => _location = sel),
            fieldViewBuilder: (ctx, ctrl, fn, _) {
              if (_locationCtrl.text.isEmpty && _location.isNotEmpty) ctrl.text = _location;
              _locationCtrl = ctrl;
              return Container(decoration: _cardDecor(), child: TextField(controller: ctrl, focusNode: fn, decoration: const InputDecoration(hintText: 'Search location...', prefixIcon: Icon(Icons.search, color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.all(16)), onChanged: (v) => setState(() => _location = v)));
            },
          ),
          const SizedBox(height: 24),
          if (_location.isNotEmpty)
            Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16), border: Border.all(color: _green, width: 2)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.map, size: 64, color: Colors.white),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 40),
                      const SizedBox(height: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)), child: Text('Mini Map Preview:\n$_location', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12))),
                    ],
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep7ListingType() {
    if (_isNearExpiry()) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: _green, size: 64), const SizedBox(height: 16), const Text('Auto-Configured', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Because this is near expiry, it has been set as a Community Giveaway.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)), const SizedBox(height: 24), ElevatedButton(onPressed: () => _goToStep(_step + 1), style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white), child: const Text('Continue'))])));
    }

    return SingleChildScrollView(
      key: const ValueKey('step7'), padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '📋', title: 'Listing Type', subtitle: 'Are you selling this or exchanging it?'),
          const SizedBox(height: 24),
          _typeCard('Sell Surplus', '💰', 'Sell it for a discounted price.', 'Sell Surplus'),
          const SizedBox(height: 12),
          _typeCard('Exchange', '♻', 'Trade it for another farm input you need.', 'Exchange'),
        ],
      ),
    );
  }

  Widget _typeCard(String title, String emoji, String subtitle, String value) {
    final sel = _listingType == value;
    return GestureDetector(
      onTap: () => setState(() => _listingType = value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: sel ? _lightGreen : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: sel ? _green : const Color(0xFFEBEBEB), width: sel ? 2 : 1)),
        child: Row(children: [Text(emoji, style: const TextStyle(fontSize: 28)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: sel ? _darkGreen : Colors.black87)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))])), Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: sel ? _green : Colors.grey)]),
      ),
    );
  }

  Widget _buildStep8Value() {
    if (_listingType == 'Community Giveaway') {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('🤝', style: TextStyle(fontSize: 64)), const SizedBox(height: 16), const Text('Free Giveaway', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('You are awesome! This will be listed for free.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)), const SizedBox(height: 24), ElevatedButton(onPressed: () => _goToStep(_step + 1), style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white), child: const Text('See Preview'))])));
    }

    return SingleChildScrollView(
      key: const ValueKey('step8'), padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: _listingType == 'Sell Surplus' ? '💰' : '♻', title: _listingType == 'Sell Surplus' ? 'Price' : 'Exchange Details', subtitle: _listingType == 'Sell Surplus' ? 'Set a fair price for your surplus.' : 'What do you need in return?'),
          const SizedBox(height: 24),
          if (_listingType == 'Sell Surplus') ...[
            _fieldLabel('Total Price (₹)'),
            Container(decoration: _cardDecor(), child: TextField(controller: _price, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), decoration: const InputDecoration(prefixText: '₹ ', border: InputBorder.none, contentPadding: EdgeInsets.all(16)))),
          ] else ...[
            _fieldLabel('What do you need in exchange?'),
            Container(decoration: _cardDecor(), child: TextField(controller: _exchangeRequirement, minLines: 3, maxLines: 5, decoration: const InputDecoration(hintText: 'e.g. Need DAP fertilizer in exchange.', border: InputBorder.none, contentPadding: EdgeInsets.all(16)))),
          ]
        ],
      ),
    );
  }

  Widget _buildStep9Preview() {
    final qty = double.tryParse(_quantity.text.trim()) ?? 0;
    final combined = [..._existingImages, ..._newImages];

    return SingleChildScrollView(
      key: const ValueKey('step9'), padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(emoji: '👁️', title: 'Listing Preview', subtitle: 'Verify everything before publishing.'),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)]),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (combined.isNotEmpty) AspectRatio(aspectRatio: 16/9, child: combined.first is String ? Image.network(combined.first as String, fit: BoxFit.cover) : Image.file(combined.first as File, fit: BoxFit.cover))
                else AspectRatio(aspectRatio: 16/9, child: Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)))),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_listingType == 'Community Giveaway') Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)), child: const Row(children: [Text('🤝', style: TextStyle(fontSize: 12)), SizedBox(width: 4), Text('Community Giveaway', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11))]))
                          else Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)), child: Row(children: [const Text('♻', style: TextStyle(fontSize: 12)), const SizedBox(width: 4), Text(_listingType, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11))])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Text(_productName.text.isEmpty ? 'Product Name' : _productName.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                          if (_listingType == 'Sell Surplus') Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(10)), child: Text('₹${_price.text}', style: const TextStyle(color: _darkGreen, fontWeight: FontWeight.w800, fontSize: 15)))
                          else if (_listingType == 'Community Giveaway') Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: const Text('FREE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _previewChip(Icons.inventory_2_rounded, '${qty.toStringAsFixed(1)} $_selectedUnit'),
                          _previewChip(Icons.category_rounded, _selectedCategoryLabel),
                          _previewChip(Icons.info_outline_rounded, _selectedCondition),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(children: [const Icon(Icons.location_on_rounded, color: Colors.grey, size: 20), const SizedBox(width: 8), Text(_location.isEmpty ? 'Location not set' : _location, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600))]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Waste Saved Counter
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [_darkGreen, _green]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Row(
              children: [
                const Text('🌍', style: TextStyle(fontSize: 32)), const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Community Impact', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('You are preventing ${qty.toStringAsFixed(1)} $_selectedUnit of agricultural inputs from being wasted.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4))])),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _save, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('Publish Exchange', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _previewChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: Colors.grey.shade700), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800))]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SAVE
  // ─────────────────────────────────────────────────────────────
  bool _validateCurrentStep() {
    if (_step == 1) {
      if (_productName.text.trim().isEmpty) { _showSnack('Product Name required'); return false; }
    } else if (_step == 2) {
      final q = double.tryParse(_quantity.text.trim()) ?? 0;
      if (q <= 0) { _showSnack('Quantity must be greater than 0'); return false; }
    } else if (_step == 4) {
      if (_expiryDate == null) { _showSnack('Expiry Date required'); return false; }
    } else if (_step == 5) {
      if (_existingImages.isEmpty && _newImages.isEmpty) { _showSnack('At least 1 photo required'); return false; }
    } else if (_step == 6) {
      if (_location.trim().isEmpty) { _showSnack('Location required'); return false; }
    } else if (_step == 8) {
      if (_listingType == 'Sell Surplus') {
        final p = double.tryParse(_price.text.trim()) ?? 0;
        if (p <= 0) { _showSnack('Price must be greater than 0'); return false; }
      } else if (_listingType == 'Exchange') {
        if (_exchangeRequirement.text.trim().isEmpty) { _showSnack('Exchange requirement needed'); return false; }
      }
    }
    return true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final uploadedUrls = List<String>.from(_existingImages);
      final uploadedIds = List<String>.from(_existingImagePublicIds);
      for (final file in _newImages) {
        final res = await _cloudinary.uploadImageWithMetadata(file);
        uploadedUrls.add(res.secureUrl);
        uploadedIds.add(res.publicId);
      }

      final model = FarmSurplusExchangeModel(
        exchangeId: widget.existing?.exchangeId ?? '',
        ownerId: widget.ownerId,
        ownerName: widget.ownerName,
        productName: _productName.text.trim(),
        brandName: _brandName.text.trim(),
        description: _description.text.trim(),
        category: _selectedCategoryLabel,
        quantity: double.tryParse(_quantity.text.trim()) ?? 0,
        unitType: _selectedUnit,
        reasonForSurplus: _selectedReason,
        condition: _selectedCondition,
        expiryDate: _expiryDate,
        listingType: _listingType,
        price: double.tryParse(_price.text.trim()) ?? 0,
        exchangeRequirement: _exchangeRequirement.text.trim(),
        location: _location,
        latitude: _lat,
        longitude: _lng,
        imageUrls: uploadedUrls,
        imagePublicIds: uploadedIds,
        status: 'published',
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existing == null) {
        await _service.addExchangeRecord(model.toMap());
      } else {
        await _service.updateExchange(exchangeId: widget.existing!.exchangeId, updates: model.toMap());
      }
      if (mounted) setState(() => _step = _totalSteps);
    } catch (e) {
      _showSnack('Error saving: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
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
                  onPressed: _saving ? null : () {
                    if (_step == 8 && _isNearExpiry()) _goToStep(6);
                    else _goToStep(_step - 1);
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: _green, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('Back', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            if (_step > 0) const SizedBox(width: 16),
            if (_step < _totalSteps - 1)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saving ? null : () {
                    if (_validateCurrentStep()) {
                      if (_step == 6 && _isNearExpiry()) _goToStep(8);
                      else _goToStep(_step + 1);
                    }
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: const Text('Next Step', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.energy_savings_leaf_rounded, color: Colors.white, size: 80)),
              const SizedBox(height: 32),
              const Text('Waste Prevented! 🌱', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const Text('Thank you for sharing your surplus.\nYou are making farming more sustainable.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
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
}
