import 'package:project/models/bank_details.dart';

class PassbookParser {
  BankDetails parsePassbook(String rawText) {
    final String cleanedText = rawText;
    final List<String> lines = cleanedText
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();

    final String accountNumber = _extractAccountNumber(lines);
    final String ifscCode = _extractIfscCode(lines, cleanedText);
    final String accountHolderName = _extractAccountHolderName(lines);

    return BankDetails(
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
    );
  }

  String _extractAccountNumber(List<String> lines) {
    final RegExp accountLinePattern = RegExp(r'(A/C|ACCT|ACCOUNT|ACC\.?\s*NO|A\s*/\s*C)', caseSensitive: false);
    final RegExp cifPattern = RegExp(r'\bCIF\b', caseSensitive: false);
    final RegExp accountLabelPattern = RegExp(
      r'(ACCOUNT\s*(NO|N0|NUMBER)?|ACCT\s*(NO|N0)?|ACC\s*(NO|N0)?|A/C\s*(NO|N0)?|A\s*/\s*C|ACR)',
      caseSensitive: false,
    );

    final List<String> prioritized = <String>[];
    final List<String> fallback = <String>[];
    final List<String> cifCandidates = <String>[];
    final List<({String value, int lineIndex, String upperLine})> orderedCandidates =
        <({String value, int lineIndex, String upperLine})>[];
    final List<int> accountLabelLineIndexes = <int>[];
    bool hasAnyAccountLabel = false;
    bool hasCifLabel = false;

    for (final String line in lines) {
      if (cifPattern.hasMatch(line)) {
        hasCifLabel = true;
      }
    }

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];
      final String upperLine = line.toUpperCase();
      if (accountLabelPattern.hasMatch(upperLine)) {
        accountLabelLineIndexes.add(index);
      }

      // Hard priority: if account label is present in this same line,
      // pick only number that appears after account label in the same line.
      final String scopedSameLine = _textAfterAccountLabel(line);
      if (scopedSameLine.isNotEmpty) {
        final List<String> scopedSameLineCandidates = _extractDigitCandidates(scopedSameLine);
        if (scopedSameLineCandidates.isNotEmpty) {
          scopedSameLineCandidates.sort((String a, String b) => b.length.compareTo(a.length));
          return scopedSameLineCandidates.first;
        }
      }

      final String accountScopedText = _textAfterAccountLabel(line);
      if (accountScopedText.isEmpty) {
        // continue to generic harvesting below
      } else {
        hasAnyAccountLabel = true;

        final List<String> scopedCandidates = _extractDigitCandidates(accountScopedText);
        for (final String value in scopedCandidates) {
          prioritized.add(value);
          orderedCandidates.add((value: value, lineIndex: index, upperLine: upperLine));
        }
      }
    }

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];
      final String upperLine = line.toUpperCase();
      final List<String> lineCandidates = _extractDigitCandidates(line);
      for (final String value in lineCandidates) {
        orderedCandidates.add((value: value, lineIndex: index, upperLine: upperLine));
      }

      if (cifPattern.hasMatch(line)) {
        cifCandidates.addAll(lineCandidates);
      }

      if (cifPattern.hasMatch(line)) {
        continue;
      }
      final String normalized = _normalizeDigitsOnlyConfusions(line);
      final Iterable<RegExpMatch> matches = RegExp(r'\b\d{9,18}\b').allMatches(normalized);
      for (final RegExpMatch match in matches) {
        final String value = match.group(0) ?? '';
        if (value.isEmpty) {
          continue;
        }
        if (accountLinePattern.hasMatch(line)) {
          prioritized.add(value);
        } else {
          fallback.add(value);
        }
      }
    }

    // Hard rule: when account label is present, pick candidate near that label.
    // Avoid very long mixed numbers from unrelated lines.
    if (accountLabelLineIndexes.isNotEmpty) {
      final int startLine = accountLabelLineIndexes.first;
      final int endLine = lines.length - 1;

      final List<({String value, int lineIndex, String upperLine})> pureDigitCandidates = orderedCandidates
          .where(
            (c) => c.lineIndex >= startLine && c.lineIndex <= endLine && RegExp(r'^\d{9,12}$').hasMatch(c.value),
          )
          .toList();

      // User rule: account number is 12 digits. Prefer 12-digit candidates first.
      for (int index = pureDigitCandidates.length - 1; index >= 0; index--) {
        final candidate = pureDigitCandidates[index];
        final bool isCifNumber = cifCandidates.contains(candidate.value);
        final String upper = candidate.upperLine;
        final bool isNoiseLine = upper.contains('PHONE') ||
            upper.contains('MOBILE') ||
            upper.contains('DOB') ||
            upper.contains('DATE') ||
            upper.contains('IFSC') ||
            upper.contains('MICR') ||
            upper.contains('PIN') ||
            upper.contains('EMAIL') ||
            upper.contains('ADDRESS') ||
            upper.contains('NOM. REG') ||
            upper.contains('BRANCH') ||
            upper.contains('CODE');
        if (candidate.value.length == 12 && !isCifNumber && !isNoiseLine) {
          return candidate.value;
        }
      }

      // Special OCR pattern: CIF and Account labels exist, and later OCR returns two
      // standalone numeric lines (first is often CIF, second is account number).
      if (hasCifLabel && pureDigitCandidates.length >= 2) {
        for (int index = pureDigitCandidates.length - 1; index >= 1; index--) {
          final prev = pureDigitCandidates[index - 1];
          final curr = pureDigitCandidates[index];
          final bool nearEachOther = (curr.lineIndex - prev.lineIndex).abs() <= 2;
          if (nearEachOther) {
            return curr.value;
          }
        }
      }

      final List<({String value, int lineIndex, String upperLine})> nearbyCandidates =
          orderedCandidates.where((c) => c.lineIndex >= startLine && c.lineIndex <= endLine).toList();

      // 1) Prefer candidates in practical account length window first.
      for (int index = nearbyCandidates.length - 1; index >= 0; index--) {
        final candidate = nearbyCandidates[index];
        final bool isCifNumber = cifCandidates.contains(candidate.value);
        final String upper = candidate.upperLine;
        final bool isNoiseLine = upper.contains('PHONE') ||
            upper.contains('MOBILE') ||
            upper.contains('DOB') ||
            upper.contains('DATE') ||
            upper.contains('IFSC') ||
            upper.contains('MICR') ||
            upper.contains('PIN') ||
            upper.contains('EMAIL') ||
            upper.contains('ADDRESS') ||
            upper.contains('NOM. REG') ||
            upper.contains('BRANCH') ||
            upper.contains('CODE');
        final bool hasPracticalLength = candidate.value.length >= 9 && candidate.value.length <= 12;
        if (!isCifNumber && !isNoiseLine && hasPracticalLength) {
          return candidate.value;
        }
      }

      // 2) Fallback: if no practical-length candidate found, return any nearby non-CIF candidate.
      for (int index = nearbyCandidates.length - 1; index >= 0; index--) {
        final candidate = nearbyCandidates[index];
        final bool isCifNumber = cifCandidates.contains(candidate.value);
        final String upper = candidate.upperLine;
        final bool isNoiseLine = upper.contains('PHONE') ||
            upper.contains('MOBILE') ||
            upper.contains('DOB') ||
            upper.contains('DATE') ||
            upper.contains('IFSC') ||
            upper.contains('MICR') ||
            upper.contains('PIN') ||
            upper.contains('EMAIL') ||
            upper.contains('ADDRESS') ||
            upper.contains('NOM. REG') ||
            upper.contains('BRANCH') ||
            upper.contains('CODE');
        if (!isCifNumber && !isNoiseLine) {
          return candidate.value;
        }
      }
    }

    for (final String line in lines) {
      final String normalized = _normalizeDigitsOnlyConfusions(line);
      final String compact = normalized.replaceAll(' ', '');
      final RegExpMatch? inlineMatch =
          RegExp(r'(ACCOUNTNO|ACCOUNTNUMBER|ACCNO|A/CNO|A/C)\D*(\d{9,18})', caseSensitive: false).firstMatch(compact);
      if (inlineMatch != null) {
        return inlineMatch.group(2) ?? '';
      }
    }

    if (prioritized.isNotEmpty) {
      prioritized.sort((String a, String b) => b.length.compareTo(a.length));
      return prioritized.first;
    }

    // OCR can fail label detection; when both CIF and another number exist,
    // prefer the last non-CIF candidate because account number usually appears after CIF.
    if (orderedCandidates.isNotEmpty) {
      for (int index = orderedCandidates.length - 1; index >= 0; index--) {
        final String candidate = orderedCandidates[index].value;
        if (!cifCandidates.contains(candidate)) {
          return candidate;
        }
      }
    }

    // If account label is present but number still not extracted, avoid returning unrelated numbers like CIF.
    if (hasAnyAccountLabel) {
      return '';
    }

    if (fallback.isNotEmpty) {
      fallback.sort((String a, String b) => b.length.compareTo(a.length));
      return fallback.first;
    }

    return '';
  }

  String _textAfterAccountLabel(String value) {
    final RegExp labelPattern = RegExp(r'(ACCOUNT\s*(NO|N0|NUMBER)?|ACCT\s*(NO|N0)?|ACC\s*(NO|N0)?|A/C\s*(NO|N0)?|A\s*/\s*C|ACR)',
        caseSensitive: false);
    final RegExpMatch? match = labelPattern.firstMatch(value);
    if (match == null) {
      return '';
    }
    return value.substring(match.end);
  }

  String _extractIfscCode(List<String> lines, String fullText) {
    final RegExp strictPattern = RegExp(r'[A-Z]{4}0[A-Z0-9]{6}', caseSensitive: false);

    for (final String line in lines) {
      if (!line.toUpperCase().contains('IFSC')) {
        continue;
      }
      final String candidateFromLine = _extractIfscFromSingleLine(line, strictPattern);
      if (candidateFromLine.isNotEmpty) {
        return candidateFromLine;
      }
    }

    // Fallback only to lines that are likely IFSC context.
    for (final String line in lines) {
      final String upper = line.toUpperCase();
      if (upper.contains('IFS') || upper.contains('FSC') || upper.contains('BRANCH CODE')) {
        final String candidate = _extractIfscFromSingleLine(line, strictPattern);
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
    }

    return '';
  }

  String _extractIfscFromSingleLine(String line, RegExp strictPattern) {
    final String normalizedAlphaNum = line
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll('O', '0')
        .replaceAll('Q', '0')
        .replaceAll('D', '0');

    final int index = normalizedAlphaNum.indexOf('IFSC');
    if (index != -1) {
      String tail = normalizedAlphaNum.substring(index + 4);
      tail = tail.replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (tail.startsWith('CODE')) {
        tail = tail.substring(4);
      }
      if (tail.startsWith('NO')) {
        tail = tail.substring(2);
      }

      final String correctedTail = _correctIfscLeadingBankCode(tail);
      final RegExpMatch? correctedTailMatch = strictPattern.firstMatch(correctedTail);
      if (correctedTailMatch != null) {
        return (correctedTailMatch.group(0) ?? '').toUpperCase();
      }

      final RegExpMatch? tailMatch = strictPattern.firstMatch(tail);
      if (tailMatch != null) {
        return (tailMatch.group(0) ?? '').toUpperCase();
      }
    }

    final RegExpMatch? strictLineMatch = strictPattern.firstMatch(normalizedAlphaNum);
    if (strictLineMatch != null) {
      return (strictLineMatch.group(0) ?? '').toUpperCase();
    }

    return '';
  }

  String _correctIfscLeadingBankCode(String value) {
    if (value.length < 5) {
      return value;
    }

    final String firstFourRaw = value.substring(0, 4);
    final StringBuffer firstFour = StringBuffer();
    for (final int codeUnit in firstFourRaw.codeUnits) {
      final String c = String.fromCharCode(codeUnit);
      switch (c) {
        case '8':
          firstFour.write('B');
          break;
        case '0':
          firstFour.write('O');
          break;
        case '1':
          firstFour.write('I');
          break;
        case '5':
          firstFour.write('S');
          break;
        case '2':
          firstFour.write('Z');
          break;
        case '6':
          firstFour.write('G');
          break;
        case '7':
          firstFour.write('T');
          break;
        default:
          firstFour.write(c);
      }
    }

    final String restRaw = value.substring(4);
    final String rest = restRaw
        .replaceAll('O', '0')
        .replaceAll('Q', '0')
        .replaceAll('D', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1')
        .replaceAll('S', '5')
        .replaceAll('B', '8');

    return '${firstFour.toString()}$rest';
  }

  String _extractAccountHolderName(List<String> lines) {
    for (final String line in lines) {
      final String upper = line.toUpperCase();
      if (upper.contains('NAME')) {
        final String extracted = _nameFromLabelLine(line);
        if (extracted.isNotEmpty) {
          return extracted;
        }
      }
    }

    const List<String> blockedKeywords = <String>[
      'BANK',
      'IFSC',
      'ACCOUNT',
      'ACCT',
      'A/C',
      'CIF',
      'MICR',
      'BRANCH',
      'PHONE',
      'MOBILE',
      'EMAIL',
      'ADDRESS',
      'DATE',
    ];

    for (final String line in lines) {
      final String upperLine = line.toUpperCase();
      final bool hasNoDigits = !RegExp(r'\d').hasMatch(line);
      final String normalizedName = line.replaceAll('.', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      final List<String> nameParts = normalizedName.split(' ').where((String p) => p.isNotEmpty).toList();
      final bool looksLikeName = RegExp(r'^[A-Z. ]{4,}$').hasMatch(upperLine);
      final bool hasBlockedKeyword = blockedKeywords.any((String word) => upperLine.contains(word));
      if (hasNoDigits && looksLikeName && !hasBlockedKeyword && nameParts.length >= 2) {
        return normalizedName;
      }
    }

    return '';
  }

  String _nameFromLabelLine(String line) {
    final String upper = line.toUpperCase();
    int index = upper.indexOf('NAME');
    if (index == -1) {
      return '';
    }

    String tail = line.substring(index + 'NAME'.length);
    tail = tail.replaceAll(RegExp(r'[:\-=]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (tail.isEmpty) {
      return '';
    }

    final String cleaned = tail.replaceAll('.', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (RegExp(r'\d').hasMatch(cleaned)) {
      return '';
    }
    final List<String> parts = cleaned.split(' ').where((String p) => p.isNotEmpty).toList();
    if (parts.length < 2) {
      return '';
    }

    return cleaned;
  }

  String _normalizeDigitsOnlyConfusions(String value) {
    return value
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('S', '5')
        .replaceAll('s', '5')
        .replaceAll('B', '8');
  }

  List<String> _extractDigitCandidates(String value) {
    final String normalized = _normalizeDigitsOnlyConfusions(value);

    final List<String> candidates = <String>[];
    final Iterable<RegExpMatch> directMatches = RegExp(r'\b\d{9,18}\b').allMatches(normalized);
    for (final RegExpMatch match in directMatches) {
      final String v = match.group(0) ?? '';
      if (v.isNotEmpty) {
        candidates.add(v);
      }
    }

    return candidates;
  }
}
