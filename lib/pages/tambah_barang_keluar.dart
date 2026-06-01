import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

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
  final TextEditingController customerSearchController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool isLoadingMaster = false;
  bool isSubmitting = false;
  String? errorMessage;

  int? selectedCustomerId;
  String? selectedStockKey;

  final List<_PickedAttachment> selectedImages = [];
  final List<Map<String, dynamic>> selectedItems = [];

  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> warehouses = [];
  List<Map<String, dynamic>> stocks = [];

  @override
  void initState() {
    super.initState();
    tanggalController.text = _formatDate(selectedTanggal);
    _loadMasterData();
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
    customerSearchController.dispose();
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

      setState(() {
        customers = loadedCustomers;
        warehouses = loadedWarehouses;
        stocks = loadedStocks;

        if (customers.isNotEmpty && selectedCustomerId == null) {
          _selectCustomer(customers.first, updateState: false);
        }

        if (stocks.isNotEmpty && selectedStockKey == null) {
          final availableStocks = stocks.where((item) {
            return _availableQty(item) > 0;
          }).toList();

          if (availableStocks.isNotEmpty) {
            _selectStock(availableStocks.first, updateState: false);
          } else {
            _selectStock(stocks.first, updateState: false);
          }
        }
      });
    } on ApiException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
      _showSnackBar(e.message, isError: true);
    } catch (e) {
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

  Map<String, dynamic>? get selectedCustomer {
    return _findById(customers, selectedCustomerId);
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
    if (id == null) return null;

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
    return selectedStock == null || qtyKosongAtauNol || barangHabis || stokTidakCukup;
  }

  bool get formTidakValid => selectedItems.isEmpty || selectedCustomerId == null;

  double get totalQtyBarangKeluar {
    return selectedItems.fold<double>(
      0,
      (total, item) => total + _toDouble(item['qty']),
    );
  }

  List<Map<String, dynamic>> get filteredStockList {
    final query = barangSearchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return stocks;
    }

    return stocks.where((item) {
      final code = _stockProductCode(item).toLowerCase();
      final name = _stockProductName(item).toLowerCase();
      final gudang = _stockWarehouseName(item).toLowerCase();

      return code.contains(query) ||
          name.contains(query) ||
          gudang.contains(query);
    }).toList();
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

  String _stockProductName(Map<String, dynamic> item) {
    final displayName = _cleanText(item['product_display_name']);
    final productName = _cleanText(item['product_name']);
    final name = _cleanText(item['name']);

    if (displayName.isNotEmpty) return displayName;
    if (productName.isNotEmpty) return productName;
    if (name.isNotEmpty) return name;

    return '-';
  }

  String _stockProductCode(Map<String, dynamic> item) {
    final productCode = _cleanText(item['product_code']);
    final code = _cleanText(item['code']);

    if (productCode.isNotEmpty) return productCode;
    if (code.isNotEmpty) return code;

    return '-';
  }

  String _stockUnit(Map<String, dynamic> item) {
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

  String _stockWarehouseCode(Map<String, dynamic> item) {
    final warehouseCode = _cleanText(item['warehouse_code']);

    if (warehouseCode.isNotEmpty) return warehouseCode;

    final warehouse = item['warehouse'];

    if (warehouse is Map) {
      final warehouseMap = Map<String, dynamic>.from(warehouse);
      final code = _cleanText(warehouseMap['code']);

      if (code.isNotEmpty) return code;
    }

    final warehouseId = _toInt(item['warehouse_id']);

    for (final warehouseItem in warehouses) {
      if (_toInt(warehouseItem['id']) == warehouseId) {
        return _cleanText(warehouseItem['code']);
      }
    }

    return '-';
  }

  String _stockSize(Map<String, dynamic> item) {
    final sizeText = _cleanText(item['product_size_text']);
    final size = _cleanText(item['size_text']);

    if (sizeText.isNotEmpty) return sizeText;
    if (size.isNotEmpty) return size;

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

  void _selectCustomer(
    Map<String, dynamic> item, {
    bool updateState = true,
  }) {
    void apply() {
      selectedCustomerId = _toInt(item['id']);
      tujuanController.text = _customerName(item);
    }

    if (updateState) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _selectStock(
    Map<String, dynamic> item, {
    bool updateState = true,
  }) {
    void apply() {
      selectedStockKey = _stockKey(item);
      qtyController.text = '1';
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

    if (stock.isEmpty) {
      _showSnackBar('Data stok tidak ditemukan.', isError: true);
      return;
    }

    final stok = _availableQty(stock);
    final currentQty = _toDouble(item['qty']);

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
      imageQuality: 60,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      selectedImages.add(
        _PickedAttachment(
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
      imageQuality: 60,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (images.isEmpty) return;

    final remaining = 3 - selectedImages.length;

    for (final img in images.take(remaining)) {
      final bytes = await img.readAsBytes();

      selectedImages.add(
        _PickedAttachment(
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

    if (widget.isEdit) {
      _showSnackBar(
        'Mode edit belum disambungkan. Untuk sementara buat pengajuan baru.',
        isError: true,
      );
      return;
    }

    if (selectedCustomerId == null) {
      _showSnackBar('Pilih customer / tujuan terlebih dahulu.', isError: true);
      return;
    }

    if (selectedItems.isEmpty) {
      _showSnackBar('Tambahkan minimal 1 barang terlebih dahulu.',
          isError: true);
      return;
    }

    final warehouseId = _toInt(selectedItems.first['warehouse_id']);

    if (warehouseId <= 0) {
      _showSnackBar('Gudang asal tidak valid.', isError: true);
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

      final uri = Uri.parse('${ApiService.baseUrl}/outbounds');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields.addAll({
        'transaction_date': _apiDate(selectedTanggal),
        'outbound_type': jenisKeluarController.text.trim().isEmpty
            ? 'Penjualan'
            : jenisKeluarController.text.trim(),
        'reference_number': invoiceController.text.trim(),
        'customer_id': selectedCustomerId.toString(),
        'warehouse_id': warehouseId.toString(),
        'note': catatanController.text.trim(),
      });

      for (int i = 0; i < selectedItems.length; i++) {
        final item = selectedItems[i];

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
          message:
              'Gagal submit barang keluar. Status: ${response.statusCode}. ${response.body}',
          statusCode: response.statusCode,
        );
      }

      if (!mounted) return;

      _showSnackBar(
        'Pengajuan barang keluar berhasil dikirim. Menunggu approval admin.',
      );

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Gagal submit barang keluar: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stock = selectedStock;

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
                            color: Color(0xFFEF4444),
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
        color: Color(0xFFB91C1C),
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
              widget.isEdit ? 'Edit Barang Keluar' : 'Tambah Barang Keluar',
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
            Color(0xFFEF4444),
            Color(0xFFB91C1C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1FEF4444),
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
              Icons.outbox_rounded,
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
                  'Form Pengeluaran Barang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Pilih barang dari stok, isi qty keluar, lalu kirim untuk approval admin.',
                  style: TextStyle(
                    color: Color(0xFFFFF1F2),
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
      subtitle: 'Informasi dasar barang keluar',
      icon: Icons.description_outlined,
      iconColor: const Color(0xFFEF4444),
      iconBgColor: const Color(0xFFFFECEC),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _inputField(
                  label: 'Tanggal Keluar',
                  controller: tanggalController,
                  readOnly: true,
                  onTap: _pickTanggal,
                  suffixIcon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inputField(
                  label: 'Jenis Keluar',
                  controller: jenisKeluarController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _pickerInputField(
            label: 'Customer / Tujuan',
            controller: tujuanController,
            hintText: 'Pilih customer / tujuan',
            onTap: _showCustomerPicker,
          ),
          const SizedBox(height: 12),
          _inputField(
            label: 'No. Keluar / Referensi',
            hintText: 'Opsional',
            controller: invoiceController,
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
      iconColor: const Color(0xFFEF4444),
      iconBgColor: const Color(0xFFFFECEC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _barangSelector(stock),
          const SizedBox(height: 10),
          _quickAdditionalItems(),
          const SizedBox(height: 12),
          if (stock != null) _selectedBarangPreview(stock),
          if (stock != null) const SizedBox(height: 12),
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
          const SizedBox(height: 10),
          _stockResultBox(stock),
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
                foregroundColor: const Color(0xFFEF4444),
                disabledForegroundColor: const Color(0xFFFCA5A5),
                side: BorderSide(
                  color: itemTidakValid
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFEF4444),
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
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Color(0xFFEF4444),
                size: 21,
              ),
            ),
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
                            color: Color(0xFF6B7280),
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
                            color: Color(0xFF111827),
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
                            color: Color(0xFF6B7280),
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
                            color: Color(0xFF111827),
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
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  void _showCustomerPicker() {
    customerSearchController.clear();

    _showGenericPicker(
      title: 'Pilih Customer / Tujuan',
      searchController: customerSearchController,
      items: customers,
      selectedId: selectedCustomerId,
      emptyText: 'Customer tidak ditemukan',
      displayTitle: (item) => _customerName(item),
      displaySubtitle: (item) {
        final phone = _cleanText(item['phone']);
        final email = _cleanText(item['email']);

        if (phone.isNotEmpty && email.isNotEmpty) return '$phone • $email';
        if (phone.isNotEmpty) return phone;
        if (email.isNotEmpty) return email;

        return 'Customer';
      },
      onSelected: (item) => _selectCustomer(item),
    );
  }

  void _showBarangPicker() {
    barangSearchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        List<Map<String, dynamic>> filtered = List.from(stocks);

        return StatefulBuilder(
          builder: (context, setModalState) {
            void runSearch(String value) {
              final query = value.trim().toLowerCase();

              setModalState(() {
                filtered = stocks.where((item) {
                  final code = _stockProductCode(item).toLowerCase();
                  final name = _stockProductName(item).toLowerCase();
                  final gudang = _stockWarehouseName(item).toLowerCase();

                  return code.contains(query) ||
                      name.contains(query) ||
                      gudang.contains(query);
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
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pilih Barang Stok',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
                              controller: barangSearchController,
                              onChanged: runSearch,
                              decoration: const InputDecoration(
                                hintText: 'Cari nama, kode, atau gudang',
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
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'Barang tidak ditemukan',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final bool isSelected =
                                    selectedStockKey == _stockKey(item);

                                return _barangOption(
                                  item: item,
                                  isSelected: isSelected,
                                  onTap: () {
                                    _selectStock(item);
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

  void _showGenericPicker({
    required String title,
    required TextEditingController searchController,
    required List<Map<String, dynamic>> items,
    required int? selectedId,
    required String emptyText,
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
                  return displayTitle(item).toLowerCase().contains(query) ||
                      displaySubtitle(item).toLowerCase().contains(query);
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  emptyText,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
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

                                return InkWell(
                                  onTap: () {
                                    onSelected(item);
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFFECEC)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFFCA5A5)
                                            : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFFFFECEC),
                                            borderRadius:
                                                BorderRadius.circular(13),
                                          ),
                                          child: Icon(
                                            isSelected
                                                ? Icons.check_rounded
                                                : Icons.person_outline_rounded,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFFEF4444),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayTitle(item),
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
                                                displaySubtitle(item),
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
                                      ],
                                    ),
                                  ),
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

  Widget _barangOption({
    required Map<String, dynamic> item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isEmpty = _availableQty(item) <= 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFECEC) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFCA5A5)
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
                    isSelected ? const Color(0xFFEF4444) : const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.inventory_2_outlined,
                color: isSelected ? Colors.white : const Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stockProductName(item),
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
                    '${_stockProductCode(item)} • ${_stockWarehouseName(item)} • ${_stockSize(item)}',
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
            const SizedBox(width: 8),
            Text(
              isEmpty
                  ? 'Habis'
                  : '${_formatQty(_availableQty(item))} ${_stockUnit(item)}',
              style: TextStyle(
                fontSize: 11,
                color: isEmpty
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF16A34A),
                fontWeight: FontWeight.w900,
              ),
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
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _selectedBarangPreview(Map<String, dynamic> stock) {
    final bool isEmpty = stokTersediaSetelahDipilih <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEmpty ? const Color(0xFFFFECEC) : const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmpty ? const Color(0xFFFCA5A5) : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _stockProductName(stock),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _itemInfoChip(Icons.qr_code_2_rounded, _stockProductCode(stock)),
              _itemInfoChip(
                Icons.inventory_2_outlined,
                '${_formatQty(_availableQty(stock))} ${_stockUnit(stock)}',
              ),
              _itemInfoChip(
                Icons.location_on_outlined,
                _stockWarehouseName(stock),
              ),
              _itemInfoChip(Icons.straighten_rounded, _stockSize(stock)),
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
          color: const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: const Color(0xFFEF4444),
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

  Widget _stockResultBox(Map<String, dynamic>? stock) {
    Color color;
    Color bgColor;
    Color borderColor;
    IconData icon;
    String text;

    if (stock == null) {
      color = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFED7AA);
      icon = Icons.warning_amber_rounded;
      text = 'Pilih barang';
    } else if (barangHabis) {
      color = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFFECEC);
      borderColor = const Color(0xFFFCA5A5);
      icon = Icons.cancel_outlined;
      text = 'Stok barang habis';
    } else if (qtyKosongAtauNol) {
      color = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFED7AA);
      icon = Icons.warning_amber_rounded;
      text = 'Qty harus lebih dari 0';
    } else if (stokTidakCukup) {
      color = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFFECEC);
      borderColor = const Color(0xFFFCA5A5);
      icon = Icons.warning_amber_rounded;
      text = 'Stok tidak cukup';
    } else {
      color = const Color(0xFF16A34A);
      bgColor = const Color(0xFFEFFDF5);
      borderColor = const Color(0xFFBBF7D0);
      icon = Icons.check_circle_outline_rounded;
      text = '${_formatQty(sisaStok)} ${_stockUnit(stock)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sisa stok setelah keluar',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF111827),
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
          : '${selectedItems.length} item • ${_formatQty(totalQtyBarangKeluar)} PCS',
      icon: Icons.list_alt_outlined,
      iconColor: const Color(0xFFEF4444),
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
                      color: Color(0xFF6B7280),
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
                    child: _selectedItemRow(index, item),
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
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Total Qty Keluar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${_formatQty(totalQtyBarangKeluar)} PCS',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFFEF4444),
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

  Widget _selectedItemRow(int index, Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(11),
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
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECEC),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item['code']} • ${item['gudang']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              _qtyButton(
                icon: Icons.remove_rounded,
                onTap: () => _decreaseItemQty(index),
              ),
              const SizedBox(width: 6),
              Text(
                _formatQty(_toDouble(item['qty'])),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                item['satuan'].toString(),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              _qtyButton(
                icon: Icons.add_rounded,
                onTap: () => _increaseItemQty(index),
              ),
            ],
          ),
          const SizedBox(width: 7),
          InkWell(
            onTap: () => _removeItemFromList(index),
            borderRadius: BorderRadius.circular(999),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 15,
          color: const Color(0xFFEF4444),
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return _sectionCard(
      title: 'Lampiran Bukti',
      subtitle: 'Upload foto bukti barang keluar maksimal 3 foto',
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
    return InkWell(
      onTap: isSubmitting ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
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
              color: const Color(0xFFEF4444),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
                          backgroundColor: const Color(0xFFEF4444),
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
                  ? 'MENGIRIM...'
                  : widget.isEdit
                      ? 'PERBARUI BARANG KELUAR'
                      : 'KIRIM PENGAJUAN BARANG KELUAR',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
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
                    color: const Color(0xFFEF4444),
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
                color: Color(0xFFEF4444),
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
}

class _PickedAttachment {
  final Uint8List bytes;
  final String fileName;

  const _PickedAttachment({
    required this.bytes,
    required this.fileName,
  });
}