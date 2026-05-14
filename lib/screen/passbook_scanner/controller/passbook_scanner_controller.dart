import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/models/bank_details.dart';
import 'package:project/utils/app_strings.dart';
import 'package:project/utils/parsers/passbook_parser.dart';

class PassbookScannerController extends ChangeNotifier {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final PassbookParser _passbookParser = PassbookParser();

  File? selectedImage;
  BankDetails? extractedBankDetails;
  String? errorMessage;
  String rawOcrText = '';
  bool isOcrDebugVisible = false;

  // Picks image from camera and runs OCR scan.
  Future<void> pickFromCameraAndScan() async {
    await _pickAndScan(ImageSource.camera);
  }

  // Picks image from gallery and runs OCR scan.
  Future<void> pickFromGalleryAndScan() async {
    await _pickAndScan(ImageSource.gallery);
  }

  // Shared scan pipeline used by both camera and gallery.
  Future<void> _pickAndScan(ImageSource source) async {
    try {
      final XFile? pickedFile = await _pickImageForSource(source);
      if (pickedFile == null) {
        return;
      }

      selectedImage = File(pickedFile.path);
      extractedBankDetails = null;
      errorMessage = null;
      notifyListeners();

      final InputImage inputImage = InputImage.fromFilePath(pickedFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      rawOcrText = recognizedText.text;
      debugPrint('PASSBOOK OCR RAW START');
      debugPrint(rawOcrText);
      debugPrint('PASSBOOK OCR RAW END');
      final BankDetails parsedData = _passbookParser.parsePassbook(recognizedText.text);
      debugPrint(
        'PASSBOOK PARSED => name: ${parsedData.accountHolderName}, account: ${parsedData.accountNumber}, ifsc: ${parsedData.ifscCode}',
      );

      if (parsedData.accountHolderName.isEmpty && parsedData.accountNumber.isEmpty && parsedData.ifscCode.isEmpty) {
        errorMessage = AppStrings.noDataFoundError;
      } else {
        extractedBankDetails = parsedData;
      }
      notifyListeners();
    } catch (_) {
      errorMessage = AppStrings.scanFailedError;
      notifyListeners();
    }
  }

  Future<XFile?> _pickImageForSource(ImageSource source) {
    if (source == ImageSource.camera) {
      return _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 100,
        maxWidth: 2400,
        maxHeight: 2400,
      );
    }
    return _imagePicker.pickImage(source: source);
  }

  // Toggles raw OCR debug panel visibility on passbook screen.
  void toggleOcrDebugVisibility() {
    isOcrDebugVisible = !isOcrDebugVisible;
    notifyListeners();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}
