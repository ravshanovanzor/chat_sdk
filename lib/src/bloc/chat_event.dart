part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatInitEvent extends ChatEvent {
  const ChatInitEvent();
}

class ChatSendMessageEvent extends ChatEvent {
  final String message;

  const ChatSendMessageEvent({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChatSendImageEvent extends ChatEvent {
  final File imageFile;
  final ChatMessageModel? replyToMessage;

  const ChatSendImageEvent({required this.imageFile, this.replyToMessage});

  @override
  List<Object?> get props => [imageFile, replyToMessage];
}

class ChatMessageReceivedEvent extends ChatEvent {
  final Map<String, dynamic> data;

  const ChatMessageReceivedEvent({required this.data});

  @override
  List<Object?> get props => [data];
}

class ChatConnectWebSocketEvent extends ChatEvent {
  final String externalId;

  const ChatConnectWebSocketEvent({required this.externalId});

  @override
  List<Object?> get props => [externalId];
}

class ChatDisconnectWebSocketEvent extends ChatEvent {
  const ChatDisconnectWebSocketEvent();
}

class ChatWebSocketConnectedEvent extends ChatEvent {
  const ChatWebSocketConnectedEvent();
}

class ChatWebSocketDisconnectedEvent extends ChatEvent {
  const ChatWebSocketDisconnectedEvent();
}

class ChatHistoryLoadedEvent extends ChatEvent {
  final Map<String, dynamic> data;

  const ChatHistoryLoadedEvent({required this.data});

  @override
  List<Object?> get props => [data];
}

class ChatClearImageUploadErrorEvent extends ChatEvent {
  const ChatClearImageUploadErrorEvent();
}

class ChatOperatorTypingEvent extends ChatEvent {
  const ChatOperatorTypingEvent();
}

class ChatSetReplyToMessageEvent extends ChatEvent {
  final ChatMessageModel message;

  const ChatSetReplyToMessageEvent({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChatClearReplyToMessageEvent extends ChatEvent {
  const ChatClearReplyToMessageEvent();
}

class ChatAdminStatusChangedEvent extends ChatEvent {
  final bool isOnline;

  const ChatAdminStatusChangedEvent({required this.isOnline});

  @override
  List<Object?> get props => [isOnline];
}

class ChatSendTypingEvent extends ChatEvent {
  const ChatSendTypingEvent();
}

class ChatLoadMoreHistoryEvent extends ChatEvent {
  const ChatLoadMoreHistoryEvent();
}

class ChatSendReadEvent extends ChatEvent {
  const ChatSendReadEvent();
}

