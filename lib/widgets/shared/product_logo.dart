import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProductLogo extends StatelessWidget {
  final Map<String, dynamic> item;
  final double size;
  final bool selected;
  final String fallbackBaseUrl;
  final int masterLoadedAtMs;
  final int rebuildVersion;

  const ProductLogo({
    super.key,
    required this.item,
    required this.fallbackBaseUrl,
    this.size = 38,
    this.selected = false,
    this.masterLoadedAtMs = 0,
    this.rebuildVersion = 0,
  });

  static const Color _primaryBlue = Color(0xFF0D5BFF);
  static const Color _softBlueBg = Color(0xFFEFF6FF);
  static const Color _softBlueBorder = Color(0xFFBFDBFE);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _fallbackBorder = Color(0xFFDBEAFE);

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();

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

  String _normalizeBaseUrl(String value) {
    return value.trim().replaceAll(RegExp(r'/$'), '');
  }

  String _normalizeImageUrl(dynamic value) {
    final raw = _cleanText(value);

    if (raw.isEmpty || raw == '-') return '';

    if (raw.startsWith('data:image/')) {
      return raw;
    }

    if (raw.startsWith('//')) {
      return Uri.encodeFull('https:$raw');
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final uri = Uri.tryParse(raw);

      if (uri == null) {
        return Uri.encodeFull(raw);
      }

      final host = uri.host.toLowerCase();

      if (host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '0.0.0.0') {
        final baseUri = Uri.tryParse(_normalizeBaseUrl(fallbackBaseUrl));

        if (baseUri != null) {
          return baseUri
              .replace(
                path: uri.path,
                query: uri.query,
                fragment: uri.fragment,
              )
              .toString();
        }
      }

      return Uri.encodeFull(raw);
    }

    var path = raw.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');

    if (path.startsWith('public/')) {
      path = path.replaceFirst('public/', '');
    }

    final base = _normalizeBaseUrl(fallbackBaseUrl);

    if (base.isEmpty) return '';

    if (path.startsWith('storage/')) {
      return Uri.encodeFull('$base/$path');
    }

    return Uri.encodeFull('$base/storage/$path');
  }

  String _productLogoUrl(Map<String, dynamic> item) {
    final possibleUrls = [
      item['logo_url'],
      item['product_logo_url'],
      item['image_url'],
      item['photo_url'],
      item['thumbnail_url'],
    ];

    for (final value in possibleUrls) {
      final url = _normalizeImageUrl(value);
      if (url.isNotEmpty) return url;
    }

    final possiblePaths = [
      item['logo_path'],
      item['product_logo_path'],
      item['image_path'],
      item['photo_path'],
      item['thumbnail_path'],
      item['logo'],
      item['image'],
      item['photo'],
    ];

    for (final value in possiblePaths) {
      final url = _normalizeImageUrl(value);
      if (url.isNotEmpty) return url;
    }

    return '';
  }

  String _safeLogoKeyText(String value) {
    final clean = value
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return clean.isEmpty ? 'empty' : clean;
  }

  String _productLogoStableKey(
    Map<String, dynamic> item,
    String logoUrl,
  ) {
    final productId = _toInt(item['id']);
    final code = _safeLogoKeyText(_productCode(item));
    final logoPath = _safeLogoKeyText(_cleanText(item['logo_path']));
    final logoUrlKey = _safeLogoKeyText(logoUrl);

    return 'product-logo-$productId-$code-$logoPath-$logoUrlKey-$rebuildVersion';
  }

  String _productLogoCacheSafeUrl(
    String logoUrl,
    Map<String, dynamic> item,
  ) {
    if (logoUrl.trim().isEmpty) return '';

    if (logoUrl.startsWith('data:image/')) {
      return logoUrl;
    }

    final uri = Uri.tryParse(logoUrl);

    if (uri == null || !uri.hasScheme) {
      return logoUrl;
    }

    final queryParameters = Map<String, String>.from(uri.queryParameters);

    queryParameters['product_id'] = _toInt(item['id']).toString();
    queryParameters['product_code'] = _safeLogoKeyText(_productCode(item));
    queryParameters['logo_loaded_at'] = masterLoadedAtMs.toString();

    return uri.replace(queryParameters: queryParameters).toString();
  }

  String _productInitial(Map<String, dynamic> item) {
    final name = _productDisplayName(item);

    if (name.isNotEmpty && name != '-') {
      return name.substring(0, 1).toUpperCase();
    }

    final code = _productCode(item);

    if (code.isNotEmpty && code != '-') {
      return code.substring(0, 1).toUpperCase();
    }

    return '?';
  }

  double get _radius {
    if (size >= 46) return 15;
    if (size >= 40) return 14;
    return 13;
  }

  Widget _fallback(String initial) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? _primaryBlue : _softBlueBg,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: selected ? _primaryBlue : _fallbackBorder,
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size >= 46 ? 18 : (size >= 40 ? 16 : 15),
          fontWeight: FontWeight.w900,
          color: selected ? Colors.white : _primaryBlue,
        ),
      ),
    );
  }

  Widget _loading() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: selected ? _softBlueBorder : _borderColor,
        ),
      ),
      child: SizedBox(
        width: size <= 34 ? 13 : 15,
        height: size <= 34 ? 13 : 15,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: _primaryBlue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawLogoUrl = _productLogoUrl(item);
    final logoUrl = _productLogoCacheSafeUrl(rawLogoUrl, item);
    final logoKey = _productLogoStableKey(item, logoUrl);
    final initial = _productInitial(item);

    if (logoUrl.isEmpty) {
      return _fallback(initial);
    }

    return Container(
      key: ValueKey('logo-container-$logoKey'),
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: selected ? _softBlueBorder : _borderColor,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _primaryBlue.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - 4),
        child: Image.network(
          logoUrl,
          key: ValueKey('logo-image-$logoKey'),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              debugPrint('GAGAL LOAD LOGO: $logoUrl');
              debugPrint('ERROR LOGO: $error');
            }

            return _fallback(initial);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return _loading();
          },
        ),
      ),
    );
  }
}