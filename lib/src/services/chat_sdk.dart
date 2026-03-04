import 'package:hive_flutter/hive_flutter.dart';
import '../config/chat_config.dart';

class ChatSdk {
  static late ChatConfig _config;
  static ChatTheme _theme = const ChatTheme();
  static ChatLocalization _localization = const ChatLocalization();
  static bool _isInitialized = false;

  static ChatConfig get config => _config;
  static ChatTheme get theme => _theme;
  static ChatLocalization get localization => _localization;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize({
    required ChatConfig config,
    ChatTheme? theme,
    ChatLocalization? localization,
  }) async {
    _config = config;
    if (theme != null) _theme = theme;
    if (localization != null) _localization = localization;

    await Hive.initFlutter();
    await _openCacheBox();

    _isInitialized = true;
  }

  static Future<void> _openCacheBox() async {
    if (!Hive.isBoxOpen('chat_cache')) {
      await Hive.openBox('chat_cache');
    }
  }

  static void updateTheme(ChatTheme theme) {
    _theme = theme;
  }

  static void updateLocalization(ChatLocalization localization) {
    _localization = localization;
  }

  static void clearCache() {
    if (Hive.isBoxOpen('chat_cache')) {
      Hive.box('chat_cache').clear();
    }
  }
}
