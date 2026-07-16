import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants/port.dart';

class SocketService {
  static IO.Socket? _socket;

  static void initializeSocket() {
    _socket = IO.io(PortConstants.backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.onConnect((_) {
      print('Socket Connected');
    });

    _socket!.onDisconnect((_) {
      print('Socket Disconnected');
    });

    _socket!.connect();
  }

  static IO.Socket? get socket => _socket;

  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
    }
  }
}
