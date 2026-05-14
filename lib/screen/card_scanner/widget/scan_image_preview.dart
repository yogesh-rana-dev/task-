import 'dart:io';

import 'package:flutter/material.dart';
import 'package:project/utils/app_strings.dart';
import 'package:project/utils/custom_text.dart';
import 'package:project/widget/app_section_card.dart';

class ScanImagePreview extends StatelessWidget {
  const ScanImagePreview({super.key, required this.imageFile});

  final File? imageFile;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(AppStrings.scanImagePreview, fontWeight: FontWeight.w700),
          const SizedBox(height: 12),
          if (imageFile == null)
            const CustomText(AppStrings.noImageSelected)
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
        ],
      ),
    );
  }
}
