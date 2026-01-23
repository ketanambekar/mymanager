import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/apis/habit_api.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/apis/user_profile_api.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/tables/tasks/models/habit_model.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/database/tables/user_profile/models/user_profile_model.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/utils/global_utils.dart';

/// Test Data Service - ONLY FOR DEBUG MODE
/// Populates database with dummy data for testing
class TestDataService {
  static const String _testDataKey = 'test_data_initialized';
  
  /// Check if test data is already initialized
  static bool get isInitialized {
    if (!kDebugMode) return true; // Always return true in release
    return GetStorage().read(_testDataKey) ?? false;
  }
  
  /// Initialize all test data
  static Future<void> initializeTestData({bool force = false}) async {
    // IMPORTANT: Only run in debug mode
    if (!kDebugMode) {
      developer.log('Test data initialization skipped - Release mode', name: 'TestDataService');
      return;
    }
    
    if (isInitialized && !force) {
      developer.log('Test data already initialized', name: 'TestDataService');
      return;
    }
    
    try {
      developer.log('🚀 Starting test data initialization...', name: 'TestDataService');
      
      await _createTestUserProfile();
      await _createTestProjects();
      await _createTestHabits();
      await _createTestTasks();
      await _createTestHabitLogs();
      
      GetStorage().write(_testDataKey, true);
      developer.log('✅ Test data initialization complete!', name: 'TestDataService');
    } catch (e, stack) {
      developer.log(
        '❌ Error initializing test data: $e',
        error: e,
        stackTrace: stack,
        name: 'TestDataService',
      );
    }
  }
  
  /// Clear all test data and reset flag
  static Future<void> clearTestData() async {
    if (!kDebugMode) return;
    
    try {
      developer.log('🗑️ Clearing test data...', name: 'TestDataService');
      GetStorage().remove(_testDataKey);
      developer.log('✅ Test data cleared', name: 'TestDataService');
    } catch (e) {
      developer.log('Error clearing test data: $e', name: 'TestDataService');
    }
  }
  
  /// Create test user profile with XP and level
  static Future<void> _createTestUserProfile() async {
    final profileId = GetStorage().read(AppConstants.profileId);
    
    if (profileId == null) {
      // Create new profile
      final newProfileId = uuid.v4();
      final profile = UserProfile(
        profileId: newProfileId,
        name: 'Test User',
        appVersion: '1.0.0',
        xpPoints: 450, // Level 5 (450/100 = 4.5, so level 5)
        level: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      await UserProfileApi.createProfile(profile);
      GetStorage().write(AppConstants.profileId, newProfileId);
      developer.log('✅ Created test user profile: Level 5, 450 XP', name: 'TestDataService');
    } else {
      // Update existing profile
      final existing = await UserProfileApi.getProfile(profileId);
      if (existing != null) {
        final updated = existing.copyWith(
          name: 'Test User',
          xpPoints: 450,
          level: 5,
        );
        await UserProfileApi.updateProfile(updated);
        developer.log('✅ Updated existing profile with test data', name: 'TestDataService');
      }
    }
  }
  
  /// Create test projects
  static Future<void> _createTestProjects() async {
    final projects = [
      UserProjects(
        projectId: uuid.v4(),
        projectName: 'Personal Growth',
        projectDescription: 'Self-improvement and learning goals',
        projectStatus: AppConstants.projectStatusActive,
        projectColor: '#7C4DFF',
        projectCreatedAt: DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        projectUpdatedAt: DateTime.now().toIso8601String(),
      ),
      UserProjects(
        projectId: uuid.v4(),
        projectName: 'Work Projects',
        projectDescription: 'Professional tasks and deliverables',
        projectStatus: AppConstants.projectStatusActive,
        projectColor: '#FF6B6B',
        projectCreatedAt: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        projectUpdatedAt: DateTime.now().toIso8601String(),
      ),
      UserProjects(
        projectId: uuid.v4(),
        projectName: 'Health & Fitness',
        projectDescription: 'Physical and mental wellness',
        projectStatus: AppConstants.projectStatusActive,
        projectColor: '#4ECDC4',
        projectCreatedAt: DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        projectUpdatedAt: DateTime.now().toIso8601String(),
      ),
    ];
    
    for (var project in projects) {
      await UserProjectsApi.createProject(project);
    }
    developer.log('✅ Created ${projects.length} test projects', name: 'TestDataService');
  }
  
  /// Create test habits with various states
  static Future<void> _createTestHabits() async {
    final habits = [
      Habit(
        habitId: uuid.v4(),
        habitName: 'Morning Meditation',
        habitDescription: 'Start the day with 10 minutes of mindfulness',
        frequency: 'Daily',
        habitColor: '#7C4DFF',
        currentStreak: 12,
        bestStreak: 18,
        lastCompleted: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        enableAlerts: true,
        alertTime: '07:00',
        habitCreatedAt: DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
        habitUpdatedAt: DateTime.now().toIso8601String(),
      ),
      Habit(
        habitId: uuid.v4(),
        habitName: 'Read for 30 Minutes',
        habitDescription: 'Daily reading habit to expand knowledge',
        frequency: 'Daily',
        habitColor: '#FF6B6B',
        currentStreak: 7,
        bestStreak: 15,
        lastCompleted: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        enableAlerts: true,
        alertTime: '20:00',
        habitCreatedAt: DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        habitUpdatedAt: DateTime.now().toIso8601String(),
      ),
      Habit(
        habitId: uuid.v4(),
        habitName: 'Exercise',
        habitDescription: 'Workout or physical activity',
        frequency: 'Daily',
        habitColor: '#4ECDC4',
        currentStreak: 5,
        bestStreak: 21,
        lastCompleted: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        enableAlerts: true,
        alertTime: '06:30',
        habitCreatedAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        habitUpdatedAt: DateTime.now().toIso8601String(),
      ),
      Habit(
        habitId: uuid.v4(),
        habitName: 'Weekly Review',
        habitDescription: 'Reflect on the week and plan ahead',
        frequency: 'Weekly',
        habitColor: '#FFBE0B',
        currentStreak: 3,
        bestStreak: 8,
        lastCompleted: DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        enableAlerts: true,
        alertTime: '18:00',
        habitCreatedAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        habitUpdatedAt: DateTime.now().toIso8601String(),
      ),
      Habit(
        habitId: uuid.v4(),
        habitName: 'Drink 8 Glasses of Water',
        habitDescription: 'Stay hydrated throughout the day',
        frequency: 'Daily',
        habitColor: '#5B8DEE',
        currentStreak: 0,
        bestStreak: 5,
        lastCompleted: null,
        enableAlerts: false,
        habitCreatedAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        habitUpdatedAt: DateTime.now().toIso8601String(),
      ),
    ];
    
    for (var habit in habits) {
      await HabitApi.createHabit(habit);
    }
    developer.log('✅ Created ${habits.length} test habits', name: 'TestDataService');
  }
  
  /// Create test tasks across different states
  static Future<void> _createTestTasks() async {
    final projects = await UserProjectsApi.getProjects();
    if (projects.isEmpty) return;
    
    final tasks = [
      // Today's tasks
      Task(
        taskId: uuid.v4(),
        taskTitle: 'Complete project proposal',
        taskDescription: 'Finish the Q1 project proposal document',
        taskDueDate: DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
        taskStatus: AppConstants.taskStatusInProgress,
        taskPriority: 'High',
        taskUrgency: AppConstants.urgencyHigh,
        taskImportance: AppConstants.importanceHigh,
        projectId: projects[1].projectId,
        taskFrequency: 'Once',
        energyLevel: AppConstants.energyHigh,
        focusRequired: true,
        timeEstimate: 120,
        enableAlerts: true,
        taskCreatedAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        taskUpdatedAt: DateTime.now().toIso8601String(),
      ),
      Task(
        taskId: uuid.v4(),
        taskTitle: 'Team standup meeting',
        taskDescription: 'Daily sync with the team',
        taskDueDate: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        taskStatus: AppConstants.taskStatusTodo,
        taskPriority: 'Medium',
        taskUrgency: AppConstants.urgencyMedium,
        taskImportance: AppConstants.importanceMedium,
        projectId: projects[1].projectId,
        taskFrequency: 'Daily',
        isRecurring: true,
        energyLevel: AppConstants.energyLow,
        timeEstimate: 15,
        enableAlerts: true,
        taskCreatedAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        taskUpdatedAt: DateTime.now().toIso8601String(),
      ),
      Task(
        taskId: uuid.v4(),
        taskTitle: 'Grocery shopping',
        taskDescription: 'Buy vegetables, fruits, and essentials',
        taskDueDate: DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
        taskStatus: AppConstants.taskStatusTodo,
        taskPriority: 'Low',
        taskUrgency: AppConstants.urgencyLow,
        taskImportance: AppConstants.importanceLow,
        taskFrequency: 'Once',
        energyLevel: AppConstants.energyMedium,
        timeEstimate: 45,
        taskCreatedAt: DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        taskUpdatedAt: DateTime.now().toIso8601String(),
      ),
      // Upcoming tasks
      Task(
        taskId: uuid.v4(),
        taskTitle: 'Learn Flutter animations',
        taskDescription: 'Complete the Flutter animations course',
        taskDueDate: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        taskStatus: AppConstants.taskStatusTodo,
        taskPriority: 'Medium',
        taskUrgency: AppConstants.urgencyLow,
        taskImportance: AppConstants.importanceHigh,
        projectId: projects[0].projectId,
        taskFrequency: 'Once',
        energyLevel: AppConstants.energyHigh,
        focusRequired: true,
        timeEstimate: 180,
        enableAlerts: true,
        taskCreatedAt: DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        taskUpdatedAt: DateTime.now().toIso8601String(),
      ),
      Task(
        taskId: uuid.v4(),
        taskTitle: 'Dentist appointment',
        taskDescription: 'Regular checkup at 2 PM',
        taskDueDate: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        taskStatus: AppConstants.taskStatusTodo,
        taskPriority: 'High',
        taskUrgency: AppConstants.urgencyHigh,
        taskImportance: AppConstants.importanceMedium,
        taskFrequency: 'Once',
        energyLevel: AppConstants.energyLow,
        timeEstimate: 60,
        enableAlerts: true,
        alertTime: DateTime.now().add(const Duration(days: 3, hours: -1)).toIso8601String(),
        taskCreatedAt: DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        taskUpdatedAt: DateTime.now().toIso8601String(),
      ),
      // Completed tasks
      Task(
        taskId: uuid.v4(),
        taskTitle: 'Morning workout',
        taskDescription: 'Completed 30-minute cardio session',
        taskDueDate: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        taskStatus: AppConstants.taskStatusCompleted,
        taskPriority: 'Medium',
        taskUrgency: AppConstants.urgencyMedium,
        taskImportance: AppConstants.importanceHigh,
        projectId: projects[2].projectId,
        taskFrequency: 'Daily',
        isRecurring: true,
        energyLevel: AppConstants.energyHigh,
        timeEstimate: 30,
        timeSpent: 35,
        taskCompletedDate: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        taskCreatedAt: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        taskUpdatedAt: DateTime.now().toIso8601String(),
      ),
    ];
    
    for (var task in tasks) {
      await TaskApi.createTask(task);
    }
    developer.log('✅ Created ${tasks.length} test tasks', name: 'TestDataService');
  }
  
  /// Create test habit completion logs
  static Future<void> _createTestHabitLogs() async {
    final habits = await HabitApi.getHabits();
    if (habits.isEmpty) return;
    
    int logsCreated = 0;
    
    // Create completion logs for the past 30 days for some habits
    for (var habit in habits.take(3)) {
      // Create varying completion patterns
      for (int i = 1; i <= 30; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        
        // Different completion patterns for different habits
        bool shouldComplete = false;
        if (habit.habitName == 'Morning Meditation') {
          shouldComplete = i <= 12; // Current streak
        } else if (habit.habitName == 'Read for 30 Minutes') {
          shouldComplete = i <= 7; // Current streak
        } else if (habit.habitName == 'Exercise') {
          // More sporadic pattern
          shouldComplete = i <= 5 || (i >= 10 && i <= 12) || (i >= 20 && i <= 25);
        }
        
        if (shouldComplete) {
          await HabitApi.completeHabit(
            habit.habitId,
            notes: i == 1 ? 'Latest completion' : null,
          );
          logsCreated++;
        }
      }
    }
    
    developer.log('✅ Created $logsCreated habit completion logs', name: 'TestDataService');
  }
}
