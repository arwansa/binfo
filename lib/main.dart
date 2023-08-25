import 'package:flutter/material.dart';
import 'bluetooth_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const BluetoothPage(),
    );
  }
}
