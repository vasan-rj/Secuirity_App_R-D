import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('kiosk_mode_channel');

  Future<void> enableKioskMode() async {
    try {
      await platform.invokeMethod('enableKiosk');
    } on PlatformException catch (e) {
      print("Failed to enable Kiosk Mode: ${e.message}");
    }
  }

  Future<void> disableKioskMode() async {
    try {
      await platform.invokeMethod('disableKiosk');
    } on PlatformException catch (e) {
      print("Failed to disable Kiosk Mode: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kiosk Mode App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: enableKioskMode,
              child: Text('ON (Enable Kiosk Mode)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: disableKioskMode,
              child: Text('OFF (Disable Kiosk Mode)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
