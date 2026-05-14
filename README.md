# Technical Assignment - Mid-Level Flutter Developer

This project implements OCR-based **Card Scanner** and **Passbook Scanner** using Flutter, based on the assignment requirements.

## 1. Project Flow

1. Open app home screen.
2. Select scanner type:
   - Card Scanner
   - Passbook Scanner
3. Capture image (camera) or select image (gallery).
4. OCR reads raw text from image.
5. Manual parser extracts structured data.
6. UI shows:
   - Scanned image preview
   - Extracted fields
   - Error state (if parsing fails)
7. Optional: enable OCR debug view to inspect raw OCR text.

## 2. Features Implemented

### Card Scanner
- Camera and gallery support
- Extracts:
  - Card Number (masked)
  - Expiry Date
  - Card Holder Name
- Manual card parsing logic
- Luhn validation implemented manually

### Passbook Scanner
- Camera and gallery support
- Extracts:
  - Account Holder Name
  - Account Number
  - IFSC Code
- Manual passbook parsing logic with noisy OCR handling

## 3. Core Algorithms

- `CardDetails parseCard(String rawText)`
- `bool isValidCard(String cardNumber)` (Luhn)
- `BankDetails parsePassbook(String rawText)`

All parsing is implemented manually (no parsing library used).

## 4. Folder Structure

```text
lib/
  screen/
    home/
      screen/
      controller/
      widget/
    card_scanner/
      screen/
      controller/
      widget/
    passbook_scanner/
      screen/
      controller/
      widget/
  widget/        # common reusable widgets
  utils/         # app colors, strings, parser utilities, custom text
  models/
```

## 5. Setup and Run

### Prerequisites
- Flutter SDK (3.x)
- Android Studio / VS Code
- Android device/emulator

### Commands
```bash
flutter pub get
flutter run
```

## 6. Testing

Run tests:

```bash
flutter test
```

Covered tests:
- Card parser test
- Luhn validation test
- Passbook parser test
- OCR-noise regression cases

## 7. Libraries Used

- `image_picker`
- `google_mlkit_text_recognition`

## 8. Assumptions

- OCR quality depends on image clarity.
- Card/passbook text may contain OCR character confusion (`O/0`, `I/1`, etc.), handled with normalization rules.
- For passbook, account extraction prioritizes account-label context over CIF context.

## 9. What Was Skipped and Why

- iOS verification was not focused (assignment marks Android mandatory, iOS optional).
- Backend integration not added (as required: no backend needed).

## 10. Notes

- Raw OCR debug panel is available in both scanners for easier troubleshooting.
- UI follows centralized strings/colors/custom text usage for maintainability.
