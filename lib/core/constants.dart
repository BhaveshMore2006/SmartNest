class Constants {
  // SharedPreferences keys
  static const String ipPrefKey = 'esp32_ip_address';
  
  // Default connection values
  static const String defaultIp = 'smarthome.local';
  
  // API Endpoints
  static String getStatusUrl(String ip) => 'http://$ip/api/status';
  static String getRelayUrl(String ip) => 'http://$ip/api/relay';
  static String getSecurityUrl(String ip) => 'http://$ip/api/security/arm';
  static String getBuzzerUrl(String ip) => 'http://$ip/api/buzzer';
  
  // Streaming & WebSocket URLs
  static String getStreamUrl(String ip) => 'http://$ip:81/stream';
  static String getWebSocketUrl(String ip) => 'ws://$ip/ws';
}
