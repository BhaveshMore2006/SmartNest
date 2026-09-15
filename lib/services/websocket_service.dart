import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>> _streamController = StreamController.broadcast();
  Timer? _reconnectTimer;
  String _currentIp = '';

  Stream<Map<String, dynamic>> get stream => _streamController.stream;

  void connect(String ip) {
    if (_currentIp == ip && _channel != null) return;
    
    disconnect();
    _currentIp = ip;
    _connectInternal();
  }

  void _connectInternal() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(Constants.getWebSocketUrl(_currentIp)),
      );

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);
            _streamController.add(decoded);
          } catch (e) {
            print('Error decoding WS message: $e');
          }
        },
        onDone: _scheduleReconnect,
        onError: (error) => _scheduleReconnect(),
      );
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void sendCommand(String action, String target, dynamic value) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': action,
        'target': target,
        'value': value,
      }));
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_currentIp.isNotEmpty) {
        _connectInternal();
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
