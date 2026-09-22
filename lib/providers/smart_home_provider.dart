import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/system_data.dart';
import '../services/api_service.dart';
import 'dart:async';
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

// Provider for the currently active ESP32-CAM IP Address
final camIpAddressProvider = StateNotifierProvider<CamIpAddressNotifier, String>((ref) {
  return CamIpAddressNotifier();
});

class CamIpAddressNotifier extends StateNotifier<String> {
  CamIpAddressNotifier() : super(Constants.defaultCamIp) {
    _loadIp();
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString(Constants.camIpPrefKey);
    if (savedIp != null && savedIp.isNotEmpty) {
      state = savedIp;
    }
  }

  Future<void> setIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.camIpPrefKey, ip);
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

  Timer? _timer;

  SystemDataNotifier(this.ip, this.api, this.ws) : super(SystemData()) {
    _init();
  }

  void _init() {
    // Start periodic polling synchronously so it can be safely cancelled
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchData();
    });
    // Fetch initial data immediately
    _fetchData();
  }

  Future<void> _fetchData() async {
    final initialData = await api.getStatus(ip);
    if (initialData != null && mounted) {
      state = initialData;
    }
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
    _timer?.cancel();
    ws.disconnect();
    super.dispose();
  }
}
