import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../models/chat_message_model.dart';
import 'chat_sdk.dart';

class ChatApiService {
  static Dio? _dio;
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

  static int _nextRequestId() {
    _requestId=DateTime.now().millisecondsSinceEpoch;
    return _requestId;
  }

  static Future<Either<String, dynamic>> _callJsonRpc({
    required String method,
    Map<String, dynamic>? params,
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

      final response = await dio.post(
        '',
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode != 200) {
        return left('HTTP ${response.statusCode}');
      }

      final responseData = response.data;
      if (responseData is! Map) {
        return left('Invalid response format');
      }

      if (responseData['error'] != null) {
        final error = responseData['error'];
        if (error is Map && error['message'] != null) {
          return left(error['message'].toString());
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
      return left(e.message ?? 'Network error');
    } catch (e) {
      return left(e.toString());
    }
  }

  static Future<Either<String, Map<String, dynamic>>> _uploadImageHttpFallback({
    required String filePath,
    required String fileName,
    int? replyToId,
  }) async {
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'multipart/form-data';

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath, filename: fileName),
        if (replyToId != null) 'reply_to_id': replyToId,
      });

      final response = await dio.post(
        ChatSdk.config.uploadImageEndpoint,
        data: formData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return right(response.data['result'] as Map<String, dynamic>);
      }
      return left(response.data['message'] ?? 'Upload failed');
    } on DioException catch (e) {
      return left(e.message ?? 'Network error');
    } catch (e) {
      return left(e.toString());
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
