import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inbound_item_form.dart';
import '../models/picked_attachment.dart';
import '../services/api_service.dart';
import '../widgets/inbound/master_product_picker.dart';
import '../widgets/shared/product_logo.dart';

class TambahBarangMasukScreen extends StatefulWidget {
  final bool isEdit;

  const TambahBarangMasukScreen({
    super.key,
    this.isEdit = false,
  });

  @override
  State<TambahBarangMasukScreen> createState() =>
      _TambahBarangMasukScreenState();
}

class _TambahBarangMasukScreenState extends State<TambahBarangMasukScreen> {
  static const Color _bgColor = Color(0xFFF7FAFC);
  static const Color _primaryGreen = Color(0xFF16A34A);
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkText = Color(0xFF111827);
  static const Color _softText = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  DateTime selectedTanggal = DateTime.now();

  final TextEditingController tanggalController = TextEditingController();
  final TextEditingController invoiceController = TextEditingController();

  final TextEditingController supplierController = TextEditingController();
  final TextEditingController gudangController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();

  final TextEditingController searchBarangController = TextEditingController();
  final TextEditingController searchSupplierController =
      TextEditingController();
  final TextEditingController searchGudangController = TextEditingController();

  final TextEditingController requestNamaBarangController =
      TextEditingController();
  final TextEditingController requestTypeController = TextEditingController();
  final TextEditingController requestDensityController =
      TextEditingController();
  final TextEditingController requestKategoriController =
      TextEditingController();
  final TextEditingController requestUkuranController =
      TextEditingController();
  final TextEditingController requestCatatanController =
      TextEditingController();

  String requestSatuan = 'PCS';

  bool isLoadingMaster = false;
  bool isSubmitting = false;

  bool isEditArgumentLoaded = false;
  bool hasAppliedEditDetail = false;

  int? editInboundId;
  Map<String, dynamic>? editDetail;

  String? errorMessage;

  int? selectedSupplierId;
  int? selectedWarehouseId;

  int masterLoadedAtMs = 0;
  int productLogoRebuildVersion = 0;

  final ImagePicker _picker = ImagePicker();

  final List<PickedAttachment> selectedImages = [];
  final List<InboundItemForm> selectedItems = [];

  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> warehouses = [];
  List<Map<String, dynamic>> products = [];

  static const String _fallbackProductionBaseUrl =
      'https://febru.djncloud.my.id';

  @override
  void initState() {
    super.initState();

    tanggalController.text = _formatDate(selectedTanggal);
    invoiceController.text = _generateInvoiceNumber(selectedTanggal);

    _loadMasterData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (isEditArgumentLoaded) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      editInboundId = int.tryParse(args['id']?.toString() ?? '');

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
    invoiceController.dispose();

    supplierController.dispose();
    gudangController.dispose();
    catatanController.dispose();

    searchBarangController.dispose();
    searchSupplierController.dispose();
    searchGudangController.dispose();

    requestNamaBarangController.dispose();
    requestTypeController.dispose();
    requestDensityController.dispose();
    requestKategoriController.dispose();
    requestUkuranController.dispose();
    requestCatatanController.dispose();

    for (final item in selectedItems) {
      item.dispose();
    }

    super.dispose();
  }

  Future<void> _loadMasterData() async {
    if (isLoadingMaster) return;

    setState(() {
      isLoadingMaster = true;
      errorMessage = null;
    });

    try {
      final productResponse = await ApiService.get('/master/products');
      final supplierResponse = await ApiService.get('/master/suppliers');
      final warehouseResponse = await ApiService.get('/master/warehouses');

      final loadedProducts = _extractList(productResponse);
      final loadedSuppliers = _extractList(supplierResponse);
      final loadedWarehouses = _extractList(warehouseResponse);

      if (!mounted) return;

      setState(() {
        products = loadedProducts;
        suppliers = loadedSuppliers;
        warehouses = loadedWarehouses;
        masterLoadedAtMs = DateTime.now().millisecondsSinceEpoch;

        if (!widget.isEdit) {
          if (warehouses.isNotEmpty && selectedWarehouseId == null) {
            _selectWarehouse(warehouses.first, updateState: false);
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
        errorMessage = 'Gagal memuat master data: $e';
      });

      _showSnackBar('Gagal memuat master data: $e', isError: true);
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
    if (products.isEmpty) return;

    _applyEditDetail(editDetail!);
  }

  void _applyEditDetail(Map<String, dynamic> data) {
    if (hasAppliedEditDetail) return;

    final transactionDate = _parseDate(data['transaction_date']);

    final supplierMap = _asMap(data['supplier']);
    final warehouseMap = _asMap(data['warehouse']);
    final itemList = _asMapList(data['items']);

    final supplierId = _toInt(data['supplier_id'] ?? supplierMap['id']);
    final warehouseId = _toInt(data['warehouse_id'] ?? warehouseMap['id']);

    final matchedSupplier = _findById(suppliers, supplierId) ?? supplierMap;
    final matchedWarehouse = _findById(warehouses, warehouseId) ?? warehouseMap;

    final List<InboundItemForm> loadedItems = [];

    for (final item in itemList) {
      final product = _productFromEditItem(item);
      final qtyText = _numberText(item['qty']);
      final unitCostText = _editUnitCostText(item, product);
      final noteText = _cleanText(item['note']);

      loadedItems.add(
        InboundItemForm(
          product: product,
          qty: qtyText,
          unitCost: unitCostText,
          note: noteText,
        ),
      );
    }

    for (final item in selectedItems) {
      item.dispose();
    }

    setState(() {
      if (transactionDate != null) {
        selectedTanggal = transactionDate;
        tanggalController.text = _formatDate(transactionDate);
      }

      final invoice = _cleanText(data['invoice_number']);
      if (invoice.isNotEmpty) {
        invoiceController.text = invoice;
      }

      if (supplierId > 0) {
        selectedSupplierId = supplierId;
      }

      if (matchedSupplier.isNotEmpty) {
        supplierController.text = _supplierName(matchedSupplier);
      }

      if (warehouseId > 0) {
        selectedWarehouseId = warehouseId;
      }

      if (matchedWarehouse.isNotEmpty) {
        gudangController.text = _warehouseName(matchedWarehouse);
      }

      catatanController.text = _cleanText(data['note']);

      selectedItems
        ..clear()
        ..addAll(loadedItems);

      productLogoRebuildVersion++;
      hasAppliedEditDetail = true;
    });
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

  Map<String, dynamic>? get selectedSupplier {
    return _findById(suppliers, selectedSupplierId);
  }

  Map<String, dynamic>? get selectedWarehouse {
    return _findById(warehouses, selectedWarehouseId);
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

  Map<String, dynamic> _productFromEditItem(Map<String, dynamic> item) {
    final nestedProduct = _asMap(item['product']);

    final productId = _toInt(
      item['product_id'] ??
          item['productId'] ??
          nestedProduct['id'] ??
          nestedProduct['product_id'],
    );

    final masterProduct = _findById(products, productId);

    if (masterProduct != null) {
      return masterProduct;
    }

    final productName = _firstClean([
      item['product_display_name'],
      item['product_full_name'],
      item['product_name'],
      nestedProduct['display_name'],
      nestedProduct['full_name'],
      nestedProduct['name'],
    ]);

    final productCode = _firstClean([
      item['product_code'],
      nestedProduct['code'],
      nestedProduct['product_code'],
    ]);

    final productSize = _firstClean([
      item['product_size_text'],
      item['size_text'],
      nestedProduct['size_text'],
      nestedProduct['product_size_text'],
    ]);

    final unitName = _firstClean([
      item['unit_name'],
      item['unit'],
      nestedProduct['unit_name'],
      nestedProduct['unit'],
    ]);

    final typeName = _firstClean([
      item['type_name'],
      item['product_type_name'],
      nestedProduct['type_name'],
      nestedProduct['product_type_name'],
    ]);

    final densityName = _firstClean([
      item['density_name'],
      item['product_density_name'],
      nestedProduct['density_name'],
      nestedProduct['product_density_name'],
    ]);

    final categoryName = _firstClean([
      item['category_name'],
      item['product_category_name'],
      nestedProduct['category_name'],
      nestedProduct['product_category_name'],
    ]);

    final logoPath = _firstClean([
      item['logo_path'],
      item['product_logo_path'],
      nestedProduct['logo_path'],
      nestedProduct['product_logo_path'],
    ]);

    final logoUrl = _firstClean([
      item['logo_url'],
      item['product_logo_url'],
      nestedProduct['logo_url'],
      nestedProduct['product_logo_url'],
    ]);

    final oldItemId = _toInt(
      item['id'] ??
          item['inbound_item_id'] ??
          item['transaction_item_id'] ??
          item['item_id'] ??
          item['detail_id'],
    );

    return {
      'id': productId,
      'inbound_item_id': oldItemId,
      'transaction_item_id': oldItemId,
      'item_id': oldItemId,
      'detail_id': oldItemId,
      'code': productCode,
      'product_code': productCode,
      'name': productName,
      'display_name': productName,
      'full_name': productName,
      'product_name': productName,
      'size_text': productSize,
      'product_size_text': productSize,
      'unit_name': unitName.isEmpty ? 'PCS' : unitName,
      'type_name': typeName,
      'density_name': densityName,
      'category_name': categoryName,
      'logo_path': logoPath.isEmpty ? null : logoPath,
      'product_logo_path': logoPath.isEmpty ? null : logoPath,
      'logo_url': logoUrl.isEmpty ? null : logoUrl,
      'product_logo_url': logoUrl.isEmpty ? null : logoUrl,
      'default_purchase_price': item['unit_cost'],
      'last_purchase_price': item['unit_cost'],
    };
  }

  String _firstClean(List<dynamic> values) {
    for (final value in values) {
      final text = _cleanText(value);

      if (text.isNotEmpty && text != '-') {
        return text;
      }
    }

    return '';
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  String _cleanText(dynamic value) {
    if (value == null) return '';

    return value
        .toString()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();

    if (raw.isEmpty) return null;

    return DateTime.tryParse(raw);
  }

  String _numberText(dynamic value) {
    final number = _toMoneyDouble(value);

    if (number <= 0) return '';

    if (number % 1 == 0) {
      return number.toInt().toString();
    }

    var result = number.toStringAsFixed(2);
    result = result.replaceFirst(RegExp(r'0+$'), '');
    result = result.replaceFirst(RegExp(r'\.$'), '');

    return result;
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

  String _generateInvoiceNumber(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return 'INV-IN-$year$month$day-0001';
  }

  String _productDisplayName(Map<String, dynamic> item) {
    final displayName = _cleanText(item['display_name']);
    final fullName = _cleanText(item['full_name']);
    final name = _cleanText(item['name']);
    final productName = _cleanText(item['product_name']);

    if (displayName.isNotEmpty) return displayName;
    if (fullName.isNotEmpty) return fullName;
    if (name.isNotEmpty) return name;
    if (productName.isNotEmpty) return productName;

    return '-';
  }

  String _productCode(Map<String, dynamic> item) {
    final code = _cleanText(item['code']);
    final productCode = _cleanText(item['product_code']);

    if (code.isNotEmpty) return code;
    if (productCode.isNotEmpty) return productCode;

    return '-';
  }

  String _productUnit(Map<String, dynamic> item) {
    final unitName = _cleanText(item['unit_name']);
    final unit = item['unit'];

    if (unitName.isNotEmpty) return unitName;

    if (unit is Map) {
      final unitMap = Map<String, dynamic>.from(unit);
      final name = _cleanText(unitMap['name']);

      if (name.isNotEmpty) return name;
    }

    return 'PCS';
  }

  String _productType(Map<String, dynamic> item) {
    final typeName = _cleanText(item['type_name']);
    final productType = item['product_type'];
    final type = item['type'];

    if (typeName.isNotEmpty) return typeName;

    if (productType is Map) {
      final map = Map<String, dynamic>.from(productType);
      final name = _cleanText(map['name']);

      if (name.isNotEmpty) return name;
    }

    if (type is Map) {
      final map = Map<String, dynamic>.from(type);
      final name = _cleanText(map['name']);

      if (name.isNotEmpty) return name;
    }

    return '-';
  }

  String _productDensity(Map<String, dynamic> item) {
    final densityName = _cleanText(item['density_name']);
    final density = item['density'];
    final productDensity = item['product_density'];

    if (densityName.isNotEmpty) return densityName;

    if (density is Map) {
      final map = Map<String, dynamic>.from(density);
      final name = _cleanText(map['name']);

      if (name.isNotEmpty) return name;
    }

    if (productDensity is Map) {
      final map = Map<String, dynamic>.from(productDensity);
      final name = _cleanText(map['name']);

      if (name.isNotEmpty) return name;
    }

    return '-';
  }

  String _productCategory(Map<String, dynamic> item) {
    final categoryName = _cleanText(item['category_name']);
    final category = item['category'];
    final productCategory = item['product_category'];

    if (categoryName.isNotEmpty) return categoryName;

    if (category is Map) {
      final map = Map<String, dynamic>.from(category);
      final name = _cleanText(map['name']);

      if (name.isNotEmpty) return name;
    }

    if (productCategory is Map) {
      final map = Map<String, dynamic>.from(productCategory);
      final name = _cleanText(map['name']);

      if (name.isNotEmpty) return name;
    }

    return '-';
  }

  String _productSize(Map<String, dynamic> item) {
    final sizeText = _cleanText(item['size_text']);
    final productSizeText = _cleanText(item['product_size_text']);

    if (sizeText.isNotEmpty) return sizeText;
    if (productSizeText.isNotEmpty) return productSizeText;

    final length = _cleanText(item['length']);
    final width = _cleanText(item['width']);
    final thickness = _cleanText(item['thickness']);

    if (length.isNotEmpty && width.isNotEmpty && thickness.isNotEmpty) {
      return '$length x $width x $thickness';
    }

    return '-';
  }

  String _supplierName(Map<String, dynamic> item) {
    final name = _cleanText(item['name']);
    final supplierName = _cleanText(item['supplier_name']);

    if (name.isNotEmpty) return name;
    if (supplierName.isNotEmpty) return supplierName;

    return '-';
  }

  String _warehouseName(Map<String, dynamic> item) {
    final name = _cleanText(item['name']);
    final warehouseName = _cleanText(item['warehouse_name']);

    if (name.isNotEmpty) return name;
    if (warehouseName.isNotEmpty) return warehouseName;

    return '-';
  }

  String _warehouseCode(Map<String, dynamic> item) {
    final code = _cleanText(item['code']);
    final warehouseCode = _cleanText(item['warehouse_code']);

    if (code.isNotEmpty) return code;
    if (warehouseCode.isNotEmpty) return warehouseCode;

    return '-';
  }

  Widget _buildProductLogo(
    Map<String, dynamic> item, {
    double size = 38,
    bool selected = false,
  }) {
    return ProductLogo(
      item: item,
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
              primary: _primaryGreen,
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
        invoiceController.text = _generateInvoiceNumber(picked);
      }
    });
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
              ? 'inbound-camera-${DateTime.now().millisecondsSinceEpoch}.jpg'
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
              ? 'inbound-gallery-${DateTime.now().millisecondsSinceEpoch}.jpg'
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

    final warehouse = selectedWarehouse;

    if (supplierController.text.trim().isEmpty) {
      _showSnackBar('Isi nama supplier terlebih dahulu.', isError: true);
      return;
    }

    if (warehouse == null || selectedWarehouseId == null) {
      _showSnackBar('Pilih gudang tujuan terlebih dahulu.', isError: true);
      return;
    }

    if (selectedItems.isEmpty) {
      _showSnackBar(
        'Tambahkan minimal satu barang terlebih dahulu.',
        isError: true,
      );
      return;
    }

    for (int i = 0; i < selectedItems.length; i++) {
      final item = selectedItems[i];
      final qty = double.tryParse(item.qtyController.text.trim());

      if (qty == null || qty <= 0) {
        _showSnackBar(
          'Qty barang ke-${i + 1} wajib diisi dan harus lebih dari 0.',
          isError: true,
        );
        return;
      }

      if (item.productId <= 0) {
        _showSnackBar(
          'Produk barang ke-${i + 1} tidak valid.',
          isError: true,
        );
        return;
      }
    }

    if (widget.isEdit && (editInboundId == null || editInboundId! <= 0)) {
      _showSnackBar(
        'ID pengajuan barang masuk tidak ditemukan.',
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

      final bool isEditing = widget.isEdit && editInboundId != null;

      final uri = Uri.parse(
        isEditing
            ? '${ApiService.baseUrl}/inbounds/$editInboundId'
            : '${ApiService.baseUrl}/inbounds',
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
        'invoice_number': invoiceController.text.trim(),
        'supplier_name': supplierController.text.trim(),
        'warehouse_id': selectedWarehouseId.toString(),
        'note': catatanController.text.trim(),
      });

      for (int i = 0; i < selectedItems.length; i++) {
        final item = selectedItems[i];

        final qty = double.tryParse(item.qtyController.text.trim()) ?? 0;
        final unitCost = _toMoneyDouble(item.unitCostController.text.trim());

        final oldItemId = _toInt(
          item.product['inbound_item_id'] ??
              item.product['transaction_item_id'] ??
              item.product['item_id'] ??
              item.product['detail_id'],
        );

        if (isEditing && oldItemId > 0) {
          request.fields['items[$i][id]'] = oldItemId.toString();
        }

        request.fields['items[$i][product_id]'] = item.productId.toString();
        request.fields['items[$i][qty]'] = qty.toString();
        request.fields['items[$i][unit_cost]'] = unitCost.toString();
        request.fields['items[$i][note]'] = item.noteController.text.trim();
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
              ? 'Gagal memperbarui barang masuk. Status: ${response.statusCode}. ${response.body}'
              : 'Gagal submit barang masuk. Status: ${response.statusCode}. ${response.body}',
          statusCode: response.statusCode,
        );
      }

      if (!mounted) return;

      _showSnackBar(
        isEditing
            ? 'Pengajuan barang masuk berhasil diperbarui.'
            : 'Pengajuan barang masuk berhasil dikirim. Menunggu approval admin.',
      );

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar(
        widget.isEdit
            ? 'Gagal memperbarui barang masuk: $e'
            : 'Gagal submit barang masuk: $e',
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

  void _submitRequestBarangBaru() {
    if (requestNamaBarangController.text.trim().isEmpty) {
      _showSnackBar('Nama barang wajib diisi', isError: true);
      return;
    }

    Navigator.pop(context);

    _showSnackBar(
      'Pengajuan barang baru belum memiliki endpoint khusus. Silakan tambahkan melalui dashboard admin.',
    );

    requestNamaBarangController.clear();
    requestTypeController.clear();
    requestDensityController.clear();
    requestKategoriController.clear();
    requestUkuranController.clear();
    requestCatatanController.clear();

    setState(() {
      requestSatuan = 'PCS';
    });
  }

  void _selectWarehouse(
    Map<String, dynamic> item, {
    bool updateState = true,
  }) {
    void apply() {
      selectedWarehouseId = _toInt(item['id']);
      gudangController.text = _warehouseName(item);
    }

    if (updateState) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _addProductItem(Map<String, dynamic> product) {
    final productId = _toInt(product['id']);

    final alreadyExists = selectedItems.any((item) {
      return item.productId == productId;
    });

    if (alreadyExists) {
      _showSnackBar('Barang ini sudah ditambahkan.', isError: true);
      return;
    }

    setState(() {
      selectedItems.add(
        InboundItemForm(
          product: product,
          qty: '',
          unitCost: _defaultUnitCostText(product),
          note: '',
        ),
      );

      productLogoRebuildVersion++;
    });
  }

  void _removeProductItem(int index) {
    if (index < 0 || index >= selectedItems.length) return;

    setState(() {
      final item = selectedItems.removeAt(index);
      item.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      bottomNavigationBar: _buildBottomButton(),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _InboundFormBackgroundPainter(),
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
                    color: _primaryGreen,
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
                                color: _primaryGreen,
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
                          _buildDetailBarangSection(),
                          const SizedBox(height: 14),
                          _buildLocationSection(),
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
            Color(0xFF22C55E),
            Color(0xFF16A34A),
            Color(0xFF15803D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.18),
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
                  widget.isEdit ? 'Edit Barang Masuk' : 'Tambah Barang Masuk',
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
                      ? 'Perbarui data penerimaan'
                      : 'Input penerimaan barang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFEFFDF5),
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
        color: const Color(0xFFEFFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
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
                color: const Color(0xFFD1FAE5),
              ),
            ),
            child: const Icon(
              Icons.move_to_inbox_rounded,
              color: _primaryGreen,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              widget.isEdit
                  ? 'Data lama otomatis dimuat. Ubah bagian yang diperlukan lalu simpan kembali.'
                  : 'Data barang masuk akan dikirim sebagai pengajuan dan menunggu approval admin.',
              style: const TextStyle(
                color: Color(0xFF166534),
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
            color: Color(0xFFEF4444),
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
      subtitle: 'Tanggal, invoice, dan supplier',
      icon: Icons.description_outlined,
      iconColor: _primaryBlue,
      iconBgColor: const Color(0xFFEFF6FF),
      child: Column(
        children: [
          _inputField(
            label: 'Tanggal Masuk',
            controller: tanggalController,
            readOnly: true,
            onTap: _pickTanggal,
            suffixIcon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'No. Invoice',
            hintText: 'Otomatis',
            controller: invoiceController,
            readOnly: true,
            enableInteractiveSelection: false,
            suffixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'Supplier',
            controller: supplierController,
            hintText: 'Masukkan nama supplier',
            suffixIcon: Icons.edit_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBarangSection() {
    return _sectionCard(
      title: 'Detail Barang',
      subtitle: 'Pilih barang dan isi jumlah masuk',
      icon: Icons.inventory_2_outlined,
      iconColor: _primaryGreen,
      iconBgColor: const Color(0xFFEFFDF5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _addProductButton(),
          const SizedBox(height: 10),
          if (selectedItems.isEmpty)
            _emptySelectedProductState()
          else
            Column(
              children: List.generate(selectedItems.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == selectedItems.length - 1 ? 0 : 10,
                  ),
                  child: _selectedInboundItemCard(
                    itemForm: selectedItems[index],
                    index: index,
                  ),
                );
              }),
            ),
          const SizedBox(height: 10),
          _newItemRequestButton(),
        ],
      ),
    );
  }

  Widget _addProductButton() {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _showMasterBarangPicker,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFDF5),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFFBBF7D0),
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: _primaryGreen,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah Barang',
                      style: TextStyle(
                        fontSize: 13,
                        color: _darkText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pilih barang dari master data',
                      style: TextStyle(
                        fontSize: 11,
                        color: _softText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _softText,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptySelectedProductState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFF59E0B),
            size: 20,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Belum ada barang dipilih. Tekan tombol Tambah Barang untuk menambahkan item.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedInboundItemCard({
    required InboundItemForm itemForm,
    required int index,
  }) {
    final product = itemForm.product;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildProductLogo(product, size: 42),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Barang ${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _primaryGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _productDisplayName(product),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _darkText,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _removeProductItem(index),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _itemInfoChip(Icons.qr_code_2_rounded, _productCode(product)),
              _itemInfoChip(Icons.inventory_2_outlined, _productUnit(product)),
              _itemInfoChip(Icons.category_outlined, _productType(product)),
              _itemInfoChip(Icons.layers_outlined, _productDensity(product)),
              _itemInfoChip(Icons.sell_outlined, _productCategory(product)),
              _itemInfoChip(Icons.straighten_rounded, _productSize(product)),
            ],
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'Qty Masuk',
            hintText: 'Contoh: 10',
            controller: itemForm.qtyController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'Harga Satuan',
            hintText: 'Rp 0',
            controller: itemForm.unitCostController,
            readOnly: true,
            enableInteractiveSelection: false,
            suffixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'Catatan Detail Barang',
            hintText: 'Contoh: kondisi barang baik, packing lengkap...',
            controller: itemForm.noteController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _itemInfoChip(IconData icon, dynamic value) {
    final text = value == null || value.toString().trim().isEmpty
        ? '-'
        : value.toString();

    final maxWidth =
        ((MediaQuery.of(context).size.width - 82).clamp(90.0, 260.0))
            .toDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFD1FAE5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: _primaryGreen,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 10.8,
                  color: _darkText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newItemRequestButton() {
    return Material(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _showRequestBarangBaruSheet,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFED7AA),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 18,
                color: Color(0xFFF59E0B),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ajukan barang baru',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return _sectionCard(
      title: 'Lokasi & Catatan',
      subtitle: 'Gudang tujuan dan catatan tambahan',
      icon: Icons.location_on_outlined,
      iconColor: const Color(0xFFF59E0B),
      iconBgColor: const Color(0xFFFFF7ED),
      child: Column(
        children: [
          _pickerInputField(
            label: 'Gudang Tujuan',
            controller: gudangController,
            hintText: 'Pilih gudang tujuan',
            onTap: _showWarehousePicker,
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'Catatan',
            hintText: 'Tulis catatan tambahan jika ada...',
            controller: catatanController,
            maxLines: 3,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          _buildImagePreviewList(),
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
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isSubmitting ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFBFDBFE),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: _primaryBlue,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _primaryBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreviewList() {
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
                      ? const Color(0xFFBFDBFE)
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
                            color: Color(0xFFEF4444),
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
                          foregroundColor: const Color(0xFFEF4444),
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
                          backgroundColor: _primaryBlue,
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
            onPressed: isSubmitting ? null : _submitForm,
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
                      ? 'Perbarui Barang Masuk'
                      : 'Kirim Pengajuan Barang Masuk',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              disabledBackgroundColor: const Color(0xFF86EFAC),
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


  void _showWarehousePicker() {
    searchGudangController.clear();

    _showGenericPicker(
      title: 'Pilih Gudang',
      searchController: searchGudangController,
      items: warehouses,
      selectedId: selectedWarehouseId,
      emptyText: 'Gudang tidak ditemukan',
      icon: Icons.warehouse_outlined,
      displayTitle: (item) => _warehouseName(item),
      displaySubtitle: (item) => _warehouseCode(item),
      onSelected: _selectWarehouse,
    );
  }

  void _showMasterBarangPicker() {
    showMasterProductPicker(
      context: context,
      searchController: searchBarangController,
      products: products,
      selectedProductId: null,
      toInt: _toInt,
      productDisplayName: _productDisplayName,
      productCode: _productCode,
      productUnit: _productUnit,
      productType: _productType,
      productDensity: _productDensity,
      productCategory: _productCategory,
      productSize: _productSize,
      productLogoBuilder: (
        Map<String, dynamic> item, {
        double size = 38,
        bool selected = false,
      }) {
        return _buildProductLogo(
          item,
          size: size,
          selected: selected,
        );
      },
      onSelected: _addProductItem,
      onRequestNewProduct: _showRequestBarangBaruSheet,
    );
  }

  void _showGenericPicker({
    required String title,
    required TextEditingController searchController,
    required List<Map<String, dynamic>> items,
    required int? selectedId,
    required String emptyText,
    required IconData icon,
    required String Function(Map<String, dynamic>) displayTitle,
    required String Function(Map<String, dynamic>) displaySubtitle,
    required void Function(Map<String, dynamic>) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        List<Map<String, dynamic>> filtered = List.from(items);

        return StatefulBuilder(
          builder: (context, setModalState) {
            void runSearch(String value) {
              final query = value.trim().toLowerCase();

              setModalState(() {
                filtered = items.where((item) {
                  final titleText = displayTitle(item).toLowerCase();
                  final subtitleText = displaySubtitle(item).toLowerCase();

                  return titleText.contains(query) ||
                      subtitleText.contains(query);
                }).toList();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.84,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sheetHandle(),
                      const SizedBox(height: 16),
                      _sheetHeader(
                        icon: icon,
                        title: title,
                        subtitle: '${items.length} data tersedia',
                        color: _primaryGreen,
                        bgColor: const Color(0xFFEFFDF5),
                      ),
                      const SizedBox(height: 12),
                      _bottomSearchField(
                        controller: searchController,
                        hintText: 'Cari data...',
                        onChanged: runSearch,
                        onClear: () {
                          searchController.clear();
                          runSearch('');
                        },
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: filtered.isEmpty
                            ? _emptyPickerState(emptyText)
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final isSelected =
                                      selectedId == _toInt(item['id']);

                                  return _pickerOption(
                                    item: item,
                                    isSelected: isSelected,
                                    title: displayTitle(item),
                                    subtitle: displaySubtitle(item),
                                    icon: icon,
                                    onTap: () {
                                      onSelected(item);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _pickerOption({
    required Map<String, dynamic> item,
    required bool isSelected,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFFDF5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFBBF7D0) : _borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? _primaryGreen : const Color(0xFFEFFDF5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : icon,
                color: isSelected ? Colors.white : _primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _darkText,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
          ],
        ),
      ),
    );
  }

  Widget _emptyPickerState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF9CA3AF),
              size: 38,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coba kata kunci lain atau refresh master data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: _softText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestBarangBaruSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _sheetHandle()),
                        const SizedBox(height: 16),
                        _sheetHeader(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Ajukan Barang Baru',
                          subtitle:
                              'Untuk sementara master barang dibuat melalui dashboard admin.',
                          color: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFFFF7ED),
                        ),
                        const SizedBox(height: 16),
                        _inputField(
                          label: 'Nama Barang',
                          hintText: 'Contoh: INOAC - EON 200x145x30',
                          controller: requestNamaBarangController,
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          label: 'Type',
                          hintText: 'EON',
                          controller: requestTypeController,
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          label: 'Density',
                          hintText: 'D-22',
                          controller: requestDensityController,
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          label: 'Kategori',
                          hintText: 'LG++',
                          controller: requestKategoriController,
                        ),
                        const SizedBox(height: 12),
                        _dropdownField(
                          label: 'Satuan',
                          value: requestSatuan,
                          items: const ['PCS', 'ROLL', 'UNIT'],
                          onChanged: (value) {
                            if (value == null) return;

                            setModalState(() {
                              requestSatuan = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          label: 'Ukuran',
                          hintText: 'Contoh: 200x145x30',
                          controller: requestUkuranController,
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          label: 'Catatan Pengajuan',
                          hintText: 'Tulis alasan atau detail barang baru...',
                          controller: requestCatatanController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _softText,
                                    side: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Batal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: _submitRequestBarangBaru,
                                  icon: const Icon(
                                    Icons.send_rounded,
                                    size: 17,
                                  ),
                                  label: const Text(
                                    'Ajukan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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

  Widget _pickerInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return _inputField(
      label: label,
      controller: controller,
      hintText: hintText,
      readOnly: true,
      onTap: onTap,
      suffixIcon: Icons.keyboard_arrow_down_rounded,
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
          cursorColor: _primaryGreen,
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
                    color: _primaryGreen,
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
                color: _primaryGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        Container(
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _softText,
              ),
              style: const TextStyle(
                fontSize: 12.5,
                color: _darkText,
                fontWeight: FontWeight.w700,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
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

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: _borderColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _sheetHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  color: _darkText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _softText,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomSearchField({
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: _softText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                isCollapsed: true,
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: _darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _toMoneyDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    var text = value.toString().trim();

    if (text.isEmpty || text == '-') return 0;

    text = text
        .replaceAll('Rp', '')
        .replaceAll('rp', '')
        .replaceAll('IDR', '')
        .replaceAll('idr', '')
        .replaceAll(' ', '')
        .trim();

    if (text.isEmpty) return 0;

    if (text.contains(',')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(text) ?? 0;
    }

    final decimalPattern = RegExp(r'^\d+\.\d{1,2}$');

    if (decimalPattern.hasMatch(text)) {
      return double.tryParse(text) ?? 0;
    }

    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    return double.tryParse(text) ?? 0;
  }

  String _formatRupiah(num value) {
    final number = value.round().toString();

    final buffer = StringBuffer();
    int counter = 0;

    for (int i = number.length - 1; i >= 0; i--) {
      buffer.write(number[i]);
      counter++;

      if (counter == 3 && i != 0) {
        buffer.write('.');
        counter = 0;
      }
    }

    final reversed = buffer.toString().split('').reversed.join();

    return 'Rp $reversed';
  }

  String _defaultUnitCostText(Map<String, dynamic> product) {
    final possibleValues = [
      product['unit_cost'],
      product['default_unit_cost'],
      product['purchase_price'],
      product['buy_price'],
      product['cost_price'],
      product['harga_beli'],
      product['harga_satuan'],
      product['last_purchase_price'],
      product['default_purchase_price'],
    ];

    for (final value in possibleValues) {
      final parsed = _toMoneyDouble(value);

      if (parsed > 0) {
        return _formatRupiah(parsed);
      }
    }

    return 'Rp 0';
  }

  String _editUnitCostText(
    Map<String, dynamic> item,
    Map<String, dynamic> product,
  ) {
    final possibleValues = [
      item['unit_cost'],
      item['harga_satuan'],
      item['purchase_price'],
      item['default_purchase_price'],
      product['unit_cost'],
      product['default_unit_cost'],
      product['purchase_price'],
      product['buy_price'],
      product['cost_price'],
      product['harga_beli'],
      product['harga_satuan'],
      product['last_purchase_price'],
      product['default_purchase_price'],
    ];

    for (final value in possibleValues) {
      final parsed = _toMoneyDouble(value);

      if (parsed > 0) {
        return _formatRupiah(parsed);
      }
    }

    return 'Rp 0';
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
        backgroundColor: isError ? const Color(0xFFEF4444) : _primaryGreen,
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

class _InboundFormBackgroundPainter extends CustomPainter {
  const _InboundFormBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF7FAFC),
          Color(0xFFF0FDF4),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);

    final topCircle = Paint()
      ..color = const Color(0xFFEFFDF5).withValues(alpha: 0.65);

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