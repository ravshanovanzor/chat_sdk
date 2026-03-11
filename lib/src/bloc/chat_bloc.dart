import 'dart:io';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/chat_message_model.dart';
import '../services/chat_api_service.dart';
import '../services/chat_cache_service.dart';
import '../services/chat_websocket_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatWebSocketService? _webSocketService;

  ChatBloc() : super(const ChatState()) {
    on<ChatInitEvent>(_onInit);
    on<ChatSendMessageEvent>(_onSendMessage);
    on<ChatSendImageEvent>(_onSendImage);
    on<ChatMessageReceivedEvent>(_onMessageReceived);
    on<ChatConnectWebSocketEvent>(_onConnectWebSocket);
    on<ChatDisconnectWebSocketEvent>(_onDisconnectWebSocket);
    on<ChatWebSocketConnectedEvent>(_onWebSocketConnected);
    on<ChatWebSocketDisconnectedEvent>(_onWebSocketDisconnected);
    on<ChatHistoryLoadedEvent>(_onHistoryLoaded);
    on<ChatClearImageUploadErrorEvent>(_onClearImageUploadError);
    on<ChatOperatorTypingEvent>(_onOperatorTyping);
    on<ChatSetReplyToMessageEvent>(_onSetReplyToMessage);
    on<ChatClearReplyToMessageEvent>(_onClearReplyToMessage);
    on<ChatAdminStatusChangedEvent>(_onAdminStatusChanged);
    on<ChatSendTypingEvent>(_onSendTyping);
    on<ChatLoadMoreHistoryEvent>(_onLoadMoreHistory);
    on<ChatSendReadEvent>(_onSendRead);
  }

  Future<void> _onInit(ChatInitEvent event, Emitter<ChatState> emit) async {
    final cachedMessages = ChatCacheService.getMessages();
    final cachedExternalId = ChatCacheService.getExternalId();

    if (cachedMessages != null && cachedMessages.isNotEmpty && cachedExternalId != null) {
      emit(state.copyWith(
        status: ChatStatus.loaded,
        messages: cachedMessages,
        externalId: cachedExternalId,
      ));

      add(ChatConnectWebSocketEvent(externalId: cachedExternalId));
      _loadInitialHistory(emit);
      return;
    }

    emit(state.copyWith(status: ChatStatus.loading));

    final response = await ChatApiService.getConversation();

    response.fold(
      (error) {
        emit(state.copyWith(status: ChatStatus.error, errorMessage: error));
      },
      (result) async {
        if (result.externalId != null) {
          ChatCacheService.saveExternalId(result.externalId!);
        }

        emit(state.copyWith(
          status: ChatStatus.loaded,
          externalId: result.externalId,
        ));

        if (result.externalId != null) {
          add(ChatConnectWebSocketEvent(externalId: result.externalId!));
        }

        _loadInitialHistory(emit);
      },
    );
  }

  Future<void> _loadInitialHistory(Emitter<ChatState> emit) async {
    final result = await ChatApiService.getHistory();
    result.fold(
      (error) => debugPrint('Initial history load error: $error'),
      (messagesData) {
        if (messagesData.isEmpty) {
          if (!emit.isDone) emit(state.copyWith(hasMoreHistory: false));
          return;
        }

        final historyMessages = _parseMessages(messagesData);
        final allMessages = _mergeMessages(state.messages, historyMessages);

        if (!emit.isDone) {
          emit(state.copyWith(messages: allMessages, hasMoreHistory: messagesData.isNotEmpty));
        }

        ChatCacheService.saveMessages(allMessages);
      },
    );
  }

  Future<void> _onSendMessage(ChatSendMessageEvent event, Emitter<ChatState> emit) async {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final replyTo = state.replyToMessage;
    
    // Create new message efficiently
    final newMessage = ChatMessageModel(
      text: event.message,
      isBot: false,
      time: time,
      createdAt: now,
      replyToId: replyTo?.messageId,
      replyToText: replyTo?.text,
    );

    // Update messages list without creating unnecessary copies
    final newMessages = [...state.messages, newMessage];
    
    _webSocketService?.sendMessage(event.message, replyToId: replyTo?.messageId);

    emit(state.copyWith(
      messages: newMessages,
      shouldScrollToBottom: true,
      clearReplyToMessage: true,
    ));

    // Cache asynchronously to avoid blocking UI
    ChatCacheService.saveMessages(newMessages).catchError((e) {
      debugPrint('ChatBloc: Failed to cache messages - $e');
    });
  }

  Future<void> _onSendImage(ChatSendImageEvent event, Emitter<ChatState> emit) async {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final localId = '${now.millisecondsSinceEpoch}';
    final replyTo = event.replyToMessage;

    final tempMessage = ChatMessageModel(
      text: '',
      isBot: false,
      time: time,
      createdAt: now,
      messageType: 'image',
      imageUrl: event.imageFile.path,
      isRead: false,
      isUploading: true,
      localId: localId,
      replyToId: replyTo?.messageId,
      replyToText: replyTo?.text,
    );

    final newMessages = List<ChatMessageModel>.from(state.messages)..add(tempMessage);
    emit(state.copyWith(
      messages: newMessages,
      shouldScrollToBottom: true,
      clearReplyToMessage: replyTo != null,
    ));

    final result = await ChatApiService.uploadImage(
      filePath: event.imageFile.path,
      fileName: event.imageFile.path.split('/').last,
      replyToId: replyTo?.messageId,
    );

    result.fold(
      (error) {
        final updatedMessages = state.messages.map((m) {
          if (m.localId == localId) {
            return m.copyWith(isUploading: false);
          }
          return m;
        }).toList();

        emit(state.copyWith(messages: updatedMessages, imageUploadError: error));
      },
      (data) {
        final updatedMessages = state.messages.map((m) {
          if (m.localId == localId) {
            return m.copyWith(
              messageId: data['id'],
              imageUrl: data['image_url'],
              isUploading: false,
            );
          }
          return m;
        }).toList();

        emit(state.copyWith(messages: updatedMessages));
        ChatCacheService.saveMessages(updatedMessages);
      },
    );
  }

  void _onMessageReceived(ChatMessageReceivedEvent event, Emitter<ChatState> emit) {
    final data = event.data;
    final message = ChatMessageModel.fromJson(data);

    final existingIndex = state.messages.indexWhere((m) => m.messageId == message.messageId);

    if (existingIndex == -1) {
      final newMessages = List<ChatMessageModel>.from(state.messages)..add(message);
      emit(state.copyWith(messages: newMessages, shouldScrollToBottom: true));
      ChatCacheService.saveMessages(newMessages);
    }
  }

  void _onConnectWebSocket(ChatConnectWebSocketEvent event, Emitter<ChatState> emit) {
    _webSocketService?.dispose();

    _webSocketService = ChatWebSocketService(
      onMessageReceived: (data) => add(ChatMessageReceivedEvent(data: data)),
      onConnected: () => add(const ChatWebSocketConnectedEvent()),
      onDisconnected: () => add(const ChatWebSocketDisconnectedEvent()),
      onHistoryLoaded: (data) => add(ChatHistoryLoadedEvent(data: data)),
      onTyping: () => add(const ChatOperatorTypingEvent()),
      onAdminStatusChanged: (isOnline) => add(ChatAdminStatusChangedEvent(isOnline: isOnline)),
    );

    _webSocketService!.connect(event.externalId);
  }

  void _onDisconnectWebSocket(ChatDisconnectWebSocketEvent event, Emitter<ChatState> emit) {
    _webSocketService?.dispose();
    _webSocketService = null;
  }

  void _onWebSocketConnected(ChatWebSocketConnectedEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(status: ChatStatus.connected));
  }

  void _onWebSocketDisconnected(ChatWebSocketDisconnectedEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(status: ChatStatus.disconnected));
  }

  void _onHistoryLoaded(ChatHistoryLoadedEvent event, Emitter<ChatState> emit) {
    final messagesData = event.data['messages'] as List? ?? [];
    if (messagesData.isEmpty) {
      emit(state.copyWith(hasMoreHistory: false, isLoadingMoreHistory: false));
      return;
    }

    final historyMessages = _parseMessages(messagesData.cast<Map<String, dynamic>>());
    final allMessages = _mergeMessages(state.messages, historyMessages);

    emit(state.copyWith(
      messages: allMessages,
      hasMoreHistory: messagesData.isNotEmpty,
      isLoadingMoreHistory: false,
    ));

    ChatCacheService.saveMessages(allMessages);
  }

  void _onClearImageUploadError(ChatClearImageUploadErrorEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(imageUploadError: null));
  }

  void _onOperatorTyping(ChatOperatorTypingEvent event, Emitter<ChatState> emit) {
    if (state.isOperatorTyping) return; // Avoid unnecessary state updates
    
    emit(state.copyWith(isOperatorTyping: true));

    // Use a more efficient approach for typing indicator
    Future.delayed(const Duration(seconds: 3), () {
      if (!emit.isDone && state.isOperatorTyping) {
        emit(state.copyWith(isOperatorTyping: false));
      }
    });
  }

  void _onSetReplyToMessage(ChatSetReplyToMessageEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(replyToMessage: event.message));
  }

  void _onClearReplyToMessage(ChatClearReplyToMessageEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearReplyToMessage: true));
  }

  void _onAdminStatusChanged(ChatAdminStatusChangedEvent event, Emitter<ChatState> emit) {
    emit(state.copyWith(isAdminOnline: event.isOnline));
  }

  void _onSendTyping(ChatSendTypingEvent event, Emitter<ChatState> emit) {
    _webSocketService?.sendTyping();
  }

  Future<void> _onLoadMoreHistory(ChatLoadMoreHistoryEvent event, Emitter<ChatState> emit) async {
    if (state.isLoadingMoreHistory || !state.hasMoreHistory) return;

    emit(state.copyWith(isLoadingMoreHistory: true));

    final oldestMessage = state.messages.firstWhereOrNull((m) => m.messageId != null);
    final lastId = oldestMessage?.messageId;

    final result = await ChatApiService.getHistory(lastId: lastId);

    result.fold(
      (error) {
        emit(state.copyWith(isLoadingMoreHistory: false));
      },
      (messagesData) {
        if (messagesData.isEmpty) {
          emit(state.copyWith(hasMoreHistory: false, isLoadingMoreHistory: false));
          return;
        }

        final historyMessages = _parseMessages(messagesData);
        final allMessages = _mergeMessages(state.messages, historyMessages);

        emit(state.copyWith(
          messages: allMessages,
          hasMoreHistory: messagesData.isNotEmpty,
          isLoadingMoreHistory: false,
        ));

        ChatCacheService.saveMessages(allMessages);
      },
    );
  }

  void _onSendRead(ChatSendReadEvent event, Emitter<ChatState> emit) {
    _webSocketService?.sendRead();
  }

  List<ChatMessageModel> _parseMessages(List<Map<String, dynamic>> messagesData) {
    return messagesData.map((json) => ChatMessageModel.fromJson(json)).toList();
  }

  List<ChatMessageModel> _mergeMessages(
    List<ChatMessageModel> newMessages,
    List<ChatMessageModel> existingMessages,
  ) {
    final allMessages = [...newMessages, ...existingMessages];
    final uniqueMessages = <int, ChatMessageModel>{};

    for (final msg in allMessages) {
      if (msg.messageId != null) {
        uniqueMessages[msg.messageId!] = msg;
      }
    }

    return uniqueMessages.values.toList()
      ..sort((a, b) => (a.messageId ?? 0).compareTo(b.messageId ?? 0));
  }

  @override
  Future<void> close() {
    debugPrint('ChatBloc: Closing BLoC');
    _webSocketService?.dispose();
    _webSocketService = null;
    return super.close();
  }
}

