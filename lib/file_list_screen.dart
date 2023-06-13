import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';

class FileListScreen extends StatefulWidget {
  @override
  _FileListScreenState createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  List<File> files = [];
  Timer? fileCheckTimer;

  @override
  void initState() {
    super.initState();
    startFileCheckTimer();
  }

  @override
  void dispose() {
    fileCheckTimer?.cancel();
    super.dispose();
  }

  void startFileCheckTimer() {
    fileCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchFiles();
    });
  }

  Future<void> fetchFiles() async {
    try {
      // final appDir = await getApplicationDocumentsDirectory();
      String appDir = (await getExternalStorageDirectory())!.absolute.path;
      final filesDir = Directory('$appDir');
      List<FileSystemEntity> entities = await filesDir.list().toList();

      List<File> updatedFiles = entities.whereType<File>().toList();
      print(updatedFiles);

      setState(() {
        files = updatedFiles;
      });
    } catch (e) {
      // Handle any error that occurs during file listing
      print('Error fetching files: $e');
    }
  }

  IconData getFileIcon(String extension) {
    final mimeType = lookupMimeType('file.$extension');
    if (mimeType != null) {
      final fileType = mimeType.split('/')[0];
      switch (fileType) {
        case 'image':
          return Icons.image;
        case 'audio':
          return Icons.audiotrack;
        case 'video':
          return Icons.videocam;
        case 'application':
          return Icons.insert_drive_file;
      }
    }
    return Icons.insert_drive_file; // Default file icon
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File List'),
      ),
      body: Column(
        children: [
          SyncStatusWidget(
            lastSyncTime: 'Last synced: 10:30 AM',
            isSyncing: false,
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                File file = files[index];
                String fileName = file.path.split('/').last;
                String fileExtension = fileName.split('.').last;
                return ListTile(
                  leading: Icon(getFileIcon(fileExtension)),
                  title: Text(fileName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class SyncStatusWidget extends StatelessWidget {
  final String lastSyncTime;
  final bool isSyncing;

  SyncStatusWidget({
    required this.lastSyncTime,
    required this.isSyncing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isSyncing ? Icons.refresh : Icons.check_circle,
                color: Colors.white,
              ),
              SizedBox(width: 8.0),
              Text(
                lastSyncTime,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isSyncing)
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
        ],
      ),
    );
  }
}
