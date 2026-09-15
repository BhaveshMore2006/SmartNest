import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/smart_home_provider.dart';
import '../main.dart';
import 'surveillance_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemData = ref.watch(systemDataProvider);
    final themeMode = ref.watch(themeProvider);

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
            _buildSecurityCard(context, ref, systemData.armed, systemData.pirMotion),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildEnvironmentCard(context, 'Temperature', '${systemData.temperature}°C', Icons.thermostat, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildEnvironmentCard(context, 'Humidity', '${systemData.humidity}%', Icons.water_drop, Colors.blue)),
              ],
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
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text('View Live Surveillance', style: TextStyle(fontSize: 16)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SurveillanceScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context, WidgetRef ref, bool isArmed, bool motionDetected) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              isArmed ? Icons.shield : Icons.shield_outlined,
              size: 48,
              color: isArmed ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              isArmed ? 'System Armed' : 'System Disarmed',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isArmed && motionDetected)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Text('MOTION DETECTED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Security Status'),
              subtitle: Text(isArmed ? 'Alarm will trigger on motion' : 'Alarm disabled'),
              value: isArmed,
              activeColor: Colors.green,
              onChanged: (val) => ref.read(systemDataProvider.notifier).toggleSecurity(val),
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
