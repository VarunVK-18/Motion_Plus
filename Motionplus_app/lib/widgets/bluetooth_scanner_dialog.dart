import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

class BluetoothScannerDialog extends StatefulWidget {
  const BluetoothScannerDialog({super.key});

  @override
  _BluetoothScannerDialogState createState() => _BluetoothScannerDialogState();
}

class _BluetoothScannerDialogState extends State<BluetoothScannerDialog> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    // Request permissions
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Listen to scan results
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });

    // Listen to scanning state
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() {
          _isScanning = state;
        });
      }
    });

    _startScan();
  }

  void _startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      debugPrint("Start Scan Error: $e");
    }
  }

  void _stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  void _connectToDevice(BluetoothDevice device) async {
    _stopScan();
    try {
      await device.connect(
        license: License.free,
        autoConnect: false,
        mtu: null,
      );

      try {
        if (Platform.isAndroid) {
          await device.createBond();
        }
      } catch (e) {
        debugPrint("Bonding error: $e");
      }

      // Discover services and subscribe to notifications to keep the connection alive
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify ||
              characteristic.properties.indicate) {
            try {
              await characteristic.setNotifyValue(true);
              // Listen to the stream so the data is consumed (keeps stream alive)
              characteristic.onValueReceived.listen((value) {});
            } catch (e) {
              debugPrint("Failed to subscribe to characteristic: $e");
            }
          }
        }
      }

      if (mounted) {
        // Show success and close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connected to ${device.advName.isNotEmpty ? device.advName : "Unknown Device"}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(device); // Return the connected device
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to connect')));
      }
    }
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bluetooth_searching, color: Colors.blue),
          const SizedBox(width: 10),
          const Text('Scan Watch'),
          const Spacer(),
          if (_isScanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _scanResults.isEmpty
            ? const Center(
                heightFactor: 3,
                child: Text(
                  "Searching for nearby devices...\nMake sure your watch is on.",
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _scanResults.length,
                itemBuilder: (context, index) {
                  final result = _scanResults[index];
                  final deviceName = result.device.advName.isNotEmpty
                      ? result.device.advName
                      : 'Unknown Device';

                  return ListTile(
                    leading: const Icon(Icons.watch),
                    title: Text(deviceName),
                    subtitle: Text(result.device.remoteId.toString()),
                    trailing: ElevatedButton(
                      child: const Text('Connect'),
                      onPressed: () => _connectToDevice(result.device),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: _isScanning ? _stopScan : _startScan,
          child: Text(_isScanning ? 'Stop' : 'Rescan'),
        ),
      ],
    );
  }
}
