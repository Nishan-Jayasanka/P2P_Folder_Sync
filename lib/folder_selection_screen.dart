import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/selected_folders_screen.dart';
import 'package:flutter_app/synchronization_engine.dart';
import 'connection_discovering_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FolderSelectionScreen extends StatefulWidget {
  @override
  _FolderSelectionScreenState createState() => _FolderSelectionScreenState();
}

class _FolderSelectionScreenState extends State<FolderSelectionScreen> {
  late Folder selected_folder;
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    pickDirectory();
  }

  void pickDirectory() async {
    try {
      // Open the file picker to select a folder
      String? folderPath = await FilePicker.platform.getDirectoryPath();
      fetchFiles(folderPath!);
    } catch (e) {
      // Handle any error that occurs during file selection
      print('Error: $e');
    }
  }

  Future<void> fetchFiles(String folderPath) async {
    if (folderPath != null) {
      // Retrieve the list of files inside the selected folder
      print('--- --- --- $folderPath');
      Directory folder = Directory(folderPath);
      List<FileSystemEntity> entities = await folder.list().toList();

      // Filter and store only the files
      List<File> fileList = entities.whereType<File>().toList();

      setState(() {
        files = fileList;
        selected_folder = Folder(folder.path.split('/').last, folder);
      });
    }
  }

  Future<void> moveFolder(String sourcePath, String destinationPath) async {
    final sourceDirectory = Directory(sourcePath);
    final destinationDirectory = Directory(destinationPath);

    // Create the destination directory if it doesn't exist
    if (!destinationDirectory.existsSync()) {
      await destinationDirectory.create(recursive: true);
    }

    // Get a list of files and directories inside the source directory
    final filesList = sourceDirectory.listSync();

    // Move each file and directory to the destination directory
    for (var fileOrDir in filesList) {
      final fileName = fileOrDir.path.split('/').last;
      final newPath = '${destinationDirectory.path}/$fileName';
      await fileOrDir.renameSync(newPath);
    }

    // Remove the empty source directory
    await sourceDirectory.delete();
    await fetchFiles(destinationPath);
    SynchronizationEngine().startMonitoring(destinationDirectory.path);
  }

  void navigateToConnectionDiscoveringScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConnectionDiscoveringScreen(
          directory_name: selected_folder.folderName,
          files: files,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Selected Files',
          style: TextStyle(color: Colors.white),
        ),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 168, 5, 35),
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            await moveFolder(selected_folder.directory.path,
                '/storage/emulated/0/SyncBuddy/${selected_folder.folderName}');
            navigateToConnectionDiscoveringScreen();
          },
          child: Text('Continue'),
        ),
      ),
    );
  }
}
