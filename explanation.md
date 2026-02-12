# SelfAttendance App - Technical Documentation

## Overview
SelfAttendance is a comprehensive Flutter-based mobile application designed to help students track their class attendance, manage timetables, and maintain attendance goals. The app features cloud synchronization, calendar integration, and a modern iOS-inspired UI.

---

## Architecture & Design Patterns

### State Management
- **Provider Pattern**: Used for centralized state management across the app
- **ChangeNotifier**: Core class `AttendanceProvider` extends `ChangeNotifier` to notify UI of data changes
- **Consumer Widgets**: UI components listen to state changes and rebuild automatically

### Data Flow
1. **Local-First Architecture**: Data is stored locally first for instant access
2. **Cloud Sync**: Background synchronization with Firebase Firestore
3. **Real-time Updates**: Firestore listeners keep data in sync across devices

---

## Libraries & Dependencies

### Core Flutter Dependencies

#### 1. **flutter** (SDK)
- **Purpose**: Core Flutter framework
- **Usage**: Base framework for building the cross-platform mobile app
- **Why**: Enables single codebase for iOS and Android

#### 2. **cupertino_icons** (^1.0.8)
- **Purpose**: iOS-style icons
- **Usage**: Provides Cupertino (iOS) design icons throughout the app
- **Implementation**: Used in navigation, buttons, and UI elements for consistent iOS aesthetic

### UI & Design Libraries

#### 3. **table_calendar** (^3.1.0)
- **Purpose**: Interactive calendar widget
- **Usage**: 
  - Displays monthly calendar view in subject details
  - Shows attendance status for each day
  - Allows users to mark attendance by tapping dates
- **Features Used**:
  - Custom day builders for attendance markers
  - Event markers for class days
  - Date selection callbacks

#### 4. **google_fonts** (^6.1.0)
- **Purpose**: Custom typography
- **Usage**: Provides premium fonts for modern UI
- **Implementation**: Used throughout the app for consistent, professional typography

#### 5. **percent_indicator** (^4.2.3)
- **Purpose**: Visual progress indicators
- **Usage**: 
  - Circular progress indicators showing attendance percentage
  - Linear progress bars for attendance goals
- **Implementation**: Subject cards display attendance as circular percentage rings

#### 6. **fl_chart** (^0.66.0)
- **Purpose**: Data visualization
- **Usage**: 
  - Line charts for attendance trends
  - Bar charts for weekly/monthly analysis
  - Pie charts for subject distribution
- **Implementation**: Analysis screen shows attendance patterns over time

### Data Persistence

#### 7. **shared_preferences** (^2.2.2)
- **Purpose**: Local key-value storage
- **Usage**: 
  - Stores user preferences
  - Caches subject data locally
  - Saves user name and settings
- **Implementation**: 
  ```dart
  // Save subjects locally
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('subjects', jsonEncode(subjectsList));
  ```

#### 8. **intl** (^0.19.0)
- **Purpose**: Internationalization and date formatting
- **Usage**: 
  - Format dates consistently (e.g., "Jan 15, 2026")
  - Parse ISO8601 date strings
  - Locale-aware number formatting
- **Implementation**: Used in calendar displays and date pickers

### Firebase Integration

#### 9. **firebase_core** (^4.4.0)
- **Purpose**: Firebase initialization
- **Usage**: Core Firebase SDK initialization
- **Implementation**: 
  ```dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  ```

#### 10. **cloud_firestore** (^6.1.2)
- **Purpose**: Cloud database
- **Usage**: 
  - Store user attendance data in the cloud
  - Real-time synchronization across devices
  - Share timetables via share codes
- **Data Structure**:
  ```
  users/{userId}/
    - user_name: String
    - subjects: Array<Subject>
    - last_updated: Timestamp
  
  shared_timetables/{shareCode}/
    - subjects: Array<SubjectSchedule>
    - createdBy: String
    - createdAt: Timestamp
  ```
- **Security Rules**:
  - Users can only access their own data
  - Shared timetables are publicly readable
  - Only authenticated users can create share codes

#### 11. **firebase_auth** (^6.1.4)
- **Purpose**: User authentication
- **Usage**: 
  - Anonymous authentication for guest users
  - Google Sign-In for cloud backup
  - User session management
- **Implementation**:
  ```dart
  // Anonymous sign-in
  await FirebaseAuth.instance.signInAnonymously();
  
  // Google Sign-In
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  final credential = GoogleAuthProvider.credential(...);
  await FirebaseAuth.instance.signInWithCredential(credential);
  ```

#### 12. **google_sign_in** (6.2.1)
- **Purpose**: Google authentication
- **Usage**: 
  - Enable users to sign in with Google account
  - Access Google profile information
  - Sync data across devices
- **Features**:
  - One-tap sign-in
  - Profile photo display
  - Automatic token refresh

### Device Integration

#### 13. **device_calendar** (^4.3.0)
- **Purpose**: Native calendar integration
- **Usage**: 
  - Add class schedules to device calendar
  - Create recurring events for weekly classes
  - Set reminders before classes
  - Delete calendar events when subjects are removed
- **Implementation**:
  ```dart
  // Create recurring calendar event
  final event = Event(
    calendarId,
    title: subject.name,
    start: classTime,
    end: classTime.add(Duration(minutes: 60)),
    recurrenceRule: RecurrenceRule(
      RecurrenceFrequency.Weekly,
      daysOfWeek: [DayOfWeek.Monday],
    ),
    reminders: [Reminder(minutes: 10)],
  );
  await deviceCalendarPlugin.createOrUpdateEvent(event);
  ```

#### 14. **timezone** (^0.9.2)
- **Purpose**: Timezone handling
- **Usage**: 
  - Convert times to device timezone
  - Handle daylight saving time
  - Ensure calendar events are created in correct timezone
- **Implementation**: Used with `device_calendar` for accurate event scheduling

### State Management

#### 15. **provider** (^6.1.1)
- **Purpose**: State management solution
- **Usage**: 
  - Manage app-wide state (subjects, user data)
  - Notify UI of data changes
  - Dependency injection
- **Implementation**:
  ```dart
  // Provide state to app
  ChangeNotifierProvider(
    create: (_) => AttendanceProvider(),
    child: MyApp(),
  )
  
  // Consume state in widgets
  final provider = Provider.of<AttendanceProvider>(context);
  ```

### Development Tools

#### 16. **flutter_lints** (^5.0.0)
- **Purpose**: Code quality
- **Usage**: Enforces Flutter best practices and coding standards
- **Rules**: Ensures consistent code style and catches common errors

#### 17. **flutter_launcher_icons** (^0.13.1)
- **Purpose**: App icon generation
- **Usage**: Automatically generates launcher icons for iOS and Android
- **Configuration**:
  ```yaml
  flutter_launcher_icons:
    android: "launcher_icon"
    ios: true
    image_path: "assets/app_icon.png"
  ```

---

## Key Features Implementation

### 1. Attendance Tracking
**How it works:**
- Each subject has a `Map<String, bool>` storing attendance by date
- Date keys are in ISO8601 format (e.g., "2026-01-15")
- Boolean values: `true` = present, `false` = absent, `null` = not marked
- Calculations:
  ```dart
  double currentPercentage = (attendedClasses / totalClasses) * 100;
  int classesToAttend = ceil((total * target - attended) / (1 - target));
  ```

### 2. Streak Calculation
**Algorithm:**
- Iterates backwards from today
- Counts consecutive attended classes
- Stops at first absence or unmarked class day
- Limits check to 2 years for performance

### 3. Share/Import Timetable
**Implementation:**
1. **Share**:
   - Generate random 6-digit code
   - Extract schedule data (no attendance/notes)
   - Upload to Firestore `shared_timetables` collection
   - Code expires after natural Firestore cleanup

2. **Import**:
   - Fetch shared data from Firestore
   - Create new subjects with imported schedules
   - Add to device calendar
   - **Race Condition Fix**: Uses `_isImporting` lock to prevent Firestore listener from overwriting imported data

### 4. Cloud Synchronization
**Strategy:**
- **Local-first**: All changes saved locally immediately
- **Background sync**: Changes pushed to Firestore asynchronously
- **Real-time listener**: Receives updates from other devices
- **Conflict resolution**: Last-write-wins (server timestamp)
- **Offline support**: Works fully offline, syncs when online

### 5. Calendar Integration
**Features:**
- Creates recurring events for weekly classes
- Supports custom times per day
- Adds reminders (default: 10 minutes before)
- Automatically deletes events when subject is removed
- Handles permissions gracefully

---

## Data Models

### Subject Model
```dart
class Subject {
  String id;                      // Unique identifier
  String name;                    // Subject name
  double targetAttendance;        // Goal percentage (e.g., 75.0)
  List<int> classDays;           // Days of week (1=Mon, 7=Sun)
  Map<String, bool> attendance;   // Date -> Present/Absent
  Map<String, String> notes;      // Date -> Note text
  bool isWeekly;                  // Weekly vs Monthly schedule
  DateTime startDate;             // When tracking started
  DateTime? endDate;              // Optional end date
  Map<int, String> dayTimings;    // Day -> Time (e.g., {1: "09:00"})
  List<String> holidays;          // Holiday dates
  int reminderMinutes;            // Calendar reminder time
  Map<int, String> calendarEventIds; // Day -> Calendar event ID
}
```

---

## App Flow

### 1. **App Launch**
```
main() 
  → Initialize Firebase
  → Create AttendanceProvider
  → Load local data
  → Sign in anonymously
  → Start Firestore listener
  → Show HomeScreen
```

### 2. **Add Subject**
```
User Input
  → Create Subject object
  → Add to _subjects list
  → Save locally (SharedPreferences)
  → Save to Firestore
  → Add to device calendar
  → Notify listeners (UI updates)
```

### 3. **Mark Attendance**
```
Tap date on calendar
  → Update attendance map
  → Recalculate percentage
  → Save locally
  → Save to Firestore
  → Notify listeners
```

### 4. **Import Timetable**
```
Enter share code
  → Set _isImporting = true (lock)
  → Fetch from Firestore
  → Parse subjects
  → Check for duplicates
  → Create Subject objects
  → Add to local list
  → Save once (batch)
  → Add to calendar
  → Set _isImporting = false (unlock)
  → Notify listeners
```

---

## Security & Privacy

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data - private
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Shared timetables - public read, auth write
    match /shared_timetables/{code} {
      allow read: if true;
      allow create: if request.auth != null;
    }
  }
}
```

### Data Privacy
- User attendance data is private (only accessible by owner)
- Shared timetables contain NO attendance or notes
- Anonymous users get unique IDs
- Google Sign-In users can sync across devices

---

## Performance Optimizations

1. **Local-First Architecture**: Instant UI updates, background sync
2. **Batch Operations**: Import saves all subjects in one Firestore write
3. **Listener Lock**: Prevents race conditions during import
4. **Lazy Loading**: Calendar events created only when needed
5. **Efficient Queries**: Firestore queries limited to user's own data

---

## UI/UX Design

### Design System
- **Color Scheme**: iOS-inspired with blue (#0A84FF) primary color
- **Typography**: Google Fonts for premium feel
- **Components**: Cupertino (iOS) widgets for native feel
- **Animations**: Smooth transitions and micro-interactions
- **Dark Theme**: Black background (#000000) with dark cards (#1C1C1E)

### Key Screens
1. **Home Screen**: Subject list with attendance percentages
2. **Subject Details**: Calendar view, attendance history, analytics
3. **Add/Edit Subject**: Form for subject configuration
4. **Analysis**: Charts and statistics
5. **Share/Import**: Timetable sharing dialogs

---

## Error Handling

### Strategies
1. **Try-Catch Blocks**: All async operations wrapped
2. **Graceful Degradation**: Calendar errors don't block subject creation
3. **User Feedback**: SnackBars for success/error messages
4. **Debug Logging**: Extensive `debugPrint` statements
5. **Offline Support**: App works without internet

---

## Future Enhancements

### Potential Features
- [ ] Export attendance as PDF/CSV
- [ ] Attendance reminders/notifications
- [ ] Multiple timetable support (different semesters)
- [ ] Attendance predictions using ML
- [ ] Widget for home screen
- [ ] Dark/Light theme toggle
- [ ] Localization (multiple languages)

---

## Build & Deployment

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS
```bash
flutter build ios --release
# Requires Apple Developer account
```

### Firebase Deployment
```bash
firebase deploy --only firestore:rules
```

---

## Troubleshooting

### Common Issues

**Issue**: Import only shows partial subjects
- **Cause**: Firestore listener race condition
- **Fix**: Implemented `_isImporting` lock

**Issue**: Calendar permission denied
- **Cause**: User denied calendar access
- **Fix**: Wrapped in try-catch, subject still created

**Issue**: Firestore permission denied
- **Cause**: Security rules too restrictive
- **Fix**: Updated rules to allow anonymous read for shared codes

---

## Credits

**Developer**: Yash (yash._clouded)
**Framework**: Flutter
**Backend**: Firebase (Firestore, Auth)
**Design Inspiration**: iOS Human Interface Guidelines

---

## License

This project is private and not published to pub.dev.
