import 'package:flutter/material.dart';

class InboundItemForm {
  final Map<String, dynamic> product;
  final TextEditingController qtyController;
  final TextEditingController unitCostController;
  final TextEditingController noteController;

  InboundItemForm({
    required this.product,
    String qty = '',
    String unitCost = '0',
    String note = '',
  })  : qtyController = TextEditingController(text: qty),
        unitCostController = TextEditingController(text: unitCost),
        noteController = TextEditingController(text: note);

  int get productId {
    final value = product['id'];

    if (value == null) return 0;
    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  void dispose() {
    qtyController.dispose();
    unitCostController.dispose();
    noteController.dispose();
  }
}