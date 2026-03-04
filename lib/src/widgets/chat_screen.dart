// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/chat_bloc.dart';
import '../config/chat_config.dart';
import '../models/chat_message_model.dart';
import '../services/chat_sdk.dart';
import 'chat_widgets.dart';

class ChatScreen extends StatelessWidget {
  final ChatTheme? theme;
  final ChatLocalization? localization;
  final Widget? customAppBar;
  final VoidCallback? onBack;

  const ChatScreen({
    super.key,
    this.theme,
    this.localization,
    this.customAppBar,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (theme != null) ChatSdk.updateTheme(theme!);
    if (localization != null) ChatSdk.updateLocalization(localization!);

    return BlocProvider(
      create: (context) => ChatBloc()..add(const ChatInitEvent()),
      child: _ChatScreenBody(customAppBar: customAppBar, onBack: onBack),
    );
  }
}

class _ChatScreenBody extends StatefulWidget {
  final Widget? customAppBar;
  final VoidCallback? onBack;

  const _ChatScreenBody({this.customAppBar, this.onBack});

  @override
  State<_ChatScreenBody> createState() => _ChatScreenBodyState();
}

class _ChatScreenBodyState extends State<_ChatScreenBody> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _focusNode = FocusNode();
  bool _showScrollToBottom = false;
  int? _highlightedMessageId;
  Timer? _typingTimer;
  bool _isTyping = false;

  ChatTheme get theme => ChatSdk.theme;
  ChatLocalization get localization => ChatSdk.localization;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow =
        _scrollController.hasClients && _scrollController.offset > 200;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }

    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      if (maxScroll - currentScroll < 200) {
        context.read<ChatBloc>().add(const ChatLoadMoreHistoryEvent());
      }
    }
  }

  void _onTextChanged(String text) {
    setState(() {});

    if (text.trim().isEmpty) {
      _isTyping = false;
      _typingTimer?.cancel();
      return;
    }

    if (!_isTyping) {
      _isTyping = true;
      context.read<ChatBloc>().add(const ChatSendTypingEvent());
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () => _isTyping = false);
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return localization.today;
    } else if (messageDay == yesterday) {
      return localization.yesterday;
    } else {
      return '${localization.getMonthName(date.month)} ${date.day}';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(ChatSendMessageEvent(message: text));
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localization.selectImage,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.botTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPickerOption(
                        Icons.camera_alt,
                        localization.camera,
                        () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      _buildPickerOption(
                        Icons.photo_library,
                        localization.gallery,
                        () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      localization.cancel,
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPickerOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: theme.botTextColor)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final replyTo = context.read<ChatBloc>().state.replyToMessage;

      if (source == ImageSource.gallery) {
        final files = await _imagePicker.pickMultiImage(
          imageQuality: ChatSdk.config.imageQuality,
          maxWidth: ChatSdk.config.maxImageWidth.toDouble(),
          maxHeight: ChatSdk.config.maxImageHeight.toDouble(),
          limit: ChatSdk.config.maxImageCount,
        );

        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          if (file.path.split('.').last.toLowerCase() == 'svg') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localization.svgNotSupported)),
            );
            continue;
          }
          context.read<ChatBloc>().add(
            ChatSendImageEvent(
              imageFile: File(file.path),
              replyToMessage: i == 0 ? replyTo : null,
            ),
          );
        }
      } else {
        final file = await _imagePicker.pickImage(
          source: source,
          imageQuality: ChatSdk.config.imageQuality,
          maxWidth: ChatSdk.config.maxImageWidth.toDouble(),
          maxHeight: ChatSdk.config.maxImageHeight.toDouble(),
        );

        if (file != null) {
          if (file.path.split('.').last.toLowerCase() == 'svg') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localization.svgNotSupported)),
            );
            return;
          }
          context.read<ChatBloc>().add(
            ChatSendImageEvent(
              imageFile: File(file.path),
              replyToMessage: replyTo,
            ),
          );
        }
      }
      _scrollToBottom();
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  void _scrollToMessage(int? messageId) {
    if (messageId == null) return;

    final state = context.read<ChatBloc>().state;
    final messageIndex = state.messages.indexWhere(
      (m) => m.messageId == messageId,
    );

    if (messageIndex != -1) {
      final reversedIndex = state.messages.length - 1 - messageIndex;
      const estimatedItemHeight = 80.0;
      final targetOffset = (reversedIndex * estimatedItemHeight) - 100.0;

      _scrollController
          .animateTo(
            targetOffset < 0 ? 0.0 : targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .then((_) {
            setState(() => _highlightedMessageId = messageId);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) setState(() => _highlightedMessageId = null);
            });
          });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.unfocus(),
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar:
            widget.customAppBar != null
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: widget.customAppBar!,
                )
                : AppBar(
                  backgroundColor: theme.backgroundColor,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.botTextColor),
                    onPressed: widget.onBack ?? () => Navigator.pop(context),
                  ),
                  title: BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      return Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  state.isAdminOnline
                                      ? theme.onlineIndicatorColor
                                      : theme.offlineIndicatorColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            state.isAdminOnline
                                ? localization.online
                                : localization.offline,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.botTextColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        body: SafeArea(
          bottom: false,
          child: BlocConsumer<ChatBloc, ChatState>(
            listener: (context, state) {
              if (state.imageUploadError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.imageUploadError!)),
                );
                context.read<ChatBloc>().add(
                  const ChatClearImageUploadErrorEvent(),
                );
              }
            },
            builder: (context, state) {
              if (state.status == ChatStatus.loading) {
                return const ChatShimmerLoading();
              }

              if (state.status == ChatStatus.error) {
                return ChatErrorView(
                  errorMessage: state.errorMessage,
                  onRetry:
                      () => context.read<ChatBloc>().add(const ChatInitEvent()),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          itemCount:
                              state.messages.length +
                              (state.isLoadingMoreHistory ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (state.isLoadingMoreHistory &&
                                index == state.messages.length) {
                              return const ChatLoadingMoreIndicator();
                            }

                            final reversedIndex =
                                state.messages.length - 1 - index;
                            final msg = state.messages[reversedIndex];

                            bool showDateSeparator = false;
                            String? dateText;
                            final msgDate = msg.createdAt ?? DateTime.now();

                            if (reversedIndex == 0) {
                              showDateSeparator = true;
                              dateText = _formatDateSeparator(msgDate);
                            } else {
                              final prevMsg = state.messages[reversedIndex - 1];
                              final prevDate =
                                  prevMsg.createdAt ?? DateTime.now();
                              if (!_isSameDay(msgDate, prevDate)) {
                                showDateSeparator = true;
                                dateText = _formatDateSeparator(msgDate);
                              }
                            }

                            return _buildMessage(
                              msg,
                              showDateSeparator: showDateSeparator,
                              dateText: dateText,
                            );
                          },
                        ),
                        if (_showScrollToBottom)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: ChatScrollToBottomButton(
                              onTap: _scrollToBottom,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (state.replyToMessage != null)
                    ChatReplyPreview(
                      replyTo: state.replyToMessage!,
                      onClose:
                          () => context.read<ChatBloc>().add(
                            const ChatClearReplyToMessageEvent(),
                          ),
                    ),
                  ChatInputBar(
                    controller: _controller,
                    focusNode: _focusNode,
                    onSend: _sendMessage,
                    onAttachmentTap: _showImagePickerOptions,
                    onChanged: _onTextChanged,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(
    ChatMessageModel msg, {
    bool showDateSeparator = false,
    String? dateText,
  }) {
    final state = context.read<ChatBloc>().state;
    String? replyText = msg.replyToText;
    String? replyImageUrl;

    if (msg.replyToId != null) {
      final replyMsg = state.messages.firstWhereOrNull(
        (m) => m.messageId == msg.replyToId,
      );
      if (replyMsg != null) {
        if (replyText == null || replyText.isEmpty) replyText = replyMsg.text;
        if (replyMsg.isImage) {
          replyImageUrl = replyMsg.imageUrl;
          if (replyText.isEmpty) replyText = localization.image;
        }
      }
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          final swipeRight = !msg.isBot && details.primaryVelocity! > 300;
          final swipeLeft = msg.isBot && details.primaryVelocity! < -300;
          if (swipeRight || swipeLeft) {
            context.read<ChatBloc>().add(
              ChatSetReplyToMessageEvent(message: msg),
            );
            _focusNode.requestFocus();
          }
        }
      },
      child: Column(
        crossAxisAlignment:
            msg.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (showDateSeparator && dateText != null)
            ChatDateSeparator(text: dateText),
          ChatMessageBubble(
            msg: msg,
            replyText: replyText,
            replyImageUrl: replyImageUrl,
            isHighlighted: _highlightedMessageId == msg.messageId,
            onReplyTap: () => _scrollToMessage(msg.replyToId),
          ),
        ],
      ),
    );
  }
}
