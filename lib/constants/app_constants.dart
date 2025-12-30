class AppConstants {
  static const String profileId = 'profileId';
  static const String dbName = 'my_manager_database.db';
  
  // Project Status
  static const String projectStatusActive = 'Active';
  static const String projectStatusDeleted = 'Deleted';
  static const String projectStatusCompleted = 'Completed';
  static const String projectStatusOnHold = 'On Hold';
  
  // Task Status
  static const String taskStatusTodo = 'Todo';
  static const String taskStatusInProgress = 'In Progress';
  static const String taskStatusCompleted = 'Completed';
  static const String taskStatusCancelled = 'Cancelled';
  static const String taskStatusBlocked = 'Blocked';
  
  // Eisenhower Matrix - Priority Quadrants
  static const String priorityUrgentImportant = 'Urgent & Important';
  static const String priorityUrgentNotImportant = 'Urgent But Not Important';
  static const String priorityNotUrgentImportant = 'Not Urgent But Important';
  static const String priorityNotUrgentNotImportant = 'Not Urgent & Not Important';
  
  // Urgency Levels
  static const String urgencyHigh = 'High';
  static const String urgencyMedium = 'Medium';
  static const String urgencyLow = 'Low';
  
  // Importance Levels
  static const String importanceHigh = 'High';
  static const String importanceMedium = 'Medium';
  static const String importanceLow = 'Low';
  
  // Frequency Types
  static const String frequencyOnce = 'Once';
  static const String frequencyHourly = 'Hourly';
  static const String frequencyDaily = 'Daily';
  static const String frequencyWeekly = 'Weekly';
  static const String frequencyBiweekly = 'Bi-weekly';
  static const String frequencyMonthly = 'Monthly';
  static const String frequencyQuarterly = 'Quarterly';
  static const String frequencyYearly = 'Yearly';
  
  // Energy Levels (from "The Power of Full Engagement")
  static const String energyHigh = 'High';
  static const String energyMedium = 'Medium';
  static const String energyLow = 'Low';
  
  // Notification Channels
  static const String channelIdTasks = 'tasks_channel';
  static const String channelNameTasks = 'Task Reminders';
  static const String channelIdHabits = 'habits_channel';
  static const String channelNameHabits = 'Habit Reminders';
  static const String channelIdFocus = 'focus_channel';
  static const String channelNameFocus = 'Focus Sessions';
  
  // Pomodoro Settings (from "Pomodoro Technique")
  static const int pomodoroWorkMinutes = 25;
  static const int pomodoroShortBreak = 5;
  static const int pomodoroLongBreak = 15;
  static const int pomodoroSessionsBeforeLongBreak = 4;
  
  // Productivity Quotes (from various sources)
  static const List<String> productivityQuotes = [
    'The key is not to prioritize your schedule, but to schedule your priorities.',
    'You don\'t have to be great to start, but you have to start to be great.',
    'Focus on being productive instead of busy.',
    'The secret of getting ahead is getting started.',
    'Your future is created by what you do today, not tomorrow.',
  ];
}
