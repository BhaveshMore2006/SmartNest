import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/smart_home_provider.dart';
import '../main.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import '../core/constants.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemData = ref.watch(systemDataProvider);
    final themeMode = ref.watch(themeProvider);
    final camIpAddress = ref.watch(camIpAddressProvider);
    final streamUrl = Constants.getStreamUrl(camIpAddress);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartNest Hub'),
        actions: [
          IconButton(
            icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).state = 
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (camIpAddress.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black,
                  height: 250,
                  width: double.infinity,
                  child: Mjpeg(
                    isLive: true,
                    stream: streamUrl,
                    timeout: const Duration(seconds: 15),
                    error: (context, error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          Text('Stream error: $error', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    loading: (context) => const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            if (camIpAddress.isEmpty)
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('Camera not configured.\nPlease set IP in Settings.', textAlign: TextAlign.center),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildEnvironmentCard(context, 'Temperature', '${systemData.temperature}°C', Icons.thermostat, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildEnvironmentCard(context, 'Humidity', '${systemData.humidity}%', Icons.water_drop, Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: systemData.pirMotion ? Colors.red.shade100 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      systemData.pirMotion ? Icons.directions_run : Icons.accessibility_new,
                      size: 36,
                      color: systemData.pirMotion ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PIR Motion Sensor', style: TextStyle(color: Colors.grey)),
                          Text(
                            systemData.pirMotion ? 'MOTION DETECTED!' : 'All Clear (No Motion)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: systemData.pirMotion ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildControlCard(
              context: context,
              title: 'Light (Relay 1)',
              icon: Icons.lightbulb,
              value: systemData.relayLight,
              onChanged: (val) => ref.read(systemDataProvider.notifier).toggleRelay(1, val),
            ),
            const SizedBox(height: 16),
            _buildControlCard(
              context: context,
              title: 'Fan (Relay 2)',
              icon: Icons.air,
              value: systemData.relayFan,
              onChanged: (val) => ref.read(systemDataProvider.notifier).toggleRelay(2, val),
            ),
            const SizedBox(height: 16),
            _buildControlCard(
              context: context,
              title: 'Manual Buzzer Alarm',
              icon: Icons.campaign,
              value: systemData.buzzer,
              onChanged: (val) => ref.read(systemDataProvider.notifier).triggerBuzzer(val),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildEnvironmentCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Icon(icon, size: 32, color: value ? Theme.of(context).primaryColor : Colors.grey),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
