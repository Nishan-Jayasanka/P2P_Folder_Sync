import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/selected_folders_screen.dart';
import 'folder_selection_screen.dart';
import 'connection_advertising_screen.dart';

class HomeScreen extends StatelessWidget {

  void createApplicationStorageDirectory() {
    String parentDirectoryPath = '/storage/emulated/0';
    String newDirectoryName = 'SyncBuddy';

    Directory parentDirectory = Directory(parentDirectoryPath);
    Directory newDirectory = Directory('${parentDirectory.path}/$newDirectoryName');

    if (!newDirectory.existsSync()) {
      newDirectory.createSync();
      print('New directory created: ${newDirectory.path}');
    } else {
      print('Directory already exists: ${newDirectory.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SyncBuddy'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                createApplicationStorageDirectory();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FolderSelectionScreen()),
                );
              },
              child: Container(
                width: 300,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // changes the position of the shadow
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 20),
                    Icon(
                      Icons.devices,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'Source Device',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                createApplicationStorageDirectory();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ConnectionAdvertisingScreen()),
                );
              },
              child: Container(
                width: 300,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // changes the position of the shadow
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 20),
                    Icon(
                      Icons.backup,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'Backup Device',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  // MaterialPageRoute(builder: (context) => SelectedFoldersScreen()),
                  MaterialPageRoute(builder: (context) => SelectedFoldersScreen()),
                );
              },
              child: Container(
                width: 300,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // changes the position of the shadow
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 20),
                    Icon(
                      Icons.folder,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'Folders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
