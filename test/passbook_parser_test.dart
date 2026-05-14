import 'package:flutter_test/flutter_test.dart';
import 'package:project/utils/parsers/passbook_parser.dart';

void main() {
  final PassbookParser parser = PassbookParser();

  test('Passbook parser extracts account, IFSC and name', () {
    const String rawText = 'STATE BANK OF INDIA\nRAHUL SHARMA\nA/C 123456789012\nIFSC SBIN0001234';
    final result = parser.parsePassbook(rawText);

    expect(result.accountHolderName, 'RAHUL SHARMA');
    expect(result.accountNumber, '123456789012');
    expect(result.ifscCode, 'SBIN0001234');
  });

  test('Passbook parser avoids CIF as name and supports noisy IFSC line', () {
    const String rawText = 'State Bank of India\nCIF No 8621486067\nA/C No: 37720820170\nifsc : sbinOO01234\nDAVID THOMAS';
    final result = parser.parsePassbook(rawText);

    expect(result.accountHolderName, 'DAVID THOMAS');
    expect(result.accountNumber, '37720820170');
    expect(result.ifscCode, 'SBIN0001234');
  });

  test('Passbook parser prioritizes account line over CIF number', () {
    const String rawText = 'CIF No: 86214868067\nAccount No : 37720820170\nIFSC: SBIN0012897\nMRS JYOTI';
    final result = parser.parsePassbook(rawText);

    expect(result.accountNumber, '37720820170');
    expect(result.ifscCode, 'SBIN0012897');
  });

  test('Passbook parser picks account number after label when CIF and account are in same line', () {
    const String rawText = 'CIF No: 86214868067  Account No: 37720820170\nIFSC: SBIN0012897\nMRS JYOTI';
    final result = parser.parsePassbook(rawText);

    expect(result.accountNumber, '37720820170');
  });

  test('Passbook parser finds account number in later lines after account label', () {
    const String rawText = 'CIF No\n86214868067\nAccount No :\n:\n37720820170\nIFSC : SBIN0012897\nMrs JYOTI';
    final result = parser.parsePassbook(rawText);

    expect(result.accountNumber, '37720820170');
  });

  test('Passbook parser prefers non-CIF later number when labels are noisy', () {
    const String rawText = 'CIF No\n86214868067\nAcc0unt N0\nrandom text\n37720820170\nState Bank';
    final result = parser.parsePassbook(rawText);

    expect(result.accountNumber, '37720820170');
  });

  test('Passbook parser extracts IFSC from IFSC Code format with OCR O/0 confusion', () {
    const String rawText = 'TA/c No: 0013201616\n2 IFSC Code: KKBKOO00883\nHome Branch: SURAT';
    final result = parser.parsePassbook(rawText);

    expect(result.ifscCode, 'KKBK0000883');
  });

  test('Passbook parser avoids phone-like false IFSC and fixes S8INOO format', () {
    const String rawText = 'Phone0904759\nIFSC:S8 INOO11017\nBranch Code: 1017';
    final result = parser.parsePassbook(rawText);

    expect(result.ifscCode, 'SBIN0011017');
  });
}
