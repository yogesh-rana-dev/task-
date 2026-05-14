class CardDetails {
  const CardDetails({
    required this.cardNumber,
    required this.expiryDate,
    required this.cardHolderName,
  });

  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;
}
