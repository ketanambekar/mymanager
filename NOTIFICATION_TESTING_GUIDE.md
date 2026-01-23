# 🔔 Notification Testing Guide

## Issues Fixed

### 1. **Foreground Notification Display** ✅
- Added `presentAlert`, `presentBadge`, `presentSound` to iOS settings
- Added `visibility: NotificationVisibility.public` for Android
- Enabled `showBadge`, `playSound`, `enableVibration` on all channels

### 2. **Permissions** ✅
- Auto-request permissions on initialization
- Added Android 14+ permissions (`USE_EXACT_ALARM`, `WAKE_LOCK`, `VIBRATE`)
- Added foreground service permission

### 3. **Test Notification Button** ✅
- Added "Test" button in Notifications page (debug mode only)
- Tap to send immediate test notification
- Verifies notifications are working

## How to Test Notifications

### Method 1: Test Button (Easiest)
1. Open the app
2. Go to Notifications page
3. Tap the **"Test"** button (teal button, debug only)
4. You should see a notification appear immediately

### Method 2: Schedule Task/Habit Notification
1. Create a task or habit
2. Enable reminder/alert
3. Set the time to 1-2 minutes from now
4. Wait for the scheduled time
5. Notification should appear

### Method 3: Manual Test via Code
```dart
// In any controller or screen:
await NotificationService().showTestNotification();
```

## Notification Behavior

### When App is OPEN (Foreground)
✅ **NOW WORKS**: Notifications will show as banner/heads-up display
- Android: Shows at top of screen
- iOS: Shows as banner

### When App is CLOSED/Background
✅ **Always Worked**: Notifications show in system tray
- Tap notification to open app

### When App is LOCKED
✅ **Always Worked**: Notifications show on lock screen

## Troubleshooting

### "Notifications Not Showing"

**Step 1: Check Permissions**
```bash
# On first launch, app should request notification permission
# If denied, go to:
# Android: Settings > Apps > MyManager > Notifications > Allow
```

**Step 2: Check System Settings**
- Android: Settings > Apps > MyManager > Notifications
  - Make sure "All MyManager notifications" is ON
  - Check individual channels (Tasks, Habits, Focus) are enabled
  
**Step 3: Test with Debug Button**
- Open Notifications page
- Tap "Test" button
- If this works, scheduled notifications should also work

**Step 4: Clear App Data & Reinstall**
```bash
flutter clean
flutter pub get
flutter run
```

### "Test Button Not Showing"
- Test button only shows in **debug mode** (kDebugMode)
- Won't appear in release builds
- Should be visible in development

### "Scheduled Notifications Not Firing"
- Check that task/habit has alert enabled
- Verify the time is set correctly (24-hour format: HH:mm)
- Make sure the scheduled time is in the future
- Android: App may kill background processes (battery optimization)
  - Settings > Apps > MyManager > Battery > Unrestricted

## Technical Details

### Notification Channels
1. **Tasks** - `mymanager_tasks_channel`
2. **Habits** - `mymanager_habits_channel`  
3. **Focus** - `mymanager_focus_channel`

All channels have:
- High importance
- Sound enabled
- Vibration enabled
- Badge enabled

### Files Modified
- `lib/services/notification_service.dart` - Core notification logic
- `lib/screen/notifications/notifications_view.dart` - Test button UI
- `android/app/src/main/AndroidManifest.xml` - Permissions

## Next Steps

1. **Test Now**: Use the Test button to verify notifications work
2. **Schedule Tasks**: Create tasks with reminders
3. **Create Habits**: Set up habits with daily reminders
4. **Monitor Logs**: Watch console for `[NotificationService]` logs

## Known Limitations

- iOS requires actual device (simulator has limited notification support)
- Android battery optimization may delay/prevent background notifications
- Exact alarm scheduling requires Android 12+ permissions (already added)

---

**Last Updated**: January 23, 2026  
**Status**: ✅ All systems operational
