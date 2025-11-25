# SPORG
The ultimate organizers attendance app for SPOT unit in Faculty of Medicine Tant University,
# SPOT Attendance

A Flutter mobile application for event organizer check-ins using QR scanning and manual entry.

## Features

- QR code scanning for quick check-ins
- Manual member ID/name entry
- Multiple user roles (Admin, Supervisor, User)
- Offline-first architecture
- Excel export functionality
- GitHub integration for data sync

## Setup Instructions

1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter packages pub run build_runner build --delete-conflicting-outputs`
4. Run the app with `flutter run`

## Testing GitHub Upload

For testing GitHub uploads locally:

1. Create a GitHub personal access token with repo permissions
2. Use the token in the login screen
3. For production, implement a backend proxy to handle GitHub API calls securely

## API Keys

GitHub tokens are stored securely using flutter_secure_storage and should not be embedded in the app binary.

## Architecture

- Clean Architecture with BLoC state management
- Repository pattern for data access
- Responsive UI design for phones and tablets
- Offline-first approach with local SQLite database
