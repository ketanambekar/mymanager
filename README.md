# MyManager - Your Personal Productivity Companion

**"The guide who makes success simple"**

A comprehensive productivity management app built with Flutter that helps you organize your life using proven time management techniques and psychological principles.

## 🎯 Features

### Eisenhower Matrix Integration
- **Urgent & Important (Do First)**: Critical tasks requiring immediate attention
- **Urgent But Not Important (Delegate)**: Tasks that are time-sensitive but less critical
- **Not Urgent But Important (Schedule)**: Important tasks for long-term success
- **Not Urgent & Not Important (Eliminate)**: Low-priority tasks to minimize

### Task Management
- ✅ Create projects and organize tasks within them
- ✅ Create standalone tasks independent of projects
- ✅ Add subtasks for better task breakdown
- ✅ Set priority levels based on urgency and importance
- ✅ Track time estimates and actual time spent
- ✅ Mark tasks with energy levels (High/Medium/Low)
- ✅ Flag tasks requiring deep focus

### Smart Scheduling
- 📅 Set due dates and times
- 🔔 Configurable alerts and reminders
- 🔁 Recurring tasks with multiple frequency options:
  - Hourly, Daily, Weekly, Bi-weekly, Monthly, Quarterly, Yearly
- ⏰ Smart notifications 15 minutes before task due time

### Productivity Tools
- **Pomodoro Timer**: Built-in focus sessions with automatic breaks
  - 25-minute work sessions
  - 5-minute short breaks
  - 15-minute long breaks after 4 sessions
  - Automatic time tracking for tasks
- **Habit Tracking**: Build consistent routines
  - Track daily, weekly, and monthly habits
  - View current and best streaks
  - Visual habit calendar

### Insights & Analytics
- 📊 Task distribution by priority quadrants
- 📈 Productivity metrics and trends
- ⏱️ Time tracking per project and task
- 🔥 Habit streaks and completion rates
- 📆 Overdue tasks dashboard
- 🎯 Today's focus view

## 🏗️ Architecture

Built using **Clean Architecture** principles with:
- **GetX** for state management and dependency injection
- **SQLite** for local data persistence
- **Flutter Local Notifications** for intelligent reminders
- **Repository Pattern** for data abstraction

### Project Structure
```
lib/
├── app/                    # App initialization and bindings
├── constants/              # App-wide constants and enums
├── database/              
│   ├── apis/              # Data access layer
│   ├── helper/            # Database initialization
│   └── tables/            # Table schemas and models
├── routes/                # Navigation configuration
├── screen/                # Feature screens (Dashboard, Projects, Tasks, etc.)
├── services/              # Business logic services
│   ├── notification_service.dart
│   └── pomodoro_controller.dart
├── theme/                 # App theming and styles
├── utils/                 # Utility functions
└── widgets/               # Reusable UI components
    ├── eisenhower_matrix.dart
    ├── task_card.dart
    └── pomodoro_widget.dart
```

## 📚 Productivity Concepts Implemented

This app integrates proven methodologies from renowned productivity books:

1. **Eisenhower Matrix** - "The 7 Habits of Highly Effective People" by Stephen Covey
2. **Pomodoro Technique** - Francesco Cirillo
3. **Time Blocking** - Cal Newport's "Deep Work"
4. **Energy Management** - "The Power of Full Engagement" by Jim Loehr
5. **Habit Formation** - "Atomic Habits" by James Clear
6. **GTD Principles** - "Getting Things Done" by David Allen

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.8.1)
- Android SDK or iOS development environment
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd mymanager
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📱 Screens Overview

- **Dashboard**: Overview of today's tasks, priority distribution, and quick actions
- **Projects**: Manage projects with tasks and progress tracking
- **Calendar**: Timeline view of all scheduled tasks
- **Reports**: Analytics and productivity insights
- **Profile**: User settings and app information

## 🎨 Design Philosophy

The UI follows a **"human-made"** design approach:
- Organic, natural-feeling interactions
- Smooth animations with Flutter Animate
- Glass-morphism effects for modern aesthetics
- Micro-interactions for better user feedback
- Accessible color coding (colorblind-friendly)

## 🔔 Notification System

Intelligent notification management:
- Task reminders 15 minutes before due time
- Recurring notifications for habitual tasks
- Pomodoro session completion alerts
- Focus mode reminders
- Customizable per-task alert settings

## 🗃️ Database Schema

**Tasks Table:**
- Priority and urgency/importance levels
- Frequency and recurrence settings
- Time tracking (estimate vs. actual)
- Energy level and focus requirements
- Parent-child relationships for subtasks

**Projects Table:**
- Status tracking (Active, Completed, On Hold, Deleted)
- Color coding for quick identification
- Task aggregation and progress

**Habits Table:**
- Frequency tracking
- Streak calculation
- Historical completion logs

## 🛠️ Technologies Used

- **Flutter** - Cross-platform UI framework
- **GetX** - State management
- **SQLite (sqflite)** - Local database
- **Flutter Local Notifications** - Push notifications
- **Google Fonts** - Typography
- **Flutter Animate** - Smooth animations
- **Glass** - Glassmorphism effects
- **Timezone** - Date/time handling

## 📈 Future Enhancements

- [ ] Cloud sync across devices
- [ ] Team collaboration features
- [ ] AI-powered task suggestions
- [ ] Voice input for task creation
- [ ] Calendar integration (Google Calendar, Outlook)
- [ ] Weekly review templates
- [ ] Goal setting with OKRs
- [ ] Dark/Light theme toggle
- [ ] Export reports as PDF

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Developer

Built with ❤️ to help people achieve work-life balance and peak productivity.

---

**Remember**: "The key is not to prioritize your schedule, but to schedule your priorities." - Stephen Covey
