import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ConnectionDiscoveringScreen extends StatefulWidget {

  String directory_name;
  List<FileSystemEntity> files;

  ConnectionDiscoveringScreen({
    required this.directory_name,
    required this.files,
  });

  @override
  _ConnectionDiscoveringScreenState createState() => _ConnectionDiscoveringScreenState();
}

class _ConnectionDiscoveringScreenState extends State<ConnectionDiscoveringScreen> {
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  Map<String, ConnectionInfo> endpointMap = Map();
  Set<String> discoveredEndpoints = Set();

  String? tempFileUri; //reference to the file currently being transferred
  Map<int, String> map = Map(); //store filename mapped to corresponding payloadId

  @override
  void initState() {
    super.initState();
    startDiscovery();
  }

  @override
  void dispose() {
    stopDiscovery();
    super.dispose();
  }

  Future<void> startDiscovery() async {
    try {
      bool a = await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          if (!discoveredEndpoints.contains(id)){
            discoveredEndpoints.add(id);
            // show dialog automatically to request connection
            showDialog(
              context: context,
              builder: (builder) {
                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text("id: " + id),
                      Text("Name: " + name),
                      Text("ServiceId: " + serviceId),
                      ElevatedButton(
                        child: Text("Request Connection"),
                        onPressed: () {
                          Navigator.pop(context);
                          Nearby().requestConnection(
                            userName,
                            id,
                            onConnectionInitiated: (id, info) {
                              onConnectionInit(id, info);
                            },
                            onConnectionResult: (id, status) {
                              showSnackbar(status);
                            },
                            onDisconnected: (id) {
                              setState(() {
                                endpointMap.remove(id);
                              });
                              showSnackbar(
                                  "Disconnected from: ${endpointMap[id]!.endpointName}, id $id");
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
        onEndpointLost: (id) {
          showSnackbar(
              "Lost discovered Endpoint: ${endpointMap[id]!.endpointName}, id $id");
        },
      );
      showSnackbar("DISCOVERING: " + a.toString());
    } catch (e) {
      showSnackbar(e);
    }
  }


  Future<void> stopDiscovery() async {
    await Nearby().stopDiscovery();
  }

  Future<bool> moveFile(String uri, String fileName) async {
    String parentDir = (await getExternalStorageDirectory())!.absolute.path;
    final b =
    await Nearby().copyFileAndDeleteOriginal(uri, '$parentDir/$fileName');

    showSnackbar("Moved file:" + b.toString());
    return b;
  }

  void sendAllFiles() async {
    print("------------------------------------------------------Send File");
    for (var file in widget.files) {
      print("---------------------------------Entity");
      print(file.path);
      // Sending files using sendFilePayload
      for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
        int payloadId = await Nearby().sendFilePayload(m.key, file.path);
        showSnackbar("Sending files to ${m.key}");
        Nearby().sendBytesPayload(m.key, Uint8List.fromList("$payloadId:${file.path.split('/').last}".codeUnits));
      }
    }
  }

  void sendFile(String fileName) async {
    print("--- --- --- --- Send File: $fileName");
    for (var file in widget.files) {
      if (file.path.split('/').last == fileName){
        print(file.path);
        // Sending file using sendFilePayload
        for (MapEntry<String, ConnectionInfo> m in endpointMap.entries) {
          int payloadId = await Nearby().sendFilePayload(m.key, file.path);
          showSnackbar("Sending file to ${m.key}");
          Nearby().sendBytesPayload(m.key, Uint8List.fromList("$payloadId:${file.path.split('/').last}".codeUnits));
        }
      }
    }
  }

  void sendPayload(String payload) async {
    for (MapEntry<String, ConnectionInfo> m in endpointMap.entries){
      showSnackbar("Sending $payload to ${m.value.endpointName}, id: ${m.key}");
      Nearby().sendBytesPayload(m.key, Uint8List.fromList(payload.codeUnits));
    }
  }

  void sync() async{
    for (var file in widget.files){
      print("--- --- ---" + file.path.split('/').last);
      String payload = file.path.split('/').last;
      sendPayload(payload);
    }
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
                        sendFile(str);
                        showSnackbar(endid + ": " + str);

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
                        showSnackbar(endid + ": File transfer started");
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
                        showSnackbar(endid + ": FAILED to transfer file");
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
                  sendPayload("Directory Name -${widget.directory_name}");
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
        title: Text("Connection Discover"),
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
                  title: Text(info.endpointName),
                  subtitle: Text("ID: $id"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => sendAllFiles(),
                        child: Text("Start Backup"),
                      ),
                      SizedBox(width: 8), // Add some spacing between buttons
                      ElevatedButton(
                        onPressed: () => sync(),
                        child: Text("Sync"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Text("Number of connected devices: ${endpointMap.length}"),
        ],
      ),
    );
  }

}
