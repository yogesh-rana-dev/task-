import 'package:flutter_test/flutter_test.dart';
import 'package:project/utils/parsers/card_parser.dart';

void main() {
  final CardParser parser = CardParser();

  test('Card parser extracts card number, expiry and name', () {
    const String rawText = 'JOHN DOE\n4111 1111 1111 1111\nVALID THRU 12/25';
    final result = parser.parseCard(rawText);

    expect(result.cardNumber, 'XXXX XXXX XXXX 1111');
    expect(result.expiryDate, '12/25');
    expect(result.cardHolderName, 'JOHN DOE');
  });

  test('Luhn validation works for valid and invalid cards', () {
    expect(parser.isValidCard('4111111111111111'), true);
    expect(parser.isValidCard('4111111111111112'), false);
  });

  test('Card parser ignores brand lines and placeholder holder labels', () {
    const String rawText = 'Visa Classic\n4000 1234 5678 9010\nCARDHOLDER NAME\nVALID THRU 12/20';
    final result = parser.parseCard(rawText);

    expect(result.cardNumber, 'XXXX XXXX XXXX 9010');
    expect(result.expiryDate, '12/20');
    expect(result.cardHolderName, '');
  });

  test('Card parser supports dotted initials in holder name', () {
    const String rawText = 'Visa Infinite\n4000 1234 5678 9010\nGOOD THRU 12/20\nG. RAYMOND';
    final result = parser.parseCard(rawText);

    expect(result.cardNumber, 'XXXX XXXX XXXX 9010');
    expect(result.expiryDate, '12/20');
    expect(result.cardHolderName, 'G RAYMOND');
  });

  test('Card parser maps OCR digits in holder name', () {
    const String rawText = 'B0RDA HARDIX\nVALID FROM 08/23\nVALID THRU 08/30\n5241 2351 8089 9005';
    final result = parser.parseCard(rawText);

    expect(result.cardHolderName, 'BORDA HARDIX');
  });
}
