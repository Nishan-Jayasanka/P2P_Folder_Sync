import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'connection_advertising_screen.dart';

class SynchronizationEngine {

  Future<void> matchFileNames(String fileName) async {
    String appDir = (await getExternalStorageDirectory())!.absolute.path;
    final filesDir = Directory(appDir);
    List<FileSystemEntity> files = await filesDir.list().toList();
    for (var file in files) {
      if (file is File && file.path.split('/').last == fileName) {
        print("--- --- Matching file found: ${file.path}");
        return;
      }
    }

    print("--- --- No matching file found for: $fileName");
    ConnectionAdvertisingScreen().sendPayload(fileName);
  }
}
