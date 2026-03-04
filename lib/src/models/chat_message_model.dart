import 'package:equatable/equatable.dart';

class ChatMessageModel extends Equatable {
  final int? messageId;
  final String text;
  final bool isBot;
  final String time;
  final DateTime? createdAt;
  final String? senderName;
  final bool isRead;
  final String? imageUrl;
  final String messageType;
  final bool isUploading;
  final String? localId;
  final int? replyToId;
  final String? replyToText;

  const ChatMessageModel({
    this.messageId,
    required this.text,
    required this.isBot,
    required this.time,
    this.createdAt,
    this.senderName,
    this.isRead = false,
    this.imageUrl,
    this.messageType = 'text',
    this.isUploading = false,
    this.localId,
    this.replyToId,
    this.replyToText,
  });

  ChatMessageModel copyWith({
    int? messageId,
    String? text,
    bool? isBot,
    String? time,
    DateTime? createdAt,
    String? senderName,
    bool? isRead,
    String? imageUrl,
    String? messageType,
    bool? isUploading,
    String? localId,
    int? replyToId,
    String? replyToText,
  }) {
    return ChatMessageModel(
      messageId: messageId ?? this.messageId,
      text: text ?? this.text,
      isBot: isBot ?? this.isBot,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      messageType: messageType ?? this.messageType,
      isUploading: isUploading ?? this.isUploading,
      localId: localId ?? this.localId,
      replyToId: replyToId ?? this.replyToId,
      replyToText: replyToText ?? this.replyToText,
    );
  }

  bool get isImage => messageType == 'image' && imageUrl != null && imageUrl!.isNotEmpty;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    String time = '';
    DateTime? createdAtDate;
    final createdAt = json['created_at'];
    if (createdAt != null) {
      try {
        createdAtDate = DateTime.parse(createdAt).toLocal();
        time = '${createdAtDate.hour.toString().padLeft(2, '0')}:${createdAtDate.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    int? replyToId;
    String? replyToText;
    final replyTo = json['reply_to'];
    if (replyTo != null && replyTo is Map) {
      replyToId = replyTo['id'];
      replyToText = replyTo['text'];
    }

    final senderType = json['sender_type'];
    final isBot = senderType != 'user';

    String? senderName;
    if (isBot) {
      final adminUser = json['admin_user'];
      if (adminUser != null && adminUser is Map) {
        final firstName = adminUser['first_name'] ?? '';
        final lastName = adminUser['last_name'] ?? '';
        senderName = '$firstName $lastName'.trim();
        if (senderName.isEmpty) senderName = null;
      } else {
        senderName = json['admin_name'];
      }
    }

    return ChatMessageModel(
      messageId: json['id'],
      text: json['text'] ?? '',
      isBot: isBot,
      time: time,
      createdAt: createdAtDate,
      senderName: senderName,
      isRead: json['is_read'] ?? false,
      messageType: json['message_type'] ?? 'text',
      imageUrl: json['image_url'],
      replyToId: replyToId,
      replyToText: replyToText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': messageId,
      'text': text,
      'is_bot': isBot,
      'time': time,
      'created_at': createdAt?.toIso8601String(),
      'sender_name': senderName,
      'is_read': isRead,
      'message_type': messageType,
      'image_url': imageUrl,
      'reply_to_id': replyToId,
      'reply_to_text': replyToText,
    };
  }

  @override
  List<Object?> get props => [
        messageId,
        text,
        isBot,
        time,
        createdAt,
        senderName,
        isRead,
        imageUrl,
        messageType,
        isUploading,
        localId,
        replyToId,
        replyToText,
      ];
}

class ConversationResult {
  final int? conversationId;
  final String? externalId;
  final String? displayName;
  final String? phoneNumber;
  final bool? isOpen;
  final String? createdAt;

  ConversationResult({
    this.conversationId,
    this.externalId,
    this.displayName,
    this.phoneNumber,
    this.isOpen,
    this.createdAt,
  });

  factory ConversationResult.fromJson(Map<String, dynamic> json) {
    return ConversationResult(
      conversationId: json['conversation_id'],
      externalId: json['external_id'],
      displayName: json['display_name'],
      phoneNumber: json['phone_number'],
      isOpen: json['is_open'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'external_id': externalId,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'is_open': isOpen,
      'created_at': createdAt,
    };
  }
}

