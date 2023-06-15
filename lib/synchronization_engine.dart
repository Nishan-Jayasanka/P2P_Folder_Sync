import 'dart:io';
import 'package:flutter_app/connection_discovering_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'connection_advertising_screen.dart';
import 'package:path/path.dart' as path;

class SynchronizationEngine {
  Directory? _directory;

  Future<void> startMonitoring(String directoryPath) async {
    print("--- --- --- MONITORING STARTED - SYNC ENGINE");

    String appDir = directoryPath;
    _directory = Directory(appDir);

    _directory!.watch(events: FileSystemEvent.all).listen((event) {
      if (event.type == FileSystemEvent.create) {
        final fileName = path.basename(event.path);
        print('---- ---- $fileName is inserted.');
        sendFile('$directoryPath/$fileName');
      }

      if (event.type == FileSystemEvent.delete) {
        final fileName = path.basename(event.path);
        print('---- ---- $fileName is removed.');
        sendPayload('Removed-$directoryPath/$fileName');
      }
    });
  }

  void sendFile(String filePath) {
    if (ConnectionAdvertisingScreen().getEndPointMap().isNotEmpty) {
      ConnectionAdvertisingScreen().sendFile(filePath);
    } else {
      ConnectionDiscoveringScreen(
        directory_name: 'null',
        files: [],
      ).sendFile(filePath);
    }
  }

  void sendPayload(String payload) {
    if (ConnectionAdvertisingScreen().getEndPointMap().isNotEmpty) {
      ConnectionAdvertisingScreen().sendPayload(payload);
    } else {
      ConnectionDiscoveringScreen(
        directory_name: 'null',
        files: [],
      ).sendPayload(payload);
    }
  }

  Future<void> stopMonitoring() async {
    _directory?.parent?.delete();
  }
}
