class Constants {
  // SharedPreferences keys
  static const String ipPrefKey = 'esp32_ip_address';
  static const String camIpPrefKey = 'esp32_cam_ip_address';
  
  // Default connection values
  static const String defaultIp = '';
  static const String defaultCamIp = '192.168.137.100';
  
  // API Endpoints
  static String getStatusUrl(String ip) => 'http://$ip/data';
  static String getRelayUrl(String ip, int channel, int state) {
    if (channel == 2) return 'http://$ip/fan?state=$state';
    return 'http://$ip/relay1?state=$state';
  }
  static String getSecurityUrl(String ip) => 'http://$ip/api/security/arm'; // Unused
  static String getBuzzerUrl(String ip, int state) => 'http://$ip/buzzer?state=$state&auto=0';
  
  // Streaming & WebSocket URLs
  static String getStreamUrl(String ip) {
    if (ip.contains('/stream')) {
      return ip.startsWith('http') ? ip : 'http://$ip';
    }
    return 'http://$ip:81/stream';
  }
  static String getWebSocketUrl(String ip) => 'ws://$ip/ws';
}
