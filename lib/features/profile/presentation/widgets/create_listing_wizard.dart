import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../models/marketplace_equipment_model.dart';
import '../../../../../services/marketplace_service.dart';
import '../../../../../services/location_service.dart';

class CreateListingWizard extends StatefulWidget {
  const CreateListingWizard({
    super.key,
    required this.ownerId,
    required this.ownerName,
    required this.onPublished,
  });

  final String ownerId;
  final String ownerName;
  final VoidCallback onPublished;

  @override
  State<CreateListingWizard> createState() => _CreateListingWizardState();
}

class _CreateListingWizardState extends State<CreateListingWizard> {
  final MarketplaceService _service = MarketplaceService();
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Step 1: Category
  String _selectedCategory = 'Farm Equipment';
  final List<Map<String, String>> _categories = [
    {'emoji': '🚜', 'label': 'Farm Equipment'},
    {'emoji': '📚', 'label': 'Books'},
    {'emoji': '🏗️', 'label': 'Construction Equipment'},
    {'emoji': '🔌', 'label': 'Electronics (Future)'},
    {'emoji': '🎸', 'label': 'Musical Instruments (Future)'},
    {'emoji': '🛠️', 'label': 'Tools (Future)'},
  ];

  // Step 2: Images
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  String _imageQualityFeedback = '';

  // Step 3: Basic Details
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  String _selectedCondition = 'Good';
  final List<String> _conditions = ['Like New', 'Excellent', 'Good', 'Fair'];
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _yearCtrl = TextEditingController();
  final TextEditingController _specsCtrl = TextEditingController();
  String _duplicateFeedback = '';



  // Step 5: Availability
  DateTimeRange? _selectedDateRange;
  final TextEditingController _minPeriodCtrl = TextEditingController(text: '1');
  final TextEditingController _maxPeriodCtrl = TextEditingController(text: '30');
  String _fulfillmentType = 'Pickup'; // Pickup, Delivery, Both

  // Step 6: Location
  final TextEditingController _addressCtrl = TextEditingController();
  double _lat = 13.0827; // Default Chennai coordinates
  double _lng = 80.2707;
  bool _gpsSelected = false;

  String _detectedArea = '';
  String _detectedCity = '';
  String _detectedState = '';
  String _detectedCountry = '';
  double _locationAccuracy = 0;
  DateTime? _locationCapturedAt;
  bool _detectingLocation = false;
  String? _locationError;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _specsCtrl.dispose();
    _minPeriodCtrl.dispose();
    _maxPeriodCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // --- Step Helpers ---
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        if (_currentStep == 4) {
          _detectLocation();
        }
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
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
        _addressCtrl.text = [
          if (_detectedArea.isNotEmpty) _detectedArea,
          if (_detectedCity.isNotEmpty) _detectedCity,
          if (_detectedState.isNotEmpty) _detectedState,
        ].join(', ');
        _gpsSelected = true;
        _detectingLocation = false;
      });
    } else if (result is LocationFailure) {
      setState(() {
        _locationError = result.reason;
        _detectingLocation = false;
        _gpsSelected = false;
      });
    }
  }

  // --- Feature Emitters (Mock AI / Checks) ---
  void _runImageQualityChecker() {
    if (_selectedImages.isEmpty) return;
    setState(() {
      _imageQualityFeedback = 'Analyzing image quality...\n'
          '✅ Resolution: Excellent (1920x1080)\n'
          '✅ Lighting: Bright & Clear\n'
          '👉 Verdict: High-quality listing photos detected!';
    });
  }

  void _generateAIDescription() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title to generate a description.')),
      );
      return;
    }
    setState(() {
      _descriptionCtrl.text = 'This premium ${_brandCtrl.text.isNotEmpty ? _brandCtrl.text : ''} ${_titleCtrl.text.trim()} is available in ${_selectedCondition.toLowerCase()} condition. '
          'Perfect for community sharing and borrowing. '
          'It is well-maintained, reliable, and available immediately. '
          'Borrow this quality ${_selectedCategory.toLowerCase()} from a neighbor!';
    });
  }

  void _detectDuplicates() {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() {
      // Mock duplicate check
      if (_titleCtrl.text.toLowerCase().contains('tractor') || _titleCtrl.text.toLowerCase().contains('book')) {
        _duplicateFeedback = '⚠️ Potential duplicate listing detected with similar title in your inventory.';
      } else {
        _duplicateFeedback = '✅ Title is unique. No duplicate listings detected.';
      }
    });
  }



  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _selectedImages.add(picked);
          _imageQualityFeedback = '';
        });
        _runImageQualityChecker();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _selectDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() => _selectedDateRange = range);
    }
  }

  Future<void> _submitListing() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete step 3: Enter listing title')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // ── Location verification gate ────────────────────────────
    final locationResult =
        await LocationService.instance.getCurrentLocation();

    if (locationResult is LocationFailure) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showLocationRequiredDialog(locationResult);
      return;
    }

    // Location verified – use real coordinates
    final verifiedLocation =
        (locationResult as LocationSuccess).location;

    // ─────────────────────────────────────────────────────────

    try {
      final title = _titleCtrl.text.trim();
      final description = _descriptionCtrl.text.trim();
      final brand = _brandCtrl.text.trim();
      final model = _modelCtrl.text.trim();
      final condition = _selectedCondition;

      // We will generate a mock image URL or use a placeholder if none is chosen
      final List<String> imageUrls = _selectedImages.isNotEmpty
          ? ['https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80']
          : ['https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=400&q=80'];

      final newEquipment = MarketplaceEquipmentModel(
        equipmentId: '', // marketplace_service sets this
        ownerId: widget.ownerId,
        ownerName: widget.ownerName,
        equipmentName: title,
        category: _selectedCategory,
        description: description,
        titleLocalized: {'en': title, 'ta': title, 'hi': title},
        categoryLocalized: {'en': _selectedCategory, 'ta': _selectedCategory, 'hi': _selectedCategory},
        descriptionLocalized: {'en': description, 'ta': description, 'hi': description},
        pricePerHour: 0.0,
        pricePerDay: 0.0,
        location: _addressCtrl.text.isNotEmpty ? _addressCtrl.text : 'Chennai, India',
        latitude: verifiedLocation.latitude,
        longitude: verifiedLocation.longitude,
        area: _detectedArea.isNotEmpty ? _detectedArea : verifiedLocation.area ?? '',
        city: _detectedCity.isNotEmpty ? _detectedCity : verifiedLocation.city ?? '',
        state: _detectedState.isNotEmpty ? _detectedState : verifiedLocation.state ?? '',
        country: _detectedCountry.isNotEmpty ? _detectedCountry : verifiedLocation.country ?? '',
        locationAccuracy: _locationAccuracy > 0 ? _locationAccuracy : verifiedLocation.accuracy,
        locationCapturedAt: _locationCapturedAt ?? verifiedLocation.timestamp,
        imageUrls: imageUrls,
        availability: true,
        rating: 5.0,
        createdAt: DateTime.now(),
        machineSpecs: 'Condition: $condition, Brand: $brand, Model: $model',
        condition: condition,
        minRentalDuration: double.tryParse(_minPeriodCtrl.text) ?? 1.0,
        priceType: 'day',
        status: 'published',
        views: 0,
        savedBy: [],
        bookingsCount: 0,
      );

      await _service.addEquipment(newEquipment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Listing published successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        widget.onPublished();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Shows a blocking dialog when location verification fails.
  /// Gives the user options to enable location, retry, or cancel.
  Future<void> _showLocationRequiredDialog(LocationFailure failure) async {
    final isPermanent = failure.isPermanent;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.location_off_rounded,
            size: 48, color: Color(0xFFF57C00)),
        title: const Text(
          'Location Required',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Borrow needs your current location before publishing this listing so nearby people can discover it.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                failure.reason,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF795548)),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // Cancel – blocks publish
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),

          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (isPermanent) {
                await LocationService.instance.openAppPermissionSettings();
              } else if (failure.reason.contains('disabled') || failure.reason.contains('services')) {
                await LocationService.instance.openLocationSettings();
              } else {
                await _submitListing();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isPermanent || failure.reason.contains('disabled') || failure.reason.contains('services') ? 'Enable Location' : 'Retry'),
          ),
          if (isPermanent || failure.reason.contains('disabled') || failure.reason.contains('services'))
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _submitListing();
              },
              child: const Text('Retry', style: TextStyle(color: Color(0xFF2E7D32))),
            ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFFF8FAF8),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          title: Text(
            'Create Listing (Step ${_currentStep + 1} of $_totalSteps)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Linear Progress Indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF2E7D32),
              minHeight: 4,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(),
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepCategory();
      case 1:
        return _buildStepImages();
      case 2:
        return _buildStepDetails();
      case 3:
        return _buildStepAvailability();
      case 4:
        return _buildStepLocation();
      case 5:
        return _buildStepPreview();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 1: Category ---
  Widget _buildStepCategory() {
    return Column(
      key: const ValueKey('step_cat'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a Category',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the category that best fits your marketplace item.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, idx) {
            final cat = _categories[idx];
            final label = cat['label']!;
            final isSelected = label == _selectedCategory;
            return InkWell(
              onTap: () {
                setState(() => _selectedCategory = label);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFEBEFF0),
                    width: isSelected ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? const Color(0xFF2E7D32).withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cat['emoji']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- STEP 2: Images ---
  Widget _buildStepImages() {
    return Column(
      key: const ValueKey('step_img'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Images',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        Text(
          'Drag and drop or select images of your item. Add at least 1 high-resolution photo.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        // Drop area simulator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBEFF0), width: 2),
          ),
          child: Column(
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF2E7D32)),
              const SizedBox(height: 16),
              const Text(
                'Drag & Drop Images Here',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Supports PNG, JPG (Max 5MB)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Selected images horizontal list
        if (_selectedImages.isNotEmpty) ...[
          const Text(
            'Uploaded Images',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, idx) {
                final file = _selectedImages[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(file.path),
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(idx);
                              _imageQualityFeedback = '';
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        // Image Quality Checker section
        if (_imageQualityFeedback.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _imageQualityFeedback,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- STEP 3: Basic Details ---
  Widget _buildStepDetails() {
    return Column(
      key: const ValueKey('step_det'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 24),
        // Title Input + Duplicate Checker
        TextField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            labelText: 'Listing Title *',
            hintText: 'e.g. Organic Farming Guide Book, John Deere Tractor',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          onChanged: (_) {
            _detectDuplicates();
          },
        ),
        if (_duplicateFeedback.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _duplicateFeedback,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _duplicateFeedback.contains('⚠️') ? Colors.orange.shade800 : const Color(0xFF2E7D32),
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Brand, Model, Year, Specs row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _brandCtrl,
                decoration: InputDecoration(
                  labelText: 'Brand / Author',
                  hintText: 'e.g. John Deere',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _modelCtrl,
                decoration: InputDecoration(
                  labelText: 'Model / Edition',
                  hintText: 'e.g. 5050D',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _yearCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Purchase/Pub Year',
                  hintText: 'e.g. 2023',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Condition Dropdown
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                items: _conditions.map((String c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCondition = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Description
        TextField(
          controller: _descriptionCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Describe details, rental terms, book chapters, condition issues, etc.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF2E7D32),
                child: IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  onPressed: _generateAIDescription,
                  tooltip: 'Generate Description with AI',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Specifications
        TextField(
          controller: _specsCtrl,
          decoration: InputDecoration(
            labelText: 'Technical Specifications / Details',
            hintText: 'e.g. Horsepower, ISBN, pages count, fuel type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
      ],
    );
  }



  // --- STEP 5: Availability ---
  Widget _buildStepAvailability() {
    return Column(
      key: const ValueKey('step_av'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Availability Period',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 24),
        // Date range picker trigger
        InkWell(
          onTap: _selectDates,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBEFF0), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF2E7D32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Listing Availability Window',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDateRange != null
                            ? '${_selectedDateRange!.start.toString().split(' ')[0]} to ${_selectedDateRange!.end.toString().split(' ')[0]}'
                            : 'Click to select available dates',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Min / Max period
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPeriodCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Min Borrow Period (Days)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxPeriodCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Borrow Period (Days)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Fulfillment & Shipping',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        // Choice chips for fulfillment
        Wrap(
          spacing: 12,
          children: ['Pickup', 'Delivery', 'Both'].map((String type) {
            final isSelected = _fulfillmentType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _fulfillmentType = type);
              },
              selectedColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- STEP 6: Location ---
  Widget _buildStepLocation() {
    return Column(
      key: const ValueKey('step_loc'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Listing Location',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        Text(
          'We will automatically detect your location to recommend it to nearby borrowers.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        if (_detectingLocation)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 16),
                  Text(
                    'Detecting location automatically...',
                    style: TextStyle(color: Color(0xFF6F7A6B), fontWeight: FontWeight.w500),
                  ),
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
                    Text(
                      'Location Detection Failed',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _locationError!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF795548)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _detectLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_gpsSelected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBEFF0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 24),
                    SizedBox(width: 8),
                    Text(
                      '📍 Current Location',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2E7D32)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_detectedArea.isNotEmpty)
                  Text(
                    _detectedArea,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (_detectedCity.isNotEmpty) _detectedCity,
                    if (_detectedState.isNotEmpty) _detectedState,
                  ].join(', '),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Detected automatically',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6F7A6B), fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Accuracy: ${_locationAccuracy.toStringAsFixed(0)} m',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6F7A6B)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _detectLocation,
                      icon: const Icon(Icons.my_location, size: 14),
                      label: const Text('Refresh Location', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        foregroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
      ],
    );
  }

  // --- STEP 7: Preview & Publish ---
  Widget _buildStepPreview() {
    return Column(
      key: const ValueKey('step_prev'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview Listing',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 24),
        // Preview Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBEFF0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=400&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedCategory,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'New Listing Name',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _descriptionCtrl.text.isNotEmpty ? _descriptionCtrl.text : 'No description provided yet.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Free to Borrow',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _addressCtrl.text.isNotEmpty ? _addressCtrl.text : 'Chennai, India',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Bottom Nav Controls ---
  Widget _buildBottomNav() {
    final isLastStep = _currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  foregroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back'),
              )
            else
              const SizedBox.shrink(),

            // Next / Publish Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : (isLastStep ? _submitListing : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(isLastStep ? 'Publish' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }
}
