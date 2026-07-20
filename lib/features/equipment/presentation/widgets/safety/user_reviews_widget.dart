import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:UzhavuSei/models/review_model.dart';
import 'package:UzhavuSei/services/review_repository.dart';
import '../details/details_theme.dart';

class UserReviewsWidget extends StatelessWidget {
  UserReviewsWidget({
    super.key,
    required this.userId,
  });

  final String userId;
  final ReviewRepository _repository = ReviewRepository();

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return StreamBuilder<List<ReviewModel>>(
      stream: _repository.watchUserReviews(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: DetailsTheme.primary),
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DetailsTheme.surface,
              borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
              border: Border.all(color: DetailsTheme.border),
            ),
            child: const Center(
              child: Text(
                'No reviews yet.',
                style: DetailsTheme.captionStyle,
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DetailsTheme.surface,
            borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
            border: Border.all(color: DetailsTheme.border),
            boxShadow: DetailsTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community Reviews (${reviews.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DetailsTheme.text,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (ctx, i) =>
                    const Divider(height: 20, color: DetailsTheme.border),
                itemBuilder: (ctx, index) {
                  final r = reviews[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: DetailsTheme.primaryContainer,
                            child: Text(
                              r.reviewerName.isNotEmpty
                                  ? r.reviewerName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: DetailsTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.reviewerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: DetailsTheme.text,
                                  ),
                                ),
                                Text(
                                  dateFormat.format(r.createdAt),
                                  style: DetailsTheme.captionStyle,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(5, (starIdx) {
                              return Icon(
                                starIdx < r.rating.floor()
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 16,
                                color: Colors.amber.shade700,
                              );
                            }),
                          ),
                        ],
                      ),
                      if (r.comment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          r.comment,
                          style: const TextStyle(
                            fontSize: 13,
                            color: DetailsTheme.text,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
