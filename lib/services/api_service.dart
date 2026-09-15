import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/system_data.dart';

class ApiService {
  Future<SystemData?> getStatus(String ip) async {
    try {
      final response = await http.get(Uri.parse(Constants.getStatusUrl(ip)));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The ESP32 returns a nested JSON. We flatten it for our model.
        return SystemData(
          uptime: data['system']?['uptime'] ?? 0,
          armed: data['system']?['armed'] ?? false,
          temperature: (data['sensors']?['temperature'] ?? 0.0).toDouble(),
          humidity: (data['sensors']?['humidity'] ?? 0.0).toDouble(),
          pirMotion: data['sensors']?['pir_motion'] ?? false,
          relayLight: data['actuators']?['relay_light'] ?? false,
          relayFan: data['actuators']?['relay_fan'] ?? false,
          buzzer: data['actuators']?['buzzer'] ?? false,
        );
      }
    } catch (e) {
      print('Error getting status: $e');
    }
    return null;
  }

  Future<bool> setRelay(String ip, int channel, bool state) async {
    try {
      final response = await http.post(
        Uri.parse(Constants.getRelayUrl(ip)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'channel': channel, 'state': state}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error setting relay: $e');
      return false;
    }
  }

  Future<bool> setSecurity(String ip, bool armed) async {
    try {
      final response = await http.post(
        Uri.parse(Constants.getSecurityUrl(ip)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'armed': armed}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error setting security: $e');
      return false;
    }
  }

  Future<bool> setBuzzer(String ip, bool state) async {
    try {
      final response = await http.post(
        Uri.parse(Constants.getBuzzerUrl(ip)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'state': state}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error setting buzzer: $e');
      return false;
    }
  }
}
