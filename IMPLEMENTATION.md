# Self Attendance App - Implementation Plan

## Overview
A Premium Flutter application for tracking attendance with a dark-themed UI, matching the user's specifications.

## Features Implemented
1.  **Home Screen**:
    *   Displays list of subjects.
    *   Shows attendance percentage calculated from records.
    *   Color-coded percentage (Green >= 65%, Red < 65%).
    *   Add Subject button.

2.  **Add Subject Screen**:
    *   Input for Subject Name.
    *   Target Attendance selector (Stepper).
    *   Days of Week selector (M, T, W...).

3.  **Subject Details Screen**:
    *   Large Percentage Display.
    *   Smart Advice: "Attend next X classes to reach target" or "On track! You can bunk X classes".
    *   Interactive Calendar:
        *   Tap a date to cycle status: Present (Green) -> Absent (Red) -> None.
    *   Reset option.

## Tech Stack
*   **Flutter & Dart**
*   **State Management**: `provider`
*   **Persistence**: `shared_preferences` (Saves data locally)
*   **UI Components**: `table_calendar`, `google_fonts` (Outfit font).
*   **Theme**: Dark Mode (Black/Dark Grey) with iOS Blue/Green/Red accents.

## How to Run
1.  Ensure you have Flutter installed.
2.  Open the project in your terminal:
    ```bash
    cd /Users/yash/selfattendence_app
    ```
3.  Run the app:
    ```bash
    flutter run
    ```
