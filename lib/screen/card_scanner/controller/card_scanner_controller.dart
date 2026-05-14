import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/models/card_details.dart';
import 'package:project/utils/app_strings.dart';
import 'package:project/utils/parsers/card_parser.dart';

class CardScannerController extends ChangeNotifier {
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final CardParser _cardParser = CardParser();

  File? selectedImage;
  CardDetails? extractedCardDetails;
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
  Future<void> _pickAndScan(ImageSource imageSource) async {
    try {
      final XFile? pickedFile = await _pickImageForSource(imageSource);
      if (pickedFile == null) {
        return;
      }

      selectedImage = File(pickedFile.path);
      errorMessage = null;
      extractedCardDetails = null;
      notifyListeners();

      final InputImage inputImage = InputImage.fromFilePath(pickedFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      rawOcrText = recognizedText.text;
      debugPrint('CARD OCR RAW START');
      debugPrint(rawOcrText);
      debugPrint('CARD OCR RAW END');
      final CardDetails parsedData = _cardParser.parseCard(recognizedText.text);
      debugPrint(
        'CARD PARSED => number: ${parsedData.cardNumber}, expiry: ${parsedData.expiryDate}, name: ${parsedData.cardHolderName}',
      );

      if (parsedData.cardNumber.isEmpty && parsedData.expiryDate.isEmpty && parsedData.cardHolderName.isEmpty) {
        errorMessage = AppStrings.noDataFoundError;
      } else {
        extractedCardDetails = parsedData;
      }
      notifyListeners();
    } catch (_) {
      errorMessage = AppStrings.scanFailedError;
      notifyListeners();
    }
  }

  Future<XFile?> _pickImageForSource(ImageSource imageSource) {
    if (imageSource == ImageSource.camera) {
      return _imagePicker.pickImage(
        source: imageSource,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 100,
        maxWidth: 2400,
        maxHeight: 2400,
      );
    }
    return _imagePicker.pickImage(source: imageSource);
  }

  // Toggles raw OCR debug panel visibility on card screen.
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
