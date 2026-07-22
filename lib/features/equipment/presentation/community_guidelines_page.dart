import 'package:flutter/material.dart';
import 'widgets/details/details_theme.dart';

class CommunityGuidelinesPage extends StatelessWidget {
  const CommunityGuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final guidelines = [
      _GuidelineItem(
        icon: Icons.sanitizer_rounded,
        title: 'Respect Borrowed Items',
        description:
            'Treat every shared item with care. Keep equipment clean and return it in original condition.',
      ),
      _GuidelineItem(
        icon: Icons.alarm_on_rounded,
        title: 'Return on Time',
        description:
            'Honour agreed handover and return dates. Communicate early if an unexpected delay arises.',
      ),
      _GuidelineItem(
        icon: Icons.record_voice_over_rounded,
        title: 'Communicate Honestly',
        description:
            'Be clear about pickup times, item condition, and expectations. Transparency builds trust.',
      ),
      _GuidelineItem(
        icon: Icons.checklist_rtl_rounded,
        title: 'Keep Listings Accurate',
        description:
            'Upload clear photos and accurate specifications for your shared resources.',
      ),
      _GuidelineItem(
        icon: Icons.favorite_rounded,
        title: 'Treat Everyone Respectfully',
        description:
            'Maintain a polite, helpful, and friendly attitude in every community interaction.',
      ),
    ];

    return Scaffold(
      backgroundColor: DetailsTheme.background,
      appBar: AppBar(
        backgroundColor: DetailsTheme.surface,
        foregroundColor: DetailsTheme.text,
        elevation: 0.5,
        title: const Text(
          'Community Guidelines',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: DetailsTheme.text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DetailsTheme.outerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DetailsTheme.primaryContainer,
                borderRadius: BorderRadius.circular(DetailsTheme.cardRadius),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 28, color: DetailsTheme.primary),
                      SizedBox(width: 10),
                      Text(
                        'Trust & Safety Principles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: DetailsTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Borrow is built on mutual trust and community sharing. Following these guidelines ensures a positive experience for everyone.',
                    style: TextStyle(
                      fontSize: 14,
                      color: DetailsTheme.text,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Guidelines List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: guidelines.length,
              itemBuilder: (context, index) {
                final item = guidelines[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DetailsTheme.surface,
                    borderRadius:
                        BorderRadius.circular(DetailsTheme.cardRadius),
                    border: Border.all(color: DetailsTheme.border),
                    boxShadow: DetailsTheme.cardShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DetailsTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon,
                            size: 22, color: DetailsTheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: DetailsTheme.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: DetailsTheme.captionStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineItem {
  final IconData icon;
  final String title;
  final String description;

  _GuidelineItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
