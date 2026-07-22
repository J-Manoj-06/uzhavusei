import 'package:flutter/material.dart';
import '../details/details_theme.dart';

class BorrowRulesChecklist extends StatefulWidget {
  const BorrowRulesChecklist({
    super.key,
    required this.onChanged,
  });

  final ValueChanged<bool> onChanged;

  @override
  State<BorrowRulesChecklist> createState() => _BorrowRulesChecklistState();
}

class _BorrowRulesChecklistState extends State<BorrowRulesChecklist> {
  bool _rule1 = false;
  bool _rule2 = false;
  bool _rule3 = false;

  void _update() {
    final allChecked = _rule1 && _rule2 && _rule3;
    widget.onChanged(allChecked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DetailsTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DetailsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel_rounded, size: 18, color: DetailsTheme.primary),
              SizedBox(width: 8),
              Text(
                'Borrowing Agreement',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: DetailsTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildCheckItem(
            value: _rule1,
            title: 'I will return the item on time.',
            onChanged: (val) {
              setState(() => _rule1 = val ?? false);
              _update();
            },
          ),
          _buildCheckItem(
            value: _rule2,
            title: 'I will use the item responsibly.',
            onChanged: (val) {
              setState(() => _rule2 = val ?? false);
              _update();
            },
          ),
          _buildCheckItem(
            value: _rule3,
            title: 'I agree to community borrowing guidelines.',
            onChanged: (val) {
              setState(() => _rule3 = val ?? false);
              _update();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required bool value,
    required String title,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: DetailsTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DetailsTheme.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
