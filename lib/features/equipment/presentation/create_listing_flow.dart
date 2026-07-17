import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intl/intl.dart';

import '../../../models/app_user_model.dart';
import '../../../models/marketplace_equipment_model.dart';
import '../../../services/marketplace_service.dart';
import '../../../services/location_service.dart';
import '../../../services/logger_service.dart';
import 'package:geolocator/geolocator.dart';

import 'widgets/borrow_image_picker.dart';
import 'widgets/listing_draft_manager.dart';
import '../../../services/cloudinary_service.dart';
import 'package:UzhavuSei/theme/app_theme.dart';

// ── SHARED DESIGN TOKENS ─────────────────────────────────────────────────────

const _kGreen = Color(0xFF2563EB);        // AppColors.primary
const _kGreenLight = Color(0xFFDBEAFE);   // AppColors.primaryContainer
const _kBg = Color(0xFFF8FAFC);           // AppColors.background
const _kCardBorder = Color(0xFFE2E8F0);   // AppColors.border
const _kFieldFill = Color(0xFFF8FAFC);    // AppColors.fieldFill
const _kFieldBorder = Color(0xFFE2E8F0);  // AppColors.border
const _kTextPrimary = Color(0xFF0F172A);  // AppColors.textPrimary
const _kTextSecondary = Color(0xFF64748B);// AppColors.textSecondary

// ── CATEGORY SELECTION PAGE ──────────────────────────────────────────────────

class _CategoryMeta {
  final String emoji;
  final String label;
  final String subtitle;
  final String keywords;
  final Widget Function(BuildContext, AppUserModel) formBuilder;

  const _CategoryMeta({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.keywords,
    required this.formBuilder,
  });
}

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({super.key, required this.currentUser});
  final AppUserModel currentUser;

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late final List<_CategoryMeta> _categories;

  @override
  void initState() {
    super.initState();
    _categories = [
      _CategoryMeta(
        emoji: '📚',
        label: 'Books',
        subtitle: 'Textbooks, novels, references',
        keywords:
            'books novels academic reference engineering exam school library textbook study',
        formBuilder: (ctx, user) => BookListingFormPage(currentUser: user),
      ),
      _CategoryMeta(
        emoji: '🚜',
        label: 'Farm Equipment',
        subtitle: 'Tractors, sprayers, cultivators',
        keywords:
            'farm equipment tractor rotavator sprayer seeder cultivator harvester agriculture crop machinery tool',
        formBuilder: (ctx, user) => FarmEquipmentFormPage(currentUser: user),
      ),
      _CategoryMeta(
        emoji: '🏗️',
        label: 'Construction Equipment',
        subtitle: 'Drills, mixers, power tools',
        keywords:
            'construction tools equipment drill machine ladder concrete mixer power tools safety helmet saw',
        formBuilder: (ctx, user) =>
            ConstructionEquipmentFormPage(currentUser: user),
      ),
    ];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_CategoryMeta> get _filtered {
    if (_searchQuery.trim().isEmpty) return _categories;
    final q = _searchQuery.toLowerCase().trim();
    return _categories
        .where((c) =>
            c.label.toLowerCase().contains(q) ||
            c.keywords.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Share an Item',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _kTextPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What do you want\nto share today?',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary,
                      height: 1.2),
                ),
                const SizedBox(height: 6),
                Text('Choose a category to create your listing.',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 20),
                _buildSearchBar(),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No categories found.',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _kTextPrimary)),
                        const SizedBox(height: 4),
                        Text('Try another keyword.',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                else ...[
                  Text('All Categories',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  LayoutBuilder(builder: (ctx, constraints) {
                    final isTablet = constraints.maxWidth > 600;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isTablet ? 3 : 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.35,
                      ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => _buildCard(items[i]),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
          color: _kFieldFill, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search categories...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: Icon(Icons.close, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(_CategoryMeta cat) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) =>
                  cat.formBuilder(ctx, widget.currentUser))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kCardBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 32)),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: _kGreenLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: _kGreen),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _kTextPrimary)),
                const SizedBox(height: 2),
                Text(cat.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── SHARED UI HELPERS (Mixin) ─────────────────────────────────────────────────

mixin _ListingFormUiMixin<T extends StatefulWidget> on State<T> {
  // Subclasses must implement these:
  List<BorrowImageItem> get pickerImages;
  String get conditionValue;
  bool get availabilityValue;
  void setAvailability(bool val);

  Widget buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: _kGreenLight,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: _kGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _kTextPrimary)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget buildOptionalExpandable({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: _kFieldFill,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.tune_rounded,
                color: _kTextSecondary, size: 20),
          ),
          title: const Text('Advanced Details',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _kTextPrimary)),
          subtitle: Text('Optional but helpful',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          iconColor: _kGreen,
          collapsedIconColor: Colors.grey.shade500,
          children: children,
        ),
      ),
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController ctrl, {
    bool isNumeric = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? hint,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumeric
          ? TextInputType.number
          : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: _kGreen, size: 20)
            : null,
        filled: true,
        fillColor: _kFieldFill,
        contentPadding: EdgeInsets.symmetric(
            horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kFieldBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: _kGreen, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Colors.red, width: 1.5)),
      ),
    );
  }

  Widget buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _kFieldFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kFieldBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: _kGreen, width: 1.5)),
      ),
      items: items
          .map((item) =>
              DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget buildConditionChips(
    List<String> conditions,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Condition *',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: conditions.map((c) {
            final selected = conditionValue == c;
            return GestureDetector(
              onTap: () => onChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _kGreen : _kFieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? _kGreen : _kFieldBorder),
                ),
                child: Text(c,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : _kTextPrimary)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget buildDateTile(
      String label, DateTime? date, VoidCallback onTap) {
    final hasDate = date != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasDate ? _kGreenLight : _kFieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: hasDate ? _kGreen : _kFieldBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 20,
                color:
                    hasDate ? _kGreen : Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text(
                    hasDate
                        ? DateFormat('MMMM d, yyyy').format(date)
                        : 'Tap to select',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasDate
                            ? _kTextPrimary
                            : Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget buildAvailabilityToggle(ValueChanged<bool> onChanged) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: availabilityValue ? _kGreenLight : _kFieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                availabilityValue ? _kGreen : _kFieldBorder),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Text('Available for Borrowing',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          availabilityValue
              ? 'Visible to the community'
              : 'Hidden from search',
          style: TextStyle(
              fontSize: 12, color: Colors.grey.shade600),
        ),
        activeThumbColor: _kGreen,
        activeTrackColor: _kGreenLight,
        value: availabilityValue,
        onChanged: onChanged,
      ),
    );
  }

  Widget buildStepHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget buildCompactStepIndicator(
      int activeStep, List<String> steps) {
    final progress = (activeStep + 1) / steps.length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(steps[activeStep],
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _kTextPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _kGreenLight,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Step ${activeStep + 1} of ${steps.length}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _kGreen)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_kGreen),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.asMap().entries.map((e) {
              final isCompleted = e.key < activeStep;
              final isActive = e.key == activeStep;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : (isActive
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked),
                    size: 12,
                    color: (isCompleted || isActive)
                        ? _kGreen
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 3),
                  Text(e.value,
                      style: TextStyle(
                          fontSize: 10,
                          color: (isCompleted || isActive)
                              ? _kGreen
                              : Colors.grey.shade400,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildImageHeroSection(
    List<BorrowImageItem> images,
    ValueChanged<List<BorrowImageItem>> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: images.isNotEmpty ? _kGreen : _kCardBorder,
          width: images.isNotEmpty ? 1.5 : 1.0,
        ),
      ),
      child: BorrowImagePicker(
        initialImages: images,
        onImagesChanged: onChanged,
      ),
    );
  }

  Widget buildPreviewCard({
    required String title,
    required String category,
    required String condition,
    required List<BorrowImageItem> images,
  }) {
    final hasImage = images.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: _kGreen),
              SizedBox(width: 6),
              Text('Live Preview',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _kGreen)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: _kFieldFill,
                    borderRadius: BorderRadius.circular(12)),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: images.first.isLocal
                            ? Image.file(images.first.localFile!,
                                fit: BoxFit.cover)
                            : Image.network(images.first.remoteUrl!,
                                fit: BoxFit.cover),
                      )
                    : const Icon(Icons.image_outlined,
                        color: _kTextSecondary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Your listing title…' : title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: title.isEmpty
                              ? Colors.grey.shade400
                              : _kTextPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _previewChip(category, Colors.blue),
                        _previewChip(condition, _kGreen),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text('Auto from GPS',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewChip(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget buildGpsDisabledBanner(
      bool visible, VoidCallback onEnable) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFECB3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.location_off_rounded,
                color: Colors.amber, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'GPS is still disabled. Enable location to publish.',
              style: TextStyle(
                  color: Color(0xFF7B6100),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onEnable,
            style: TextButton.styleFrom(
                foregroundColor: _kGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(50, 30),
                tapTargetSize:
                    MaterialTapTargetSize.shrinkWrap),
            child: const Text('Enable',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget buildSubmittingView(
      String status, double progress) {
    return Container(
      color: _kBg,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: _kGreenLight,
                    borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.cloud_upload_rounded,
                    color: _kGreen, size: 36),
              ),
              const SizedBox(height: 24),
              Text(status,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kTextPrimary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('${(progress * 100).toInt()}% complete',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_kGreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStickyActionBar({
    required BuildContext ctx,
    required int activeStep,
    required int totalSteps,
    required VoidCallback onBack,
    required VoidCallback onNext,
  }) {
    final isLast = activeStep == totalSteps - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(ctx).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          if (activeStep > 0) ...[
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: _kGreen,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(0, 52),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLast) ...[
                    const Icon(Icons.rocket_launch_rounded,
                        size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(isLast ? 'Publish Listing' : 'Continue',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  if (!isLast) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 18),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BOOK LISTING FORM ─────────────────────────────────────────────────────────

class BookListingFormPage extends StatefulWidget {
  const BookListingFormPage(
      {super.key, required this.currentUser, this.existing});
  final AppUserModel currentUser;
  final MarketplaceEquipmentModel? existing;

  @override
  State<BookListingFormPage> createState() =>
      _BookListingFormPageState();
}

class _BookListingFormPageState extends State<BookListingFormPage>
    with WidgetsBindingObserver, _ListingFormUiMixin {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceService _service = MarketplaceService();
  // ignore: unused_field
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _languageCtrl;
  late TextEditingController _publisherCtrl;
  late TextEditingController _pubYearCtrl;
  late TextEditingController _editionCtrl;
  late TextEditingController _isbnCtrl;
  late TextEditingController _pagesCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _qtyCtrl;

  int _activeStep = 0;
  String _genre = 'Academic';
  String _condition = 'Good';
  bool _availability = true;
  bool _submitting = false;
  final List<BorrowImageItem> _pickerImages = [];
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  bool _waitingForGps = false;
  bool _gpsDisabledBannerVisible = false;

  DateTime? _availableFrom;
  DateTime? _availableUntil;
  bool _loadingDraft = false;

  static const _steps = ['Photos', 'Book Details', 'Availability'];

  // Mixin interface
  @override
  List<BorrowImageItem> get pickerImages => _pickerImages;
  @override
  String get conditionValue => _condition;
  @override
  bool get availabilityValue => _availability;
  @override
  void setAvailability(bool val) => setState(() => _availability = val);

  // ── BUSINESS LOGIC (UNCHANGED) ──────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _titleCtrl = TextEditingController();
    _authorCtrl = TextEditingController();
    _languageCtrl = TextEditingController(text: 'English');
    _publisherCtrl = TextEditingController();
    _pubYearCtrl = TextEditingController();
    _editionCtrl = TextEditingController();
    _isbnCtrl = TextEditingController();
    _pagesCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _qtyCtrl = TextEditingController(text: '1');

    if (widget.existing != null) {
      final specsStr = widget.existing!.machineSpecs;
      _titleCtrl.text = widget.existing!.equipmentName;
      _authorCtrl.text = _parseSpec(specsStr, 'Author: ');
      _languageCtrl.text =
          _parseSpec(specsStr, 'Language: ', defaultValue: 'English');
      _publisherCtrl.text = _parseSpec(specsStr, 'Publisher: ');
      _pubYearCtrl.text = _parseSpec(specsStr, 'Year: ');
      _editionCtrl.text = _parseSpec(specsStr, 'Edition: ');
      _isbnCtrl.text = _parseSpec(specsStr, 'ISBN: ');
      _genre =
          _parseSpec(specsStr, 'Genre: ', defaultValue: 'Academic');
      _pagesCtrl.text = _parseSpec(specsStr, 'Pages: ');
      _condition = widget.existing!.condition;
      _descCtrl.text = widget.existing!.description;
      _qtyCtrl.text =
          widget.existing!.minRentalDuration.toInt().toString();
      _availability = widget.existing!.availability;
      _availableFrom = widget.existing!.availabilityFrom;
      _availableUntil = widget.existing!.availabilityTo;
      _pickerImages.addAll(widget.existing!.imageUrls
          .map((u) => BorrowImageItem(remoteUrl: u)));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadDraft();
      });
    }

    _titleCtrl.addListener(_saveDraft);
    _authorCtrl.addListener(_saveDraft);
    _languageCtrl.addListener(_saveDraft);
    _publisherCtrl.addListener(_saveDraft);
    _pubYearCtrl.addListener(_saveDraft);
    _editionCtrl.addListener(_saveDraft);
    _isbnCtrl.addListener(_saveDraft);
    _pagesCtrl.addListener(_saveDraft);
    _descCtrl.addListener(_saveDraft);
    _qtyCtrl.addListener(_saveDraft);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _languageCtrl.dispose();
    _publisherCtrl.dispose();
    _pubYearCtrl.dispose();
    _editionCtrl.dispose();
    _isbnCtrl.dispose();
    _pagesCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  String _parseSpec(String specs, String prefix,
      {String defaultValue = ''}) {
    if (specs.isEmpty) return defaultValue;
    try {
      final parts = specs.split(', ');
      final found =
          parts.firstWhere((p) => p.startsWith(prefix), orElse: () => '');
      if (found.isNotEmpty) return found.replaceAll(prefix, '');
    } catch (_) {}
    return defaultValue;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForGps) {
      _checkGpsAndContinuePublishing();
    }
  }

  Future<void> _checkGpsAndContinuePublishing() async {
    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
      _gpsDisabledBannerVisible = false;
    });
    final isGpsEnabled =
        await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() {
        _submitting = false;
        _waitingForGps = false;
        _gpsDisabledBannerVisible = true;
      });
      return;
    }
    _waitingForGps = false;
    _continuePublishingWithLocation();
  }

  Future<void> _continuePublishingWithLocation() async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Getting your location...';
      _uploadProgress = 0.0;
    });
    try {
      final locResult =
          await LocationService.instance.getCurrentLocation();
      if (locResult is LocationFailure) {
        setState(() => _submitting = false);
        if (locResult.isPermanent) {
          _showErrorBottomSheet(
              title: 'Permission Required',
              message:
                  'Borrow needs location permissions. Please enable them in your app settings to proceed.',
              actionLabel: 'Open Settings',
              onAction: () => Geolocator.openAppSettings());
        } else {
          _showErrorBottomSheet(
              title: 'Location Error',
              message: locResult.reason,
              actionLabel: 'Retry',
              onAction: () => _continuePublishingWithLocation());
        }
        return;
      }
      final loc = (locResult as LocationSuccess).location;
      await _publishWithLocation(loc);
    } catch (e) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
          title: 'Publish Failed',
          message:
              'Something went wrong while getting your location: $e',
          actionLabel: 'Retry',
          onAction: () => _continuePublishingWithLocation());
    }
  }

  Future<void> _publishWithLocation(VerifiedLocation loc) async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Publishing Listing...';
      _uploadProgress = 0.0;
    });
    try {
      final List<String> finalUrls = [];
      final CloudinaryService cloudinary = CloudinaryService();
      for (var i = 0; i < _pickerImages.length; i++) {
        final img = _pickerImages[i];
        setState(() {
          _uploadStatus = 'Publishing Listing...';
          _uploadProgress = (i / _pickerImages.length);
        });
        if (img.isLocal) {
          final secureUrl =
              await cloudinary.uploadImage(img.localFile!);
          finalUrls.add(secureUrl);
        } else {
          finalUrls.add(img.remoteUrl!);
        }
      }
      setState(() {
        _uploadStatus = 'Publishing Listing...';
        _uploadProgress = 1.0;
      });
      final specs =
          'Author: ${_authorCtrl.text.trim()}, Language: ${_languageCtrl.text.trim()}, Publisher: ${_publisherCtrl.text.trim()}, Year: ${_pubYearCtrl.text.trim()}, Edition: ${_editionCtrl.text.trim()}, ISBN: ${_isbnCtrl.text.trim()}, Genre: $_genre, Pages: ${_pagesCtrl.text.trim()}';
      final model = MarketplaceEquipmentModel(
        equipmentId: widget.existing?.equipmentId ?? '',
        ownerId: widget.currentUser.userId,
        ownerName: widget.currentUser.name,
        equipmentName: _titleCtrl.text.trim(),
        category: 'Books',
        description: _descCtrl.text.trim(),
        titleLocalized: {'en': _titleCtrl.text.trim()},
        categoryLocalized: {'en': 'Books'},
        descriptionLocalized: {'en': _descCtrl.text.trim()},
        pricePerHour: 0.0,
        pricePerDay: 0.0,
        location: [loc.area, loc.city]
            .where((e) => e != null && e.isNotEmpty)
            .join(', '),
        latitude: loc.latitude,
        longitude: loc.longitude,
        area: loc.area ?? '',
        city: loc.city ?? '',
        state: loc.state ?? '',
        country: loc.country ?? '',
        locationAccuracy: loc.accuracy ?? 0.0,
        locationCapturedAt: loc.timestamp,
        imageUrls: finalUrls,
        availability: _availability,
        rating: 5.0,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        machineSpecs: specs,
        condition: _condition,
        minRentalDuration:
            double.tryParse(_qtyCtrl.text.trim()) ?? 1.0,
        priceType: 'day',
        status: 'published',
        views: widget.existing?.views ?? 0,
        savedBy: widget.existing?.savedBy ?? [],
        bookingsCount: widget.existing?.bookingsCount ?? 0,
        availabilityFrom: _availableFrom,
        availabilityTo: _availableUntil,
      );
      if (widget.existing != null) {
        await _service.updateEquipment(
            equipmentId: widget.existing!.equipmentId,
            updates: model.toMap());
      } else {
        await _service.addEquipment(model);
        await ListingDraftManager.clearDraft('Books');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🎉 Listing Published Successfully'),
            backgroundColor: _kGreen));
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      LoggerService.error('Error publishing listing', e);
      setState(() => _submitting = false);
      _showErrorBottomSheet(
          title: 'Publish Failed',
          message:
              'Failed to upload images or save listing: $e. Please check your internet connection.',
          actionLabel: 'Retry',
          onAction: () => _publishWithLocation(loc));
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickerImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please upload at least one image.'),
          backgroundColor: Colors.red));
      return;
    }
    if (_availableFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select an available start date.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
    });
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('No internet connection');
      }
    } catch (_) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
          title: 'No Internet Connection',
          message:
              'Borrow requires an active internet connection to publish listings.',
          actionLabel: 'Retry',
          onAction: () => _publish());
      return;
    }
    final isGpsEnabled =
        await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() => _submitting = false);
      _showGpsRequiredBottomSheet();
      return;
    }
    _continuePublishingWithLocation();
  }

  void _showGpsRequiredBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📍',
                  style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Location Required',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: _kTextPrimary)),
              const SizedBox(height: 12),
              const Text(
                'Borrow needs your location to publish this listing and recommend it to nearby users. Your exact address will never be shared.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 14,
                    height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _waitingForGps = true);
                    Geolocator.openLocationSettings();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: const Text('Enable GPS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(
                          color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorBottomSheet({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: _kTextPrimary)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onAction();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: Text(actionLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(
                          color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadDraft() async {
    if (widget.existing != null) return;
    setState(() => _loadingDraft = true);
    final draft = await ListingDraftManager.loadDraft('Books');
    if (draft != null && mounted) {
      setState(() {
        _titleCtrl.text = draft['title'] ?? '';
        _authorCtrl.text = draft['author'] ?? '';
        _languageCtrl.text = draft['language'] ?? 'English';
        _publisherCtrl.text = draft['publisher'] ?? '';
        _pubYearCtrl.text = draft['year'] ?? '';
        _editionCtrl.text = draft['edition'] ?? '';
        _isbnCtrl.text = draft['isbn'] ?? '';
        _pagesCtrl.text = draft['pages'] ?? '';
        _descCtrl.text = draft['description'] ?? '';
        _qtyCtrl.text = draft['quantity'] ?? '1';
        _genre = draft['genre'] ?? 'Academic';
        _condition = draft['condition'] ?? 'Good';
        _availability = draft['availability'] ?? true;
        if (draft['from'] != null) {
          _availableFrom = DateTime.tryParse(draft['from']);
        }
        if (draft['until'] != null) {
          _availableUntil = DateTime.tryParse(draft['until']);
        }
        final List<dynamic> imgPaths = draft['imagePaths'] ?? [];
        _pickerImages.clear();
        for (var p in imgPaths) {
          _pickerImages.add(BorrowImageItem(localFile: File(p)));
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✍ Restored your unfinished book draft.'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating));
    }
    setState(() => _loadingDraft = false);
  }

  void _saveDraft() {
    if (_loadingDraft || widget.existing != null) return;
    final draft = {
      'title': _titleCtrl.text,
      'author': _authorCtrl.text,
      'language': _languageCtrl.text,
      'publisher': _publisherCtrl.text,
      'year': _pubYearCtrl.text,
      'edition': _editionCtrl.text,
      'isbn': _isbnCtrl.text,
      'pages': _pagesCtrl.text,
      'description': _descCtrl.text,
      'quantity': _qtyCtrl.text,
      'genre': _genre,
      'condition': _condition,
      'availability': _availability,
      'from': _availableFrom?.toIso8601String(),
      'until': _availableUntil?.toIso8601String(),
      'imagePaths': _pickerImages
          .where((i) => i.isLocal)
          .map((i) => i.localFile!.path)
          .toList(),
    };
    ListingDraftManager.saveDraft('Books', draft);
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = isFrom
        ? DateTime(now.year, now.month, now.day)
        : (_availableFrom ??
            DateTime(now.year, now.month, now.day));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_availableFrom ?? firstDate)
          : (_availableUntil ?? firstDate),
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _kGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _availableFrom = picked;
          if (_availableUntil != null &&
              _availableUntil!.isBefore(_availableFrom!)) {
            _availableUntil = null;
          }
        } else {
          _availableUntil = picked;
        }
      });
      _saveDraft();
    }
  }

  // ── REDESIGNED UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
            widget.existing != null ? 'Edit Book Listing' : 'Share a Book',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (widget.existing == null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onSelected: (val) {
                if (val == 'save') {
                  _saveDraft();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('💾 Draft Saved'),
                          backgroundColor: _kGreen));
                } else if (val == 'discard') {
                  ListingDraftManager.clearDraft('Books');
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Draft discarded.')));
                } else if (val == 'reset') {
                  setState(() {
                    _titleCtrl.clear();
                    _authorCtrl.clear();
                    _languageCtrl.text = 'English';
                    _publisherCtrl.clear();
                    _pubYearCtrl.clear();
                    _editionCtrl.clear();
                    _isbnCtrl.clear();
                    _pagesCtrl.clear();
                    _descCtrl.clear();
                    _qtyCtrl.text = '1';
                    _genre = 'Academic';
                    _condition = 'Good';
                    _availability = true;
                    _availableFrom = null;
                    _availableUntil = null;
                    _pickerImages.clear();
                    _activeStep = 0;
                  });
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                    value: 'save',
                    child: Row(children: [
                      Icon(Icons.save_outlined, size: 18),
                      SizedBox(width: 12),
                      Text('Save Draft')
                    ])),
                PopupMenuItem(
                    value: 'discard',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18),
                      SizedBox(width: 12),
                      Text('Discard Draft')
                    ])),
                PopupMenuItem(
                    value: 'reset',
                    child: Row(children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Reset Form')
                    ])),
              ],
            ),
        ],
      ),
      body: _submitting
          ? buildSubmittingView(_uploadStatus, _uploadProgress)
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  buildCompactStepIndicator(_activeStep, _steps),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          20, 16, 20, 120),
                      children: [
                        buildGpsDisabledBanner(
                            _gpsDisabledBannerVisible, () {
                          setState(() => _waitingForGps = true);
                          Geolocator.openLocationSettings();
                        }),
                        ..._buildStepContent(),
                        const SizedBox(height: 24),
                        buildPreviewCard(
                          title: _titleCtrl.text,
                          category: 'Books',
                          condition: _condition,
                          images: _pickerImages,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _submitting
          ? null
          : buildStickyActionBar(
              ctx: context,
              activeStep: _activeStep,
              totalSteps: _steps.length,
              onBack: () => setState(() => _activeStep--),
              onNext: () {
                if (_formKey.currentState!.validate()) {
                  if (_activeStep < _steps.length - 1) {
                    setState(() => _activeStep++);
                  } else {
                    _publish();
                  }
                }
              },
            ),
    );
  }

  List<Widget> _buildStepContent() {
    if (_activeStep == 0) {
      return [
        buildStepHeader(
            'Add Photos',
            'Great photos help your listing get noticed.'),
        buildImageHeroSection(_pickerImages, (list) {
          setState(() {
            _pickerImages.clear();
            _pickerImages.addAll(list);
          });
          _saveDraft();
        }),
        const SizedBox(height: 24),
        buildSectionCard(
          icon: Icons.info_outline_rounded,
          title: 'Basic Information',
          subtitle: 'The essentials for your listing',
          children: [
            buildTextField('Book Title *', _titleCtrl,
                validator: (v) =>
                    v!.isEmpty ? 'Enter book title' : null,
                hint: 'e.g. Clean Code'),
            const SizedBox(height: 16),
            buildTextField('Description *', _descCtrl,
                maxLines: 4,
                validator: (v) =>
                    v!.isEmpty ? 'Enter description' : null,
                hint:
                    'Describe the content, condition, and any notes…'),
            const SizedBox(height: 20),
            buildConditionChips(
              ['New', 'Like New', 'Good', 'Fair', 'Poor'],
              (c) {
                setState(() => _condition = c);
                _saveDraft();
              },
            ),
          ],
        ),
      ];
    } else if (_activeStep == 1) {
      return [
        buildStepHeader('Book Details',
            'Help borrowers understand what you\'re sharing.'),
        buildSectionCard(
          icon: Icons.menu_book_rounded,
          title: 'Book Information',
          subtitle: 'Required details for this book',
          children: [
            buildTextField('Author *', _authorCtrl,
                validator: (v) =>
                    v!.isEmpty ? 'Enter author name' : null,
                hint: 'e.g. Robert C. Martin'),
            const SizedBox(height: 16),
            buildTextField('Language *', _languageCtrl,
                validator: (v) =>
                    v!.isEmpty ? 'Enter language' : null,
                hint: 'e.g. English'),
            const SizedBox(height: 20),
            _buildGenreChips(),
          ],
        ),
        const SizedBox(height: 16),
        buildOptionalExpandable(children: [
          buildTextField('Publisher', _publisherCtrl,
              hint: 'e.g. Prentice Hall'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: buildTextField('Year', _pubYearCtrl,
                      isNumeric: true, hint: 'e.g. 2020')),
              const SizedBox(width: 12),
              Expanded(
                  child: buildTextField('Edition', _editionCtrl,
                      hint: 'e.g. 3rd')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: buildTextField('ISBN', _isbnCtrl,
                      hint: 'Optional')),
              const SizedBox(width: 12),
              Expanded(
                  child: buildTextField('Pages', _pagesCtrl,
                      isNumeric: true, hint: 'Optional')),
            ],
          ),
        ]),
      ];
    } else {
      return [
        buildStepHeader('Availability',
            'Set when the book is available to borrow.'),
        buildSectionCard(
          icon: Icons.calendar_today_rounded,
          title: 'Availability',
          subtitle: 'When can this book be borrowed?',
          children: [
            buildTextField('Available Quantity *', _qtyCtrl,
                isNumeric: true,
                validator: (v) =>
                    v!.isEmpty ? 'Enter quantity' : null,
                hint: 'e.g. 1'),
            const SizedBox(height: 20),
            Text('Borrowing Period *',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            buildDateTile('Available From *', _availableFrom,
                () => _selectDate(context, true)),
            const SizedBox(height: 12),
            buildDateTile('Available Until (Optional)',
                _availableUntil,
                () => _selectDate(context, false)),
            const SizedBox(height: 20),
            buildAvailabilityToggle((val) {
              setState(() => _availability = val);
              _saveDraft();
            }),
          ],
        ),
      ];
    }
  }

  Widget _buildGenreChips() {
    const genres = [
      'Academic', 'Novel', 'Biography', 'Reference',
      'Competitive Exam', 'Children', 'Magazine', 'Other'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Genre',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres.map((g) {
            final selected = _genre == g;
            return GestureDetector(
              onTap: () {
                setState(() => _genre = g);
                _saveDraft();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _kGreen : _kFieldFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: selected ? _kGreen : _kFieldBorder),
                ),
                child: Text(g,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : _kTextSecondary)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── FARM EQUIPMENT FORM ───────────────────────────────────────────────────────

class FarmEquipmentFormPage extends StatefulWidget {
  const FarmEquipmentFormPage(
      {super.key, required this.currentUser, this.existing});
  final AppUserModel currentUser;
  final MarketplaceEquipmentModel? existing;

  @override
  State<FarmEquipmentFormPage> createState() =>
      _FarmEquipmentFormPageState();
}

class _FarmEquipmentFormPageState
    extends State<FarmEquipmentFormPage>
    with WidgetsBindingObserver, _ListingFormUiMixin {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceService _service = MarketplaceService();
  // ignore: unused_field
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _instructionsCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _customDurationCtrl;

  int _activeStep = 0;
  String _type = 'Tractor';
  String _condition = 'Good';
  String _fuel = 'Diesel';
  String _delivery = 'Pickup Only';
  String _duration = '1 Week';
  bool _operatorRequired = false;
  bool _availability = true;
  bool _submitting = false;
  final List<BorrowImageItem> _pickerImages = [];
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  bool _waitingForGps = false;
  bool _gpsDisabledBannerVisible = false;

  DateTime? _availableFrom;
  DateTime? _availableUntil;
  bool _loadingDraft = false;

  static const _steps = ['Photos', 'Equipment', 'Logistics'];

  @override
  List<BorrowImageItem> get pickerImages => _pickerImages;
  @override
  String get conditionValue => _condition;
  @override
  bool get availabilityValue => _availability;
  @override
  void setAvailability(bool val) => setState(() => _availability = val);

  // ── BUSINESS LOGIC (UNCHANGED) ──────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nameCtrl = TextEditingController();
    _brandCtrl = TextEditingController();
    _yearCtrl = TextEditingController();
    _modelCtrl = TextEditingController();
    _instructionsCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _customDurationCtrl = TextEditingController();

    if (widget.existing != null) {
      final specsStr = widget.existing!.machineSpecs;
      _nameCtrl.text = widget.existing!.equipmentName;
      _brandCtrl.text = _parseSpec(specsStr, 'Brand: ');
      _type = _parseSpec(specsStr, 'Type: ', defaultValue: 'Tractor');
      _yearCtrl.text = _parseSpec(specsStr, 'Year: ');
      _modelCtrl.text = _parseSpec(specsStr, 'Model: ');
      _condition = widget.existing!.condition;
      _instructionsCtrl.text =
          _parseSpec(specsStr, 'Instructions: ');
      _fuel =
          _parseSpec(specsStr, 'Fuel Type: ', defaultValue: 'Diesel');
      _delivery = _parseSpec(specsStr, 'Delivery: ',
          defaultValue: 'Pickup Only');
      _duration = _parseSpec(specsStr, 'Max Duration: ',
          defaultValue: '1 Week');
      if (!['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks']
          .contains(_duration)) {
        _customDurationCtrl.text = _duration;
        _duration = 'Custom';
      }
      _operatorRequired =
          _parseSpec(specsStr, 'Operator: ') == 'Yes';
      _descCtrl.text = widget.existing!.description;
      _availability = widget.existing!.availability;
      _availableFrom = widget.existing!.availabilityFrom;
      _availableUntil = widget.existing!.availabilityTo;
      _pickerImages.addAll(widget.existing!.imageUrls
          .map((u) => BorrowImageItem(remoteUrl: u)));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadDraft();
      });
    }

    _nameCtrl.addListener(_saveDraft);
    _brandCtrl.addListener(_saveDraft);
    _yearCtrl.addListener(_saveDraft);
    _modelCtrl.addListener(_saveDraft);
    _instructionsCtrl.addListener(_saveDraft);
    _descCtrl.addListener(_saveDraft);
    _customDurationCtrl.addListener(_saveDraft);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _yearCtrl.dispose();
    _modelCtrl.dispose();
    _instructionsCtrl.dispose();
    _descCtrl.dispose();
    _customDurationCtrl.dispose();
    super.dispose();
  }

  String _parseSpec(String specs, String prefix,
      {String defaultValue = ''}) {
    if (specs.isEmpty) return defaultValue;
    try {
      final parts = specs.split(', ');
      final found =
          parts.firstWhere((p) => p.startsWith(prefix), orElse: () => '');
      if (found.isNotEmpty) return found.replaceAll(prefix, '');
    } catch (_) {}
    return defaultValue;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForGps) {
      _checkGpsAndContinuePublishing();
    }
  }

  Future<void> _checkGpsAndContinuePublishing() async {
    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
      _gpsDisabledBannerVisible = false;
    });
    final isGpsEnabled =
        await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() {
        _submitting = false;
        _waitingForGps = false;
        _gpsDisabledBannerVisible = true;
      });
      return;
    }
    _waitingForGps = false;
    _continuePublishingWithLocation();
  }

  Future<void> _continuePublishingWithLocation() async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Getting your location...';
      _uploadProgress = 0.0;
    });
    try {
      final locResult =
          await LocationService.instance.getCurrentLocation();
      if (locResult is LocationFailure) {
        setState(() => _submitting = false);
        if (locResult.isPermanent) {
          _showErrorBottomSheet(
              title: 'Permission Required',
              message:
                  'Borrow needs location permissions. Please enable them in your app settings to proceed.',
              actionLabel: 'Open Settings',
              onAction: () => Geolocator.openAppSettings());
        } else {
          _showErrorBottomSheet(
              title: 'Location Error',
              message: locResult.reason,
              actionLabel: 'Retry',
              onAction: () => _continuePublishingWithLocation());
        }
        return;
      }
      final loc = (locResult as LocationSuccess).location;
      await _publishWithLocation(loc);
    } catch (e) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
          title: 'Publish Failed',
          message:
              'Something went wrong while getting your location: $e',
          actionLabel: 'Retry',
          onAction: () => _continuePublishingWithLocation());
    }
  }

  Future<void> _publishWithLocation(VerifiedLocation loc) async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Publishing Listing...';
      _uploadProgress = 0.0;
    });
    try {
      final List<String> finalUrls = [];
      final CloudinaryService cloudinary = CloudinaryService();
      for (var i = 0; i < _pickerImages.length; i++) {
        final img = _pickerImages[i];
        setState(() {
          _uploadStatus = 'Publishing Listing...';
          _uploadProgress = (i / _pickerImages.length);
        });
        if (img.isLocal) {
          final secureUrl =
              await cloudinary.uploadImage(img.localFile!);
          finalUrls.add(secureUrl);
        } else {
          finalUrls.add(img.remoteUrl!);
        }
      }
      setState(() {
        _uploadStatus = 'Publishing Listing...';
        _uploadProgress = 1.0;
      });
      final specs =
          'Brand: ${_brandCtrl.text.trim()}, Type: $_type, Year: ${_yearCtrl.text.trim()}, Model: ${_modelCtrl.text.trim()}, Fuel Type: $_fuel, Operator: ${_operatorRequired ? 'Yes' : 'No'}, Delivery: $_delivery, Max Duration: ${_duration == 'Custom' ? _customDurationCtrl.text.trim() : _duration}, Instructions: ${_instructionsCtrl.text.trim()}';
      final model = MarketplaceEquipmentModel(
        equipmentId: widget.existing?.equipmentId ?? '',
        ownerId: widget.currentUser.userId,
        ownerName: widget.currentUser.name,
        equipmentName: _nameCtrl.text.trim(),
        category: 'Farm Equipment',
        description: _descCtrl.text.trim(),
        titleLocalized: {'en': _nameCtrl.text.trim()},
        categoryLocalized: {'en': 'Farm Equipment'},
        descriptionLocalized: {'en': _descCtrl.text.trim()},
        pricePerHour: 0.0,
        pricePerDay: 0.0,
        location: [loc.area, loc.city]
            .where((e) => e != null && e.isNotEmpty)
            .join(', '),
        latitude: loc.latitude,
        longitude: loc.longitude,
        area: loc.area ?? '',
        city: loc.city ?? '',
        state: loc.state ?? '',
        country: loc.country ?? '',
        locationAccuracy: loc.accuracy ?? 0.0,
        locationCapturedAt: loc.timestamp,
        imageUrls: finalUrls,
        availability: _availability,
        rating: 5.0,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        machineSpecs: specs,
        condition: _condition,
        minRentalDuration: 1.0,
        priceType: 'day',
        status: 'published',
        views: widget.existing?.views ?? 0,
        savedBy: widget.existing?.savedBy ?? [],
        bookingsCount: widget.existing?.bookingsCount ?? 0,
        availabilityFrom: _availableFrom,
        availabilityTo: _availableUntil,
      );
      if (widget.existing != null) {
        await _service.updateEquipment(
            equipmentId: widget.existing!.equipmentId,
            updates: model.toMap());
      } else {
        await _service.addEquipment(model);
        await ListingDraftManager.clearDraft('Farm Equipment');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🎉 Listing Published Successfully'),
            backgroundColor: _kGreen));
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      LoggerService.error('Error publishing listing', e);
      setState(() => _submitting = false);
      _showErrorBottomSheet(
          title: 'Publish Failed',
          message:
              'Failed to upload images or save listing: $e. Please check your internet connection.',
          actionLabel: 'Retry',
          onAction: () => _publishWithLocation(loc));
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickerImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please upload at least one image.'),
          backgroundColor: Colors.red));
      return;
    }
    if (_availableFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select an available start date.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
    });
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('No internet connection');
      }
    } catch (_) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
          title: 'No Internet Connection',
          message:
              'Borrow requires an active internet connection to publish listings.',
          actionLabel: 'Retry',
          onAction: () => _publish());
      return;
    }
    final isGpsEnabled =
        await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() => _submitting = false);
      _showGpsRequiredBottomSheet();
      return;
    }
    _continuePublishingWithLocation();
  }

  void _showGpsRequiredBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Location Required',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: _kTextPrimary)),
              const SizedBox(height: 12),
              const Text(
                'Borrow needs your location to publish this listing and recommend it to nearby users. Your exact address will never be shared.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 14,
                    height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _waitingForGps = true);
                    Geolocator.openLocationSettings();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: const Text('Enable GPS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(
                          color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorBottomSheet({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: _kTextPrimary)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onAction();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: Text(actionLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(
                          color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadDraft() async {
    if (widget.existing != null) return;
    setState(() => _loadingDraft = true);
    final draft =
        await ListingDraftManager.loadDraft('Farm Equipment');
    if (draft != null && mounted) {
      setState(() {
        _nameCtrl.text = draft['name'] ?? '';
        _type = draft['type'] ?? 'Tractor';
        _brandCtrl.text = draft['brand'] ?? '';
        _yearCtrl.text = draft['year'] ?? '';
        _modelCtrl.text = draft['model'] ?? '';
        _condition = draft['condition'] ?? 'Good';
        _fuel = draft['fuel'] ?? 'Diesel';
        _delivery = draft['delivery'] ?? 'Pickup Only';
        _duration = draft['duration'] ?? '1 Week';
        if (!['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks']
            .contains(_duration)) {
          _customDurationCtrl.text = _duration;
          _duration = 'Custom';
        }
        _operatorRequired = draft['operator'] ?? false;
        _instructionsCtrl.text = draft['instructions'] ?? '';
        _descCtrl.text = draft['description'] ?? '';
        _availability = draft['availability'] ?? true;
        if (draft['from'] != null) {
          _availableFrom = DateTime.tryParse(draft['from']);
        }
        if (draft['until'] != null) {
          _availableUntil = DateTime.tryParse(draft['until']);
        }
        final List<dynamic> imgPaths = draft['imagePaths'] ?? [];
        _pickerImages.clear();
        for (var p in imgPaths) {
          _pickerImages.add(BorrowImageItem(localFile: File(p)));
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              '✍ Restored your unfinished farm equipment draft.'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating));
    }
    setState(() => _loadingDraft = false);
  }

  void _saveDraft() {
    if (_loadingDraft || widget.existing != null) return;
    final draft = {
      'name': _nameCtrl.text,
      'type': _type,
      'brand': _brandCtrl.text,
      'year': _yearCtrl.text,
      'model': _modelCtrl.text,
      'condition': _condition,
      'fuel': _fuel,
      'delivery': _delivery,
      'duration': _duration == 'Custom'
          ? _customDurationCtrl.text
          : _duration,
      'operator': _operatorRequired,
      'instructions': _instructionsCtrl.text,
      'description': _descCtrl.text,
      'availability': _availability,
      'from': _availableFrom?.toIso8601String(),
      'until': _availableUntil?.toIso8601String(),
      'imagePaths': _pickerImages
          .where((i) => i.isLocal)
          .map((i) => i.localFile!.path)
          .toList(),
    };
    ListingDraftManager.saveDraft('Farm Equipment', draft);
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = isFrom
        ? DateTime(now.year, now.month, now.day)
        : (_availableFrom ??
            DateTime(now.year, now.month, now.day));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_availableFrom ?? firstDate)
          : (_availableUntil ?? firstDate),
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _kGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _availableFrom = picked;
          if (_availableUntil != null &&
              _availableUntil!.isBefore(_availableFrom!)) {
            _availableUntil = null;
          }
        } else {
          _availableUntil = picked;
        }
      });
      _saveDraft();
    }
  }

  // ── REDESIGNED UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
            widget.existing != null
                ? 'Edit Farm Equipment'
                : 'Share Farm Equipment',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (widget.existing == null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onSelected: (val) {
                if (val == 'save') {
                  _saveDraft();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('💾 Draft Saved'),
                          backgroundColor: _kGreen));
                } else if (val == 'discard') {
                  ListingDraftManager.clearDraft('Farm Equipment');
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Draft discarded.')));
                } else if (val == 'reset') {
                  setState(() {
                    _nameCtrl.clear();
                    _brandCtrl.clear();
                    _yearCtrl.clear();
                    _modelCtrl.clear();
                    _instructionsCtrl.clear();
                    _descCtrl.clear();
                    _customDurationCtrl.clear();
                    _type = 'Tractor';
                    _condition = 'Good';
                    _fuel = 'Diesel';
                    _delivery = 'Pickup Only';
                    _duration = '1 Week';
                    _operatorRequired = false;
                    _availability = true;
                    _availableFrom = null;
                    _availableUntil = null;
                    _pickerImages.clear();
                    _activeStep = 0;
                  });
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                    value: 'save',
                    child: Row(children: [
                      Icon(Icons.save_outlined, size: 18),
                      SizedBox(width: 12),
                      Text('Save Draft')
                    ])),
                PopupMenuItem(
                    value: 'discard',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18),
                      SizedBox(width: 12),
                      Text('Discard Draft')
                    ])),
                PopupMenuItem(
                    value: 'reset',
                    child: Row(children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Reset Form')
                    ])),
              ],
            ),
        ],
      ),
      body: _submitting
          ? buildSubmittingView(_uploadStatus, _uploadProgress)
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  buildCompactStepIndicator(_activeStep, _steps),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          20, 16, 20, 120),
                      children: [
                        buildGpsDisabledBanner(
                            _gpsDisabledBannerVisible, () {
                          setState(() => _waitingForGps = true);
                          Geolocator.openLocationSettings();
                        }),
                        ..._buildStepContent(),
                        const SizedBox(height: 24),
                        buildPreviewCard(
                          title: _nameCtrl.text,
                          category: 'Farm Equipment',
                          condition: _condition,
                          images: _pickerImages,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _submitting
          ? null
          : buildStickyActionBar(
              ctx: context,
              activeStep: _activeStep,
              totalSteps: _steps.length,
              onBack: () => setState(() => _activeStep--),
              onNext: () {
                if (_formKey.currentState!.validate()) {
                  if (_activeStep < _steps.length - 1) {
                    setState(() => _activeStep++);
                  } else {
                    _publish();
                  }
                }
              },
            ),
    );
  }

  List<Widget> _buildStepContent() {
    if (_activeStep == 0) {
      return [
        buildStepHeader('Add Photos',
            'High quality photos build trust with borrowers.'),
        buildImageHeroSection(_pickerImages, (list) {
          setState(() {
            _pickerImages.clear();
            _pickerImages.addAll(list);
          });
          _saveDraft();
        }),
        const SizedBox(height: 24),
        buildSectionCard(
          icon: Icons.info_outline_rounded,
          title: 'Basic Information',
          subtitle: 'The essentials for your listing',
          children: [
            buildTextField('Equipment Name *', _nameCtrl,
                validator: (v) =>
                    v!.isEmpty ? 'Enter equipment name' : null,
                hint: 'e.g. Mahindra Tractor 575 DI'),
            const SizedBox(height: 16),
            buildTextField('Description *', _descCtrl,
                maxLines: 4,
                validator: (v) =>
                    v!.isEmpty ? 'Enter description' : null,
                hint:
                    'Describe the equipment, usage history, and any notes…'),
            const SizedBox(height: 20),
            buildConditionChips(
              ['New', 'Excellent', 'Good', 'Fair', 'Needs Repair'],
              (c) {
                setState(() => _condition = c);
                _saveDraft();
              },
            ),
          ],
        ),
      ];
    } else if (_activeStep == 1) {
      return [
        buildStepHeader('Equipment Details',
            'Help borrowers understand your equipment.'),
        buildSectionCard(
          icon: Icons.agriculture_rounded,
          title: 'Equipment Specifications',
          subtitle: 'Key details about this machine',
          children: [
            buildDropdown(
              'Equipment Type *',
              _type,
              ['Tractor', 'Rotavator', 'Sprayer', 'Cultivator', 'Seeder', 'Harvester', 'Pump', 'Other'],
              (val) {
                setState(() => _type = val!);
                _saveDraft();
              },
            ),
            const SizedBox(height: 16),
            buildTextField('Brand', _brandCtrl,
                hint: 'e.g. Mahindra, John Deere'),
            const SizedBox(height: 20),
            _buildOperatorToggle(),
          ],
        ),
        const SizedBox(height: 16),
        buildOptionalExpandable(children: [
          buildDropdown(
            'Fuel Type',
            _fuel,
            ['Diesel', 'Petrol', 'Electric', 'Battery', 'Manual', 'Other'],
            (val) {
              setState(() => _fuel = val!);
              _saveDraft();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: buildTextField('Year', _yearCtrl,
                      isNumeric: true, hint: 'e.g. 2019')),
              const SizedBox(width: 12),
              Expanded(
                  child: buildTextField(
                      'Model Number', _modelCtrl,
                      hint: 'Optional')),
            ],
          ),
        ]),
      ];
    } else {
      return [
        buildStepHeader('Logistics',
            'Set availability and delivery options.'),
        buildSectionCard(
          icon: Icons.local_shipping_outlined,
          title: 'Rental Settings',
          subtitle: 'Delivery, duration and availability',
          children: [
            buildDropdown(
              'Delivery Option *',
              _delivery,
              ['Pickup Only', 'Owner Can Deliver', 'Meet at Location'],
              (val) {
                setState(() => _delivery = val!);
                _saveDraft();
              },
            ),
            const SizedBox(height: 16),
            buildDropdown(
              'Maximum Borrow Duration *',
              _duration,
              ['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks', 'Custom'],
              (val) {
                setState(() => _duration = val!);
                _saveDraft();
              },
            ),
            if (_duration == 'Custom') ...[
              const SizedBox(height: 16),
              buildTextField(
                  'Custom Duration (e.g. 3 Weeks) *',
                  _customDurationCtrl,
                  validator: (v) => v!.isEmpty
                      ? 'Enter custom duration limit'
                      : null),
            ],
            const SizedBox(height: 20),
            Text('Availability Period *',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            buildDateTile('Available From *', _availableFrom,
                () => _selectDate(context, true)),
            const SizedBox(height: 12),
            buildDateTile('Available Until (Optional)',
                _availableUntil,
                () => _selectDate(context, false)),
            const SizedBox(height: 16),
            buildTextField(
                'Usage Instructions (Optional)',
                _instructionsCtrl,
                maxLines: 3,
                hint: 'Safe usage guidelines for the borrower…'),
            const SizedBox(height: 20),
            buildAvailabilityToggle((val) {
              setState(() => _availability = val);
              _saveDraft();
            }),
          ],
        ),
      ];
    }
  }

  Widget _buildOperatorToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Operator Required? *',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _operatorRequired = false);
                  _saveDraft();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: !_operatorRequired
                        ? _kGreen
                        : _kFieldFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: !_operatorRequired
                            ? _kGreen
                            : _kFieldBorder),
                  ),
                  child: Center(
                    child: Text('No Operator',
                        style: TextStyle(
                            color: !_operatorRequired
                                ? Colors.white
                                : _kTextPrimary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _operatorRequired = true);
                  _saveDraft();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _operatorRequired
                        ? _kGreen
                        : _kFieldFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _operatorRequired
                            ? _kGreen
                            : _kFieldBorder),
                  ),
                  child: Center(
                    child: Text('Operator Needed',
                        style: TextStyle(
                            color: _operatorRequired
                                ? Colors.white
                                : _kTextPrimary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── CONSTRUCTION EQUIPMENT FORM ───────────────────────────────────────────────

class ConstructionEquipmentFormPage extends StatefulWidget {
  const ConstructionEquipmentFormPage(
      {super.key, required this.currentUser, this.existing});
  final AppUserModel currentUser;
  final MarketplaceEquipmentModel? existing;

  @override
  State<ConstructionEquipmentFormPage> createState() =>
      _ConstructionEquipmentFormPageState();
}

class _ConstructionEquipmentFormPageState
    extends State<ConstructionEquipmentFormPage>
    with WidgetsBindingObserver, _ListingFormUiMixin {
  final _formKey = GlobalKey<FormState>();
  final MarketplaceService _service = MarketplaceService();
  // ignore: unused_field
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _safetyCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _customDurationCtrl;

  int _activeStep = 0;
  String _category = 'Power Tool';
  String _condition = 'Good';
  String _powerSource = 'Electric';
  String _delivery = 'Pickup';
  String _duration = '1 Week';
  bool _availability = true;
  bool _submitting = false;
  final List<BorrowImageItem> _pickerImages = [];
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  bool _waitingForGps = false;
  bool _gpsDisabledBannerVisible = false;

  DateTime? _availableFrom;
  DateTime? _availableUntil;
  bool _loadingDraft = false;

  static const _steps = ['Photos', 'Equipment', 'Logistics'];

  @override
  List<BorrowImageItem> get pickerImages => _pickerImages;
  @override
  String get conditionValue => _condition;
  @override
  bool get availabilityValue => _availability;
  @override
  void setAvailability(bool val) => setState(() => _availability = val);

  // ── BUSINESS LOGIC (UNCHANGED) ──────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nameCtrl = TextEditingController();
    _typeCtrl = TextEditingController();
    _brandCtrl = TextEditingController();
    _modelCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _safetyCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _customDurationCtrl = TextEditingController();

    if (widget.existing != null) {
      final specsStr = widget.existing!.machineSpecs;
      _nameCtrl.text = widget.existing!.equipmentName;
      _brandCtrl.text = _parseSpec(specsStr, 'Brand: ');
      _modelCtrl.text = _parseSpec(specsStr, 'Model: ');
      _typeCtrl.text = _parseSpec(specsStr, 'Type: ');
      _category = _parseSpec(specsStr, 'Category: ',
          defaultValue: 'Power Tool');
      _condition = widget.existing!.condition;
      _powerSource = _parseSpec(specsStr, 'Power Source: ',
          defaultValue: 'Electric');
      _weightCtrl.text = _parseSpec(specsStr, 'Weight: ');
      _delivery =
          _parseSpec(specsStr, 'Delivery: ', defaultValue: 'Pickup');
      _duration = _parseSpec(specsStr, 'Max Duration: ',
          defaultValue: '1 Week');
      if (!['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks']
          .contains(_duration)) {
        _customDurationCtrl.text = _duration;
        _duration = 'Custom';
      }
      _safetyCtrl.text = _parseSpec(specsStr, 'Safety: ');
      _descCtrl.text = widget.existing!.description;
      _availability = widget.existing!.availability;
      _availableFrom = widget.existing!.availabilityFrom;
      _availableUntil = widget.existing!.availabilityTo;
      _pickerImages.addAll(widget.existing!.imageUrls
          .map((u) => BorrowImageItem(remoteUrl: u)));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadDraft();
      });
    }

    _nameCtrl.addListener(_saveDraft);
    _typeCtrl.addListener(_saveDraft);
    _brandCtrl.addListener(_saveDraft);
    _modelCtrl.addListener(_saveDraft);
    _weightCtrl.addListener(_saveDraft);
    _safetyCtrl.addListener(_saveDraft);
    _descCtrl.addListener(_saveDraft);
    _customDurationCtrl.addListener(_saveDraft);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _weightCtrl.dispose();
    _safetyCtrl.dispose();
    _descCtrl.dispose();
    _customDurationCtrl.dispose();
    super.dispose();
  }

  String _parseSpec(String specs, String prefix,
      {String defaultValue = ''}) {
    if (specs.isEmpty) return defaultValue;
    try {
      final parts = specs.split(', ');
      final found =
          parts.firstWhere((p) => p.startsWith(prefix), orElse: () => '');
      if (found.isNotEmpty) return found.replaceAll(prefix, '');
    } catch (_) {}
    return defaultValue;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForGps) {
      _checkGpsAndContinuePublishing();
    }
  }

  Future<void> _checkGpsAndContinuePublishing() async {
    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
      _gpsDisabledBannerVisible = false;
    });
    final isGpsEnabled =
        await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() {
        _submitting = false;
        _waitingForGps = false;
        _gpsDisabledBannerVisible = true;
      });
      return;
    }
    _waitingForGps = false;
    _continuePublishingWithLocation();
  }

  Future<void> _continuePublishingWithLocation() async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Getting your location...';
      _uploadProgress = 0.0;
    });
    try {
      final locResult =
          await LocationService.instance.getCurrentLocation();
      if (locResult is LocationFailure) {
        setState(() => _submitting = false);
        if (locResult.isPermanent) {
          _showErrorBottomSheet(
              title: 'Permission Required',
              message:
                  'Borrow needs location permissions. Please enable them in your app settings to proceed.',
              actionLabel: 'Open Settings',
              onAction: () => Geolocator.openAppSettings());
        } else {
          _showErrorBottomSheet(
              title: 'Location Error',
              message: locResult.reason,
              actionLabel: 'Retry',
              onAction: () => _continuePublishingWithLocation());
        }
        return;
      }
      final loc = (locResult as LocationSuccess).location;
      await _publishWithLocation(loc);
    } catch (e) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
          title: 'Publish Failed',
          message:
              'Something went wrong while getting your location: $e',
          actionLabel: 'Retry',
          onAction: () => _continuePublishingWithLocation());
    }
  }

  Future<void> _publishWithLocation(VerifiedLocation loc) async {
    setState(() {
      _submitting = true;
      _uploadStatus = 'Publishing Listing...';
      _uploadProgress = 0.0;
    });
    try {
      final List<String> finalUrls = [];
      final CloudinaryService cloudinary = CloudinaryService();
      for (var i = 0; i < _pickerImages.length; i++) {
        final img = _pickerImages[i];
        setState(() {
          _uploadStatus = 'Publishing Listing...';
          _uploadProgress = (i / _pickerImages.length);
        });
        if (img.isLocal) {
          final secureUrl =
              await cloudinary.uploadImage(img.localFile!);
          finalUrls.add(secureUrl);
        } else {
          finalUrls.add(img.remoteUrl!);
        }
      }
      setState(() {
        _uploadStatus = 'Publishing Listing...';
        _uploadProgress = 1.0;
      });
      final specs =
          'Brand: ${_brandCtrl.text.trim()}, Model: ${_modelCtrl.text.trim()}, Category: $_category, Power Source: $_powerSource, Weight: ${_weightCtrl.text.trim()}, Delivery: $_delivery, Max Duration: ${_duration == 'Custom' ? _customDurationCtrl.text.trim() : _duration}, Safety: ${_safetyCtrl.text.trim()}';
      final model = MarketplaceEquipmentModel(
        equipmentId: widget.existing?.equipmentId ?? '',
        ownerId: widget.currentUser.userId,
        ownerName: widget.currentUser.name,
        equipmentName: _nameCtrl.text.trim(),
        category: 'Construction Equipment',
        description: _descCtrl.text.trim(),
        titleLocalized: {'en': _nameCtrl.text.trim()},
        categoryLocalized: {'en': 'Construction Equipment'},
        descriptionLocalized: {'en': _descCtrl.text.trim()},
        pricePerHour: 0.0,
        pricePerDay: 0.0,
        location: [loc.area, loc.city]
            .where((e) => e != null && e.isNotEmpty)
            .join(', '),
        latitude: loc.latitude,
        longitude: loc.longitude,
        area: loc.area ?? '',
        city: loc.city ?? '',
        state: loc.state ?? '',
        country: loc.country ?? '',
        locationAccuracy: loc.accuracy ?? 0.0,
        locationCapturedAt: loc.timestamp,
        imageUrls: finalUrls,
        availability: _availability,
        rating: 5.0,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        machineSpecs: specs,
        condition: _condition,
        minRentalDuration: 1.0,
        priceType: 'day',
        status: 'published',
        views: widget.existing?.views ?? 0,
        savedBy: widget.existing?.savedBy ?? [],
        bookingsCount: widget.existing?.bookingsCount ?? 0,
        availabilityFrom: _availableFrom,
        availabilityTo: _availableUntil,
      );
      if (widget.existing != null) {
        await _service.updateEquipment(
            equipmentId: widget.existing!.equipmentId,
            updates: model.toMap());
      } else {
        await _service.addEquipment(model);
        await ListingDraftManager.clearDraft(
            'Construction Equipment');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🎉 Listing Published Successfully'),
            backgroundColor: _kGreen));
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      LoggerService.error('Error publishing listing', e);
      setState(() => _submitting = false);
      _showErrorBottomSheet(
          title: 'Publish Failed',
          message:
              'Failed to upload images or save listing: $e. Please check your internet connection.',
          actionLabel: 'Retry',
          onAction: () => _publishWithLocation(loc));
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickerImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please upload at least one image.'),
          backgroundColor: Colors.red));
      return;
    }
    if (_availableFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select an available start date.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Checking location...';
    });
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('No internet connection');
      }
    } catch (_) {
      setState(() => _submitting = false);
      _showErrorBottomSheet(
          title: 'No Internet Connection',
          message:
              'Borrow requires an active internet connection to publish listings.',
          actionLabel: 'Retry',
          onAction: () => _publish());
      return;
    }
    final isGpsEnabled =
        await LocationService.instance.isLocationServiceEnabled();
    if (!isGpsEnabled) {
      setState(() => _submitting = false);
      _showGpsRequiredBottomSheet();
      return;
    }
    _continuePublishingWithLocation();
  }

  void _showGpsRequiredBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Location Required',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: _kTextPrimary)),
              const SizedBox(height: 12),
              const Text(
                'Borrow needs your location to publish this listing and recommend it to nearby users. Your exact address will never be shared.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 14,
                    height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _waitingForGps = true);
                    Geolocator.openLocationSettings();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: const Text('Enable GPS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(
                          color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorBottomSheet({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: _kTextPrimary)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onAction();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: Text(actionLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(
                          color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12))),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadDraft() async {
    if (widget.existing != null) return;
    setState(() => _loadingDraft = true);
    final draft = await ListingDraftManager.loadDraft(
        'Construction Equipment');
    if (draft != null && mounted) {
      setState(() {
        _nameCtrl.text = draft['name'] ?? '';
        _typeCtrl.text = draft['type'] ?? '';
        _category = draft['category'] ?? 'Power Tool';
        _brandCtrl.text = draft['brand'] ?? '';
        _modelCtrl.text = draft['model'] ?? '';
        _condition = draft['condition'] ?? 'Good';
        _powerSource = draft['power'] ?? 'Electric';
        _weightCtrl.text = draft['weight'] ?? '';
        _delivery = draft['delivery'] ?? 'Pickup';
        _duration = draft['duration'] ?? '1 Week';
        if (!['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks']
            .contains(_duration)) {
          _customDurationCtrl.text = _duration;
          _duration = 'Custom';
        }
        _safetyCtrl.text = draft['safety'] ?? '';
        _descCtrl.text = draft['description'] ?? '';
        _availability = draft['availability'] ?? true;
        if (draft['from'] != null) {
          _availableFrom = DateTime.tryParse(draft['from']);
        }
        if (draft['until'] != null) {
          _availableUntil = DateTime.tryParse(draft['until']);
        }
        final List<dynamic> imgPaths = draft['imagePaths'] ?? [];
        _pickerImages.clear();
        for (var p in imgPaths) {
          _pickerImages.add(BorrowImageItem(localFile: File(p)));
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              '✍ Restored your unfinished construction equipment draft.'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating));
    }
    setState(() => _loadingDraft = false);
  }

  void _saveDraft() {
    if (_loadingDraft || widget.existing != null) return;
    final draft = {
      'name': _nameCtrl.text,
      'type': _typeCtrl.text,
      'category': _category,
      'brand': _brandCtrl.text,
      'model': _modelCtrl.text,
      'condition': _condition,
      'power': _powerSource,
      'weight': _weightCtrl.text,
      'delivery': _delivery,
      'duration': _duration == 'Custom'
          ? _customDurationCtrl.text
          : _duration,
      'safety': _safetyCtrl.text,
      'description': _descCtrl.text,
      'availability': _availability,
      'from': _availableFrom?.toIso8601String(),
      'until': _availableUntil?.toIso8601String(),
      'imagePaths': _pickerImages
          .where((i) => i.isLocal)
          .map((i) => i.localFile!.path)
          .toList(),
    };
    ListingDraftManager.saveDraft('Construction Equipment', draft);
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = isFrom
        ? DateTime(now.year, now.month, now.day)
        : (_availableFrom ??
            DateTime(now.year, now.month, now.day));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_availableFrom ?? firstDate)
          : (_availableUntil ?? firstDate),
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _kGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _availableFrom = picked;
          if (_availableUntil != null &&
              _availableUntil!.isBefore(_availableFrom!)) {
            _availableUntil = null;
          }
        } else {
          _availableUntil = picked;
        }
      });
      _saveDraft();
    }
  }

  // ── REDESIGNED UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
            widget.existing != null
                ? 'Edit Construction Equipment'
                : 'Share Construction Equipment',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (widget.existing == null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onSelected: (val) {
                if (val == 'save') {
                  _saveDraft();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('💾 Draft Saved'),
                          backgroundColor: _kGreen));
                } else if (val == 'discard') {
                  ListingDraftManager.clearDraft(
                      'Construction Equipment');
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Draft discarded.')));
                } else if (val == 'reset') {
                  setState(() {
                    _nameCtrl.clear();
                    _typeCtrl.clear();
                    _brandCtrl.clear();
                    _modelCtrl.clear();
                    _weightCtrl.clear();
                    _safetyCtrl.clear();
                    _descCtrl.clear();
                    _customDurationCtrl.clear();
                    _category = 'Power Tool';
                    _condition = 'Good';
                    _powerSource = 'Electric';
                    _delivery = 'Pickup';
                    _duration = '1 Week';
                    _availability = true;
                    _availableFrom = null;
                    _availableUntil = null;
                    _pickerImages.clear();
                    _activeStep = 0;
                  });
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(
                    value: 'save',
                    child: Row(children: [
                      Icon(Icons.save_outlined, size: 18),
                      SizedBox(width: 12),
                      Text('Save Draft')
                    ])),
                PopupMenuItem(
                    value: 'discard',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18),
                      SizedBox(width: 12),
                      Text('Discard Draft')
                    ])),
                PopupMenuItem(
                    value: 'reset',
                    child: Row(children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Reset Form')
                    ])),
              ],
            ),
        ],
      ),
      body: _submitting
          ? buildSubmittingView(_uploadStatus, _uploadProgress)
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  buildCompactStepIndicator(_activeStep, _steps),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          20, 16, 20, 120),
                      children: [
                        buildGpsDisabledBanner(
                            _gpsDisabledBannerVisible, () {
                          setState(() => _waitingForGps = true);
                          Geolocator.openLocationSettings();
                        }),
                        ..._buildStepContent(),
                        const SizedBox(height: 24),
                        buildPreviewCard(
                          title: _nameCtrl.text,
                          category: 'Construction Equipment',
                          condition: _condition,
                          images: _pickerImages,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _submitting
          ? null
          : buildStickyActionBar(
              ctx: context,
              activeStep: _activeStep,
              totalSteps: _steps.length,
              onBack: () => setState(() => _activeStep--),
              onNext: () {
                if (_formKey.currentState!.validate()) {
                  if (_activeStep < _steps.length - 1) {
                    setState(() => _activeStep++);
                  } else {
                    _publish();
                  }
                }
              },
            ),
    );
  }

  List<Widget> _buildStepContent() {
    if (_activeStep == 0) {
      return [
        buildStepHeader('Add Photos',
            'Showcase your equipment with great photos.'),
        buildImageHeroSection(_pickerImages, (list) {
          setState(() {
            _pickerImages.clear();
            _pickerImages.addAll(list);
          });
          _saveDraft();
        }),
        const SizedBox(height: 24),
        buildSectionCard(
          icon: Icons.info_outline_rounded,
          title: 'Basic Information',
          subtitle: 'The essentials for your listing',
          children: [
            buildTextField('Equipment Name *', _nameCtrl,
                validator: (v) =>
                    v!.isEmpty ? 'Enter equipment name' : null,
                hint: 'e.g. Bosch GSB 500W Drill'),
            const SizedBox(height: 16),
            buildTextField('Description *', _descCtrl,
                maxLines: 4,
                validator: (v) =>
                    v!.isEmpty ? 'Enter description' : null,
                hint:
                    'Describe the equipment, specifications, and any notes…'),
            const SizedBox(height: 20),
            buildConditionChips(
              ['New', 'Excellent', 'Good', 'Fair', 'Needs Repair'],
              (c) {
                setState(() => _condition = c);
                _saveDraft();
              },
            ),
          ],
        ),
      ];
    } else if (_activeStep == 1) {
      return [
        buildStepHeader('Tool Details',
            'Describe your construction equipment.'),
        buildSectionCard(
          icon: Icons.construction_rounded,
          title: 'Equipment Specifications',
          subtitle: 'Key details about this tool',
          children: [
            buildDropdown(
              'Equipment Category *',
              _category,
              ['Drill', 'Concrete Mixer', 'Ladder', 'Generator', 'Scaffolding', 'Power Tool', 'Safety Equipment', 'Other'],
              (val) {
                setState(() => _category = val!);
                _saveDraft();
              },
            ),
            const SizedBox(height: 16),
            buildTextField(
                'Equipment Type', _typeCtrl,
                hint: 'e.g. Rotary Hammer, Circular Saw'),
            const SizedBox(height: 16),
            buildTextField('Brand', _brandCtrl,
                hint: 'e.g. Bosch, Makita, DeWalt'),
            const SizedBox(height: 16),
            buildDropdown(
              'Power Source *',
              _powerSource,
              ['Electric', 'Battery', 'Diesel', 'Petrol', 'Manual'],
              (val) {
                setState(() => _powerSource = val!);
                _saveDraft();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        buildOptionalExpandable(children: [
          buildTextField('Model Number', _modelCtrl,
              hint: 'Optional'),
          const SizedBox(height: 16),
          buildTextField('Weight (kg)', _weightCtrl,
              hint: 'e.g. 3.5 kg'),
        ]),
      ];
    } else {
      return [
        buildStepHeader('Availability & Logistics',
            'Set when and how it can be borrowed.'),
        buildSectionCard(
          icon: Icons.local_shipping_outlined,
          title: 'Rental Settings',
          subtitle: 'Delivery, duration and availability',
          children: [
            buildDropdown(
              'Delivery Option *',
              _delivery,
              ['Pickup', 'Delivery', 'Meet Halfway'],
              (val) {
                setState(() => _delivery = val!);
                _saveDraft();
              },
            ),
            const SizedBox(height: 16),
            buildDropdown(
              'Maximum Borrow Duration *',
              _duration,
              ['1 Day', '2 Days', '3 Days', '1 Week', '2 Weeks', 'Custom'],
              (val) {
                setState(() => _duration = val!);
                _saveDraft();
              },
            ),
            if (_duration == 'Custom') ...[
              const SizedBox(height: 16),
              buildTextField(
                  'Custom Duration (e.g. 3 Weeks) *',
                  _customDurationCtrl,
                  validator: (v) => v!.isEmpty
                      ? 'Enter custom duration limit'
                      : null),
            ],
            const SizedBox(height: 20),
            Text('Availability Period *',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            buildDateTile('Available From *', _availableFrom,
                () => _selectDate(context, true)),
            const SizedBox(height: 12),
            buildDateTile('Available Until (Optional)',
                _availableUntil,
                () => _selectDate(context, false)),
            const SizedBox(height: 16),
            buildTextField(
                'Safety Instructions (Optional)',
                _safetyCtrl,
                maxLines: 3,
                hint:
                    'PPE requirements, safe usage guidelines…'),
            const SizedBox(height: 20),
            buildAvailabilityToggle((val) {
              setState(() => _availability = val);
              _saveDraft();
            }),
          ],
        ),
      ];
    }
  }
}
