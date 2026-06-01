import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

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
  DateTime selectedTanggal = DateTime.now();

  final TextEditingController tanggalController = TextEditingController();
  final TextEditingController invoiceController = TextEditingController();

  final TextEditingController supplierController = TextEditingController();
  final TextEditingController gudangController = TextEditingController();
  final TextEditingController productController = TextEditingController();

  final TextEditingController qtyController = TextEditingController();
  final TextEditingController unitCostController = TextEditingController(
    text: '0',
  );
  final TextEditingController detailBarangController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();

  final TextEditingController searchBarangController = TextEditingController();
  final TextEditingController searchSupplierController =
      TextEditingController();
  final TextEditingController searchGudangController = TextEditingController();

  final TextEditingController requestNamaBarangController =
      TextEditingController();
  final TextEditingController requestTypeController = TextEditingController();
  final TextEditingController requestDensityController = TextEditingController();
  final TextEditingController requestKategoriController =
      TextEditingController();
  final TextEditingController requestUkuranController = TextEditingController();
  final TextEditingController requestCatatanController =
      TextEditingController();

  String requestSatuan = 'PCS';

  bool isLoadingMaster = false;
  bool isSubmitting = false;

  String? errorMessage;

  int? selectedSupplierId;
  int? selectedWarehouseId;
  int? selectedProductId;

  final ImagePicker _picker = ImagePicker();
  final List<_PickedAttachment> selectedImages = [];

  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> warehouses = [];
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();

    tanggalController.text = _formatDate(selectedTanggal);
    _loadMasterData();
  }

  @override
  void dispose() {
    tanggalController.dispose();
    invoiceController.dispose();

    supplierController.dispose();
    gudangController.dispose();
    productController.dispose();

    qtyController.dispose();
    unitCostController.dispose();
    detailBarangController.dispose();
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

      setState(() {
        products = loadedProducts;
        suppliers = loadedSuppliers;
        warehouses = loadedWarehouses;

        if (suppliers.isNotEmpty && selectedSupplierId == null) {
          _selectSupplier(suppliers.first, updateState: false);
        }

        if (warehouses.isNotEmpty && selectedWarehouseId == null) {
          _selectWarehouse(warehouses.first, updateState: false);
        }

        if (products.isNotEmpty && selectedProductId == null) {
          _selectProduct(products.first, updateState: false);
        }
      });
    } on ApiException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
      _showSnackBar(e.message, isError: true);
    } catch (e) {
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

  Map<String, dynamic>? get selectedProduct {
    return _findById(products, selectedProductId);
  }

  Map<String, dynamic>? _findById(
    List<Map<String, dynamic>> list,
    int? id,
  ) {
    if (id == null) return null;

    for (final item in list) {
      if (_toInt(item['id']) == id) {
        return item;
      }
    }

    return null;
  }

  String get previewBarang {
    final item = selectedProduct;

    if (item == null) return '-';

    return _productDisplayName(item);
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

  String _formatQty(num value) {
    final doubleValue = value.toDouble();

    if (doubleValue % 1 == 0) {
      return doubleValue.toInt().toString();
    }

    return doubleValue.toStringAsFixed(2);
  }

  String _formatCurrency(num value) {
    final raw = _formatQty(value);
    final parts = raw.split('.');
    final number = parts.first;
    final buffer = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      final reverseIndex = number.length - i;

      buffer.write(number[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    if (parts.length > 1) {
      return 'Rp ${buffer.toString()},${parts.last}';
    }

    return 'Rp ${buffer.toString()}';
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

  String _cleanText(dynamic value) {
    if (value == null) return '';

    return value
        .toString()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _productDisplayName(Map<String, dynamic> item) {
    final displayName = _cleanText(item['display_name']);
    final name = _cleanText(item['name']);
    final productName = _cleanText(item['product_name']);

    if (displayName.isNotEmpty) return displayName;
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

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedTanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      selectedTanggal = picked;
      tanggalController.text = _formatDate(picked);
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
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      selectedImages.add(
        _PickedAttachment(
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
    );

    if (images.isEmpty) return;

    final remaining = 3 - selectedImages.length;

    for (final img in images.take(remaining)) {
      final bytes = await img.readAsBytes();

      selectedImages.add(
        _PickedAttachment(
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
    _showSnackBar('Maksimal 3 foto');
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('mobile_api_token') ??
        prefs.getString('api_token') ??
        prefs.getString('token');
  }

  String _contentTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    return 'application/octet-stream';
  }

  Future<void> _submitForm() async {
    if (isSubmitting) return;

    if (widget.isEdit) {
      _showSnackBar(
        'Mode edit belum disambungkan. Untuk sementara buat pengajuan baru.',
        isError: true,
      );
      return;
    }

    final product = selectedProduct;
    final supplier = selectedSupplier;
    final warehouse = selectedWarehouse;

    if (supplier == null || selectedSupplierId == null) {
      _showSnackBar('Pilih supplier terlebih dahulu.', isError: true);
      return;
    }

    if (warehouse == null || selectedWarehouseId == null) {
      _showSnackBar('Pilih gudang tujuan terlebih dahulu.', isError: true);
      return;
    }

    if (product == null || selectedProductId == null) {
      _showSnackBar('Pilih barang terlebih dahulu.', isError: true);
      return;
    }

    final qty = double.tryParse(qtyController.text.trim());

    if (qty == null || qty <= 0) {
      _showSnackBar('Qty barang wajib diisi dan harus lebih dari 0.',
          isError: true);
      return;
    }

    final unitCost = double.tryParse(unitCostController.text.trim()) ?? 0;

    setState(() {
      isSubmitting = true;
    });

    try {
      final token = await _getToken();

      if (token == null || token.trim().isEmpty) {
        throw ApiException(message: 'Token login tidak ditemukan.');
      }

      final uri = Uri.parse('${ApiService.baseUrl}/inbounds');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields.addAll({
        'transaction_date': _apiDate(selectedTanggal),
        'invoice_number': invoiceController.text.trim(),
        'supplier_id': selectedSupplierId.toString(),
        'warehouse_id': selectedWarehouseId.toString(),
        'note': catatanController.text.trim(),

        'items[0][product_id]': selectedProductId.toString(),
        'items[0][qty]': qty.toString(),
        'items[0][unit_cost]': unitCost.toString(),
        'items[0][note]': detailBarangController.text.trim(),
      });

      for (int i = 0; i < selectedImages.length; i++) {
        final file = selectedImages[i];

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
          message:
              'Gagal submit barang masuk. Status: ${response.statusCode}. ${response.body}',
          statusCode: response.statusCode,
        );
      }

      if (!mounted) return;

      _showSnackBar(
        'Pengajuan barang masuk berhasil dikirim. Menunggu approval admin.',
      );

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Gagal submit barang masuk: $e', isError: true);
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

  void _selectSupplier(
    Map<String, dynamic> item, {
    bool updateState = true,
  }) {
    void apply() {
      selectedSupplierId = _toInt(item['id']);
      supplierController.text = _supplierName(item);
    }

    if (updateState) {
      setState(apply);
    } else {
      apply();
    }
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

  void _selectProduct(
    Map<String, dynamic> item, {
    bool updateState = true,
  }) {
    void apply() {
      selectedProductId = _toInt(item['id']);
      productController.text = _productDisplayName(item);
    }

    if (updateState) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF7),
      bottomNavigationBar: _buildBottomButton(),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadMasterData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
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
                            color: Color(0xFF2F47B7),
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
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(14),
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
              ),
            ),
          ),
          TextButton(
            onPressed: _loadMasterData,
            child: const Text('Ulangi'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF2F47B7),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isEdit ? 'Edit Barang Masuk' : 'Tambah Barang Masuk',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadMasterData,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1677FF),
            Color(0xFF2F47B7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0D5BFF),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: const Icon(
              Icons.move_to_inbox_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Form Penerimaan Barang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Data yang dikirim akan masuk sebagai pending dan menunggu approval admin.',
                  style: TextStyle(
                    color: Color(0xFFEAF1FF),
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection() {
    return _sectionCard(
      title: 'Data Dokumen',
      subtitle: 'Informasi dasar penerimaan barang',
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF0D5BFF),
      iconBgColor: const Color(0xFFEFF6FF),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _inputField(
                  label: 'Tanggal Masuk',
                  controller: tanggalController,
                  readOnly: true,
                  onTap: _pickTanggal,
                  suffixIcon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inputField(
                  label: 'No. Invoice',
                  hintText: 'Opsional',
                  controller: invoiceController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _pickerInputField(
            label: 'Supplier',
            controller: supplierController,
            hintText: 'Pilih supplier',
            onTap: _showSupplierPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBarangSection() {
    final item = selectedProduct;

    return _sectionCard(
      title: 'Detail Barang',
      subtitle: 'Pilih barang dari master data',
      icon: Icons.inventory_2_outlined,
      iconColor: const Color(0xFF16A34A),
      iconBgColor: const Color(0xFFEFFDF5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _masterBarangSelector(),
          const SizedBox(height: 10),
          if (item != null) ...[
            _selectedItemPreview(item),
            const SizedBox(height: 10),
          ],
          _newItemRequestButton(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _inputField(
                  label: 'Qty Masuk',
                  hintText: 'Contoh: 10',
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inputField(
                  label: 'Harga Satuan',
                  hintText: '0',
                  controller: unitCostController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'Catatan Detail Barang',
            hintText: 'Contoh: kondisi barang baik, packing lengkap...',
            controller: detailBarangController,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _masterBarangSelector() {
    final item = selectedProduct;

    return InkWell(
      onTap: _showMasterBarangPicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Color(0xFF0D5BFF),
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Barang',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item == null
                        ? 'Pilih dari master barang'
                        : _productDisplayName(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (item != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${_productCode(item)} • ${_productUnit(item)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _newItemRequestButton() {
    return InkWell(
      onTap: _showRequestBarangBaruSheet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
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
    );
  }

  Widget _selectedItemPreview(Map<String, dynamic> item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Barang Terpilih',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _productDisplayName(item),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _itemInfoChip(Icons.qr_code_2_rounded, _productCode(item)),
              _itemInfoChip(Icons.inventory_2_outlined, _productUnit(item)),
              _itemInfoChip(Icons.category_outlined, _productType(item)),
              _itemInfoChip(Icons.layers_outlined, _productDensity(item)),
              _itemInfoChip(Icons.sell_outlined, _productCategory(item)),
              _itemInfoChip(Icons.straighten_rounded, _productSize(item)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemInfoChip(IconData icon, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
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
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(width: 5),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 10.8,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _sectionCard(
      title: 'Lokasi & Catatan',
      subtitle: 'Tentukan gudang tujuan dan catatan tambahan',
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
      subtitle: 'Upload foto bukti barang masuk maksimal 3 foto',
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
    return InkWell(
      onTap: isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
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
              color: const Color(0xFF0D5BFF),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF0D5BFF),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
      barrierColor: Colors.black.withOpacity(0.82),
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
                          color: Color(0xFF111827),
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
                          color: Color(0xFF6B7280),
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
                          backgroundColor: const Color(0xFF0D5BFF),
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
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
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
          height: 48,
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
                  ? 'MENGIRIM...'
                  : widget.isEdit
                      ? 'PERBARUI BARANG MASUK'
                      : 'KIRIM PENGAJUAN BARANG MASUK',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F47B7),
              disabledBackgroundColor: const Color(0xFF93A4D8),
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

  void _showSupplierPicker() {
    searchSupplierController.clear();

    _showGenericPicker(
      title: 'Pilih Supplier',
      searchController: searchSupplierController,
      items: suppliers,
      selectedId: selectedSupplierId,
      emptyText: 'Supplier tidak ditemukan',
      displayTitle: (item) => _supplierName(item),
      displaySubtitle: (item) {
        final phone = _cleanText(item['phone']);
        final email = _cleanText(item['email']);

        if (phone.isNotEmpty && email.isNotEmpty) return '$phone • $email';
        if (phone.isNotEmpty) return phone;
        if (email.isNotEmpty) return email;

        return 'Supplier';
      },
      onSelected: (item) {
        _selectSupplier(item);
      },
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
      displayTitle: (item) => _warehouseName(item),
      displaySubtitle: (item) => _warehouseCode(item),
      onSelected: (item) {
        _selectWarehouse(item);
      },
    );
  }

  void _showMasterBarangPicker() {
    searchBarangController.clear();

    _showGenericPicker(
      title: 'Pilih Barang Master',
      searchController: searchBarangController,
      items: products,
      selectedId: selectedProductId,
      emptyText: 'Barang tidak ditemukan',
      displayTitle: (item) => _productDisplayName(item),
      displaySubtitle: (item) {
        return '${_productCode(item)} • ${_productType(item)} • ${_productSize(item)}';
      },
      trailingText: (item) => _productUnit(item),
      headerAction: InkWell(
        onTap: () {
          Navigator.pop(context);
          _showRequestBarangBaruSheet();
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Ajukan Baru',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFF59E0B),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      onSelected: (item) {
        _selectProduct(item);
      },
    );
  }

  void _showGenericPicker({
    required String title,
    required TextEditingController searchController,
    required List<Map<String, dynamic>> items,
    required int? selectedId,
    required String emptyText,
    required String Function(Map<String, dynamic>) displayTitle,
    required String Function(Map<String, dynamic>) displaySubtitle,
    required void Function(Map<String, dynamic>) onSelected,
    String Function(Map<String, dynamic>)? trailingText,
    Widget? headerAction,
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
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.82,
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (headerAction != null) headerAction,
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: runSearch,
                              decoration: const InputDecoration(
                                hintText: 'Cari data...',
                                border: InputBorder.none,
                                isCollapsed: true,
                                hintStyle: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                                  trailing: trailingText?.call(item),
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
    required VoidCallback onTap,
    String? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF0D5BFF) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.inventory_2_outlined,
                color: isSelected ? Colors.white : const Color(0xFF0D5BFF),
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
                      color: Color(0xFF111827),
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
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(
                trailing,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF0D5BFF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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
                color: Color(0xFF6B7280),
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
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ajukan Barang Baru',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Untuk sementara pengajuan barang baru belum memiliki endpoint khusus. Data master tetap dibuat melalui dashboard admin.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7280),
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        label: 'Nama Barang',
                        hintText: 'Contoh: INOAC - EON 200x145x30',
                        controller: requestNamaBarangController,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _inputField(
                              label: 'Type',
                              hintText: 'EON',
                              controller: requestTypeController,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _inputField(
                              label: 'Density',
                              hintText: 'D-22',
                              controller: requestDensityController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _inputField(
                              label: 'Kategori',
                              hintText: 'LG++',
                              controller: requestKategoriController,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dropdownField(
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
                          ),
                        ],
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
                                  foregroundColor: const Color(0xFF6B7280),
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
                                  backgroundColor: const Color(0xFF0D5BFF),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
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
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
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
          onTap: onTap,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF111827),
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
                    color: const Color(0xFF0D5BFF),
                    size: 18,
                  ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 12 : 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0D5BFF),
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
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF6B7280),
              ),
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF111827),
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
}

class _PickedAttachment {
  final Uint8List bytes;
  final String fileName;

  const _PickedAttachment({
    required this.bytes,
    required this.fileName,
  });
}