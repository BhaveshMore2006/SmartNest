import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/system_data.dart';

class ApiService {
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<SystemData?> getStatus(String ip) async {
    if (ip.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(Constants.getStatusUrl(ip)))
          .timeout(const Duration(seconds: 5));
      print('--- getStatus RESPONSE ---');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The new ESP-12 returns a flat JSON.
        return SystemData(
          uptime: 0,
          armed: false,
          temperature: _parseDouble(data['temp']),
          humidity: _parseDouble(data['hum']),
          pirMotion: data['motion']?.toString() == 'true',
          relayLight: data['relay1']?.toString() == '1',
          relayFan: data['fan']?.toString() == '1',
          buzzer: data['buzzer']?.toString() == '1',
        );
      }
    } catch (e) {
      print('Error getting status: $e');
    }
    return null;
  }

  Future<bool> setRelay(String ip, int channel, bool state) async {
    if (ip.isEmpty) return false;
    try {
      final url = Constants.getRelayUrl(ip, channel, state ? 1 : 0);
      print('--- setRelay REQUEST ---');
      print('URL: $url');
      
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      
      // The ESP-12 redirects (303), or we just consider it successful if not an error.
      return response.statusCode == 200 || response.statusCode == 303;
    } catch (e) {
      print('Error setting relay: $e');
      return false;
    }
  }

  Future<bool> setSecurity(String ip, bool armed) async {
    if (ip.isEmpty) return false;
    try {
      final response = await http.post(
        Uri.parse(Constants.getSecurityUrl(ip)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'armed': armed}),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Error setting security: $e');
      return false;
    }
  }

  Future<bool> setBuzzer(String ip, bool state) async {
    if (ip.isEmpty) return false;
    try {
      final url = Constants.getBuzzerUrl(ip, state ? 1 : 0);
      print('--- setBuzzer REQUEST ---');
      print('URL: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      print('Status Code: ${response.statusCode}');
      
      return response.statusCode == 200 || response.statusCode == 303;
    } catch (e) {
      print('Error setting buzzer: $e');
      return false;
    }
  }
}
