import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:UzhavuSei/models/borrow_request_model.dart';
import '../../widgets/details/details_theme.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    required this.request,
    required this.revieweeName,
    required this.onSubmit,
  });

  final BorrowRequestModel request;
  final String revieweeName;
  final Function(double rating, String comment) onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final fromStr = dateFormat.format(widget.request.borrowFrom);
    final toStr = dateFormat.format(widget.request.borrowUntil);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: DetailsTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: DetailsTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 40,
                  color: DetailsTheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Rate Experience with ${widget.revieweeName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DetailsTheme.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.request.listingTitle} • $fromStr - $toStr',
                textAlign: TextAlign.center,
                style: DetailsTheme.captionStyle,
              ),

              const SizedBox(height: 20),

              // Interactive 5 Star Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return IconButton(
                    iconSize: 36,
                    icon: Icon(
                      starVal <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: starVal <= _rating
                          ? Colors.amber.shade700
                          : Colors.grey.shade400,
                    ),
                    onPressed: () {
                      setState(() => _rating = starVal.toDouble());
                    },
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Optional Comment TextField
              TextField(
                controller: _commentController,
                maxLength: 250,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add an optional comment (max 250 chars)...',
                  hintStyle: const TextStyle(fontSize: 13),
                  isDense: true,
                  filled: true,
                  fillColor: DetailsTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: DetailsTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: DetailsTheme.border),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: DetailsTheme.secondaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSubmit(_rating, _commentController.text.trim());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DetailsTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Review',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
}
