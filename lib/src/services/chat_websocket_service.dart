import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'chat_sdk.dart';

class ChatWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  String? _externalId;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _baseReconnectDelay = Duration(seconds: 1);

  final Function(Map<String, dynamic>)? onMessageReceived;
  final Function()? onConnected;
  final Function()? onDisconnected;
  final Function(Map<String, dynamic>)? onHistoryLoaded;
  final Function()? onTyping;
  final Function(bool)? onAdminStatusChanged;

  ChatWebSocketService({
    this.onMessageReceived,
    this.onConnected,
    this.onDisconnected,
    this.onHistoryLoaded,
    this.onTyping,
    this.onAdminStatusChanged,
  });

  bool get isConnected => _isConnected;

  Future<void> connect(String externalId) async {
    if (_isConnected) {
      debugPrint('ChatWebSocket: Already connected');
      return;
    }

    _externalId = externalId;
    _shouldReconnect = true;

    try {
      final wsUrl = '${ChatSdk.config.webSocketUrl}$externalId/';
      debugPrint('ChatWebSocket: Connecting to $wsUrl (attempt #$_reconnectAttempts)');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _subscription = _channel?.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0; // Reset on successful connection
      onConnected?.call();
      _startPingTimer();

      debugPrint('ChatWebSocket: Connected successfully');
    } catch (e) {
      debugPrint('ChatWebSocket: Connection error - $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'];

      debugPrint('ChatWebSocket: Received - $type');

      switch (type) {
        case 'message':
          onMessageReceived?.call(data);
          break;
        case 'history':
          final messages = data['messages'] as List? ?? [];
          onHistoryLoaded?.call({'messages': messages});
          break;
        case 'typing':
          onTyping?.call();
          break;
        case 'admin_status':
          final isOnline = data['is_online'] == true;
          onAdminStatusChanged?.call(isOnline);
          break;
        case 'pong':
          debugPrint('ChatWebSocket: Pong received');
          break;
      }
    } catch (e) {
      debugPrint('ChatWebSocket: Parse error - $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('ChatWebSocket: Error - $error');
    _isConnected = false;
    onDisconnected?.call();
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('ChatWebSocket: Connection closed');
    _isConnected = false;
    onDisconnected?.call();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect || _externalId == null || _reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('ChatWebSocket: Max reconnect attempts reached or reconnection disabled');
      return;
    }

    _reconnectAttempts++;
    final delay = _baseReconnectDelay * (1 << (_reconnectAttempts - 1)); // Exponential backoff
    
    debugPrint('ChatWebSocket: Scheduling reconnect #$_reconnectAttempts in ${delay.inSeconds}s');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect && _externalId != null) {
        connect(_externalId!);
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        _sendPing();
      }
    });
  }

  void _sendPing() {
    _send({'type': 'ping'});
  }

  void sendMessage(String text, {int? replyToId}) {
    final data = <String, dynamic>{'type': 'message', 'text': text};
    if (replyToId != null) {
      data['reply_to_id'] = replyToId;
    }
    _send(data);
  }

  void sendTyping() {
    _send({'type': 'typing'});
  }

  void sendRead() {
    _send({'type': 'read'});
  }

  void requestHistory({int? lastId}) {
    final data = <String, dynamic>{
      'type': 'get_history',
      'count': ChatSdk.config.historyPageSize,
    };
    if (lastId != null) {
      data['last_id'] = lastId;
    }
    _send(data);
  }

  void _send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (e) {
        debugPrint('ChatWebSocket: Send error - $e');
      }
    }
  }

  void dispose() {
    debugPrint('ChatWebSocket: Disposing service');
    _shouldReconnect = false;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    
    if (_channel != null) {
      try {
        _channel!.sink.close();
      } catch (e) {
        debugPrint('ChatWebSocket: Error closing channel - $e');
      }
    }
    
    _isConnected = false;
    _channel = null;
    _subscription = null;
  }
}
