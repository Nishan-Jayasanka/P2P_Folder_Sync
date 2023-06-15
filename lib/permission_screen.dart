import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'home_screen.dart';
import 'dart:math';

class PermissionScreen extends StatefulWidget {
  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool locationPermissionGranted = false;
  bool externalStoragePermissionGranted = false;
  bool bluetoothPermissionGranted = false;
  bool locationEnabled = false;
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  Map<String, ConnectionInfo> endpointMap = {};

  @override
  void initState() {
    super.initState();
    checkPermissions();
    checkLocationEnabled();
  }

  void checkPermissions() async {
    bool locationGranted = await Permission.location.isGranted;
    bool storageGranted = await Permission.storage.isGranted;
    bool bluetoothGranted = await Permission.bluetooth.isGranted;

    setState(() {
      locationPermissionGranted = locationGranted;
      externalStoragePermissionGranted = storageGranted;
      bluetoothPermissionGranted = bluetoothGranted;
    });
  }

  void checkLocationEnabled() async {
    bool enabled = await Nearby().checkLocationEnabled();
    setState(() {
      locationEnabled = enabled;
    });
  }

  Future<void> navigateToFileShareScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(),
      ),
    );
  }

  void openSettings() async {
    await openAppSettings();
  }

  Future<void> requestLocationPermission() async {
    bool isLocationPermissionGranted = await Nearby().askLocationPermission();
    if (isLocationPermissionGranted) {
      setState(() {
        locationPermissionGranted = true;
      });
    }
  }

  Future<void> requestStoragePermission() async {
    Nearby().askExternalStoragePermission();
    setState(() {
      externalStoragePermissionGranted = true;
    });
    bool c = await Nearby().checkExternalStoragePermission();
    print(c);
  }

  Future<void> requestBluetoothPermission() async {
    Nearby().askBluetoothPermission();
    setState(() {
      bluetoothPermissionGranted = true;
    });
    bool isBluetoothPermissionGranted =
        await Nearby().checkBluetoothPermission();
    print(isBluetoothPermissionGranted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 237, 240, 248),
      appBar: AppBar(
        title: Text(
          "Permission",
          style: TextStyle(color: Colors.white),
        ),
        // titleTextStyle: Text,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 15, // <-- SEE HERE
            ),
            Text(
              "Permission Needed",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 50, // <-- SEE HERE
            ),
            ListTile(
              title: Text("Location Permission"),
              leading: Icon(Icons.location_pin),
              trailing: ElevatedButton(
                onPressed: locationPermissionGranted
                    ? null
                    : requestLocationPermission,
                style: ElevatedButton.styleFrom(
                    // backgroundColor: Color.fromARGB(1, 154, 3, 30),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white),
                child: Text("Grant Permission"),
              ),
              onTap:
                  locationPermissionGranted ? null : requestLocationPermission,
            ),
            SizedBox(
              height: 30, // <-- SEE HERE
            ),
            ListTile(
              title: Text("External Storage Permission"),
              leading: Icon(Icons.storage_rounded),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    // backgroundColor: Color.fromARGB(1, 154, 3, 30),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white),
                onPressed: externalStoragePermissionGranted
                    ? null
                    : requestStoragePermission,
                child: Text("Grant Permission"),
              ),
              onTap: externalStoragePermissionGranted
                  ? null
                  : requestStoragePermission,
            ),
            SizedBox(
              height: 30, // <-- SEE HERE
            ),
            ListTile(
              title: Text("Bluetooth Permission (Android 12+)"),
              leading: Icon(Icons.bluetooth),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    // backgroundColor: Color.fromARGB(1, 154, 3, 30),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white),
                onPressed: bluetoothPermissionGranted
                    ? null
                    : requestBluetoothPermission,
                child: Text("Grant Permission"),
              ),
              onTap: bluetoothPermissionGranted
                  ? null
                  : requestBluetoothPermission,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: EdgeInsets.only(top: 50),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: Color.fromARGB(1, 154, 3, 30),
                        backgroundColor: Color.fromARGB(255, 168, 5, 35),
                        foregroundColor: Colors.white,
                        minimumSize: Size.fromHeight(50),
                      ),
                      onPressed: (locationPermissionGranted &&
                              externalStoragePermissionGranted &&
                              bluetoothPermissionGranted)
                          ? navigateToFileShareScreen
                          : null,
                      child: Text(
                        "Continue",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
