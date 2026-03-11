import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import 'chat_sdk.dart';

class ChatApiService {
  static Dio? _dio;
  static Dio? _imageUploadDio;
  static int _requestId = 0;

  static Dio get dio {
    _dio ??= Dio(
      BaseOptions(
        baseUrl: ChatSdk.config.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return _dio!;
  }

  static Dio get imageUploadDio {
    _imageUploadDio ??= Dio(
      BaseOptions(
        baseUrl: ChatSdk.config.imageUploadBaseUrl ?? ChatSdk.config.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return _imageUploadDio!;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await ChatSdk.config.authTokenProvider();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (ChatSdk.config.headersProvider != null) {
      final customHeaders = await ChatSdk.config.headersProvider!();
      headers.addAll(customHeaders);
    }
    return headers;
  }

  static Future<Map<String, String>> _getImageUploadHeaders() async {
    final token = await ChatSdk.config.authTokenProvider();
    final headers = <String, String>{};
    // Rasm yuklashda Content-Type avtomatik sozlanadi (multipart/form-data)
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (ChatSdk.config.headersProvider != null) {
      final customHeaders = await ChatSdk.config.headersProvider!();
      headers.addAll(customHeaders);
    }
    return headers;
  }

  static int _nextRequestId() {
    _requestId = DateTime.now().millisecondsSinceEpoch;
    return _requestId;
  }

  static Future<Either<String, dynamic>> _callJsonRpc({
    required String method,
    Map<String, dynamic>? params,
    int? timeoutSeconds,
    String? customBaseUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final id = _nextRequestId();
      final body = <String, dynamic>{
        'jsonrpc': '2.0',
        'method': method,
        'params': params ?? <String, dynamic>{},
        'id': id,
      };

      final url = customBaseUrl != null ? customBaseUrl : '';

      final response = await dio.post(
        url,
        data: body,
        options: Options(
          headers: headers,
          sendTimeout: Duration(seconds: timeoutSeconds ?? 30),
          receiveTimeout: Duration(seconds: timeoutSeconds ?? 30),
        ),
      );

      if (response.statusCode != 200) {
        return left('HTTP ${response.statusCode}: ${response.statusMessage}');
      }

      final responseData = response.data;
      if (responseData is! Map) {
        return left('Invalid response format: expected JSON object');
      }

      if (responseData['error'] != null) {
        final error = responseData['error'];
        if (error is Map && error['message'] != null) {
          return left('API Error: ${error['message']}');
        }
        return left('Unknown JSON-RPC error');
      }

      if (responseData.containsKey('result')) {
        return right(responseData['result']);
      }

      if (responseData['status'] == true) {
        return right(responseData['result']);
      }

      return left(responseData['message']?.toString() ?? 'Unknown error');
    } on DioException catch (e) {
      return left('Network error: ${e.message ?? 'Connection failed'}');
    } catch (e) {
      return left('Unexpected error: ${e.toString()}');
    }
  }

  static Future<Either<String, Map<String, dynamic>>> _uploadImageHttpFallback({
    required String filePath,
    required String fileName,
    int? replyToId,
  }) async {
    try {
      final headers = await _getImageUploadHeaders();
      
      debugPrint('ChatApi: Uploading image to ${ChatSdk.config.imageUploadBaseUrl ?? ChatSdk.config.baseUrl}');

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath, filename: fileName),
        if (replyToId != null) 'reply_to_id': replyToId,
      });

      final response = await imageUploadDio.post(
        ChatSdk.config.uploadImageEndpoint,
        data: formData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        debugPrint('ChatApi: Image uploaded successfully');
        return right(response.data['result'] as Map<String, dynamic>);
      }
      return left(response.data['message'] ?? 'Upload failed');
    } on DioException catch (e) {
      debugPrint('ChatApi: Image upload error - ${e.type}: ${e.message}');
      return left('Upload error: ${e.message ?? 'Connection failed'}');
    } catch (e, stackTrace) {
      debugPrint('ChatApi: Unexpected upload error - $e');
      debugPrint('ChatApi: Stack trace - $stackTrace');
      return left('Unexpected upload error: ${e.toString()}');
    }
  }

  static Future<Either<String, ConversationResult>> getConversation() async {
    final rpcResult = await _callJsonRpc(
      method: ChatSdk.config.getConversationEndpoint,
    );

    return rpcResult.fold(left, (result) {
      if (result is Map<String, dynamic>) {
        return right(ConversationResult.fromJson(result));
      }
      return left('Invalid conversation result format');
    });
  }

  static Future<Either<String, List<Map<String, dynamic>>>> getHistory({
    int? lastId,
  }) async {
    final params = <String, dynamic>{'count': ChatSdk.config.historyPageSize};
    if (lastId != null) {
      params['last_id'] = lastId;
    }

    final rpcResult = await _callJsonRpc(
      method: ChatSdk.config.getHistoryEndpoint,
      params: params,
    );

    return rpcResult.fold(left, (result) {
      if (result is List) {
        return right(
          result
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList(),
        );
      }
      return left('Invalid history result format');
    });
  }

  static Future<Either<String, Map<String, dynamic>>> uploadImage({
    required String filePath,
    required String fileName,
    int? replyToId,
  }) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final params = <String, dynamic>{
        'file_name': fileName,
        'file_base64': base64Encode(bytes),
        if (replyToId != null) 'reply_to_id': replyToId,
      };

      final rpcResult = await _callJsonRpc(
        method: ChatSdk.config.uploadImageEndpoint,
        params: params,
        customBaseUrl: ChatSdk.config.imageUploadBaseUrl, // Rasm uchun maxsus URL
      );

      return rpcResult.fold(
        (_) => _uploadImageHttpFallback(
          filePath: filePath,
          fileName: fileName,
          replyToId: replyToId,
        ),
        (result) {
          if (result is Map<String, dynamic>) {
            return right(result);
          }
          return left('Invalid upload result format');
        },
      );
    } catch (_) {
      return _uploadImageHttpFallback(
        filePath: filePath,
        fileName: fileName,
        replyToId: replyToId,
      );
    }
  }
}
