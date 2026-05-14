import 'package:project/models/card_details.dart';

class CardParser {
  CardDetails parseCard(String rawText) {
    final String cleanedText = rawText;
    final List<String> lines = cleanedText
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();

    final String validCardNumber = _extractBestCardNumber(lines);

    String expiryDate = '';
    final String fullTextUpper = cleanedText.toUpperCase();
    final RegExp labelledExpiryPattern = RegExp(
      r'(?:EXP|EXPIRY|VALID\s*THRU|VALID\s*UPTO)\D{0,12}(0[1-9]|1[0-2])[\/-]?([0-9OIl]{2})',
      caseSensitive: false,
    );
    final RegExpMatch? labelledMatch = labelledExpiryPattern.firstMatch(fullTextUpper);
    if (labelledMatch != null) {
      final String month = labelledMatch.group(1) ?? '';
      final String year = _normalizeOcrDigits(labelledMatch.group(2) ?? '');
      expiryDate = '$month/$year';
    } else {
      for (final String line in lines) {
        if (RegExp(r'\d{6,}').hasMatch(line.replaceAll(RegExp(r'\s+'), ''))) {
          continue;
        }
        final String normalizedLine = _normalizeOcrDigits(line);
        final RegExpMatch? plainMatch = RegExp(r'\b(0[1-9]|1[0-2])[\/-]([0-9]{2})\b').firstMatch(normalizedLine);
        if (plainMatch != null) {
          final String month = plainMatch.group(1) ?? '';
          final String year = plainMatch.group(2) ?? '';
          expiryDate = '$month/$year';
          break;
        }
      }
    }

    String cardHolderName = _extractNameFromLabelLine(lines);
    const List<String> blockedNameTokens = <String>[
      'VISA',
      'MASTERCARD',
      'RUPAY',
      'CLASSIC',
      'PLATINUM',
      'DEBIT',
      'CREDIT',
      'CARD',
      'BANK',
      'VALID',
      'THRU',
      'EXP',
      'EXPIRY',
      'NAME',
      'CARDHOLDER',
      'GOOD',
      'THRU',
      'VALID',
      'INFINITE',
    ];

    if (cardHolderName.isEmpty) {
      for (final String line in lines) {
        final String normalizedForName = _normalizeNameOcr(line);
        final String upperLine = normalizedForName.toUpperCase();
        final String normalizedName = normalizedForName.replaceAll('.', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        final bool looksLikeName = RegExp(r'^[A-Z. ]{4,}$').hasMatch(upperLine);
        final bool hasNoDigits = !RegExp(r'\d').hasMatch(normalizedForName);
        final bool hasBlockedToken = blockedNameTokens.any((String token) => upperLine.contains(token));
        final List<String> nameParts = normalizedName.split(' ').where((String p) => p.isNotEmpty).toList();
        final bool hasAtLeastTwoParts = nameParts.length >= 2;
        if (looksLikeName && hasNoDigits && !hasBlockedToken && hasAtLeastTwoParts) {
          cardHolderName = normalizedName;
          break;
        }
      }
    }

    return CardDetails(
      cardNumber: maskCardNumber(validCardNumber),
      expiryDate: expiryDate,
      cardHolderName: cardHolderName,
    );
  }

  String maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) {
      return '';
    }
    final String lastFourDigits = cardNumber.substring(cardNumber.length - 4);
    return 'XXXX XXXX XXXX $lastFourDigits';
  }

  bool isValidCard(String cardNumber) {
    int sum = 0;
    bool shouldDouble = false;

    for (int index = cardNumber.length - 1; index >= 0; index--) {
      int digit = int.parse(cardNumber[index]);
      if (shouldDouble) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      shouldDouble = !shouldDouble;
    }

    return sum % 10 == 0;
  }

  String _normalizeOcrDigits(String value) {
    return value
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('S', '5')
        .replaceAll('s', '5')
        .replaceAll('B', '8')
        .replaceAll('b', '6')
        .replaceAll('G', '6')
        .replaceAll('Z', '2')
        .replaceAll('?', '');
  }

  String _normalizeNameOcr(String value) {
    return value
        .replaceAll('0', 'O')
        .replaceAll('1', 'I')
        .replaceAll('5', 'S')
        .replaceAll('8', 'B');
  }

  String _extractBestCardNumber(List<String> lines) {
    final List<({String digits, int substitutions})> prioritizedCandidates = <({String digits, int substitutions})>[];
    final List<String> fallbackCandidates = <String>[];

    for (final String line in lines) {
      final List<String> rawGroups =
          RegExp(r'[A-Za-z0-9]{2,6}').allMatches(line).map((RegExpMatch m) => m.group(0) ?? '').toList();
      if (rawGroups.length < 3) {
        continue;
      }

      List<({String digits, int substitutions})> lineVariants = <({String digits, int substitutions})>[
        (digits: '', substitutions: 0),
      ];

      for (final String group in rawGroups) {
        final List<({String digits, int substitutions})> tokenVariants = _buildTokenVariants(group);
        if (tokenVariants.isEmpty) {
          continue;
        }

        final List<({String digits, int substitutions})> next = <({String digits, int substitutions})>[];
        for (final previous in lineVariants) {
          for (final token in tokenVariants) {
            final String combinedDigits = '${previous.digits}${token.digits}';
            if (combinedDigits.length > 19) {
              continue;
            }
            next.add((digits: combinedDigits, substitutions: previous.substitutions + token.substitutions));
          }
        }
        lineVariants = next;
        if (lineVariants.length > 300) {
          lineVariants = lineVariants.take(300).toList();
        }
      }

      for (final variant in lineVariants) {
        if (variant.digits.length >= 13 && variant.digits.length <= 19) {
          prioritizedCandidates.add(variant);
        }
      }
    }

    ({String digits, int score})? best;
    for (final candidate in prioritizedCandidates) {
      int score = 0;
      if (isValidCard(candidate.digits)) {
        score += 120;
      }
      if (candidate.digits.length == 16) {
        score += 30;
      } else if (candidate.digits.length == 15) {
        score += 20;
      }
      score -= candidate.substitutions * 2;
      if (best == null || score > best.score) {
        best = (digits: candidate.digits, score: score);
      }
    }

    if (best != null) {
      return best.digits;
    }

    for (final String line in lines) {
      final String normalizedLine = _normalizeOcrDigits(line);
      final String digitsOnly = normalizedLine.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length >= 13 && digitsOnly.length <= 19) {
        fallbackCandidates.add(digitsOnly);
      }
    }

    for (final String candidate in fallbackCandidates) {
      if (isValidCard(candidate)) {
        return candidate;
      }
    }

    for (final String candidate in fallbackCandidates) {
      if (candidate.length == 16 || candidate.length == 15) {
        return candidate;
      }
    }

    return '';
  }

  List<({String digits, int substitutions})> _buildTokenVariants(String token) {
    List<({String digits, int substitutions})> variants = <({String digits, int substitutions})>[
      (digits: '', substitutions: 0),
    ];

    for (final int codeUnit in token.codeUnits) {
      final String char = String.fromCharCode(codeUnit);
      final List<({String digit, int substitutions})> options = _charOptions(char);
      if (options.isEmpty) {
        continue;
      }

      final List<({String digits, int substitutions})> next = <({String digits, int substitutions})>[];
      for (final previous in variants) {
        for (final option in options) {
          next.add((digits: '${previous.digits}${option.digit}', substitutions: previous.substitutions + option.substitutions));
        }
      }
      variants = next;
      if (variants.length > 40) {
        variants = variants.take(40).toList();
      }
    }

    return variants.where((v) => v.digits.isNotEmpty).toList();
  }

  List<({String digit, int substitutions})> _charOptions(String char) {
    if (RegExp(r'^[0-9]$').hasMatch(char)) {
      return <({String digit, int substitutions})>[(digit: char, substitutions: 0)];
    }

    switch (char.toUpperCase()) {
      case 'O':
      case 'D':
      case 'Q':
        return <({String digit, int substitutions})>[(digit: '0', substitutions: 1)];
      case 'I':
      case 'L':
        return <({String digit, int substitutions})>[(digit: '1', substitutions: 1)];
      case 'Z':
        return <({String digit, int substitutions})>[(digit: '2', substitutions: 1)];
      case 'E':
        return <({String digit, int substitutions})>[(digit: '2', substitutions: 1), (digit: '3', substitutions: 1)];
      case 'A':
        return <({String digit, int substitutions})>[(digit: '4', substitutions: 1)];
      case 'S':
        return <({String digit, int substitutions})>[(digit: '5', substitutions: 1)];
      case 'G':
        return <({String digit, int substitutions})>[(digit: '6', substitutions: 1)];
      case 'T':
        return <({String digit, int substitutions})>[(digit: '7', substitutions: 1)];
      case 'B':
        return <({String digit, int substitutions})>[(digit: '8', substitutions: 1)];
      case 'Y':
        return <({String digit, int substitutions})>[(digit: '4', substitutions: 1), (digit: '7', substitutions: 1)];
      default:
        return const <({String digit, int substitutions})>[];
    }
  }

  String _extractNameFromLabelLine(List<String> lines) {
    for (final String line in lines) {
      final String upper = line.toUpperCase();
      if (!upper.contains('CARDHOLDER')) {
        continue;
      }

      final List<String> splitByLabel = upper.split('CARDHOLDER');
      if (splitByLabel.length < 2) {
        continue;
      }

      final String originalAfterLabel = line.substring(line.toUpperCase().indexOf('CARDHOLDER') + 'CARDHOLDER'.length).trim();
      final String cleaned = originalAfterLabel
          .replaceAll(RegExp(r'[:\-]'), ' ')
          .replaceAll(RegExp(r'\bNAME\b', caseSensitive: false), '')
          .replaceAll('.', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final List<String> parts = cleaned.split(' ').where((String p) => p.isNotEmpty).toList();
      if (parts.length >= 2 && !RegExp(r'\d').hasMatch(cleaned)) {
        return cleaned;
      }
    }
    return '';
  }
}
