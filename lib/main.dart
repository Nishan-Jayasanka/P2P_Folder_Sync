import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <WordPair>[];

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Folder Sync App'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to sync settings screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SyncSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: syncedFolders.length,
        itemBuilder: (context, index) {
          final folder = syncedFolders[index];
          return ListTile(
            leading: Icon(Icons.folder),
            title: Text(folder.name),
            subtitle: Text(folder.lastSync),
            trailing: Icon(
              folder.isSynced ? Icons.check_circle : Icons.error,
              color: folder.isSynced ? Colors.green : Colors.red,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to folder selection screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FolderSelectionScreen(folderItems: [])),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class SyncSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sync Settings'),
      ),
      body: Center(
        child: Text('Sync Settings Screen'),
      ),
    );
  }
}

class SyncedFolder {
  final String name;
  final String lastSync;
  final bool isSynced;

  SyncedFolder(this.name, this.lastSync, this.isSynced);
}

List<SyncedFolder> syncedFolders = [
  SyncedFolder('Documents', 'Last synced: 2 hours ago', true),
  SyncedFolder('Photos', 'Last synced: 1 day ago', true),
  SyncedFolder('Music', 'Not synced', false),
  SyncedFolder('Videos', 'Last synced: 3 days ago', true),
];

class FolderSelectionScreen extends StatefulWidget {
  final List<FolderItem> folderItems;

  FolderSelectionScreen({required this.folderItems});

  @override
  _FolderSelectionScreenState createState() => _FolderSelectionScreenState();
}

class _FolderSelectionScreenState extends State<FolderSelectionScreen> {
  List<FolderItem> _folderItems = [];

  @override
  void initState() {
    super.initState();
    // Load the device's file system here
    _loadFileSystem();
  }

  void _loadFileSystem() {
    // Simulating loading the file system
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _folderItems = _generateFileSystem(); // Replace this with your own logic to load the device's file system
      });
    });
  }

  List<FolderItem> _generateFileSystem() {
    // Replace this with your own logic to generate the device's file system hierarchy
    return [
      FolderItem(
        name: 'Root',
        isFolder: true,
        children: [
          FolderItem(
            name: 'Documents',
            isFolder: true,
            children: [
              FolderItem(name: 'Folder 1', isFolder: true),
              FolderItem(name: 'Folder 2', isFolder: true),
            ],
          ),
          FolderItem(
            name: 'Photos',
            isFolder: true,
            children: [
              FolderItem(name: 'Folder 3', isFolder: true),
              FolderItem(name: 'Folder 4', isFolder: true),
            ],
          ),
          FolderItem(name: 'File 1', isFolder: false),
          FolderItem(name: 'File 2', isFolder: false),
        ],
      ),
    ];
  }

  Widget _buildFolderItem(FolderItem folderItem) {
    return ListTile(
      leading: Icon(folderItem.isFolder ? Icons.folder : Icons.file_copy),
      title: Text(folderItem.name),
      onTap: () {
        if (folderItem.isFolder) {
          // If the item is a folder, navigate to its contents
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FolderSelectionScreen(folderItems: folderItem.children),
            ),
          );
        } else {
          // Add folder sync logic here for selecting files
          // For this example, we're simply printing the selected file
          print('Selected File: ${folderItem.name}');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Folder to Sync'),
      ),
      body: ListView.builder(
        itemCount: _folderItems.length,
        itemBuilder: (context, index) {
          final folderItem = _folderItems[index];
          return _buildFolderItem(folderItem);
        },
      ),
    );
  }
}

class FolderItem {
  final String name;
  final bool isFolder;
  final List<FolderItem> children;

  FolderItem({required this.name, required this.isFolder, this.children = const []});
}







