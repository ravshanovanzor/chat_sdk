part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, loaded, error, connected, disconnected }

class ChatState extends Equatable {
  final ChatStatus status;
  final int? conversationId;
  final String? externalId;
  final String? displayName;
  final String? phoneNumber;
  final bool isOpen;
  final List<ChatMessageModel> messages;
  final String? errorMessage;
  final String? webSocketUrl;
  final bool shouldScrollToBottom;
  final String? imageUploadError;
  final bool isOperatorTyping;
  final ChatMessageModel? replyToMessage;
  final bool isAdminOnline;
  final bool isLoadingMoreHistory;
  final bool hasMoreHistory;

  const ChatState({
    this.status = ChatStatus.initial,
    this.conversationId,
    this.externalId,
    this.displayName,
    this.phoneNumber,
    this.isOpen = false,
    this.messages = const [],
    this.errorMessage,
    this.webSocketUrl,
    this.shouldScrollToBottom = false,
    this.imageUploadError,
    this.isOperatorTyping = false,
    this.replyToMessage,
    this.isAdminOnline = false,
    this.isLoadingMoreHistory = false,
    this.hasMoreHistory = true,
  });

  ChatState copyWith({
    ChatStatus? status,
    int? conversationId,
    String? externalId,
    String? displayName,
    String? phoneNumber,
    bool? isOpen,
    List<ChatMessageModel>? messages,
    String? errorMessage,
    String? webSocketUrl,
    bool? shouldScrollToBottom,
    String? imageUploadError,
    bool? isOperatorTyping,
    ChatMessageModel? replyToMessage,
    bool clearReplyToMessage = false,
    bool? isAdminOnline,
    bool? isLoadingMoreHistory,
    bool? hasMoreHistory,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversationId: conversationId ?? this.conversationId,
      externalId: externalId ?? this.externalId,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOpen: isOpen ?? this.isOpen,
      messages: messages ?? this.messages,
      errorMessage: errorMessage ?? this.errorMessage,
      webSocketUrl: webSocketUrl ?? this.webSocketUrl,
      shouldScrollToBottom: shouldScrollToBottom ?? false,
      imageUploadError: imageUploadError,
      isOperatorTyping: isOperatorTyping ?? this.isOperatorTyping,
      replyToMessage: clearReplyToMessage ? null : (replyToMessage ?? this.replyToMessage),
      isAdminOnline: isAdminOnline ?? this.isAdminOnline,
      isLoadingMoreHistory: isLoadingMoreHistory ?? this.isLoadingMoreHistory,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
    );
  }

  @override
  List<Object?> get props => [
        status,
        conversationId,
        externalId,
        displayName,
        phoneNumber,
        isOpen,
        messages,
        errorMessage,
        webSocketUrl,
        shouldScrollToBottom,
        imageUploadError,
        isOperatorTyping,
        replyToMessage,
        isAdminOnline,
        isLoadingMoreHistory,
        hasMoreHistory,
      ];
}

