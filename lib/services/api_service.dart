import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() {
    return message;
  }
}

class ApiUploadFile {
  final String fieldName;
  final String filename;
  final Uint8List bytes;

  const ApiUploadFile({
    required this.fieldName,
    required this.filename,
    required this.bytes,
  });
}

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.67/api/mobile/v1',
  );

  static const String _tokenKey = 'mobile_api_token';
  static const Duration _timeout = Duration(seconds: 30);

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Uri _uri(String endpoint, [Map<String, dynamic>? query]) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;

    final uri = Uri.parse('$cleanBase/$cleanEndpoint');

    final queryParams = <String, String>{};

    if (query != null) {
      query.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          queryParams[key] = value.toString();
        }
      });
    }

    if (queryParams.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: queryParams);
  }

  static Future<Map<String, String>> _headers({
    bool auth = true,
    bool jsonContent = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (jsonContent) {
      headers['Content-Type'] = 'application/json';
    }

    if (auth) {
      final token = await getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    try {
      final response = await http
          .get(
            _uri(endpoint, query),
            headers: await _headers(auth: auth),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Koneksi timeout. Coba lagi.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal terhubung ke server: $e');
    }
  }

  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final response = await http
          .post(
            _uri(endpoint),
            headers: await _headers(auth: auth),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Koneksi timeout. Coba lagi.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal terhubung ke server: $e');
    }
  }

  static Future<dynamic> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    List<ApiUploadFile> files = const [],
    bool auth = true,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        _uri(endpoint),
      );

      final headers = await _headers(
        auth: auth,
        jsonContent: false,
      );

      request.headers.addAll(headers);
      request.fields.addAll(fields);

      for (final file in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            file.fieldName,
            file.bytes,
            filename: file.filename,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Upload timeout. Coba lagi.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Gagal upload data: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final rawBody = response.body;

    dynamic decoded;

    if (rawBody.isNotEmpty) {
      try {
        decoded = jsonDecode(rawBody);
      } catch (_) {
        decoded = rawBody;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    }

    String message = 'Terjadi kesalahan server.';

    dynamic errors;

    if (decoded is Map<String, dynamic>) {
      message = decoded['message']?.toString() ?? message;
      errors = decoded['errors'];
    } else if (decoded is String && decoded.isNotEmpty) {
      message = decoded;
    }

    if (statusCode == 401) {
      message = 'Sesi login habis. Silakan login ulang.';
    }

    throw ApiException(
      statusCode: statusCode,
      message: message,
      errors: errors,
    );
  }
}