import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/apis/user_profile_api.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/helper/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class ProfileController extends GetxController {
  final RxString userName = ''.obs;
  final RxString appVersion = ''.obs;
  final RxString id = ''.obs;
  final RxString activeSince = ''.obs;
  final RxString lastActive = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getUserData();
  }

  Future<void> getUserData() async {
    try {
      final profileId = GetStorage().read(AppConstants.profileId);
      if (kDebugMode) {
        developer.log('ProfileId from storage: $profileId', name: 'ProfileController');
      }

      if (profileId != null) {
        final fetched = await UserProfileApi.getProfile(profileId);
        if (kDebugMode) {
          developer.log(
            'Fetched profile - Created: ${fetched?.createdAt}, Updated: ${fetched?.updatedAt}',
            name: 'ProfileController',
          );
        }

        if (fetched != null) {
          userName.value = fetched.name ?? '';
          appVersion.value = fetched.appVersion ?? '';
          id.value = fetched.profileId;
          activeSince.value = fetched.createdAt ?? '';
          lastActive.value = fetched.updatedAt ?? '';
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error fetching user profile: $e',
          error: e,
          stackTrace: stack,
          name: 'ProfileController',
        );
      }
    }
  }

  Future<void> updateName() async {
    try {
      final profileId = GetStorage().read(AppConstants.profileId);

      if (profileId != null) {
        final fetched = await UserProfileApi.getProfile(profileId);
        if (kDebugMode) {
          developer.log('Updating profile name', name: 'ProfileController');
        }

        if (fetched != null) {
          final updated = fetched.copyWith(name: userName.value);
          await UserProfileApi.updateProfile(updated);
          getUserData();
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error updating user profile: $e',
          error: e,
          stackTrace: stack,
          name: 'ProfileController',
        );
      }
    }
  }

  Future<void> backupDatabase() async {
    try {
      // Get the database path
      final databasesPath = await getDatabasesPath();
      final dbPath = path.join(databasesPath, AppConstants.dbName);
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        Get.snackbar(
          'Error',
          'Database file not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFFF6B6B),
          colorText: Colors.white,
        );
        return;
      }

      // Show options dialog
      final choice = await Get.dialog<String>(
        AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          title: Text(
            'Backup Database',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'How would you like to backup your database?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: 'download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4ECDC4),
              ),
              child: Text('Download Locally'),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Get.back(result: 'share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7C4DFF),
              ),
              child: Text('Share'),
            ),
          ],
        ),
      );

      if (choice == null) return;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName = 'mymanager_backup_$timestamp.db';

      if (choice == 'download') {
        // Save to Downloads folder
        final downloadsPath = await getExternalStorageDirectory();
        if (downloadsPath != null) {
          // Try to get the actual Downloads directory
          final downloadsDir = Directory('/storage/emulated/0/Download');
          final backupPath = path.join(
            downloadsDir.existsSync() ? downloadsDir.path : downloadsPath.path,
            backupFileName,
          );
          
          await dbFile.copy(backupPath);
          
          developer.log('Database backed up to: $backupPath', name: 'ProfileController');

          Get.snackbar(
            'Success',
            'Database backup saved to Downloads folder',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Color(0xFF4ECDC4),
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
        }
      } else {
        // Share option
        final directory = await getApplicationDocumentsDirectory();
        final backupPath = path.join(directory.path, backupFileName);
        
        // Copy database file
        await dbFile.copy(backupPath);

        developer.log('Database backed up to: $backupPath', name: 'ProfileController');

        // Share the backup file
        await Share.shareXFiles(
          [XFile(backupPath)],
          subject: 'MyManager Database Backup',
          text: 'MyManager database backup created on ${DateTime.now()}',
        );

        Get.snackbar(
          'Success',
          'Database backup created and shared successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFF4ECDC4),
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      }
    } catch (e, stack) {
      developer.log(
        'Error backing up database: $e',
        error: e,
        stackTrace: stack,
        name: 'ProfileController',
      );
      Get.snackbar(
        'Error',
        'Failed to backup database: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFFF6B6B),
        colorText: Colors.white,
      );
    }
  }

  Future<void> importDatabase() async {
    try {
      // Pick file - use FileType.any to avoid extension issues on Android
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final pickedFile = File(result.files.single.path!);

      // Validate it's a database file by checking extension
      if (!pickedFile.path.endsWith('.db')) {
        Get.snackbar(
          'Error',
          'Please select a valid database file (.db)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Color(0xFFFF6B6B),
          colorText: Colors.white,
        );
        return;
      }

      // Show confirmation dialog
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: Color(0xFF1A1A2E),
          title: Text(
            'Import Database',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'This will merge the imported data with your existing data. Do you want to continue?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7C4DFF),
              ),
              child: Text('Import'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Open the imported database
      final importedDb = await openDatabase(pickedFile.path, readOnly: true);

      // Get the main app database
      final appDb = await DatabaseHelper.database;

      List<Map<String, dynamic>> importedTasks = [];
      List<Map<String, dynamic>> importedProjects = [];

      // Try to get data from imported database
      try {
        importedTasks = await importedDb.query('tasks');
        developer.log('Found ${importedTasks.length} tasks to import', name: 'ProfileController');
      } catch (e) {
        developer.log('No tasks table in imported database', name: 'ProfileController');
      }

      try {
        importedProjects = await importedDb.query('user_projects_table');
        developer.log('Found ${importedProjects.length} projects to import', name: 'ProfileController');
      } catch (e) {
        developer.log('No user_projects_table in imported database', name: 'ProfileController');
      }

      int tasksImported = 0;
      int projectsImported = 0;

      // Import projects first
      for (final projectData in importedProjects) {
        try {
          // Check if project already exists in main database
          final existing = await UserProjectsApi.getProjectById(projectData['project_id'] as String);
          if (existing == null) {
            // Insert into main app database
            await appDb.insert(
              'user_projects_table',
              projectData,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            projectsImported++;
          }
        } catch (e) {
          developer.log('Error importing project: $e', name: 'ProfileController');
        }
      }

      // Import tasks
      for (final taskData in importedTasks) {
        try {
          // Check if task already exists
          final tasks = await TaskApi.getTasks();
          final exists = tasks.any((t) => t.taskId == taskData['task_id']);
          
          if (!exists) {
            // Insert into main app database
            await appDb.insert(
              'tasks',
              taskData,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            tasksImported++;
          }
        } catch (e) {
          developer.log('Error importing task: $e', name: 'ProfileController');
        }
      }

      await importedDb.close();

      Get.snackbar(
        'Import Complete',
        'Imported $projectsImported projects and $tasksImported tasks',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );

      developer.log(
        'Import complete: $projectsImported projects, $tasksImported tasks',
        name: 'ProfileController',
      );
    } catch (e, stack) {
      developer.log(
        'Error importing database: $e',
        error: e,
        stackTrace: stack,
        name: 'ProfileController',
      );
      Get.snackbar(
        'Error',
        'Failed to import database: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFFF6B6B),
        colorText: Colors.white,
      );
    }
  }
}
