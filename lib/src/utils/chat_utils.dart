import 'dart:io';
import 'chat_constants.dart';

/// Utility class for chat-related validations and operations
class ChatUtils {
  // Private constructor to prevent instantiation
  ChatUtils._();

  /// Validates if a message text is valid
  static bool isValidMessage(String text) {
    if (text.isEmpty) return false;
    if (text.length > ChatConstants.maxMessageLength) return false;
    return true;
  }

  /// Validates if an image file is supported
  static bool isValidImageFile(File file) {
    if (!file.existsSync()) return false;
    
    final fileSize = file.lengthSync();
    if (fileSize > ChatConstants.maxImageFileSize) return false;
    
    final extension = file.path.split('.').last.toLowerCase();
    return ChatConstants.supportedImageFormats.contains(extension);
  }

  /// Gets file extension from file path
  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  /// Checks if file extension is unsupported
  static bool isUnsupportedImageFormat(String filePath) {
    final extension = getFileExtension(filePath);
    return ChatConstants.unsupportedImageFormats.contains(extension);
  }

  /// Formats file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Validates URL format
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Sanitizes text for display
  static String sanitizeText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .substring(0, text.length > ChatConstants.maxMessageLength 
            ? ChatConstants.maxMessageLength 
            : text.length);
  }

  /// Checks if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Formats time for display
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Gets relative date string
  static String getRelativeDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(date.year, date.month, date.day);

    if (ChatUtils.isSameDay(messageDay, today)) {
      return 'Today';
    } else if (ChatUtils.isSameDay(messageDay, yesterday)) {
      return 'Yesterday';
    } else {
      return '${_getMonthName(date.month)} ${date.day}';
    }
  }

  /// Gets month name
  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  /// Truncates text with ellipsis if too long
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Generates a unique local ID for messages
  static String generateLocalId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
