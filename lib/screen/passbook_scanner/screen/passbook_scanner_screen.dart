import 'package:flutter/material.dart';
import 'package:project/screen/card_scanner/widget/raw_ocr_view.dart';
import 'package:project/screen/card_scanner/widget/scan_image_preview.dart';
import 'package:project/screen/passbook_scanner/controller/passbook_scanner_controller.dart';
import 'package:project/screen/passbook_scanner/widget/passbook_data_view.dart';
import 'package:project/utils/app_colors.dart';
import 'package:project/utils/app_strings.dart';
import 'package:project/utils/custom_text.dart';
import 'package:project/widget/primary_button.dart';

class PassbookScannerScreen extends StatefulWidget {
  const PassbookScannerScreen({super.key});

  @override
  State<PassbookScannerScreen> createState() => _PassbookScannerScreenState();
}

class _PassbookScannerScreenState extends State<PassbookScannerScreen> {
  final PassbookScannerController _controller = PassbookScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const CustomText(AppStrings.passbookScannerTitle, color: AppColors.cardBackground, fontWeight: FontWeight.w700),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // User clicks this to open camera, scan passbook image, then parse OCR result.
                PrimaryButton(
                  label: AppStrings.openCamera,
                  icon: Icons.camera_alt,
                  onPressed: _controller.pickFromCameraAndScan,
                ),
                const SizedBox(height: 10),
                // User clicks this to pick passbook image from gallery, then parse result.
                PrimaryButton(
                  label: AppStrings.uploadImage,
                  icon: Icons.photo_library,
                  onPressed: _controller.pickFromGalleryAndScan,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _controller.toggleOcrDebugVisibility,
                    child: CustomText(
                      _controller.isOcrDebugVisible ? AppStrings.hideOcrDebug : AppStrings.showOcrDebug,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Selected image preview after camera/gallery action.
                ScanImagePreview(imageFile: _controller.selectedImage),
                const SizedBox(height: 16),
                // If OCR/parse fails then error shows, otherwise extracted bank details show.
                if (_controller.errorMessage != null)
                  CustomText(_controller.errorMessage!, color: AppColors.error)
                else if (_controller.extractedBankDetails != null)
                  PassbookDataView(bankDetails: _controller.extractedBankDetails!),
                // Optional raw OCR text section for debugging incorrect scans.
                if (_controller.isOcrDebugVisible) ...<Widget>[
                  const SizedBox(height: 16),
                  RawOcrView(rawText: _controller.rawOcrText),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
