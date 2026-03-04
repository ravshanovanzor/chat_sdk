# Chat SDK

A customizable chat SDK for Flutter applications with WebSocket support, image sharing, and reply functionality.

## Features

- 💬 Real-time messaging with WebSocket
- 🖼️ Image sharing support
- ↩️ Reply to messages
- 🎨 Fully customizable theme
- 📱 Works on iOS and Android
- 🔄 Message caching with Hive
- ✨ Shimmer loading animation
- 🔔 Typing indicators

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  chat_sdk: ^1.0.0
```

## Usage

### 1. Initialize the SDK

```dart
import 'package:chat_sdk/chat_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await ChatSdk.initialize(
    config: ChatConfig(
      baseUrl: 'https://your-api.com',
      webSocketUrl: 'wss://your-websocket.com/ws/chat/',
      getConversationEndpoint: 'chat.get_conversation',
      getHistoryEndpoint: 'chat.get_history',
      uploadImageEndpoint: 'chat.upload_image',
      authTokenProvider: () async => 'your-auth-token',
    ),
  );
  
  runApp(MyApp());
}
```

### 2. Open Chat Screen

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const ChatScreen(),
  ),
);
```

### 3. Customize Theme

```dart
ChatScreen(
  theme: ChatTheme(
    primaryColor: Colors.blue,
    userBubbleColor: Colors.blue,
    botBubbleColor: Colors.grey[200],
    userTextColor: Colors.white,
    botTextColor: Colors.black87,
    backgroundColor: Colors.white,
    inputBackgroundColor: Colors.grey[100],
    inputBorderRadius: 24,
    messageBorderRadius: 16,
  ),
)
```

### 4. Localization

```dart
ChatScreen(
  localization: ChatLocalization(
    today: 'Today',
    yesterday: 'Yesterday',
    typeMessage: 'Type a message...',
    send: 'Send',
    image: 'Image',
    svgNotSupported: 'SVG format is not supported',
    errorTitle: 'Error',
    retry: 'Retry',
    camera: 'Camera',
    gallery: 'Gallery',
  ),
)
```

## API Reference

### ChatConfig

| Property | Type | Description |
|----------|------|-------------|
| `baseUrl` | `String` | Base URL for API requests |
| `webSocketUrl` | `String` | WebSocket connection URL |
| `getConversationEndpoint` | `String` | Endpoint for getting conversation |
| `getHistoryEndpoint` | `String` | Endpoint for getting chat history |
| `uploadImageEndpoint` | `String` | Endpoint for uploading images |
| `authTokenProvider` | `Future<String> Function()` | Function to provide auth token |

### ChatTheme

| Property | Type | Default |
|----------|------|---------|
| `primaryColor` | `Color` | `Colors.blue` |
| `userBubbleColor` | `Color` | `Colors.blue` |
| `botBubbleColor` | `Color` | `Colors.grey[200]` |
| `backgroundColor` | `Color` | `Colors.white` |
| `inputBackgroundColor` | `Color` | `Colors.grey[100]` |
| `messageBorderRadius` | `double` | `16` |

## Example

See the [example](example/) directory for a complete sample app.

## License

MIT License - see [LICENSE](LICENSE) for details.

