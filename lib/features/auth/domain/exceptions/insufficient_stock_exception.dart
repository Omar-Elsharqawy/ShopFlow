class InsufficientStockException implements Exception {
  final String productName;
  final int availableStock;
  final int requestedQuantity;

  InsufficientStockException({
    required this.productName,
    required this.availableStock,
    required this.requestedQuantity,
  });

  @override
  String toString() {
    return 'Not enough stock for $productName. '
        'Available: $availableStock, '
        'Requested: $requestedQuantity';
  }
}