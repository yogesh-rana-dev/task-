import 'package:flutter/material.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/utils/app_strings.dart';
import 'package:project/utils/custom_text.dart';
import 'package:project/widget/app_section_card.dart';

class RawOcrView extends StatelessWidget {
  const RawOcrView({super.key, required this.rawText});

  final String rawText;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(AppStrings.rawOcrTextTitle, fontWeight: FontWeight.w700),
          const SizedBox(height: 10),
          CustomText(
            rawText.trim().isEmpty ? AppStrings.noOcrText : rawText,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
