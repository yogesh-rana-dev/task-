import 'package:flutter/material.dart';
import 'package:project/models/card_details.dart';
import 'package:project/utils/app_strings.dart';
import 'package:project/utils/custom_text.dart';
import 'package:project/widget/app_section_card.dart';
import 'package:project/widget/label_value_row.dart';

class CardDataView extends StatelessWidget {
  const CardDataView({super.key, required this.cardDetails});

  final CardDetails cardDetails;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(AppStrings.extractedData, fontWeight: FontWeight.w700),
          const SizedBox(height: 12),
          LabelValueRow(
            label: AppStrings.cardNumberLabel,
            value: cardDetails.cardNumber.isEmpty ? AppStrings.missingValue : cardDetails.cardNumber,
          ),
          LabelValueRow(
            label: AppStrings.expiryLabel,
            value: cardDetails.expiryDate.isEmpty ? AppStrings.missingValue : cardDetails.expiryDate,
          ),
          LabelValueRow(
            label: AppStrings.cardHolderLabel,
            value: cardDetails.cardHolderName.isEmpty ? AppStrings.missingValue : cardDetails.cardHolderName,
          ),
        ],
      ),
    );
  }
}
