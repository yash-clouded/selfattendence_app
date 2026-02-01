# Attendance App - Major Feature Implementation Plan

## Overview
This plan outlines the implementation of advanced scheduling, alarm integration, and timetable features.

## Phase 1: Enhanced Data Model

### 1.1 Update Subject Model
- Add `Map<int, String> dayTimings` - Maps day (1-7) to time (HH:mm)
- Add `List<String> holidays` - List of holiday dates (ISO8601)
- Add `List<String> cancelledClasses` - List of cancelled class dates
- Remove single `classTime` field (replaced by per-day timings)

### 1.2 Update AttendanceProvider
- Add `updateSubject()` method for editing
- Add `addHoliday()` and `removeHoliday()` methods
- Add `cancelClass()` method
- Update `_addToDeviceCalendar()` to handle per-day timings

## Phase 2: UI Components

### 2.1 Today's Timetable Widget (Home Screen)
- Create `TodayScheduleWidget`
- Show all classes for current day with times
- Display countdown to next class
- Show "No classes today" if none scheduled

### 2.2 Edit Subject Screen
- Clone AddSubjectScreen as `EditSubjectScreen`
- Pre-populate all fields with existing data
- Add "Save Changes" button
- Add validation

### 2.3 Holiday Management Screen
- Create `HolidayManagementScreen`
- Calendar view to add/remove holidays
- List of upcoming holidays
- Quick actions (semester break, exam week, etc.)

### 2.4 Enhanced AddSubject Screen
- Replace single time picker with per-day time configuration
- Show time input for each selected day
- Add "Same time for all days" quick option

## Phase 3: Alarm Integration

### 3.1 Alarm Service
- Create `AlarmService` class
- Use `android_alarm_manager_plus` for Android
- Schedule alarms 10 minutes before each class
- Handle alarm rescheduling on subject edit
- Cancel alarms on subject delete

### 3.2 Notification Handler
- Create notification channel for class reminders
- Show notification with subject name and time
- Add "Mark Present" quick action
- Add "Snooze 5 min" option

## Phase 4: Integration

### 4.1 Home Screen Updates
- Add TodayScheduleWidget at top
- Keep existing subject list below
- Add floating action button menu:
  - Add Subject
  - Manage Holidays
  - Settings

### 4.2 Subject Details Updates
- Add "Edit" button in app bar
- Show holiday-adjusted attendance stats
- Exclude holidays from streak calculation

## Technical Considerations

### Permissions Required
- `SCHEDULE_EXACT_ALARM` (Android 12+)
- `USE_EXACT_ALARM` (Android 13+)
- `POST_NOTIFICATIONS` (Android 13+)

### Data Migration
- Need migration logic for existing subjects
- Convert single `classTime` to `dayTimings` map
- Initialize empty holidays list

### Edge Cases
- Handle timezone changes
- Handle device reboot (alarm persistence)
- Handle app updates (alarm rescheduling)
- Handle overlapping class times

## Implementation Order

1. ✅ Add dependencies
2. Update Subject model with new fields
3. Create TodayScheduleWidget
4. Create EditSubjectScreen
5. Update AddSubjectScreen for per-day timings
6. Implement AlarmService
7. Create HolidayManagementScreen
8. Integrate all components
9. Add data migration
10. Testing & refinement

## Estimated Complexity
- High complexity due to:
  - Native alarm integration
  - Data model changes requiring migration
  - Multiple new screens
  - Calendar/timezone handling

Would you like me to proceed with this implementation?
