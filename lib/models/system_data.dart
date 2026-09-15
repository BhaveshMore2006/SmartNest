class SystemData {
  final double temperature;
  final double humidity;
  final bool pirMotion;
  final bool relayLight;
  final bool relayFan;
  final bool buzzer;
  final bool armed;
  final int uptime;

  SystemData({
    this.temperature = 0.0,
    this.humidity = 0.0,
    this.pirMotion = false,
    this.relayLight = false,
    this.relayFan = false,
    this.buzzer = false,
    this.armed = false,
    this.uptime = 0,
  });

  factory SystemData.fromJson(Map<String, dynamic> json) {
    return SystemData(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      pirMotion: json['pir_motion'] ?? false,
      relayLight: json['light'] ?? json['relay_light'] ?? false,
      relayFan: json['fan'] ?? json['relay_fan'] ?? false,
      buzzer: json['buzzer'] ?? false,
      armed: json['armed'] ?? false,
      uptime: json['uptime'] ?? 0,
    );
  }

  SystemData copyWith({
    double? temperature,
    double? humidity,
    bool? pirMotion,
    bool? relayLight,
    bool? relayFan,
    bool? buzzer,
    bool? armed,
    int? uptime,
  }) {
    return SystemData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pirMotion: pirMotion ?? this.pirMotion,
      relayLight: relayLight ?? this.relayLight,
      relayFan: relayFan ?? this.relayFan,
      buzzer: buzzer ?? this.buzzer,
      armed: armed ?? this.armed,
      uptime: uptime ?? this.uptime,
    );
  }
}
