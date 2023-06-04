import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'connection_discovering_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FolderSelectionScreen extends StatefulWidget {
  @override
  _FolderSelectionScreenState createState() => _FolderSelectionScreenState();
}

class _FolderSelectionScreenState extends State<FolderSelectionScreen> {
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    fetchDirectories();
  }

  void fetchDirectories() async {
    try {
      // Open the file picker to select a folder
      String? folderPath = await FilePicker.platform.getDirectoryPath();

      final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      print(appDocumentsDir.path);

      if (folderPath != null) {
        // Retrieve the list of files inside the selected folder
        print("------------------------------");
        print(folderPath);
        Directory folder = Directory(folderPath);
        List<FileSystemEntity> entities = await folder.list().toList();

        // Filter and store only the files
        List<File> fileList = entities.whereType<File>().toList();

        setState(() {
          files = fileList;
        });
      }
    } catch (e) {
      // Handle any error that occurs during file selection
      print('Error: $e');
    }
  }

  void navigateToConnectionDiscoveringScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConnectionDiscoveringScreen(
          files: files,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selected Files'),
      ),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          FileSystemEntity file = files[index];
          String fileName = file.path.split('/').last;

          // Determine the icon based on the file type
          IconData fileIcon;
          if (file is File) {
            fileIcon = Icons.insert_drive_file;
          } else if (file is Directory) {
            fileIcon = Icons.folder;
          } else {
            fileIcon = Icons.attachment;
          }

          return ListTile(
            leading: Icon(fileIcon),
            title: Text(fileName),
            onTap: () {
              // Handle file selection if needed
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            navigateToConnectionDiscoveringScreen();
          },
          child: Text('Backup'),
        ),
      ),
    );
  }
}
