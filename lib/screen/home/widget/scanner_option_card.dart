import 'package:flutter/material.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/utils/custom_text.dart';
import 'package:project/widget/app_section_card.dart';

class ScannerOptionCard extends StatelessWidget {
  const ScannerOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AppSectionCard(
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(title, fontSize: 16, fontWeight: FontWeight.w700),
                  const SizedBox(height: 4),
                  CustomText(description, color: AppColors.textSecondary),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
