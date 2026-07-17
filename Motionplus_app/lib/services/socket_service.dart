import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants/port.dart';
import '../notifications/notification_service.dart';

class SocketService {
  static IO.Socket? _socket;
  static final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get onNewMessage => _messageController.stream;

  static void initializeSocket(String userId) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(PortConstants.backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'userId': userId},
    });

    _socket!.onConnect((_) {
      debugPrint('Socket Connected for $userId');
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket Disconnected');
    });

    _socket!.on('newMessage', (data) {
      debugPrint('New message received: $data');
      if (data != null && data is Map) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('notification', (data) {
      debugPrint('Notification received: $data');
      if (data != null && data is Map) {
        NotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: data['title'] ?? 'New Notification',
          body: data['body'] ?? '',
        );
      }
    });

    _socket!.connect();
  }

  static IO.Socket? get socket => _socket;

  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.destroy();
      _socket = null;
    }
  }
}
