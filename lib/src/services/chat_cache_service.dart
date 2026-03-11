import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/chat_message_model.dart';

class ChatCacheService {
  static const String _boxName = 'chat_cache';
  static const String _messagesKey = 'messages';
  static const String _externalIdKey = 'external_id';

  static Box? _box;

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  static Box get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('ChatCacheService must be initialized before use. Call initialize() first.');
    }
    return _box!;
  }

  static Future<void> saveMessages(List<ChatMessageModel> messages) async {
    try {
      final jsonList = messages.map((m) => m.toJson()).toList();
      await box.put(_messagesKey, jsonEncode(jsonList));
      debugPrint('ChatCache: Saved ${messages.length} messages');
    } catch (e, stackTrace) {
      debugPrint('ChatCache: Failed to save messages - $e');
      debugPrint('ChatCache: Stack trace - $stackTrace');
    }
  }

  static List<ChatMessageModel>? getMessages() {
    try {
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
      await box.put(_externalIdKey, externalId);
      debugPrint('ChatCache: Saved external ID');
    } catch (e, stackTrace) {
      debugPrint('ChatCache: Failed to save external ID - $e');
      debugPrint('ChatCache: Stack trace - $stackTrace');
    }
  }

  static String? getExternalId() {
    try {
      final externalId = box.get(_externalIdKey);
      if (externalId != null) {
        debugPrint('ChatCache: Loaded external ID');
      }
      return externalId;
    } catch (e, stackTrace) {
      debugPrint('ChatCache: Failed to load external ID - $e');
      debugPrint('ChatCache: Stack trace - $stackTrace');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await box.clear();
      debugPrint('ChatCache: Cache cleared successfully');
    } catch (e, stackTrace) {
      debugPrint('ChatCache: Failed to clear cache - $e');
      debugPrint('ChatCache: Stack trace - $stackTrace');
    }
  }
}
