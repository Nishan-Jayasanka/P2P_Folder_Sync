import 'dart:io';
import 'package:flutter/material.dart';

class SelectedFoldersScreen extends StatefulWidget {
  @override
  _SelectedFoldersScreenState createState() => _SelectedFoldersScreenState();
}

class _SelectedFoldersScreenState extends State<SelectedFoldersScreen> {
  static List<Folder> folders = [];

  @override
  void initState() {
    super.initState();
    fetchDirectories();
  }

  Future<void> fetchDirectories() async {
    try {
      String parentDirectoryPath = '/storage/emulated/0/SyncBuddy';
      Directory folder = Directory(parentDirectoryPath);
      List<FileSystemEntity> entities = await folder.list().toList();

      // Filter and store only the directories
      List<Folder> folderList = entities
          .whereType<Directory>()
          .map((directory) => Folder(directory.path.split('/').last, directory))
          .toList();

      setState(() {
        folders = folderList;
      });

    } catch (e) {
      // Handle any error that occurs during file selection
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selected Folders'),
      ),
      body: ListView.builder(
        itemCount: folders.length,
        itemBuilder: (context, index) {
          Folder folder = folders[index];

          return ListTile(
            leading: Icon(Icons.folder),
            title: Text(folder.folderName),
            onTap: () {
              navigateToFolderContentScreen(context, folder.directory);
            },
          );
        },
      ),
    );
  }

  void navigateToFolderContentScreen(BuildContext context, Directory folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderContentScreen(folder: folder),
      ),
    );
  }
}

class Folder {
  final String folderName;
  final Directory directory;

  Folder(this.folderName, this.directory);
}

class FolderContentScreen extends StatelessWidget {
  final Directory folder;

  FolderContentScreen({required this.folder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folder.path.split('/').last),
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: fetchFolderContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<FileSystemEntity> entities = snapshot.data ?? [];

          return ListView.builder(
            itemCount: entities.length,
            itemBuilder: (context, index) {
              FileSystemEntity entity = entities[index];
              String entityName = entity.path.split('/').last;

              // Determine the icon based on the entity type
              IconData entityIcon;
              if (entity is File) {
                entityIcon = Icons.insert_drive_file;
              } else if (entity is Directory) {
                entityIcon = Icons.folder;
              } else {
                entityIcon = Icons.attachment;
              }

              return ListTile(
                leading: Icon(entityIcon),
                title: Text(entityName),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<FileSystemEntity>> fetchFolderContent() async {
    try {
      List<FileSystemEntity> entities = await folder.list().toList();
      return entities;
    } catch (e) {
      // Handle any error that occurs during folder content retrieval
      print('Error: $e');
      return [];
    }
  }
}
