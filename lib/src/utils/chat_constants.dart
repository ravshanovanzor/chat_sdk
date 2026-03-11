/// Chat SDK Constants
/// 
/// Contains all constant values used throughout the chat SDK
class ChatConstants {
  // Private constructor to prevent instantiation
  ChatConstants._();

  // WebSocket constants
  static const int maxReconnectAttempts = 5;
  static const Duration baseReconnectDelay = Duration(seconds: 1);
  static const Duration pingInterval = Duration(seconds: 30);
  static const int maxMessageSize = 1024 * 1024; // 1MB

  // UI constants
  static const double scrollThreshold = 200.0;
  static const Duration typingIndicatorDuration = Duration(seconds: 3);
  static const Duration typingDebounceDuration = Duration(seconds: 2);
  static const Duration scrollToBottomDelay = Duration(milliseconds: 300);
  static const Duration messageHighlightDuration = Duration(milliseconds: 500);

  // Cache constants
  static const String cacheBoxName = 'chat_cache';
  static const String messagesKey = 'messages';
  static const String externalIdKey = 'external_id';
  static const int maxCachedMessages = 1000;

  // Image constants
  static const int defaultImageQuality = 85;
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  static const int maxImageCount = 5;
  static const int maxImageFileSize = 5 * 1024 * 1024; // 5MB

  // API constants
  static const int defaultTimeoutSeconds = 30;
  static const int uploadTimeoutSeconds = 60;
  static const int defaultHistoryPageSize = 50;

  // Animation constants
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration fadeInDuration = Duration(milliseconds: 200);
  static const Duration slideInDuration = Duration(milliseconds: 300);

  // Validation constants
  static const int maxMessageLength = 4000;
  static const int minMessageLength = 1;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> unsupportedImageFormats = ['svg', 'bmp', 'tiff'];
}
