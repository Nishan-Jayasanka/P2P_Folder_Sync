import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ConnectionDiscoveringScreen extends StatefulWidget {
  final _ConnectionDiscoveringScreenState state =
      _ConnectionDiscoveringScreenState();
  String directory_name;
  List<FileSystemEntity> files;

  @override
  _ConnectionDiscoveringScreenState createState() => state;

  ConnectionDiscoveringScreen({
    required this.directory_name,
    required this.files,
  });

  void sendPayload(String fileName) {
    state.sendPayload(fileName);
  }

  void sendFile(String filePath) {
    state.sendFile(filePath);
  }
}

class _ConnectionDiscoveringScreenState
    extends State<ConnectionDiscoveringScreen> {
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  static Map<String, ConnectionInfo> endpointMap = Map();
  Set<String> discoveredEndpoints = Set();
  bool isBackup = true;

  String? tempFileUri; //reference to the file currently being transferred
  Map<int, String> map = {}; //store filename mapped to corresponding payloadId

  @override
  void initState() {
    super.initState();
    startDiscovery();
  }

  // @override
  // void dispose() {
  //   stopDiscovery();
  //   super.dispose();
  // }

  Future<void> startDiscovery() async {
    try {
      bool startDiscovery = await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          if (!discoveredEndpoints.contains(id)) {
            discoveredEndpoints.add(id);
            // show dialog automatically to request connection
            showDialog(
              context: context,
              builder: (builder) {
                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("Id: $id"),
                      SizedBox(
                        height: 10,
                      ),
                      Text("Name: $name"),
                      SizedBox(
                        height: 10,
                      ),
                      // Text("ServiceId: $serviceId"),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 15, 70, 116),
                            foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                          Nearby().requestConnection(
                            userName,
                            id,
                            onConnectionInitiated: (id, info) {
                              onConnectionInit(id, info);
                            },
                            onConnectionResult: (id, status) {
                              // showSnackbar(status);
                            },
                            onDisconnected: (id) {
                              setState(() {
                                endpointMap.remove(id);
                              });
                              showSnackbar("Device Disconnected");
                              // "Disconnected from: ${endpointMap[id]!.endpointName}, id $id");
                            },
                          );
                        },
                        child: Text("Request Connection"),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
        onEndpointLost: (id) {
          showSnackbar("Device Disconnected");
          // "Lost discovered Endpoint: ${endpointMap[id]!.endpointName}, id $id");
        },
      );
      // showSnackbar("DISCOVERING: " + startDiscovery.toString());
      showSnackbar("DISCOVERING Devices");
    } catch (e) {
      // showSnackbar(e);
      print(e);
    }
  }

  Future<void> stopDiscovery() async {
    await Nearby().stopDiscovery();
  }

  Future<bool> moveFile(String uri, String fileName) async {
    String parentDir = '/storage/emulated/0/SyncBuddy';
    final b = await Nearby().copyFileAndDeleteOriginal(
        uri, '$parentDir/${widget.directory_name}/$fileName');

    // showSnackbar("Moved file:" + b.toString());

    Directory dir =
        Directory('/storage/emulated/0/SyncBuddy/${widget.directory_name}');
    final files = (await dir.list(recursive: true).toList())
        .map((f) => f.path)
        .toList()
        .join('\n');
    // showSnackbar(files);
    // navigateToFileListScreen();
    return b;
  }

  Future<void> sendAllFiles() async {
    print("--- --- --- Start sending all files");
    for (var file in widget.files) {
      print("--- --- --- Start sending ${file.path}");
      // Sending files using sendFilePayload
      for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
        int payloadId = await Nearby().sendFilePayload(m.key, file.path);
        Nearby().sendBytesPayload(
            m.key,
            Uint8List.fromList(
                "$payloadId:${file.path.split('/').last}".codeUnits));
      }
    }
    showSnackbar("Backup Success.");
    print("--- --- --- Files sending Completed");
  }

  void sendFile(String filePath) async {
    print("--- --- --- --- Send File: $filePath");
    // Sending file using sendFilePayload
    for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
      int payloadId = await Nearby().sendFilePayload(m.key, filePath);
      Nearby().sendBytesPayload(
          m.key,
          Uint8List.fromList(
              "$payloadId:${filePath.split('/').last}".codeUnits));
    }
  }

  void sendPayload(String payload) async {
    for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
      Nearby().sendBytesPayload(m.key, Uint8List.fromList(payload.codeUnits));
    }
  }

  void sync() async {
    for (var file in widget.files) {
      print("--- --- ---${file.path.split('/').last}");
      String payload = file.path.split('/').last;
      sendPayload(payload);
    }
  }

  void showSnackbar(dynamic startDiscovery) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(startDiscovery.toString()),
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
              Text("Id: $id"),
              SizedBox(
                height: 10,
              ),
              // Text("Token: ${info.authenticationToken}"),
              Text("Name: ${info.endpointName}"),
              SizedBox(
                height: 10,
              ),
              // Text("Incoming: ${info.isIncomingConnection}"),
              //Color.fromARGB(255, 168, 5, 35),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 15, 70, 116),
                  foregroundColor: Colors.white,
                ),
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
                        // showSnackbar(endid + ": " + str);
                        if (str.contains('Removed-')) {
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
                              showSnackbar("File doesn't exist");
                            }
                          } else {
                            //add to map if not already
                            map[payloadId] = fileName;
                          }
                        }
                      } else if (payload.type == PayloadType.FILE) {
                        showSnackbar("File transfer started");
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
                        showSnackbar("FAILED to transfer file");
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.SUCCESS) {
                        // showSnackbar(
                        //     // "$endid success, total bytes = ${payloadTransferUpdate.totalBytes}");
                        //   "File transfer success.");

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
                  sendPayload("Directory Name -${widget.directory_name}");
                },
                child: Text("Accept Connection"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 168, 5, 35),
                  foregroundColor: Colors.white,
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connection Discovery"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: endpointMap.length,
              itemBuilder: (context, index) {
                final String id = endpointMap.keys.elementAt(index);
                final ConnectionInfo info = endpointMap[id]!;

                return ListTile(
                  // title: Text(info.endpointName),
                  // subtitle: Text("ID: $id"),
                  leading: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 15,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isBackup = true;
                          });
                          await sendAllFiles();
                          isBackup
                              ? sendPayload("Start Backup")
                              : sendPayload("Start Sync");
                        },
                        child: Text("Start Backup"),
                      ),
                      SizedBox(
                        height: 15,
                      ), // Add some spacing between buttons
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isBackup = false;
                          });
                          // sync();
                          await sendAllFiles();
                          isBackup
                              ? sendPayload("Start Backup")
                              : sendPayload("Start Sync");
                        },
                        child: Text("Sync"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Text(
              "Number of connected devices: ${endpointMap.length}",
              style: TextStyle(
                fontSize: 18,
                color: const Color.fromARGB(255, 14, 53, 85),
              ),
            ),
          ),
          SizedBox(
            height: 15,
          )
        ],
      ),
    );
  }
}
