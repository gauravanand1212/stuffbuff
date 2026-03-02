# ToolShare - P2P Tool Rental Marketplace

A Flutter-based peer-to-peer tool rental marketplace MVP. Users can list their tools for rent, browse available tools, and request rentals from neighbors in their community.

## Features

### Authentication
- Phone number authentication via Firebase Auth
- Simple, secure login flow with OTP verification

### Tool Listings
- Create, edit, and delete tool listings
- Upload multiple photos with automatic compression
- Categorize tools (Power Tools, Hand Tools, Garden, Automotive, etc.)
- Set daily rental price
- Mark tools as available/unavailable

### Browsing
- Browse all available tools
- Filter by category
- View tool details with photo gallery
- See pricing and owner information

### Rentals
- Request to rent tools for specific date ranges
- View all your rental requests (as renter)
- Manage incoming rental requests (as owner)
- Track rental status: Pending → Approved → Active → Completed
- Add messages and notes to rentals

### User Profile
- Edit display name and profile photo
- View rental stats and rating
- Sign out functionality

## Tech Stack

- **Framework:** Flutter 3.0+
- **Language:** Dart
- **State Management:** BLoC (flutter_bloc)
- **Backend:** Firebase
  - Firebase Authentication (Phone)
  - Cloud Firestore (Database)
  - Firebase Storage (Images)
- **Key Packages:**
  - `flutter_bloc` - State management
  - `image_picker` - Photo selection
  - `flutter_image_compress` - Image optimization
  - `intl` - Date formatting
  - `uuid` - Unique identifiers

## Project Structure

```
lib/
├── blocs/
│   └── auth/
│       ├── auth_bloc.dart
│       ├── auth_event.dart
│       └── auth_state.dart
├── models/
│   ├── user.dart
│   ├── tool.dart
│   └── rental.dart
├── screens/
│   ├── auth/
│   │   ├── auth_wrapper.dart
│   │   ├── phone_auth_screen.dart
│   │   └── otp_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   ├── browse_tools_screen.dart
│   │   ├── my_tools_screen.dart      # Your tool listings
│   │   ├── my_rentals_screen.dart    # Rental management
│   │   └── profile_screen.dart       # User profile
│   ├── listing/
│   │   ├── tool_detail_screen.dart
│   │   └── add_tool_screen.dart      # Create/edit tools
│   └── rental/
│       └── request_rental_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── firebase_options.dart
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Firebase account
- Android Studio / Xcode (for emulators)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd toolshare
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   
   See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed Firebase configuration instructions.
   
   Quick steps:
   - Create a Firebase project
   - Add Android/iOS apps
   - Enable Authentication (Phone), Firestore, and Storage
   - Download and place config files (`google-services.json`, `GoogleService-Info.plist`)
   - Update Firestore security rules

4. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Firebase Options

The app uses `lib/firebase_options.dart` for Firebase configuration. You can either:
- Use FlutterFire CLI to auto-generate this file
- Manually update the placeholder values with your Firebase config

### Android Setup

1. Place `google-services.json` in `android/app/`
2. Ensure your `android/build.gradle` includes the Google Services plugin
3. Add your SHA-1 fingerprint to Firebase for Phone Auth
4. Add the following permissions to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
   ```

### iOS Setup

1. Place `GoogleService-Info.plist` in `ios/Runner/` (add via Xcode)
2. Run `pod install` in the `ios/` directory
3. Configure URL schemes for Phone Auth (done automatically by Firebase config)
4. Add the following to `ios/Runner/Info.plist` for image picker permissions:
   ```xml
   <key>NSPhotoLibraryUsageDescription</key>
   <string>This app needs access to photo library to upload tool photos</string>
   <key>NSCameraUsageDescription</key>
   <string>This app needs access to camera to take tool photos</string>
   ```

## Usage Guide

### First Launch

1. Sign in with your phone number
2. Enter the OTP code sent via SMS
3. Complete your profile with a display name and photo

### Listing a Tool

1. Go to "My Tools" tab
2. Tap "List Your First Tool"
3. Add photos, title, description, category, and price
4. Tap "List Tool" to publish

### Renting a Tool

1. Browse tools in the "Browse" tab
2. Tap a tool to view details
3. Tap "Request to Rent"
4. Select dates and add an optional message
5. Submit the request

### Managing Rentals

1. Go to "My Rentals" tab
2. As a renter: View status of your requests
3. As an owner: Approve/reject incoming requests, mark as picked up/returned

## Development

### Running Tests

```bash
flutter test
```

### Building for Production

**Android:**
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

### Code Generation

If you add new Firebase configurations:
```bash
flutterfire configure
```

## Architecture

### State Management

The app uses BLoC (Business Logic Component) pattern:
- **AuthBloc:** Manages authentication state
- Events: `AppStarted`, `PhoneNumberSubmitted`, `OTPSubmitted`, `LoggedOut`, `ProfileUpdated`
- States: `AuthInitial`, `AuthLoading`, `Authenticated`, `Unauthenticated`, `AuthError`

### Data Flow

1. UI triggers an Event → BLoC
2. BLoC processes the event (calls Services)
3. BLoC emits a new State
4. UI rebuilds based on new State

### Services

- **AuthService:** Firebase Authentication operations
- **FirestoreService:** Database CRUD operations and queries
- **StorageService:** Image upload and compression

## Security Considerations

- Firestore security rules restrict data access based on authentication
- Users can only modify their own tools and rentals
- Phone authentication provides secure, password-less login
- Image uploads are validated and compressed before storage

## Known Limitations (MVP)

- No in-app messaging between users
- No payment integration (arrange payment offline)
- No location-based search
- No push notifications
- No rating/review system (ratings are placeholder)

## Future Enhancements

- [ ] In-app chat between renters and owners
- [ ] Integrated payment processing
- [ ] Map view with location-based search
- [ ] Push notifications for rental updates
- [ ] Rating and review system
- [ ] Search functionality
- [ ] Favorites/bookmarks
- [ ] Rental history and analytics

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source and available under the MIT License.

## Support

For Firebase setup issues, see [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

For Flutter issues, check the [Flutter documentation](https://docs.flutter.dev/).

## Acknowledgments

- Built with Flutter and Firebase
- Inspired by the sharing economy and community tool libraries
