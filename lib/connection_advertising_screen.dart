import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_app/synchronization_engine.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'animated_connection_icon.dart';
import 'file_list_screen.dart';

class ConnectionAdvertisingScreen extends StatefulWidget {
  final _ConnectionAdvertisingScreenState state = _ConnectionAdvertisingScreenState();

  @override
  _ConnectionAdvertisingScreenState createState() => state;

  void sendPayload(String fileName) {
    state.sendPayload(fileName);
  }

  void sendFile(String filePath) {
    state.sendFile(filePath);
  }

  Map<String, ConnectionInfo> getEndPointMap(){
    return state.getEndPointMap();
  }
}

class _ConnectionAdvertisingScreenState extends State<ConnectionAdvertisingScreen> {
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  static Map<String, ConnectionInfo> endpointMap = Map();
  bool isBackup = true;

  String? tempFileUri; //reference to the file currently being transferred
  static String? tempDirectoryName;
  static Map<int, String> map = Map(); //store filename mapped to corresponding payloadId

  @override
  void initState() {
    super.initState();
    startAdvertising();
  }

  // @override
  // void dispose() {
  //   stopAdvertising();
  //   super.dispose();
  // }

  Map<String, ConnectionInfo> getEndPointMap() {
    return endpointMap;
  }

  Future<void> startAdvertising() async {
    try {
      bool a = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {
          // showSnackbar("Starting network");
        },
        onDisconnected: (id) {
          showSnackbar(
              // "Disconnected: ${endpointMap[id]!.endpointName}, id $id");
              "Device Disconnected");
          setState(() {
            endpointMap.remove(id);
          });
        },
      );
      // showSnackbar("ADVERTISING: " + a.toString());
    } catch (exception) {
      // showSnackbar(exception);
      print(exception);
    }
  }

  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    showDialog(
      context: context,
      builder: (builder) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                      if (payload.type == PayloadType.BYTES) {
                        String str = String.fromCharCodes(payload.bytes!);

                        if (str.contains('Directory Name -')){
                          String parentDirectoryPath = '/storage/emulated/0/SyncBuddy';
                          String newDirectoryName = str.split('-').last;
                          tempDirectoryName = newDirectoryName;
                          Directory newDirectory = Directory('$parentDirectoryPath/$newDirectoryName');
                          if (!(await newDirectory.exists())) {
                            newDirectory.create(recursive: true);
                            print('--- --- New directory created: ${newDirectory.path}');
                          } else {
                            print('--- --- Directory already exists: ${newDirectory.path}');
                          }

                        }

                        if (str.contains("Start sync")){
                          setState(() {
                            isBackup = false;
                          });
                          SynchronizationEngine().startMonitoring('/storage/emulated/0/SyncBuddy/$tempDirectoryName');
                        }else{
                          setState(() {
                            isBackup = true;
                          });
                          SynchronizationEngine().startMonitoring('/storage/emulated/0/SyncBuddy/$tempDirectoryName');
                        }

                        if (str.contains('Removed-') && !isBackup){
                          String filePath = str.split('-').last;
                          final file = File(filePath);
                          await file.delete();
                          print('--- --- File deleted successfully');
                        }

                        if (str.contains(':')) {
                          // used for file payload as file payload is mapped as
                          // payloadId:filename
                          int payloadId = int.parse(str.split(':')[0]);
                          String fileName = (str.split(':')[1]);

                          if (map.containsKey(payloadId)) {
                            if (tempFileUri != null) {
                              moveFile(tempFileUri!, fileName);
                            } else {
                              showSnackbar("--- --- --- File doesn't exist");
                            }
                          } else {
                            //add to map if not already
                            map[payloadId] = fileName;
                          }
                        }
                        // showSnackbar(endid + ": " + str);
                      } else if (payload.type == PayloadType.FILE) {
                        showSnackbar("File transfer started");
                        tempFileUri = payload.uri;
                      }
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      if (payloadTransferUpdate.status == PayloadStatus.IN_PROGRESS) {
                        print("--- --- --- Payload transfer in progress.");
                        print(payloadTransferUpdate.bytesTransferred);
                      } else if (payloadTransferUpdate.status == PayloadStatus.FAILURE) {
                        print("--- --- --- Payload transfer failed.");
                        showSnackbar("FAILED to transfer file");
                      } else if (payloadTransferUpdate.status == PayloadStatus.SUCCESS) {
                        print("--- --- --- Payload transfer successful.");
                        // showSnackbar("File transfer successful");

                        if (map.containsKey(payloadTransferUpdate.id)) {
                          //rename the file now
                          String name = map[payloadTransferUpdate.id]!;
                          moveFile(tempFileUri!, name);
                        } else {
                          //bytes not received till yet
                          print("--- --- --- Bytes not received till yet");
                          map[payloadTransferUpdate.id] = "";
                        }
                      }
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
                    // showSnackbar(e);
                    print(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // void navigateToFileListScreen() async {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => FileListScreen(),
  //     ),
  //   );
  // }

  void sendPayload(String payload) async {
    for (MapEntry<String, ConnectionInfo> m in endpointMap.entries){
      Nearby().sendBytesPayload(m.key, Uint8List.fromList(payload.codeUnits));
      print("--- --- ---Payload sent successfully. payload: $payload");
    }
  }

  void sendFile(String filePath) async {
    print("--- --- --- --- Send File: $filePath");
    for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
      int payloadId = await Nearby().sendFilePayload(m.key, filePath);
      Nearby().sendBytesPayload(m.key, Uint8List.fromList("$payloadId:${filePath.split('/').last}".codeUnits));
    }
  }


  Future<bool> moveFile(String uri, String fileName) async {
    String parentDir = '/storage/emulated/0/SyncBuddy';
    final b = await Nearby().copyFileAndDeleteOriginal(uri, '$parentDir/$tempDirectoryName/$fileName');

    // showSnackbar("Moved file:" + b.toString());

    Directory dir = Directory('/storage/emulated/0/SyncBuddy/$tempDirectoryName');
    final files = (await dir.list(recursive: true).toList())
        .map((f) => f.path)
        .toList()
        .join('\n');
    // showSnackbar(files);
    // navigateToFileListScreen();
    return b;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Device Connecting"),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.devices,
                size: 30,
              ),
              SizedBox(width: 10),
              Text(
                "User Name: $userName",
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: Center(
              child: AnimatedConnectionIcon(), // Replace with the animated broadcasting widget
            ),
          ),
          SizedBox(height: 20),
          Text("Number of connected devices: ${endpointMap.length}"),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

