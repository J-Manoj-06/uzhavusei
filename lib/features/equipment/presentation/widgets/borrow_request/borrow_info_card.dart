import 'package:flutter/material.dart';
import '../details/details_theme.dart';

class BorrowInfoCard extends StatelessWidget {
  const BorrowInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DetailsTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DetailsTheme.border),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 18,
            color: DetailsTheme.primary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your request will be sent to the owner for approval.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DetailsTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
