# Whyleloop SDK for Flutter

A Flutter SDK for implementing deferred deep linking with Whyleloop.

## Features

- **Deferred Deep Linking**: Restore original link data after app installation
- **Cross-Platform**: Works on both iOS and Android
- **Anonymous Support**: Device fingerprinting for users without accounts
- **UTM Parameter Extraction**: Access campaign tracking data
- **Easy Integration**: Simple API with async/await support

## Installation

### 1. Add to pubspec.yaml

```yaml
dependencies:
  whyleloop_sdk:
    path: path/to/whyleloop_sdk
```

### 2. Install dependencies

```bash
flutter pub get
```

## Usage

### Basic Setup

```dart
import 'package:whyleloop_sdk/whyleloop_sdk.dart';

// Initialize the SDK
final whyleloopSDK = WhyleloopSDK(appId: 'your-app-id');
```

### Restore Pending Links

```dart
// For authenticated users
final restoredLinks = await whyleloopSDK.restorePendingLinks(
  userEmail: 'user@example.com',
);

// For anonymous users
final restoredLinks = await whyleloopSDK.restorePendingLinksForAnonymous();
```

### Handle Restored Links

```dart
for (RestoredLink link in restoredLinks) {
  // Access link data
  final destinationUrl = link.destinationUrl;
  final utmSource = link.utmSource;
  final utmCampaign = link.utmCampaign;
  
  // Navigate to appropriate screen
  _navigateToDestination(link);
}
```

## API Reference

### WhyleloopSDK

#### Constructor
```dart
WhyleloopSDK({
  required String appId,
  String baseURL = 'https://whyleloop.app',
})
```

#### Methods

##### restorePendingLinks
```dart
Future<List<RestoredLink>> restorePendingLinks({
  String? userEmail,
})
```

##### restorePendingLinksForAnonymous
```dart
Future<List<RestoredLink>> restorePendingLinksForAnonymous()
```

### RestoredLink

#### Properties
- `pendingLinkId`: Unique identifier for the pending link
- `originalUrl`: The original deep link URL that was clicked
- `destinationUrl`: The final destination URL with UTM parameters
- `metadata`: Map containing UTM parameters and other tracking data
- `linkId`: The ID of the original link

#### UTM Parameter Getters
- `utmSource`: Traffic source (e.g., "google", "facebook")
- `utmMedium`: Marketing medium (e.g., "cpc", "social")
- `utmCampaign`: Campaign name (e.g., "summer-sale")
- `utmTerm`: Paid search keywords
- `utmContent`: Ad content or link text

## Example Integration

See the complete example in the SDK file comments for a full integration example.

## Requirements

- Flutter 3.0.0 or higher
- Dart 2.17.0 or higher
- iOS 11.0 or higher
- Android API level 21 or higher

## Dependencies

- `http`: For API communication
- `shared_preferences`: For device fingerprint storage
- `device_info_plus`: For device information

## License

This SDK is provided as part of the Whyleloop platform.
