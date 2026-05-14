class BankDetails {
  const BankDetails({
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
  });

  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
}
