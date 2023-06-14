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
  final _ConnectionAdvertisingScreenState state =
      _ConnectionAdvertisingScreenState();

  @override
  _ConnectionAdvertisingScreenState createState() => state;

  void sendPayload(String fileName) {
    state.sendPayload(fileName);
  }
}

class _ConnectionAdvertisingScreenState
    extends State<ConnectionAdvertisingScreen> {
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  static Map<String, ConnectionInfo> endpointMap = {};

  String? tempFileUri; //reference to the file currently being transferred
  String? tempDirectoryName;
  Map<int, String> map = {}; //store filename mapped to corresponding payloadId

  @override
  void initState() {
    super.initState();
    startAdvertising();
  }

  @override
  void dispose() {
    stopAdvertising();
    super.dispose();
  }

  Future<void> startAdvertising() async {
    try {
      bool a = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {
          showSnackbar(status);
        },
        onDisconnected: (id) {
          showSnackbar(
              "Disconnected: ${endpointMap[id]!.endpointName}, id $id");
          setState(() {
            endpointMap.remove(id);
          });
        },
      );
      showSnackbar("ADVERTISING: $a");
    } catch (exception) {
      showSnackbar(exception);
    }
  }

  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
      backgroundColor: Colors.orange[700],
      dismissDirection: DismissDirection.horizontal,
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
              Text("Id   : $id"),
              SizedBox(
                height: 10,
              ),
              // Text("Token: ${info.authenticationToken}"),
              Text("Name : ${info.endpointName}"),
              SizedBox(
                height: 10,
              ),
              // Text("Incoming: ${info.isIncomingConnection}"),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 168, 5, 35),
                  foregroundColor: Colors.white,
                ),
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
                        if (str.contains('Directory Name -')) {
                          Directory? externalDirectory =
                              await getExternalStorageDirectory();

                          if (externalDirectory != null) {
                            String newDirectoryName = str.split('-').last;
                            tempDirectoryName = newDirectoryName;
                            Directory newDirectory = Directory(
                                '${externalDirectory.absolute.path}/$newDirectoryName');
                            if (!(await newDirectory.exists())) {
                              newDirectory.create(recursive: true);
                              print(
                                  'New directory created: ${newDirectory.path}');
                            } else {
                              print(
                                  'Directory already exists: ${newDirectory.path}');
                            }
                          } else {
                            print('External storage directory not found');
                          }
                        } else {
                          SynchronizationEngine().matchFileNames(str);
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
                              showSnackbar("File doesn't exist");
                            }
                          } else {
                            //add to map if not already
                            map[payloadId] = fileName;
                          }
                        }
                        showSnackbar("$endid: $str");
                      } else if (payload.type == PayloadType.FILE) {
                        showSnackbar("$endid: File transfer started");
                        tempFileUri = payload.uri;
                      }
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      if (payloadTransferUpdate.status ==
                          PayloadStatus.IN_PROGRESS) {
                        print(payloadTransferUpdate.bytesTransferred);
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.FAILURE) {
                        print("failed");
                        showSnackbar("$endid: FAILED to transfer file");
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.SUCCESS) {
                        showSnackbar(
                            "$endid success, total bytes = ${payloadTransferUpdate.totalBytes}");

                        if (map.containsKey(payloadTransferUpdate.id)) {
                          //rename the file now
                          String name = map[payloadTransferUpdate.id]!;
                          moveFile(tempFileUri!, name);
                        } else {
                          //bytes not received till yet
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

  void navigateToFileListScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileListScreen(),
      ),
    );
  }

  void sendPayload(String payload) async {
    for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
      Nearby().sendBytesPayload(m.key, Uint8List.fromList(payload.codeUnits));
      print("--- --- ---Payload sent successfully. payload: $payload");
    }
  }

  Future<bool> moveFile(String uri, String fileName) async {
    String parentDir = (await getExternalStorageDirectory())!.absolute.path;
    final b = await Nearby().copyFileAndDeleteOriginal(
        uri, '$parentDir/$tempDirectoryName/$fileName');

    showSnackbar("Moved file:$b");

    final dir = (await getExternalStorageDirectory())!;
    final files = (await dir.list(recursive: true).toList())
        .map((f) => f.path)
        .toList()
        .join('\n');
    showSnackbar(files);
    navigateToFileListScreen();
    return b;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Connect Device",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phonelink_ring,
                  color: Color.fromARGB(255, 14, 2, 6),
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  "User Name: $userName",
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 14, 2, 6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Center(
              child:
                  AnimatedConnectionIcon(), // Replace with the animated broadcasting widget
            ),
          ),
          // SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(35),
            child: Text(
              "Number of connected devices: ${endpointMap.length}",
              style:
                  TextStyle(fontSize: 18, color: Color.fromARGB(255, 1, 5, 8)),
            ),
          ),
          // SizedBox(height: 20),
        ],
      ),
    );
  }
}
