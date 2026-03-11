import '../config/chat_config.dart';
import 'chat_cache_service.dart';

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

    // Hive.initFlutter() is handled inside ChatCacheService.initialize()
    await ChatCacheService.initialize();

    _isInitialized = true;
  }

  static void updateTheme(ChatTheme theme) {
    _theme = theme;
  }

  static void updateLocalization(ChatLocalization localization) {
    _localization = localization;
  }

  static Future<void> clearCache() async {
    await ChatCacheService.clear();
  }
}
