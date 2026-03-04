import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/chat_config.dart';
import '../models/chat_message_model.dart';
import '../services/chat_sdk.dart';

ChatTheme get _theme => ChatSdk.theme;
ChatLocalization get _localization => ChatSdk.localization;

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final String? replyText;
  final String? replyImageUrl;
  final bool isHighlighted;
  final VoidCallback? onReplyTap;

  const ChatMessageBubble({
    super.key,
    required this.msg,
    this.replyText,
    this.replyImageUrl,
    this.isHighlighted = false,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = !msg.isBot;
    final bubbleColor = isUser ? _theme.userBubbleColor : _theme.botBubbleColor;
    final textColor = isUser ? _theme.userTextColor : _theme.botTextColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(
        left: isUser ? 48 : 8,
        right: isUser ? 8 : 48,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color:
            isHighlighted
                ? _theme.primaryColor.withValues(alpha: 0.3)
                : bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_theme.messageBorderRadius),
          topRight: Radius.circular(_theme.messageBorderRadius),
          bottomLeft: Radius.circular(isUser ? _theme.messageBorderRadius : 4),
          bottomRight: Radius.circular(isUser ? 4 : _theme.messageBorderRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.replyToId != null && replyText != null)
            GestureDetector(
              onTap: onReplyTap,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _theme.replyBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: _theme.replyBorderColor, width: 3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replyImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: replyImageUrl!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (replyImageUrl != null) const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        replyText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _theme.replyTextColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (msg.isImage)
            _buildImageContent()
          else
            Padding(
              padding: _theme.messagePadding,
              child: Text(
                msg.text,
                style: TextStyle(color: textColor, fontSize: 15),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 6, left: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.time,
                  style: TextStyle(fontSize: 11, color: _theme.timeTextColor),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color:
                        msg.isRead ? _theme.primaryColor : _theme.timeTextColor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    final imageUrl = msg.imageUrl;
    if (imageUrl == null) return const SizedBox.shrink();

    final isLocalFile = !imageUrl.startsWith('http');

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_theme.messageBorderRadius - 4),
          child:
              isLocalFile
                  ? Image.file(
                    File(imageUrl),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                  : CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder:
                        (_, __) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (_, __, ___) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                  ),
        ),
        if (msg.isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(
                  _theme.messageBorderRadius - 4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _localization.uploading,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttachmentTap;
  final ValueChanged<String> onChanged;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttachmentTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: _theme.backgroundColor,
        border: Border(
          top: BorderSide(color: _theme.inputBorderColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onAttachmentTap,
            icon: Icon(Icons.attach_file, color: _theme.attachmentButtonColor),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _theme.inputBackgroundColor,
                borderRadius: BorderRadius.circular(_theme.inputBorderRadius),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(color: _theme.inputTextColor),
                decoration: InputDecoration(
                  hintText: _localization.typeMessage,
                  hintStyle: TextStyle(color: _theme.inputHintColor),
                  border: InputBorder.none,
                  contentPadding: _theme.inputPadding,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _theme.sendButtonColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatReplyPreview extends StatelessWidget {
  final ChatMessageModel replyTo;
  final VoidCallback onClose;

  const ChatReplyPreview({
    super.key,
    required this.replyTo,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _theme.replyBackgroundColor,
        border: Border(
          top: BorderSide(color: _theme.inputBorderColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 40, color: _theme.replyBorderColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  replyTo.isBot ? (replyTo.senderName ?? 'Admin') : 'You',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _theme.primaryColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyTo.isImage ? _localization.image : replyTo.text,
                  style: TextStyle(color: _theme.replyTextColor, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, size: 20, color: _theme.replyTextColor),
          ),
        ],
      ),
    );
  }
}

class ChatDateSeparator extends StatelessWidget {
  final String text;

  const ChatDateSeparator({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _theme.dateSeparatorColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: _theme.dateSeparatorTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

class ChatScrollToBottomButton extends StatelessWidget {
  final VoidCallback onTap;

  const ChatScrollToBottomButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _theme.scrollToBottomColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
      ),
    );
  }
}

class ChatShimmerLoading extends StatelessWidget {
  const ChatShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, index) {
          final isRight = index % 2 == 0;
          return Align(
            alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 200,
              height: 60,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatErrorView extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const ChatErrorView({super.key, this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? _localization.connectionError,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _theme.primaryColor,
            ),
            child: Text(_localization.retry),
          ),
        ],
      ),
    );
  }
}

class ChatLoadingMoreIndicator extends StatelessWidget {
  const ChatLoadingMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
