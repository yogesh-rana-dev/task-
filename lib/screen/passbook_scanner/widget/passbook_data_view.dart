import 'package:flutter/material.dart';
import 'package:project/models/bank_details.dart';
import 'package:project/utils/app_strings.dart';
import 'package:project/utils/custom_text.dart';
import 'package:project/widget/app_section_card.dart';
import 'package:project/widget/label_value_row.dart';

class PassbookDataView extends StatelessWidget {
  const PassbookDataView({super.key, required this.bankDetails});

  final BankDetails bankDetails;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(AppStrings.extractedData, fontWeight: FontWeight.w700),
          const SizedBox(height: 12),
          LabelValueRow(
            label: AppStrings.accountHolderLabel,
            value: bankDetails.accountHolderName.isEmpty ? AppStrings.missingValue : bankDetails.accountHolderName,
          ),
          LabelValueRow(
            label: AppStrings.accountNumberLabel,
            value: bankDetails.accountNumber.isEmpty ? AppStrings.missingValue : bankDetails.accountNumber,
          ),
          LabelValueRow(
            label: AppStrings.ifscLabel,
            value: bankDetails.ifscCode.isEmpty ? AppStrings.missingValue : bankDetails.ifscCode,
          ),
        ],
      ),
    );
  }
}
