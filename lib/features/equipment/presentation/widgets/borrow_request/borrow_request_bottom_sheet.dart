import 'package:flutter/material.dart';
import 'package:UzhavuSei/models/marketplace_equipment_model.dart';
import 'package:UzhavuSei/models/borrow_request_model.dart';
import 'package:UzhavuSei/services/borrow_request_repository.dart';
import 'package:UzhavuSei/widgets/image_loader.dart';
import 'package:intl/intl.dart';
import '../details/details_theme.dart';
import 'borrow_date_selector.dart';
import 'borrow_duration_card.dart';
import 'borrow_rules_checklist.dart';
import 'borrow_request_success_dialog.dart';

class BorrowRequestBottomSheet extends StatefulWidget {
  const BorrowRequestBottomSheet({
    super.key,
    required this.equipment,
    required this.borrowerId,
    this.borrowerName = 'Borrower',
    this.initialStartDate,
    this.initialEndDate,
  });

  final MarketplaceEquipmentModel equipment;
  final String borrowerId;
  final String borrowerName;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  static Future<void> show({
    required BuildContext context,
    required MarketplaceEquipmentModel equipment,
    required String borrowerId,
    String borrowerName = 'Borrower',
    DateTime? initialStartDate,
    DateTime? initialEndDate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BorrowRequestBottomSheet(
        equipment: equipment,
        borrowerId: borrowerId,
        borrowerName: borrowerName,
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
      ),
    );
  }

  @override
  State<BorrowRequestBottomSheet> createState() =>
      _BorrowRequestBottomSheetState();
}

class _BorrowRequestBottomSheetState extends State<BorrowRequestBottomSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _noteCtrl = TextEditingController();
  bool _rulesAccepted = false;
  bool _isPreviewMode = false;
  bool _isLoading = false;

  final BorrowRequestRepository _repository = BorrowRequestRepository();

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_isLoading) return false;
    if (_startDate == null || _endDate == null) return false;
    if (_endDate!.isBefore(_startDate!)) return false;
    if (!_rulesAccepted) return false;
    return true;
  }

  Future<void> _handleSendRequest() async {
    if (!_isValid || _isLoading) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final durationDays = _endDate!.difference(_startDate!).inDays + 1;
    final image = widget.equipment.imageUrls.isNotEmpty
        ? widget.equipment.imageUrls.first
        : 'assets/logo.jpg';

    final requestModel = BorrowRequestModel(
      requestId: '',
      listingId: widget.equipment.equipmentId,
      listingTitle: widget.equipment.equipmentName,
      listingImage: image,
      category: widget.equipment.category,
      ownerId: widget.equipment.ownerId,
      borrowerId: widget.borrowerId,
      borrowerName: widget.borrowerName,
      borrowFrom: _startDate!,
      borrowUntil: _endDate!,
      borrowDuration: durationDays,
      status: 'Requested',
      requestedAt: now,
      updatedAt: now,
    );

    try {
      await _repository.createBorrowRequest(requestModel);

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        BorrowRequestSuccessDialog.show(
          context,
          borrowerId: widget.borrowerId,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.equipment.imageUrls.isNotEmpty
        ? widget.equipment.imageUrls.first
        : 'assets/logo.jpg';

    final pickupArea = widget.equipment.area.isNotEmpty
        ? widget.equipment.area
        : (widget.equipment.location.isNotEmpty
            ? widget.equipment.location
            : 'Nearby Area');

    return Container(
      padding: EdgeInsets.only(
        left: DetailsTheme.outerPadding,
        right: DetailsTheme.outerPadding,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      decoration: const BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: DetailsTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isPreviewMode ? 'Request Preview' : 'Request to Borrow',
                  style: DetailsTheme.sectionHeadingStyle,
                ),
                if (_isPreviewMode)
                  TextButton.icon(
                    onPressed: () => setState(() => _isPreviewMode = false),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            if (!_isPreviewMode) ...[
              // 📦 Borrow Summary Header
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: buildSmartImage(image, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.equipment.equipmentName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: DetailsTheme.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: DetailsTheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.equipment.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: DetailsTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Owner: ${widget.equipment.ownerName}',
                                style: DetailsTheme.captionStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined,
                                size: 14, color: DetailsTheme.secondaryText),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Pickup: $pickupArea',
                                style: DetailsTheme.captionStyle,
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

              const SizedBox(height: 16),
              const Divider(height: 1, color: DetailsTheme.border),
              const SizedBox(height: 16),

              // 📅 Borrow Dates Selector
              BorrowDateSelector(
                startDate: _startDate,
                endDate: _endDate,
                onStartDateSelected: (date) {
                  setState(() {
                    _startDate = date;
                    if (_endDate == null || _endDate!.isBefore(_startDate!)) {
                      _endDate = _startDate;
                    }
                  });
                },
                onEndDateSelected: (date) {
                  setState(() {
                    _endDate = date;
                  });
                },
              ),

              const SizedBox(height: 14),

              // 📆 Duration Card
              BorrowDurationCard(
                startDate: _startDate,
                endDate: _endDate,
              ),

              const SizedBox(height: 14),

              // ✍ Optional Request Note
              TextField(
                controller: _noteCtrl,
                maxLength: 200,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Reason for borrowing (Optional)',
                  hintText: 'Brief explanation for the owner...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: DetailsTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: DetailsTheme.primary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 📋 Borrow Rules Checklist
              BorrowRulesChecklist(
                onChanged: (accepted) {
                  setState(() => _rulesAccepted = accepted);
                },
              ),

              const SizedBox(height: 20),
            ] else ...[
              // 🔍 STEP 2: REQUEST PREVIEW MODE
              _buildRequestPreviewCard(image, pickupArea),
              const SizedBox(height: 20),
            ],

            // Bottom Actions Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DetailsTheme.secondaryText,
                      side: const BorderSide(color: DetailsTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: _isValid
                          ? const LinearGradient(
                              colors: [
                                DetailsTheme.primary,
                                Color(0xFF1D4ED8),
                              ],
                            )
                          : null,
                      color: _isValid ? null : DetailsTheme.border,
                      boxShadow: _isValid
                          ? [
                              BoxShadow(
                                color: DetailsTheme.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _isValid
                          ? (_isPreviewMode
                              ? _handleSendRequest
                              : () => setState(() => _isPreviewMode = true))
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isPreviewMode ? 'Confirm & Send' : 'Preview Request',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestPreviewCard(String image, String pickupArea) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final durationDays = _endDate!.difference(_startDate!).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DetailsTheme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DetailsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: buildSmartImage(image, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.equipment.equipmentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DetailsTheme.text,
                      ),
                    ),
                    Text(
                      'Owner: ${widget.equipment.ownerName}',
                      style: DetailsTheme.captionStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: DetailsTheme.border),
          const SizedBox(height: 12),
          _buildPreviewRow('Borrow Period',
              '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}'),
          _buildPreviewRow('Duration',
              '$durationDays ${durationDays == 1 ? "Day" : "Days"}'),
          _buildPreviewRow('Pickup Area', pickupArea),
          if (_noteCtrl.text.trim().isNotEmpty)
            _buildPreviewRow('Note', _noteCtrl.text.trim()),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: DetailsTheme.captionStyle),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: DetailsTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
