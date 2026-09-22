import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/smart_home_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _camIpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill the current IP
    _ipController.text = ref.read(ipAddressProvider);
    _camIpController.text = ref.read(camIpAddressProvider);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _camIpController.dispose();
    super.dispose();
  }

  void _saveIp() {
    final ip = _ipController.text.trim();
    final camIp = _camIpController.text.trim();
    if (ip.isNotEmpty) {
      ref.read(ipAddressProvider.notifier).setIp(ip);
    }
    if (camIp.isNotEmpty) {
      ref.read(camIpAddressProvider.notifier).setIp(camIp);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('IP Addresses saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hardware Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'ESP-12 (Hub) IP Address or Hostname',
                hintText: 'e.g., 192.168.1.50 or smarthome.local',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _camIpController,
              decoration: const InputDecoration(
                labelText: 'ESP32-CAM IP Address or Hostname',
                hintText: 'e.g., 192.168.1.51 or cam.local',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.camera_alt),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              onPressed: _saveIp,
              child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
