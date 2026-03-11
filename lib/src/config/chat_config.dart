import 'package:flutter/material.dart';

class ChatConfig {
  final String baseUrl;
  final String? imageUploadBaseUrl; // Rasm yuklash uchun alohida base URL
  final String webSocketUrl;
  final String getConversationEndpoint;
  final String getHistoryEndpoint;
  final String uploadImageEndpoint;
  final Future<String?> Function() authTokenProvider;
  final Future<Map<String, String>> Function()? headersProvider;
  final int historyPageSize;
  final Duration webSocketReconnectDelay;
  final int maxImageCount;
  final int imageQuality;
  final int maxImageWidth;
  final int maxImageHeight;

  const ChatConfig({
    required this.baseUrl,
    this.imageUploadBaseUrl, // Rasm yuklash uchun alohida URL (agar bo'lmasa baseUrl ishlatiladi)
    required this.webSocketUrl,
    required this.getConversationEndpoint,
    required this.getHistoryEndpoint,
    required this.uploadImageEndpoint,
    required this.authTokenProvider,
    this.headersProvider,
    this.historyPageSize = 20,
    this.webSocketReconnectDelay = const Duration(seconds: 3),
    this.maxImageCount = 3,
    this.imageQuality = 80,
    this.maxImageWidth = 1024,
    this.maxImageHeight = 1024,
  });
}

class ChatTheme {
  final Color primaryColor;
  final Color userBubbleColor;
  final Color botBubbleColor;
  final Color userTextColor;
  final Color botTextColor;
  final Color backgroundColor;
  final Color inputBackgroundColor;
  final Color inputBorderColor;
  final Color inputTextColor;
  final Color inputHintColor;
  final Color sendButtonColor;
  final Color attachmentButtonColor;
  final Color timeTextColor;
  final Color dateSeparatorColor;
  final Color dateSeparatorTextColor;
  final Color replyBorderColor;
  final Color replyBackgroundColor;
  final Color replyTextColor;
  final Color scrollToBottomColor;
  final Color onlineIndicatorColor;
  final Color offlineIndicatorColor;
  final Color typingIndicatorColor;
  final double messageBorderRadius;
  final double inputBorderRadius;
  final double avatarRadius;
  final EdgeInsets messagePadding;
  final EdgeInsets inputPadding;
  final TextStyle? userTextStyle;
  final TextStyle? botTextStyle;
  final TextStyle? timeTextStyle;
  final TextStyle? inputTextStyle;

  const ChatTheme({
    this.primaryColor = const Color(0xFF438BFA),
    this.userBubbleColor = const Color(0xFF438BFA),
    this.botBubbleColor = const Color(0xFFF2F3F5),
    this.userTextColor = Colors.white,
    this.botTextColor = const Color(0xFF2A2A2A),
    this.backgroundColor = Colors.white,
    this.inputBackgroundColor = const Color(0xFFF2F3F5),
    this.inputBorderColor = const Color(0xFFE0E0E0),
    this.inputTextColor = const Color(0xFF2A2A2A),
    this.inputHintColor = const Color(0xFF9E9E9E),
    this.sendButtonColor = const Color(0xFF438BFA),
    this.attachmentButtonColor = const Color(0xFF757575),
    this.timeTextColor = const Color(0xFF9E9E9E),
    this.dateSeparatorColor = const Color(0xFFE0E0E0),
    this.dateSeparatorTextColor = const Color(0xFF757575),
    this.replyBorderColor = const Color(0xFF438BFA),
    this.replyBackgroundColor = const Color(0xFFF5F5F5),
    this.replyTextColor = const Color(0xFF757575),
    this.scrollToBottomColor = const Color(0xFF438BFA),
    this.onlineIndicatorColor = const Color(0xFF4CAF50),
    this.offlineIndicatorColor = const Color(0xFF9E9E9E),
    this.typingIndicatorColor = const Color(0xFF757575),
    this.messageBorderRadius = 16,
    this.inputBorderRadius = 24,
    this.avatarRadius = 20,
    this.messagePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.inputPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.userTextStyle,
    this.botTextStyle,
    this.timeTextStyle,
    this.inputTextStyle,
  });

  ChatTheme copyWith({
    Color? primaryColor,
    Color? userBubbleColor,
    Color? botBubbleColor,
    Color? userTextColor,
    Color? botTextColor,
    Color? backgroundColor,
    Color? inputBackgroundColor,
    Color? inputBorderColor,
    Color? inputTextColor,
    Color? inputHintColor,
    Color? sendButtonColor,
    Color? attachmentButtonColor,
    Color? timeTextColor,
    Color? dateSeparatorColor,
    Color? dateSeparatorTextColor,
    Color? replyBorderColor,
    Color? replyBackgroundColor,
    Color? replyTextColor,
    Color? scrollToBottomColor,
    Color? onlineIndicatorColor,
    Color? offlineIndicatorColor,
    Color? typingIndicatorColor,
    double? messageBorderRadius,
    double? inputBorderRadius,
    double? avatarRadius,
    EdgeInsets? messagePadding,
    EdgeInsets? inputPadding,
    TextStyle? userTextStyle,
    TextStyle? botTextStyle,
    TextStyle? timeTextStyle,
    TextStyle? inputTextStyle,
  }) {
    return ChatTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      userBubbleColor: userBubbleColor ?? this.userBubbleColor,
      botBubbleColor: botBubbleColor ?? this.botBubbleColor,
      userTextColor: userTextColor ?? this.userTextColor,
      botTextColor: botTextColor ?? this.botTextColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      inputBackgroundColor: inputBackgroundColor ?? this.inputBackgroundColor,
      inputBorderColor: inputBorderColor ?? this.inputBorderColor,
      inputTextColor: inputTextColor ?? this.inputTextColor,
      inputHintColor: inputHintColor ?? this.inputHintColor,
      sendButtonColor: sendButtonColor ?? this.sendButtonColor,
      attachmentButtonColor: attachmentButtonColor ?? this.attachmentButtonColor,
      timeTextColor: timeTextColor ?? this.timeTextColor,
      dateSeparatorColor: dateSeparatorColor ?? this.dateSeparatorColor,
      dateSeparatorTextColor: dateSeparatorTextColor ?? this.dateSeparatorTextColor,
      replyBorderColor: replyBorderColor ?? this.replyBorderColor,
      replyBackgroundColor: replyBackgroundColor ?? this.replyBackgroundColor,
      replyTextColor: replyTextColor ?? this.replyTextColor,
      scrollToBottomColor: scrollToBottomColor ?? this.scrollToBottomColor,
      onlineIndicatorColor: onlineIndicatorColor ?? this.onlineIndicatorColor,
      offlineIndicatorColor: offlineIndicatorColor ?? this.offlineIndicatorColor,
      typingIndicatorColor: typingIndicatorColor ?? this.typingIndicatorColor,
      messageBorderRadius: messageBorderRadius ?? this.messageBorderRadius,
      inputBorderRadius: inputBorderRadius ?? this.inputBorderRadius,
      avatarRadius: avatarRadius ?? this.avatarRadius,
      messagePadding: messagePadding ?? this.messagePadding,
      inputPadding: inputPadding ?? this.inputPadding,
      userTextStyle: userTextStyle ?? this.userTextStyle,
      botTextStyle: botTextStyle ?? this.botTextStyle,
      timeTextStyle: timeTextStyle ?? this.timeTextStyle,
      inputTextStyle: inputTextStyle ?? this.inputTextStyle,
    );
  }
}

class ChatLocalization {
  final String today;
  final String yesterday;
  final String typeMessage;
  final String send;
  final String image;
  final String svgNotSupported;
  final String errorTitle;
  final String retry;
  final String camera;
  final String gallery;
  final String cancel;
  final String selectImage;
  final String uploading;
  final String online;
  final String offline;
  final String typing;
  final String connectionError;
  final String noMessages;
  final String loadingMessages;
  final String Function(int month)? monthFormatter;

  const ChatLocalization({
    this.today = 'Today',
    this.yesterday = 'Yesterday',
    this.typeMessage = 'Type a message...',
    this.send = 'Send',
    this.image = 'Image',
    this.svgNotSupported = 'SVG format is not supported',
    this.errorTitle = 'Error',
    this.retry = 'Retry',
    this.camera = 'Camera',
    this.gallery = 'Gallery',
    this.cancel = 'Cancel',
    this.selectImage = 'Select Image',
    this.uploading = 'Uploading...',
    this.online = 'Online',
    this.offline = 'Offline',
    this.typing = 'Typing...',
    this.connectionError = 'Connection error. Please try again.',
    this.noMessages = 'No messages yet',
    this.loadingMessages = 'Loading messages...',
    this.monthFormatter,
  });

  String getMonthName(int month) {
    if (monthFormatter != null) {
      return monthFormatter!(month);
    }
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
