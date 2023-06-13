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
  Map<String, ConnectionInfo> endpointMap = Map();

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
    bool c = await  Nearby().checkExternalStoragePermission();
    print(c);
  }

  Future<void> requestBluetoothPermission() async {
    Nearby().askBluetoothPermission();
    setState(() {
      bluetoothPermissionGranted = true;
    });
    bool isBluetoothPermissionGranted = await Nearby().checkBluetoothPermission();
    print(isBluetoothPermissionGranted);
  }

  Future<void> startAdvertising() async {
    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {
          showSnackbar(status);
        },
        onDisconnected: (id) {
          showSnackbar("Disconnected: ${endpointMap[id]!.endpointName}, id $id");
          setState(() {
            endpointMap.remove(id);
          });
        },
      );
      showSnackbar("ADVERTISING");
    } catch (exception) {
      print('button pressed!');
      showSnackbar(exception);
    }
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Center(
          child: Column(
            children: <Widget>[
              Text("id: " + id),
              Text("Token: " + info.authenticationToken),
              Text("Name" + info.endpointName),
              Text("Incoming: " + info.isIncomingConnection.toString()),
              ElevatedButton(
                child: Text("Accept Connection"),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    endpointMap[id] = info;
                  });
                  Nearby().acceptConnection(
                    id,
                    onPayLoadRecieved: (endid, payload) async {
                      // Handle payload received
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      // Handle payload transfer updates
                    },
                  );
                },
              ),
              ElevatedButton(
                child: Text("Reject Connection"),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await Nearby().rejectConnection(id);
                  } catch (e) {
                    showSnackbar(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Permission Screen"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Location Permission",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              title: Text("Granted"),
              leading: Checkbox(
                value: locationPermissionGranted,
                onChanged: null,
              ),
            ),
            ListTile(
              title: Text("External Storage Permission"),
              leading: Checkbox(
                value: externalStoragePermissionGranted,
                onChanged: null,
              ),
            ),
            ListTile(
              title: Text("Bluetooth Permission (Android 12+)"),
              leading: Checkbox(
                value: bluetoothPermissionGranted,
                onChanged: null,
              ),
            ),
            Divider(),
            Text(
              "Location Enabled",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              title: Text(locationEnabled ? "Enabled" : "Disabled"),
              leading: Checkbox(
                value: locationEnabled,
                onChanged: null,
              ),
            ),
            SizedBox(height: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (locationPermissionGranted &&
                  // externalStoragePermissionGranted &&
                  bluetoothPermissionGranted)
                  ? navigateToFileShareScreen : null,
                  child: Text("Continue"),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              "Permission Issues",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              title: Text("Location Permission"),
              trailing: ElevatedButton(
                child: Text("Grant Permission"),
                onPressed: locationPermissionGranted
                    ? null
                    : requestLocationPermission,
              ),
              onTap: locationPermissionGranted ? null : requestLocationPermission,
            ),
            ListTile(
              title: Text("External Storage Permission"),
              trailing: ElevatedButton(
                child: Text("Grant Permission"),
                onPressed: externalStoragePermissionGranted
                    ? null
                    : requestStoragePermission,
              ),
              onTap:
              externalStoragePermissionGranted ? null : requestStoragePermission,
            ),
            ListTile(
              title: Text("Bluetooth Permission (Android 12+)"),
              trailing: ElevatedButton(
                child: Text("Grant Permission"),
                onPressed: bluetoothPermissionGranted
                    ? null
                    : requestBluetoothPermission,
              ),
              onTap: bluetoothPermissionGranted ? null : requestBluetoothPermission,
            ),
          ],
        ),
      ),
    );
  }
}

