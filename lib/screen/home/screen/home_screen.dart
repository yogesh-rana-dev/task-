import 'package:flutter/material.dart';
import 'package:project/screen/home/controller/home_controller.dart';
import 'package:project/screen/home/widget/scanner_option_card.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/utils/app_strings.dart';
import 'package:project/utils/custom_text.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController controller = HomeController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const CustomText(AppStrings.homeTitle, color: AppColors.cardBackground, fontWeight: FontWeight.w700),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText(AppStrings.homeSubtitle, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            // Click card option -> opens card scanner flow.
            ScannerOptionCard(
              title: AppStrings.cardScannerTitle,
              description: AppStrings.cardDescription,
              icon: Icons.credit_card,
              onTap: () => controller.openCardScanner(context),
            ),
            const SizedBox(height: 12),
            // Click passbook option -> opens passbook scanner flow.
            ScannerOptionCard(
              title: AppStrings.passbookScannerTitle,
              description: AppStrings.passbookDescription,
              icon: Icons.account_balance,
              onTap: () => controller.openPassbookScanner(context),
            ),
          ],
        ),
      ),
    );
  }
}
