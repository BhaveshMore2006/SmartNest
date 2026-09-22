import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import '../core/constants.dart';
import '../providers/smart_home_provider.dart';

class SurveillanceScreen extends ConsumerWidget {
  const SurveillanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camIpAddress = ref.watch(camIpAddressProvider);
    final systemData = ref.watch(systemDataProvider);
    final streamUrl = Constants.getStreamUrl(camIpAddress);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Surveillance'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.black,
            height: 300,
            child: camIpAddress.isEmpty 
              ? const Center(
                  child: Text(
                    'Camera IP not configured. Please set it in Settings.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : Mjpeg(
              isLive: true,
              stream: streamUrl,
              error: (context, error, stack) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text('Stream error: $error', style: const TextStyle(color: Colors.white)),
                      const Text('Ensure ESP32-CAM is online and IP is correct.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              },
              loading: (context) {
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Security Controls',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: systemData.buzzer ? Colors.red : Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.volume_up),
                    label: Text(systemData.buzzer ? 'Siren ON' : 'Trigger Siren'),
                    onPressed: () {
                      ref.read(systemDataProvider.notifier).triggerBuzzer(!systemData.buzzer);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
