import 'package:flutter/material.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/utils/custom_text.dart';

class LabelValueRow extends StatelessWidget {
  const LabelValueRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: CustomText(label, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          Expanded(
            flex: 6,
            child: CustomText(value, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
