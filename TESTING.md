# Testing ToolShare Locally

## Option 1: Firebase Emulator Suite (Recommended for Testing)

### Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### Initialize Emulators
```bash
cd stuffbuff
firebase init emulators
# Select: Authentication, Firestore, Storage
```

### Start Emulators
```bash
firebase emulators:start
```

This gives you local Firebase at:
- Auth: http://localhost:9099
- Firestore: http://localhost:8080
- Storage: http://localhost:9199
- Emulator UI: http://localhost:4000

### Connect App to Emulators

Add to `lib/main.dart` before `runApp()`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Connect to local emulators
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  
  runApp(const ToolShareApp());
}
```

Now you can test with fake phone numbers and data without using real Firebase quota.

---

## Option 2: Real Firebase Testing

### Test Phone Numbers (Firebase Console)

1. Go to Firebase Console → Authentication → Sign-in method
2. Click "Phone" → "Phone numbers for testing"
3. Add test numbers:
   - Number: `+1 555-0100`
   - Verification code: `123456`

Use these in the app to skip real SMS.

---

## Testing Checklist

### Authentication Flow
- [ ] Enter phone number → "Continue"
- [ ] Enter OTP → Verify
- [ ] Check user created in Firestore
- [ ] Edit profile (name + photo)
- [ ] Sign out and sign back in

### Tool Listing Flow
- [ ] Go to "My Tools" → "List Your First Tool"
- [ ] Upload 1-5 photos
- [ ] Fill: Title, Description, Category, Price
- [ ] Submit listing
- [ ] Check tool appears in "My Tools"
- [ ] Toggle availability on/off
- [ ] Edit tool details
- [ ] Delete tool

### Browse & Rental Flow
- [ ] Browse tab shows tools
- [ ] Filter by category works
- [ ] Tap tool → Detail screen
- [ ] Tap "Request to Rent"
- [ ] Select start/end dates
- [ ] Add message
- [ ] Submit request
- [ ] Check appears in "My Rentals" (as renter)
- [ ] As owner, see incoming request
- [ ] Approve/reject rental
- [ ] Mark as picked up/returned

### Edge Cases
- [ ] Try to rent your own tool (shouldn't work)
- [ ] Try to rent unavailable tool
- [ ] Try overlapping dates (should block)
- [ ] Upload large photo (should compress)
- [ ] No internet connection (should show error)

---

## Testing on Real Devices

### Android
```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Build APK for side-loading
flutter build apk --debug
# Install: adb install build/app/outputs/flutter-apk/app-debug.apk
```

### iOS
```bash
# Run on connected iPhone
flutter run -d <device-id>

# Or build and install via Xcode
flutter build ios
# Open ios/Runner.xcworkspace in Xcode → Run
```

---

## Debugging Tips

### View Logs
```bash
flutter logs
```

### Debug Mode
```bash
flutter run --verbose
```

### Check Firestore Data
- Emulator UI: http://localhost:4000
- Real Firebase: Firebase Console → Firestore Database

### Common Issues

**"No Firebase app has been created"**
→ Update `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)

**Phone auth not working**
→ Add SHA-1 fingerprint to Firebase Android app settings

**Images not uploading**
→ Check Storage rules allow authenticated uploads

---

## Automated Testing (Optional)

### Run Unit Tests
```bash
flutter test
```

### Create a Simple Widget Test

Add to `test/widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toolshare/main.dart';

void main() {
  testWidgets('App launches and shows auth screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ToolShareApp());
    
    // Should show phone auth screen initially
    expect(find.text('Welcome to ToolShare'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
```

Run: `flutter test`

---

## Performance Testing

### Check App Size
```bash
flutter build apk --analyze-size
```

### Profile Mode
```bash
flutter run --profile
```

Open DevTools: `flutter pub global activate devtools && flutter pub global run devtools`

---

## Beta Testing

### Firebase App Distribution

1. Build release APK:
```bash
flutter build apk --release
```

2. Upload to Firebase App Distribution
3. Invite testers by email
4. They get download link

### TestFlight (iOS)

1. Build: `flutter build ios --release`
2. Archive in Xcode
3. Upload to App Store Connect
4. Add internal testers

---

## Production Readiness Checklist

Before real users:

- [ ] Firebase security rules tested
- [ ] All test data removed from Firestore
- [ ] Test phone numbers removed from Firebase Auth
- [ ] App icon and splash screen set
- [ ] App name configured in AndroidManifest and Info.plist
- [ ] Privacy policy link added
- [ ] Terms of service link added
- [ ] Analytics enabled (optional)
- [ ] Crashlytics enabled (optional)

---

*Next: See FIREBASE_SETUP.md for full Firebase configuration.*
