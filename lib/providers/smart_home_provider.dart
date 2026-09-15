import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/system_data.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());
final webSocketServiceProvider = Provider((ref) => WebSocketService());

// Provider for the currently active IP Address
final ipAddressProvider = StateNotifierProvider<IpAddressNotifier, String>((ref) {
  return IpAddressNotifier();
});

class IpAddressNotifier extends StateNotifier<String> {
  IpAddressNotifier() : super(Constants.defaultIp) {
    _loadIp();
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString(Constants.ipPrefKey);
    if (savedIp != null && savedIp.isNotEmpty) {
      state = savedIp;
    }
  }

  Future<void> setIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.ipPrefKey, ip);
    state = ip;
  }
}

// Provider for the live system data
final systemDataProvider = StateNotifierProvider<SystemDataNotifier, SystemData>((ref) {
  final ip = ref.watch(ipAddressProvider);
  final api = ref.watch(apiServiceProvider);
  final ws = ref.watch(webSocketServiceProvider);
  return SystemDataNotifier(ip, api, ws);
});

class SystemDataNotifier extends StateNotifier<SystemData> {
  final String ip;
  final ApiService api;
  final WebSocketService ws;

  SystemDataNotifier(this.ip, this.api, this.ws) : super(SystemData()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Get initial state via HTTP
    final initialData = await api.getStatus(ip);
    if (initialData != null) {
      state = initialData;
    }

    // 2. Connect WebSocket and listen for updates
    ws.connect(ip);
    ws.stream.listen((message) {
      if (message['type'] == 'TELEMETRY_UPDATE') {
        state = state.copyWith(
          temperature: (message['temperature'] ?? state.temperature).toDouble(),
          humidity: (message['humidity'] ?? state.humidity).toDouble(),
          pirMotion: message['pir'] ?? state.pirMotion,
          relayLight: message['light'] ?? state.relayLight,
          relayFan: message['fan'] ?? state.relayFan,
          armed: message['armed'] ?? state.armed,
        );
      } else if (message['type'] == 'ALARM_TRIGGERED') {
        // Handle alarm (e.g., show notification/dialog in UI layer)
        state = state.copyWith(pirMotion: true);
      }
    });
  }

  Future<void> toggleRelay(int channel, bool value) async {
    // Optimistic UI update
    if (channel == 1) state = state.copyWith(relayLight: value);
    if (channel == 2) state = state.copyWith(relayFan: value);
    
    final success = await api.setRelay(ip, channel, value);
    if (!success) {
      // Revert if failed
      if (channel == 1) state = state.copyWith(relayLight: !value);
      if (channel == 2) state = state.copyWith(relayFan: !value);
    }
  }

  Future<void> toggleSecurity(bool armed) async {
    state = state.copyWith(armed: armed);
    final success = await api.setSecurity(ip, armed);
    if (!success) state = state.copyWith(armed: !armed);
  }
  
  Future<void> triggerBuzzer(bool value) async {
    state = state.copyWith(buzzer: value);
    final success = await api.setBuzzer(ip, value);
    if (!success) state = state.copyWith(buzzer: !value);
  }

  @override
  void dispose() {
    ws.disconnect();
    super.dispose();
  }
}
