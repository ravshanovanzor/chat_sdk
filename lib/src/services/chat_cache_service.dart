import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/chat_message_model.dart';

class ChatCacheService {
  static const String _boxName = 'chat_cache';
  static const String _messagesKey = 'messages';
  static const String _externalIdKey = 'external_id';

  static Box? _box;

  static Box get box {
    if (_box == null || !_box!.isOpen) {
      _box = Hive.box(_boxName);
    }
    return _box!;
  }

  static Future<void> saveMessages(List<ChatMessageModel> messages) async {
    try {
      final jsonList = messages.map((m) => m.toJson()).toList();
      await box.put(_messagesKey, jsonEncode(jsonList));
    } catch (e) {
      // Ignore cache errors
    }
  }

  static List<ChatMessageModel>? getMessages() {
    try {
      final data = box.get(_messagesKey);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        return jsonList
            .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Ignore cache errors
    }
    return null;
  }

  static Future<void> saveExternalId(String externalId) async {
    try {
      await box.put(_externalIdKey, externalId);
    } catch (e) {
      // Ignore cache errors
    }
  }

  static String? getExternalId() {
    try {
      return box.get(_externalIdKey);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await box.clear();
    } catch (e) {
      // Ignore cache errors
    }
  }
}

