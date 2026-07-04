class OutboundItemForm {
  final Map<String, dynamic> stock;
  double qty;

  OutboundItemForm({
    required this.stock,
    this.qty = 1,
  });

  int get stockBalanceId {
    final value = stock['id'];

    if (value == null) return 0;
    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  int get productId {
    final value = stock['product_id'];

    if (value == null) return 0;
    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  int get warehouseId {
    final value = stock['warehouse_id'];

    if (value == null) return 0;
    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }
}