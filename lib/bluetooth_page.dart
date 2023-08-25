import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;
  String _receivedData = '';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  void _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.bluetoothConnect, Permission.bluetoothScan].request();

    if (statuses[Permission.bluetoothConnect] == PermissionStatus.granted &&
        statuses[Permission.bluetoothScan] == PermissionStatus.granted) {
      // Bluetooth permissions granted
      FlutterBluetoothSerial.instance.state.then((state) {
        setState(() {
          _bluetoothState = state;
        });
      });
    } else {
      // Bluetooth permissions denied
    }
  }

  void _turnOnBluetooth() async {
    await FlutterBluetoothSerial.instance.requestEnable();
    setState(() {
      _bluetoothState = BluetoothState.STATE_ON;
    });
  }

  void _turnOffBluetooth() async {
    await FlutterBluetoothSerial.instance.requestDisable();
    setState(() {
      _bluetoothState = BluetoothState.STATE_OFF;
      _devicesList.clear();
      _receivedData = '';
      _connection?.dispose();
    });
  }

  void _getDevices() async {
    try {
      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devicesList = devices;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Bluetooth: $e');
      }
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    // Connect to the selected device
    BluetoothConnection connection =
        await BluetoothConnection.toAddress(device.address);
    setState(() {
      _connection = connection;
    });

    // Send a request to the device to start sending data
    _connection?.output.add(Uint8List.fromList(utf8.encode('START')));

    // Listen for incoming data
    _connection?.input?.listen((data) {
      String receivedString = utf8.decode(data);
      List<String> dataParts = receivedString.split(';');
      if (dataParts.length == 7 && dataParts[0] == '9614') {
        setState(() {
          _receivedData = receivedString;
        });
      }
    });

    setState(() {
      _connectedDevice = device;
    });
  }

  void _disconnectDevice() {
    _connection?.dispose();
  }

  void _sendData() async {
    // Send the data
    String data = '9614;DATA1;DATA2;DATA3;DATA4;DATA5;CRC;';
    Uint8List bytes = Uint8List.fromList(utf8.encode(data));
    _connection?.output.add(bytes);
    await _connection?.output.allSent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bluetooth State: $_bluetoothState',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_bluetoothState == BluetoothState.STATE_OFF) {
                  _turnOnBluetooth();
                } else if (_bluetoothState == BluetoothState.STATE_ON) {
                  _turnOffBluetooth();
                }
              },
              child: Text(
                _bluetoothState == BluetoothState.STATE_OFF
                    ? 'Turn On Bluetooth'
                    : 'Turn Off Bluetooth',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getDevices,
              child: const Text('Get Devices'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Received Data:',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              _receivedData,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paired Devices:',
              style: TextStyle(fontSize: 18),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = _devicesList[index];
                return ListTile(
                  title: Text(device.name ?? 'Unknown Device'),
                  subtitle: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            {_disconnectDevice(), _connectToDevice(device)},
                        child: Text(
                          _connectedDevice == device ? 'Connected' : 'Connect',
                        ),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      ElevatedButton(
                        onPressed: () => _sendData(),
                        child: const Text(
                          'Send',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}
