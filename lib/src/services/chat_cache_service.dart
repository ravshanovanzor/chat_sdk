import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_message_model.dart';

class ChatCacheService {
  static const String _boxName = 'chat_cache';
  static const String _messagesKey = 'messages';
  static const String _externalIdKey = 'external_id';

  static Box? _box;
  static Future<void>? _initializationFuture;

  static Future<void> initialize() async {
    if (_box?.isOpen ?? false) return;

    _initializationFuture ??= _openBox();

    try {
      await _initializationFuture;
    } catch (_) {
      // Allow retry if initialization fails.
      _initializationFuture = null;
      rethrow;
    }
  }

  static Future<void> _openBox() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  static Future<Box?> _ensureBoxReady() async {
    try {
      await initialize();
      if (_box == null || !_box!.isOpen) {
        debugPrint('ChatCache: Box is not available after initialization');
        return null;
      }
      return _box;
    } catch (e, stackTrace) {
      debugPrint('ChatCache: Initialization failed - $e');
      debugPrint('ChatCache: Stack trace - $stackTrace');
      return null;
    }
  }

  static Future<void> saveMessages(List<ChatMessageModel> messages) async {
    try {
      final box = await _ensureBoxReady();
      if (box == null) return;

      final jsonList = messages.map((m) => m.toJson()).toList();
      await box.put(_messagesKey, jsonEncode(jsonList));
      debugPrint('ChatCache: Saved ${messages.length} messages');
    } catch (e, stackTrace) {
      debugPrint('ChatCache: Failed to save messages - $e');
      debugPrint('ChatCache: Stack trace - $stackTrace');
    }
  }

  static Future<List<ChatMessageModel>?> getMessages() async {
    try {
      final box = await _ensureBoxReady();
      if (box == null) return null;

      final data = box.get(_messagesKey);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        final messages = jsonList
            .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('ChatCache: Loaded ${messages.length} messages');
        return messages;
      }
    } catch (e, stackTrace) {
      debugPrint('ChatCache: Failed to load messages - $e');
      debugPrint('ChatCache: Stack trace - $stackTrace');
    }
    return null;
  }

  static Future<void> saveExternalId(String externalId) async {
    try {
      final box = await _ensureBoxReady();
      if (box == null) return;

      await box.put(_externalIdKey, externalId);
      debugPrint('ChatCache: Saved external ID');
    } catch (e, stackTrace) {
      debugPrint('ChatCache: Failed to save external ID - $e');
      debugPrint('ChatCache: Stack trace - $stackTrace');
    }
  }

  static Future<String?> getExternalId() async {
    try {
      final box = await _ensureBoxReady();
      if (box == null) return null;

      final externalId = box.get(_externalIdKey);
      if (externalId != null) {
        debugPrint('ChatCache: Loaded external ID');
      }
      return externalId as String?;
    } catch (e, stackTrace) {
      debugPrint('ChatCache: Failed to load external ID - $e');
      debugPrint('ChatCache: Stack trace - $stackTrace');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final box = await _ensureBoxReady();
      if (box == null) return;

      await box.clear();
      debugPrint('ChatCache: Cache cleared successfully');
    } catch (e, stackTrace) {
      debugPrint('ChatCache: Failed to clear cache - $e');
      debugPrint('ChatCache: Stack trace - $stackTrace');
    }
  }
}
