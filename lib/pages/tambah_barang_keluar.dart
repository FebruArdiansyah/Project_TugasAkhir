import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/picked_attachment.dart';
import '../services/api_service.dart';
import '../widgets/outbound/outbound_item_card.dart';
import '../widgets/outbound/outbound_stock_info_card.dart';
import '../widgets/outbound/outbound_stock_picker.dart';
import '../widgets/shared/product_logo.dart';

class TambahBarangKeluarScreen extends StatefulWidget {
  final bool isEdit;

  const TambahBarangKeluarScreen({
    super.key,
    this.isEdit = false,
  });

  @override
  State<TambahBarangKeluarScreen> createState() =>
      _TambahBarangKeluarScreenState();
}

class _TambahBarangKeluarScreenState extends State<TambahBarangKeluarScreen> {
  static const Color _bgColor = Color(0xFFF7FAFC);
  static const Color _primaryRed = Color(0xFFEF4444);
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  DateTime selectedTanggal = DateTime.now();

  final TextEditingController tanggalController = TextEditingController();
  final TextEditingController jenisKeluarController = TextEditingController(
    text: 'Penjualan',
  );
  final TextEditingController tujuanController = TextEditingController();
  final TextEditingController invoiceController = TextEditingController();

  final TextEditingController qtyController = TextEditingController(text: '1');
  final TextEditingController catatanController = TextEditingController();
  final TextEditingController barangSearchController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool isLoadingMaster = false;
  bool isSubmitting = false;

  bool isEditArgumentLoaded = false;
  bool hasAppliedEditDetail = false;

  int? editOutboundId;
  Map<String, dynamic>? editDetail;

  String? errorMessage;

  int? selectedCustomerId;
  String? selectedStockKey;

  int masterLoadedAtMs = 0;
  int productLogoRebuildVersion = 0;

  final List<PickedAttachment> selectedImages = [];
  final List<Map<String, dynamic>> selectedItems = [];

  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> warehouses = [];
  List<Map<String, dynamic>> stocks = [];

  static const String _fallbackProductionBaseUrl =
      'https://febru.djncloud.my.id';

  @override
  void initState() {
    super.initState();

    tanggalController.text = _formatDate(selectedTanggal);
    invoiceController.text = _generateReferenceNumber(selectedTanggal);

    _loadMasterData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (isEditArgumentLoaded) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      editOutboundId = int.tryParse(args['id']?.toString() ?? '');

      final rawDetail = args['detail'];

      if (rawDetail is Map) {
        editDetail = Map<String, dynamic>.from(rawDetail);
      }
    }

    isEditArgumentLoaded = true;

    _tryApplyEditDetail();
  }

  @override
  void dispose() {
    tanggalController.dispose();
    jenisKeluarController.dispose();
    tujuanController.dispose();
    invoiceController.dispose();
    qtyController.dispose();
    catatanController.dispose();
    barangSearchController.dispose();

    super.dispose();
  }

  Future<void> _loadMasterData() async {
    if (isLoadingMaster) return;

    setState(() {
      isLoadingMaster = true;
      errorMessage = null;
    });

    try {
      final customerResponse = await ApiService.get('/master/customers');
      final warehouseResponse = await ApiService.get('/master/warehouses');
      final stockResponse = await ApiService.get('/stocks');

      final loadedCustomers = _extractList(customerResponse);
      final loadedWarehouses = _extractList(warehouseResponse);
      final loadedStocks = _extractList(stockResponse);

      if (!mounted) return;

      setState(() {
        customers = loadedCustomers;
        warehouses = loadedWarehouses;
        stocks = loadedStocks;
        masterLoadedAtMs = DateTime.now().millisecondsSinceEpoch;

        if (!widget.isEdit) {
          selectedCustomerId = null;
          tujuanController.clear();

          if (stocks.isNotEmpty && selectedStockKey == null) {
            final availableStocks = stocks.where((item) {
              return _availableQty(item) > 0;
            }).toList();

            if (availableStocks.isNotEmpty) {
              _selectStock(availableStocks.first, updateState: false);
            }
          }
        }
      });

      _tryApplyEditDetail();
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.message;
      });

      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Gagal memuat data master: $e';
      });

      _showSnackBar('Gagal memuat data master: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoadingMaster = false;
        });
      }
    }
  }

  void _tryApplyEditDetail() {
    if (!widget.isEdit) return;
    if (hasAppliedEditDetail) return;
    if (editDetail == null) return;
    if (stocks.isEmpty) return;

    _applyEditDetail(editDetail!);
  }

  void _applyEditDetail(Map<String, dynamic> data) {
    if (hasAppliedEditDetail) return;

    final transactionDate = _parseDate(data['transaction_date']);
    final customerMap = _asMap(data['customer']);
    final itemList = _asMapList(data['items']);

    final customerId = _toInt(data['customer_id'] ?? customerMap['id']);
    final matchedCustomer = _findById(customers, customerId) ?? customerMap;

    final List<Map<String, dynamic>> loadedItems = [];

    for (final item in itemList) {
      loadedItems.add(_outboundItemFromEditItem(item));
    }

    setState(() {
      if (transactionDate != null) {
        selectedTanggal = transactionDate;
        tanggalController.text = _formatDate(transactionDate);
      }

      final outboundType = _cleanText(data['outbound_type']);
      jenisKeluarController.text =
          outboundType.isNotEmpty ? outboundType : 'Penjualan';

      final referenceNumber = _cleanText(data['reference_number']);
      final invoiceNumber = _cleanText(data['invoice_number']);

      if (referenceNumber.isNotEmpty) {
        invoiceController.text = referenceNumber;
      } else if (invoiceNumber.isNotEmpty) {
        invoiceController.text = invoiceNumber;
      }

      if (customerId > 0) {
        selectedCustomerId = customerId;
      }

      if (matchedCustomer.isNotEmpty) {
        tujuanController.text = _customerName(matchedCustomer);
      }

      catatanController.text = _cleanText(data['note']);

      selectedItems
        ..clear()
        ..addAll(loadedItems);

      if (selectedItems.isNotEmpty) {
        selectedStockKey = selectedItems.first['stock_key']?.toString();
      }

      productLogoRebuildVersion++;
      hasAppliedEditDetail = true;
    });
  }

  Map<String, dynamic> _outboundItemFromEditItem(Map<String, dynamic> item) {
    final productId = _toInt(item['product_id']);
    final warehouseId = _toInt(item['warehouse_id']);

    final matchedStock = _findStockForEditItem(item);

    final stockBalanceId = _toInt(
      item['stock_balance_id'] ??
          item['stock_id'] ??
          matchedStock?['id'] ??
          item['id'],
    );

    final stockKey = matchedStock == null
        ? '$stockBalanceId-$productId-$warehouseId'
        : _stockKey(matchedStock);

    final oldItemId = _toInt(
      item['id'] ??
          item['outbound_item_id'] ??
          item['transaction_item_id'] ??
          item['item_id'] ??
          item['detail_id'],
    );

    final productCode = _firstNonEmpty([
      item['product_code'],
      item['code'],
      matchedStock?['product_code'],
      matchedStock?['code'],
    ]);

    final productName = _firstNonEmpty([
      item['product_name'],
      item['product_display_name'],
      item['name'],
      matchedStock?['product_display_name'],
      matchedStock?['product_name'],
      matchedStock?['name'],
    ]);

    final sizeText = _firstNonEmpty([
      item['product_size_text'],
      item['size_text'],
      item['ukuran'],
      matchedStock?['product_size_text'],
      matchedStock?['size_text'],
    ]);

    final unitName = _firstNonEmpty(
      [
        item['unit_name'],
        item['satuan'],
        matchedStock?['unit_name'],
      ],
      fallback: 'PCS',
    );

    final warehouseName = _firstNonEmpty([
      item['warehouse_name'],
      item['gudang'],
      matchedStock?['warehouse_name'],
    ]);

    final qty = _toDouble(item['qty']);

    final stokAwal = _toDouble(
      item['available_stock'] ??
          item['stock_available'] ??
          item['remaining_stock'] ??
          item['stock_after'] ??
          matchedStock?['available_qty'] ??
          matchedStock?['qty_available'] ??
          matchedStock?['stock'] ??
          matchedStock?['qty_on_hand'] ??
          matchedStock?['available_stock'],
    );

    final logoPath = _firstNonEmpty(
      [
        item['logo_path'],
        item['product_logo_path'],
        matchedStock?['logo_path'],
        matchedStock?['product_logo_path'],
      ],
      fallback: '',
    );

    final logoUrl = _firstNonEmpty(
      [
        item['logo_url'],
        item['product_logo_url'],
        matchedStock?['logo_url'],
        matchedStock?['product_logo_url'],
      ],
      fallback: '',
    );

    return {
      'id': oldItemId,
      'outbound_item_id': oldItemId,
      'transaction_item_id': oldItemId,
      'item_id': oldItemId,
      'detail_id': oldItemId,
      'stock_key': stockKey,
      'stock_balance_id': stockBalanceId,
      'product_id': productId,
      'warehouse_id': warehouseId,
      'code': productCode,
      'name': productName,
      'ukuran': sizeText,
      'qty': qty,
      'satuan': unitName,
      'gudang': warehouseName,
      'stokAwal': stokAwal + qty,
      'type_name': _firstNonEmpty(
        [
          item['type_name'],
          item['product_type_name'],
          matchedStock?['type_name'],
          matchedStock?['product_type_name'],
        ],
        fallback: 'UMUM',
      ),
      'density_name': _firstNonEmpty(
        [
          item['density_name'],
          item['product_density_name'],
          matchedStock?['density_name'],
          matchedStock?['product_density_name'],
        ],
        fallback: 'UMUM',
      ),
      'category_name': _firstNonEmpty(
        [
          item['category_name'],
          item['product_category_name'],
          matchedStock?['category_name'],
          matchedStock?['product_category_name'],
        ],
        fallback: 'UMUM',
      ),
      'logo_path': logoPath.isEmpty ? null : logoPath,
      'product_logo_path': logoPath.isEmpty ? null : logoPath,
      'logo_url': logoUrl.isEmpty ? null : logoUrl,
      'product_logo_url': logoUrl.isEmpty ? null : logoUrl,
    };
  }

  Map<String, dynamic>? _findStockForEditItem(Map<String, dynamic> item) {
    final stockBalanceId = _toInt(item['stock_balance_id'] ?? item['stock_id']);
    final productId = _toInt(item['product_id']);
    final warehouseId = _toInt(item['warehouse_id']);

    if (stockBalanceId > 0) {
      for (final stock in stocks) {
        if (_toInt(stock['id']) == stockBalanceId) {
          return stock;
        }
      }
    }

    for (final stock in stocks) {
      if (_toInt(stock['product_id']) == productId &&
          _toInt(stock['warehouse_id']) == warehouseId) {
        return stock;
      }
    }

    for (final stock in stocks) {
      if (_toInt(stock['product_id']) == productId) {
        return stock;
      }
    }

    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();

    if (raw.isEmpty) return null;

    return DateTime.tryParse(raw);
  }

  List<Map<String, dynamic>> _extractList(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];

      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return [];
  }

  Map<String, dynamic>? get selectedStock {
    if (selectedStockKey == null) return null;

    for (final item in stocks) {
      if (_stockKey(item) == selectedStockKey) {
        return item;
      }
    }

    return null;
  }

  Map<String, dynamic>? _findById(
    List<Map<String, dynamic>> list,
    int? id,
  ) {
    if (id == null || id <= 0) return null;

    for (final item in list) {
      if (_toInt(item['id']) == id) {
        return item;
      }
    }

    return null;
  }

  String _stockKey(Map<String, dynamic> item) {
    final stockId = _toInt(item['id']);
    final productId = _toInt(item['product_id']);
    final warehouseId = _toInt(item['warehouse_id']);

    return '$stockId-$productId-$warehouseId';
  }

  int get qtyKeluar {
    return int.tryParse(qtyController.text.trim()) ?? 0;
  }

  double get stokAwal {
    final item = selectedStock;

    if (item == null) return 0;

    return _availableQty(item);
  }

  double get qtySudahDipilihUntukBarangIni {
    if (selectedStockKey == null) return 0;

    return selectedItems
        .where((item) => item['stock_key'] == selectedStockKey)
        .fold<double>(
          0,
          (total, item) => total + _toDouble(item['qty']),
        );
  }

  double get stokTersediaSetelahDipilih {
    return stokAwal - qtySudahDipilihUntukBarangIni;
  }

  double get sisaStok {
    return stokTersediaSetelahDipilih - qtyKeluar;
  }

  bool get qtyKosongAtauNol => qtyKeluar <= 0;

  bool get barangHabis => stokTersediaSetelahDipilih <= 0;

  bool get stokTidakCukup => qtyKeluar > stokTersediaSetelahDipilih;

  bool get itemTidakValid {
    return selectedStock == null ||
        qtyKosongAtauNol ||
        barangHabis ||
        stokTidakCukup;
  }

  bool get formTidakValid {
  return selectedItems.isEmpty || tujuanController.text.trim().isEmpty;
}

  double get totalQtyBarangKeluar {
    return selectedItems.fold<double>(
      0,
      (total, item) => total + _toDouble(item['qty']),
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  double _availableQty(Map<String, dynamic> item) {
    return _toDouble(
      item['available_qty'] ??
          item['qty_available'] ??
          item['stock'] ??
          item['qty_on_hand'] ??
          item['available_stock'],
    );
  }

  String _formatQty(num value) {
    final doubleValue = value.toDouble();

    if (doubleValue % 1 == 0) {
      return doubleValue.toInt().toString();
    }

    return doubleValue.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    const bulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${bulan[date.month]} ${date.year}';
  }

  String _apiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _generateReferenceNumber(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return 'INV-NAURA-$year$month$day-0001';
  }

  String _cleanText(dynamic value) {
    if (value == null) return '';

    return value
        .toString()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _customerName(Map<String, dynamic> item) {
    final name = _cleanText(item['name']);
    final customerName = _cleanText(item['customer_name']);

    if (name.isNotEmpty) return name;
    if (customerName.isNotEmpty) return customerName;

    return '-';
  }

  Map<String, dynamic> _productMap(Map<String, dynamic> item) {
    final product = item['product'];

    if (product is Map) {
      return Map<String, dynamic>.from(product);
    }

    return {};
  }

  String _firstNonEmpty(List<dynamic> values, {String fallback = '-'}) {
    for (final value in values) {
      final text = _cleanText(value);

      if (text.isNotEmpty && text != '-') {
        return text;
      }
    }

    return fallback;
  }

  String _stockProductName(Map<String, dynamic> item) {
    final product = _productMap(item);

    return _firstNonEmpty([
      item['product_display_name'],
      item['product_name'],
      item['name'],
      product['display_name'],
      product['full_name'],
      product['name'],
    ]);
  }

  String _stockProductCode(Map<String, dynamic> item) {
    final product = _productMap(item);

    return _firstNonEmpty([
      item['product_code'],
      item['code'],
      product['code'],
    ]);
  }

  String _stockUnit(Map<String, dynamic> item) {
    final product = _productMap(item);
    final unit = item['unit'];
    final productUnit = product['unit'];

    if (_cleanText(item['unit_name']).isNotEmpty) {
      return _cleanText(item['unit_name']);
    }

    if (unit is Map && _cleanText(unit['name']).isNotEmpty) {
      return _cleanText(unit['name']);
    }

    if (_cleanText(product['unit_name']).isNotEmpty) {
      return _cleanText(product['unit_name']);
    }

    if (productUnit is Map && _cleanText(productUnit['name']).isNotEmpty) {
      return _cleanText(productUnit['name']);
    }

    return 'PCS';
  }

  String _stockWarehouseName(Map<String, dynamic> item) {
    final warehouseName = _cleanText(item['warehouse_name']);

    if (warehouseName.isNotEmpty) return warehouseName;

    final warehouse = item['warehouse'];

    if (warehouse is Map) {
      final warehouseMap = Map<String, dynamic>.from(warehouse);
      final name = _cleanText(warehouseMap['name']);

      if (name.isNotEmpty) return name;
    }

    final warehouseId = _toInt(item['warehouse_id']);

    for (final warehouseItem in warehouses) {
      if (_toInt(warehouseItem['id']) == warehouseId) {
        return _cleanText(warehouseItem['name']);
      }
    }

    return '-';
  }

  String _stockSize(Map<String, dynamic> item) {
    final product = _productMap(item);

    return _firstNonEmpty([
      item['product_size_text'],
      item['size_text'],
      product['product_size_text'],
      product['size_text'],
    ]);
  }

  String _stockType(Map<String, dynamic> item) {
    final product = _productMap(item);
    final productType = product['product_type'];

    if (_cleanText(item['type_name']).isNotEmpty) {
      return _cleanText(item['type_name']);
    }

    if (_cleanText(item['product_type_name']).isNotEmpty) {
      return _cleanText(item['product_type_name']);
    }

    if (_cleanText(product['type_name']).isNotEmpty) {
      return _cleanText(product['type_name']);
    }

    if (_cleanText(product['product_type_name']).isNotEmpty) {
      return _cleanText(product['product_type_name']);
    }

    if (productType is Map && _cleanText(productType['name']).isNotEmpty) {
      return _cleanText(productType['name']);
    }

    return 'UMUM';
  }

  String _stockDensity(Map<String, dynamic> item) {
    final product = _productMap(item);
    final density = product['product_density'];

    if (_cleanText(item['density_name']).isNotEmpty) {
      return _cleanText(item['density_name']);
    }

    if (_cleanText(item['product_density_name']).isNotEmpty) {
      return _cleanText(item['product_density_name']);
    }

    if (_cleanText(product['density_name']).isNotEmpty) {
      return _cleanText(product['density_name']);
    }

    if (_cleanText(product['product_density_name']).isNotEmpty) {
      return _cleanText(product['product_density_name']);
    }

    if (density is Map && _cleanText(density['name']).isNotEmpty) {
      return _cleanText(density['name']);
    }

    return 'UMUM';
  }

  String _stockCategory(Map<String, dynamic> item) {
    final product = _productMap(item);
    final category = product['product_category'];

    if (_cleanText(item['category_name']).isNotEmpty) {
      return _cleanText(item['category_name']);
    }

    if (_cleanText(item['product_category_name']).isNotEmpty) {
      return _cleanText(item['product_category_name']);
    }

    if (_cleanText(product['category_name']).isNotEmpty) {
      return _cleanText(product['category_name']);
    }

    if (_cleanText(product['product_category_name']).isNotEmpty) {
      return _cleanText(product['product_category_name']);
    }

    if (category is Map && _cleanText(category['name']).isNotEmpty) {
      return _cleanText(category['name']);
    }

    return 'UMUM';
  }

  String? _extractLogoPath(Map<String, dynamic> item) {
    final product = _productMap(item);

    final candidates = [
      item['logo_path'],
      item['product_logo_path'],
      product['logo_path'],
      product['product_logo_path'],
    ];

    for (final candidate in candidates) {
      final text = _cleanText(candidate);

      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  String? _extractLogoUrl(Map<String, dynamic> item) {
    final product = _productMap(item);

    final candidates = [
      item['logo_url'],
      item['product_logo_url'],
      product['logo_url'],
      product['product_logo_url'],
    ];

    for (final candidate in candidates) {
      final text = _cleanText(candidate);

      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  Map<String, dynamic> _stockLogoItem(Map<String, dynamic> item) {
    final product = item['product'];

    Map<String, dynamic> productMap = {};

    if (product is Map) {
      productMap = Map<String, dynamic>.from(product);
    }

    return {
      ...item,
      'id': item['product_id'] ?? productMap['id'] ?? item['id'],
      'code': item['product_code'] ?? productMap['code'] ?? item['code'],
      'name': item['product_name'] ??
          item['product_display_name'] ??
          productMap['name'] ??
          item['name'],
      'display_name': item['product_display_name'] ??
          item['product_name'] ??
          productMap['display_name'] ??
          productMap['full_name'] ??
          productMap['name'] ??
          item['name'],
      'full_name': item['product_display_name'] ??
          productMap['full_name'] ??
          item['product_name'] ??
          item['name'],
      'logo_path': item['logo_path'] ??
          item['product_logo_path'] ??
          productMap['logo_path'] ??
          productMap['product_logo_path'],
      'product_logo_path': item['product_logo_path'] ??
          item['logo_path'] ??
          productMap['product_logo_path'] ??
          productMap['logo_path'],
      'logo_url': item['logo_url'] ??
          item['product_logo_url'] ??
          productMap['logo_url'] ??
          productMap['product_logo_url'],
      'product_logo_url': item['product_logo_url'] ??
          item['logo_url'] ??
          productMap['product_logo_url'] ??
          productMap['logo_url'],
    };
  }

  Widget _buildProductLogo(
    Map<String, dynamic> item, {
    double size = 40,
    bool selected = false,
  }) {
    return ProductLogo(
      item: _stockLogoItem(item),
      size: size,
      selected: selected,
      fallbackBaseUrl: _fallbackProductionBaseUrl,
      masterLoadedAtMs: masterLoadedAtMs,
      rebuildVersion: productLogoRebuildVersion,
    );
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedTanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryRed,
              onPrimary: Colors.white,
              onSurface: _darkText,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      selectedTanggal = picked;
      tanggalController.text = _formatDate(picked);

      if (!widget.isEdit) {
        invoiceController.text = _generateReferenceNumber(picked);
      }
    });
  }


  void _selectStock(
    Map<String, dynamic> item, {
    bool updateState = true,
  }) {
    void apply() {
      selectedStockKey = _stockKey(item);
      qtyController.text = '1';
      productLogoRebuildVersion++;
    }

    if (updateState) {
      setState(apply);
    } else {
      apply();
    }
  }

  bool _isSameWarehouseAsSelectedList(Map<String, dynamic> stockItem) {
    if (selectedItems.isEmpty) return true;

    final firstWarehouseId = _toInt(selectedItems.first['warehouse_id']);
    final currentWarehouseId = _toInt(stockItem['warehouse_id']);

    return firstWarehouseId == currentWarehouseId;
  }

  void _addItemToList() {
    final stock = selectedStock;

    if (stock == null) {
      _showSnackBar('Pilih barang terlebih dahulu.', isError: true);
      return;
    }

    if (!_isSameWarehouseAsSelectedList(stock)) {
      _showSnackBar(
        'Barang keluar dalam 1 transaksi harus dari gudang yang sama.',
        isError: true,
      );
      return;
    }

    if (itemTidakValid) {
      _showSnackBar(_warningMessage(), isError: true);
      return;
    }

    _addSelectedStockToList(qtyKeluar);
  }

  void _addSelectedStockToList(int qty) {
    final stock = selectedStock;

    if (stock == null || selectedStockKey == null) return;

    final existingIndex = selectedItems.indexWhere(
      (item) => item['stock_key'] == selectedStockKey,
    );

    setState(() {
      if (existingIndex >= 0) {
        selectedItems[existingIndex]['qty'] =
            _toDouble(selectedItems[existingIndex]['qty']) + qty;
      } else {
        selectedItems.add({
          'stock_key': selectedStockKey,
          'stock_balance_id': _toInt(stock['id']),
          'product_id': _toInt(stock['product_id']),
          'warehouse_id': _toInt(stock['warehouse_id']),
          'code': _stockProductCode(stock),
          'name': _stockProductName(stock),
          'ukuran': _stockSize(stock),
          'qty': qty.toDouble(),
          'satuan': _stockUnit(stock),
          'gudang': _stockWarehouseName(stock),
          'stokAwal': _availableQty(stock),
          'type_name': _stockType(stock),
          'density_name': _stockDensity(stock),
          'category_name': _stockCategory(stock),
          'logo_path': _extractLogoPath(stock),
          'product_logo_path': _extractLogoPath(stock),
          'logo_url': _extractLogoUrl(stock),
          'product_logo_url': _extractLogoUrl(stock),
        });
      }

      qtyController.text = '1';
    });

    _showSnackBar('${_stockProductName(stock)} ditambahkan ke daftar');
  }

  void _quickAddBarang(String keyword) {
    final query = keyword.trim().toLowerCase();

    final matches = stocks.where((item) {
      final name = _stockProductName(item).toLowerCase();
      final code = _stockProductCode(item).toLowerCase();

      return (name.contains(query) || code.contains(query)) &&
          _availableQty(item) > 0;
    }).toList();

    if (matches.isEmpty) {
      _showSnackBar('$keyword tidak ditemukan atau stok kosong.', isError: true);
      return;
    }

    final stock = matches.first;

    if (!_isSameWarehouseAsSelectedList(stock)) {
      _showSnackBar(
        '$keyword tidak bisa ditambahkan karena beda gudang.',
        isError: true,
      );
      return;
    }

    setState(() {
      selectedStockKey = _stockKey(stock);
      qtyController.text = '1';
      productLogoRebuildVersion++;
    });

    _addSelectedStockToList(1);
  }

  void _removeItemFromList(int index) {
    setState(() {
      selectedItems.removeAt(index);
    });
  }

  void _increaseItemQty(int index) {
    final item = selectedItems[index];

    final stock = stocks.firstWhere(
      (element) => _stockKey(element) == item['stock_key'],
      orElse: () => {},
    );

    final currentQty = _toDouble(item['qty']);

    if (stock.isEmpty) {
      setState(() {
        selectedItems[index]['qty'] = currentQty + 1;
      });

      return;
    }

    final stok = _availableQty(stock) + currentQty;

    if (currentQty + 1 > stok) {
      _showSnackBar('Qty sudah mencapai stok tersedia.', isError: true);
      return;
    }

    setState(() {
      selectedItems[index]['qty'] = currentQty + 1;
    });
  }

  void _decreaseItemQty(int index) {
    final currentQty = _toDouble(selectedItems[index]['qty']);

    if (currentQty <= 1) {
      _removeItemFromList(index);
      return;
    }

    setState(() {
      selectedItems[index]['qty'] = currentQty - 1;
    });
  }

  String _warningMessage() {
    if (selectedStock == null) {
      return 'Pilih barang terlebih dahulu.';
    }

    if (barangHabis) {
      return 'Barang tidak dapat dikeluarkan karena stok habis.';
    }

    if (qtyKosongAtauNol) {
      return 'Qty keluar harus diisi dan lebih dari 0.';
    }

    if (stokTidakCukup) {
      return 'Qty keluar melebihi stok tersedia.';
    }

    return 'Data barang belum valid.';
  }

  Future<void> _pickFromCamera() async {
    if (selectedImages.length >= 3) {
      _showMaxPhotoMessage();
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      selectedImages.add(
        PickedAttachment(
          bytes: bytes,
          fileName: image.name.isEmpty
              ? 'outbound-camera-${DateTime.now().millisecondsSinceEpoch}.jpg'
              : image.name,
        ),
      );
    });
  }

  Future<void> _pickFromGallery() async {
    if (selectedImages.length >= 3) {
      _showMaxPhotoMessage();
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (images.isEmpty) return;

    final remaining = 3 - selectedImages.length;

    for (final img in images.take(remaining)) {
      final bytes = await img.readAsBytes();

      selectedImages.add(
        PickedAttachment(
          bytes: bytes,
          fileName: img.name.isEmpty
              ? 'outbound-gallery-${DateTime.now().millisecondsSinceEpoch}.jpg'
              : img.name,
        ),
      );
    }

    setState(() {});

    if (images.length > remaining) {
      _showMaxPhotoMessage();
    }
  }

  void _showMaxPhotoMessage() {
    _showSnackBar('Maksimal 3 foto', isError: true);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('mobile_api_token') ??
        prefs.getString('api_token') ??
        prefs.getString('token');
  }

  Future<void> _submitForm() async {
    if (isSubmitting) return;

    if (tujuanController.text.trim().isEmpty) {
      _showSnackBar('Isi customer / tujuan terlebih dahulu.', isError: true);
      return;
    }

    if (selectedItems.isEmpty) {
      _showSnackBar(
        'Tambahkan minimal 1 barang terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final warehouseId = _toInt(selectedItems.first['warehouse_id']);

    if (warehouseId <= 0) {
      _showSnackBar('Gudang asal tidak valid.', isError: true);
      return;
    }

    if (widget.isEdit && (editOutboundId == null || editOutboundId! <= 0)) {
      _showSnackBar(
        'ID pengajuan barang keluar tidak ditemukan.',
        isError: true,
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final token = await _getToken();

      if (token == null || token.trim().isEmpty) {
        throw ApiException(message: 'Token login tidak ditemukan.');
      }

      final bool isEditing = widget.isEdit && editOutboundId != null;

      final uri = Uri.parse(
        isEditing
            ? '${ApiService.baseUrl}/outbounds/$editOutboundId'
            : '${ApiService.baseUrl}/outbounds',
      );

      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        if (isEditing) 'X-HTTP-Method-Override': 'PUT',
      });

      if (isEditing) {
        request.fields['_method'] = 'PUT';
      }

      request.fields.addAll({
        'transaction_date': _apiDate(selectedTanggal),
        'outbound_type': jenisKeluarController.text.trim().isEmpty
            ? 'Penjualan'
            : jenisKeluarController.text.trim(),
        'reference_number': invoiceController.text.trim(),
        'customer_name': tujuanController.text.trim(),
        'warehouse_id': warehouseId.toString(),
        'note': catatanController.text.trim(),
      });

      for (int i = 0; i < selectedItems.length; i++) {
        final item = selectedItems[i];

        final oldItemId = _toInt(
          item['outbound_item_id'] ??
              item['transaction_item_id'] ??
              item['item_id'] ??
              item['detail_id'] ??
              item['id'],
        );

        if (isEditing && oldItemId > 0) {
          request.fields['items[$i][id]'] = oldItemId.toString();
        }

        request.fields['items[$i][product_id]'] =
            _toInt(item['product_id']).toString();
        request.fields['items[$i][warehouse_id]'] =
            _toInt(item['warehouse_id']).toString();
        request.fields['items[$i][stock_balance_id]'] =
            _toInt(item['stock_balance_id']).toString();
        request.fields['items[$i][qty]'] = _toDouble(item['qty']).toString();
        request.fields['items[$i][note]'] = catatanController.text.trim();
      }

      for (final file in selectedImages) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'attachments[]',
            file.bytes,
            filename: file.fileName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: isEditing
              ? 'Gagal memperbarui barang keluar. Status: ${response.statusCode}. ${response.body}'
              : 'Gagal submit barang keluar. Status: ${response.statusCode}. ${response.body}',
          statusCode: response.statusCode,
        );
      }

      if (!mounted) return;

      _showSnackBar(
        isEditing
            ? 'Pengajuan barang keluar berhasil diperbarui.'
            : 'Pengajuan barang keluar berhasil dikirim. Menunggu approval admin.',
      );

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar(
        widget.isEdit
            ? 'Gagal memperbarui barang keluar: $e'
            : 'Gagal submit barang keluar: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = selectedStock;

    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: _buildBottomButton(),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _OutboundFormBackgroundPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildHeader(),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: _primaryRed,
                    backgroundColor: Colors.white,
                    onRefresh: _loadMasterData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoBanner(),
                          if (isLoadingMaster) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: const LinearProgressIndicator(
                                minHeight: 4,
                                backgroundColor: Color(0xFFE5E7EB),
                                color: _primaryRed,
                              ),
                            ),
                          ],
                          if (errorMessage != null) ...[
                            const SizedBox(height: 10),
                            _buildErrorBanner(),
                          ],
                          const SizedBox(height: 14),
                          _buildDocumentSection(),
                          const SizedBox(height: 14),
                          _buildDetailBarangSection(stock),
                          const SizedBox(height: 14),
                          _buildSelectedItemsSection(),
                          const SizedBox(height: 14),
                          _buildAttachmentSection(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF5757),
            Color(0xFFEF4444),
            Color(0xFFDC2626),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryRed.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit ? 'Edit Barang Keluar' : 'Tambah Barang Keluar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEdit
                      ? 'Perbarui data pengeluaran'
                      : 'Input pengeluaran barang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFF1F2),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            onTap: _loadMasterData,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: const Color(0xFFFCA5A5),
              ),
            ),
            child: const Icon(
              Icons.outbox_rounded,
              color: _primaryRed,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              widget.isEdit
                  ? 'Data lama otomatis dimuat. Ubah bagian yang diperlukan lalu simpan kembali.'
                  : 'Data barang keluar akan dikirim sebagai pengajuan dan menunggu approval admin.',
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: _primaryRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage ?? 'Terjadi kesalahan.',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadMasterData,
            child: const Text(
              'Ulangi',
              style: TextStyle(
                color: _primaryRed,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection() {
    return _sectionCard(
      title: 'Data Dokumen',
      subtitle: 'Tanggal, jenis keluar, dan tujuan',
      icon: Icons.description_outlined,
      iconColor: _primaryBlue,
      iconBgColor: const Color(0xFFEFF6FF),
      child: Column(
        children: [
          _inputField(
            label: 'Tanggal Keluar',
            controller: tanggalController,
            readOnly: true,
            onTap: _pickTanggal,
            suffixIcon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'Jenis Keluar',
            controller: jenisKeluarController,
            hintText: 'Contoh: Penjualan',
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'Customer / Tujuan',
            controller: tujuanController,
            hintText: 'Masukkan customer / tujuan',
            suffixIcon: Icons.edit_outlined,
            onChanged: (_) {
              setState(() {
                selectedCustomerId = null;
              });
            },
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'No. Keluar / Referensi',
            hintText: 'Otomatis',
            controller: invoiceController,
            readOnly: true,
            enableInteractiveSelection: false,
            suffixIcon: Icons.lock_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBarangSection(Map<String, dynamic>? stock) {
    return _sectionCard(
      title: 'Detail Barang',
      subtitle: 'Pilih barang dan tentukan qty keluar',
      icon: Icons.inventory_2_outlined,
      iconColor: _primaryRed,
      iconBgColor: const Color(0xFFFFECEC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _barangSelector(stock),
          const SizedBox(height: 10),
          _quickAdditionalItems(),
          const SizedBox(height: 12),
          if (stock != null) ...[
            OutboundStockInfoCard(
              stock: stock,
              productName: _stockProductName(stock),
              productCode: _stockProductCode(stock),
              unit: _stockUnit(stock),
              warehouseName: _stockWarehouseName(stock),
              sizeText: _stockSize(stock),
              typeName: _stockType(stock),
              densityName: _stockDensity(stock),
              categoryName: _stockCategory(stock),
              availableQty: _availableQty(stock),
              availableAfterSelected: stokTersediaSetelahDipilih,
              sisaStok: sisaStok,
              barangHabis: barangHabis,
              qtyKosongAtauNol: qtyKosongAtauNol,
              stokTidakCukup: stokTidakCukup,
              formatQty: _formatQty,
              logoBuilder: (
                Map<String, dynamic> item, {
                double size = 40,
                bool selected = false,
              }) {
                return _buildProductLogo(
                  item,
                  size: size,
                  selected: selected,
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _inputField(
                  label: 'Qty Keluar',
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _readOnlyBox(
                  label: 'Satuan',
                  value: stock == null ? '-' : _stockUnit(stock),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: itemTidakValid ? null : _addItemToList,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Tambahkan ke Daftar',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryRed,
                disabledForegroundColor: const Color(0xFFFCA5A5),
                side: BorderSide(
                  color: itemTidakValid
                      ? const Color(0xFFFCA5A5)
                      : _primaryRed,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'Catatan',
            hintText: 'Contoh: barang keluar untuk penjualan...',
            controller: catatanController,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _barangSelector(Map<String, dynamic>? stock) {
    return InkWell(
      onTap: _showBarangPicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _borderColor,
          ),
        ),
        child: Row(
          children: [
            stock == null
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFECACA),
                      ),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: _primaryRed,
                      size: 21,
                    ),
                  )
                : _buildProductLogo(stock, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: stock == null
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Barang',
                          style: TextStyle(
                            fontSize: 11,
                            color: _softText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Belum ada barang dipilih',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: _darkText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Barang',
                          style: TextStyle(
                            fontSize: 11,
                            color: _softText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stockProductName(stock),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _darkText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_stockProductCode(stock)} • Stok ${_formatQty(stokTersediaSetelahDipilih)} ${_stockUnit(stock)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _softText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _softText,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAdditionalItems() {
    return Row(
      children: [
        Expanded(
          child: _quickAddChip(
            label: '+ VACUM',
            onTap: () => _quickAddBarang('VACUM'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickAddChip(
            label: '+ KARUNG',
            onTap: () => _quickAddBarang('KARUNG'),
          ),
        ),
      ],
    );
  }

  Widget _quickAddChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _primaryRed,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _readOnlyBox({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 47,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: _darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedItemsSection() {
    return _sectionCard(
      title: 'Daftar Barang Keluar',
      subtitle: selectedItems.isEmpty
          ? 'Belum ada barang ditambahkan'
          : '${selectedItems.length} item • ${_formatQty(totalQtyBarangKeluar)} qty',
      icon: Icons.list_alt_outlined,
      iconColor: _primaryRed,
      iconBgColor: const Color(0xFFFFECEC),
      child: selectedItems.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 38,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada barang ditambahkan',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pilih barang, isi qty, lalu tambahkan ke daftar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _softText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                ...selectedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == selectedItems.length - 1 ? 0 : 8,
                    ),
                    child: OutboundItemCard(
                      index: index,
                      item: item,
                      formatQty: _formatQty,
                      productLogoBuilder: (
                        Map<String, dynamic> item, {
                        double size = 40,
                        bool selected = false,
                      }) {
                        return _buildProductLogo(
                          item,
                          size: size,
                          selected: selected,
                        );
                      },
                      onIncrease: () => _increaseItemQty(index),
                      onDecrease: () => _decreaseItemQty(index),
                      onRemove: () => _removeItemFromList(index),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.summarize_outlined,
                        size: 18,
                        color: _primaryRed,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Total Qty Keluar',
                          style: TextStyle(
                            fontSize: 12,
                            color: _primaryRed,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        _formatQty(totalQtyBarangKeluar),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _primaryRed,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAttachmentSection() {
    return _sectionCard(
      title: 'Lampiran Bukti',
      subtitle: 'Upload foto maksimal 3 foto',
      icon: Icons.attach_file_rounded,
      iconColor: const Color(0xFF7C3AED),
      iconBgColor: const Color(0xFFF3E8FF),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _photoButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Kamera',
                  onTap: _pickFromCamera,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _photoButton(
                  icon: Icons.image_outlined,
                  label: 'Galeri',
                  onTap: _pickFromGallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _imagePreviewList(),
        ],
      ),
    );
  }

  Widget _photoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFFFECEC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isSubmitting ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFCA5A5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: _primaryRed,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _primaryRed,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePreviewList() {
    return Row(
      children: List.generate(3, (index) {
        final hasImage = index < selectedImages.length;

        return Expanded(
          child: InkWell(
            onTap: hasImage ? () => _showImagePreview(index) : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 84,
              margin: EdgeInsets.only(
                right: index == 2 ? 0 : 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasImage
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              selectedImages[index].bytes,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: Color(0xFF9CA3AF),
                              size: 24,
                            ),
                          ),
                  ),
                  if (hasImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0x66000000),
                            ],
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  if (hasImage)
                    const Positioned(
                      left: 8,
                      bottom: 7,
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Preview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasImage)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedImages.removeAt(index);
                          });
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: _primaryRed,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showImagePreview(int index) {
    if (index >= selectedImages.length) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedImages[index].fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _darkText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: _softText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.68,
                ),
                width: double.infinity,
                color: Colors.black,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.memory(
                    selectedImages[index].bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);

                          setState(() {
                            selectedImages.removeAt(index);
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Hapus Foto'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryRed,
                          side: const BorderSide(
                            color: Color(0xFFFECACA),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Selesai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: isSubmitting || formTidakValid ? null : _submitForm,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    widget.isEdit
                        ? Icons.check_circle_outline
                        : Icons.send_rounded,
                    size: 19,
                  ),
            label: Text(
              isSubmitting
                  ? 'Mengirim...'
                  : widget.isEdit
                      ? 'Perbarui Barang Keluar'
                      : 'Kirim Pengajuan Barang Keluar',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              disabledBackgroundColor: const Color(0xFFFCA5A5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _showBarangPicker() {
    showOutboundStockPicker(
      context: context,
      searchController: barangSearchController,
      stocks: stocks,
      selectedStockKey: selectedStockKey,
      stockKey: _stockKey,
      stockProductName: _stockProductName,
      stockProductCode: _stockProductCode,
      stockWarehouseName: _stockWarehouseName,
      stockSize: _stockSize,
      stockUnit: _stockUnit,
      stockType: _stockType,
      stockDensity: _stockDensity,
      stockCategory: _stockCategory,
      availableQty: _availableQty,
      stockLogoBuilder: (
        Map<String, dynamic> item, {
        double size = 40,
        bool selected = false,
      }) {
        return _buildProductLogo(
          item,
          size: size,
          selected: selected,
        );
      },
      onSelected: _selectStock,
    );
  }


  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _darkText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.2,
                        color: _softText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }


  Widget _inputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    bool enableInteractiveSelection = true,
    VoidCallback? onTap,
    IconData? suffixIcon,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          enableInteractiveSelection: enableInteractiveSelection,
          onTap: onTap,
          onChanged: onChanged,
          cursorColor: _primaryRed,
          style: const TextStyle(
            fontSize: 12.5,
            color: _darkText,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            suffixIcon: suffixIcon == null
                ? null
                : Icon(
                    suffixIcon,
                    color: _primaryRed,
                    size: 18,
                  ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 12 : 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: _primaryRed,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11.5,
        color: Color(0xFF374151),
        fontWeight: FontWeight.w800,
      ),
    );
  }


  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _primaryRed : const Color(0xFF16A34A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _OutboundFormBackgroundPainter extends CustomPainter {
  const _OutboundFormBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF7FAFC),
          Color(0xFFFFF1F2),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);

    final topCircle = Paint()
      ..color = const Color(0xFFFFECEC).withValues(alpha: 0.65);

    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.10),
      size.width * 0.35,
      topCircle,
    );

    final bottomCircle = Paint()
      ..color = const Color(0xFFEFF6FF).withValues(alpha: 0.55);

    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.88),
      size.width * 0.40,
      bottomCircle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}