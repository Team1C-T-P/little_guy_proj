# Google Authentication Setup Guide

This guide explains how to set up Google OAuth authentication for the Little Guy Project.

## Prerequisites

1. Flutter SDK installed
2. Firebase CLI installed: `npm install -g firebase-tools`
3. FlutterFire CLI installed: `dart pub global activate flutterfire_cli`

## Setup Steps

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "little-guy-project")
4. Follow the setup wizard

### 2. Enable Google Sign-In

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click on **Google** provider
3. Toggle **Enable**
4. Set a support email
5. Click **Save**

### 3. Enable Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
4. Select a location
5. Click **Enable**

### 4. Configure Firebase for Flutter

Run the following command in the project root:

```bash
flutterfire configure
```

This will:
- Create/select your Firebase project
- Generate `firebase_options.dart` with platform-specific configurations
- Set up Firebase for iOS, Android, Web, macOS, Windows, and Linux

Select the platforms you want to support when prompted.

### 5. Update Main App File

The Firebase initialization is already included in `lib/main.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

After running `flutterfire configure`, you'll need to import the generated file:

```dart
import 'firebase_options.dart';
```

And update the initialization:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 6. Platform-Specific Setup

#### Android

1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`
3. In `android/build.gradle`, add:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
   }
   ```
4. In `android/app/build.gradle`, add at the bottom:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

#### iOS

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to `ios/Runner/` in Xcode
3. Open `ios/Runner.xcworkspace` in Xcode
4. The Google Sign-In will be automatically configured

#### Web

1. Add Firebase config in `web/index.html` before the closing `</body>` tag
2. Get the config from Firebase Console → Project Settings → Web app

### 7. Install Dependencies

```bash
flutter pub get
```

### 8. Run the App

```bash
flutter run
```

## Features

- **Google Sign-In**: Users can sign in with their Google account
- **Profile Persistence**: User data is stored in Firestore
- **Pets Management**: Users can add and view their pets
- **Costumes Management**: Users can add and view their costumes
- **Auto-Login**: Users stay logged in across app sessions

## Firestore Data Structure

```
users (collection)
  └── {userId} (document)
      ├── email: string
      ├── displayName: string
      ├── photoUrl: string
      ├── pets: array of strings
      ├── costumes: array of strings
      ├── createdAt: timestamp
      └── lastLogin: timestamp
```

## Security Rules

For production, update Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Troubleshooting

### Firebase not initialized
- Make sure you ran `flutterfire configure`
- Check that `firebase_options.dart` exists
- Verify Firebase.initializeApp() is called before runApp()

### Google Sign-In not working
- Verify Google Sign-In is enabled in Firebase Console
- Check platform-specific configuration (google-services.json for Android, GoogleService-Info.plist for iOS)
- Make sure SHA-1 fingerprint is added in Firebase Console for Android

### Firestore permission denied
- Check Firestore security rules
- Ensure user is authenticated before accessing data

## Development Mode

For testing without Firebase setup, the app will show appropriate error messages and can still demonstrate the UI flow. To fully enable authentication:

1. Complete Firebase setup above
2. Run `flutterfire configure`
3. Update imports in main.dart to include firebase_options.dart

## Next Steps

- Add email/password authentication
- Implement password reset
- Add profile picture upload
- Add more user data fields
- Implement offline support with local caching
