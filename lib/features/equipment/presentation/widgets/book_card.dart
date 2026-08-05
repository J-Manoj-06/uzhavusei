import 'package:flutter/material.dart';
import '../../../../models/book_model.dart';
import '../../../../widgets/image_loader.dart';
import '../../../../theme/app_theme.dart';

/// A polished card widget that displays a single [BookModel].
/// Shows: cover image, title, author, category chip, available/total count,
/// and a colour-coded status badge.
class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;
  final VoidCallback? onFavourite;
  final bool isFavourite;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onFavourite,
    this.isFavourite = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(book);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover Image ──────────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // Book cover
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      width: double.infinity,
                      child: buildSmartImage(
                        book.coverImage,
                        fit: BoxFit.cover,
                        isBook: true,
                      ),
                    ),
                  ),

                  // Category chip — top left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.60),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        book.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Status badge — top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusInfo.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusInfo.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Favourite button — if callback provided
                  if (onFavourite != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onFavourite,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.85),
                          child: Icon(
                            isFavourite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                isFavourite ? Colors.red : Colors.grey.shade600,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Book info ────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),

                    // Author
                    Text(
                      book.author.isNotEmpty ? book.author : 'Unknown Author',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Department (if applicable)
                    if (book.department.trim().isNotEmpty)
                      Text(
                        book.department,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    // Available / Total copies row
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusInfo.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            book.availableCopies > 0
                                ? '${book.availableCopies} Available'
                                : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: statusInfo.color,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Borrow Now button
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: ElevatedButton(
                        onPressed: book.availableCopies > 0 ? onTap : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          book.availableCopies > 0 ? 'Borrow Now' : 'Out of Stock',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusInfo _getStatusInfo(BookModel book) {
    if (book.availableCopies <= 0) {
      return _StatusInfo('Out of Stock', const Color(0xFFEF4444));
    }
    if (book.availableCopies <= 2) {
      return _StatusInfo('Low Stock', const Color(0xFFF97316));
    }
    return _StatusInfo('Available', const Color(0xFF22C55E));
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}
