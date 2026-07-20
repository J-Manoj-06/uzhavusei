import 'package:flutter/material.dart';
import 'details_theme.dart';

class DescriptionSection extends StatefulWidget {
  const DescriptionSection({
    super.key,
    required this.description,
  });

  final String description;

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final trimmedText = widget.description.trim();

    // Hide section completely if description is empty or blank
    if (trimmedText.isEmpty) {
      return const SizedBox.shrink();
    }

    final isLongText = trimmedText.length > 180;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DetailsTheme.outerPadding),
      child: Container(
        padding: const EdgeInsets.all(DetailsTheme.cardSpacing),
        decoration: BoxDecoration(
          color: DetailsTheme.surface,
          borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
          border: Border.all(color: DetailsTheme.border),
          boxShadow: DetailsTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: DetailsTheme.sectionHeadingStyle,
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              firstChild: Text(
                trimmedText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: DetailsTheme.bodyStyle,
              ),
              secondChild: Text(
                trimmedText,
                style: DetailsTheme.bodyStyle,
              ),
              crossFadeState: (_isExpanded || !isLongText)
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            if (isLongText) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Read Less' : 'Read More',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: DetailsTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: DetailsTheme.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
