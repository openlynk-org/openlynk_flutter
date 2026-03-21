# Openlynk SDK for Flutter

A Flutter SDK for implementing deferred deep linking with Openlynk.

## Features

- **Automatic deep link listener**: Listens for Universal Links (iOS) and App Links (Android); callbacks when the app is opened via a link
- **Auto parsing of universal/app links**: Incoming links are resolved to destination path and parameters via the API
- **Automatic restore on init**: Restores pending links when you call `init()`, so install → open app → navigate in one step
- **Deferred Deep Linking**: Restore original link data after app installation
- **Cross-Platform**: Works on both iOS and Android
- **Anonymous Support**: Device fingerprinting for users without accounts
- **UTM Parameter Extraction**: Access campaign tracking data
- **Easy Integration**: Simple API with async/await support

## Installation

### 1. Add to pubspec.yaml

```yaml
dependencies:
  openlynk_sdk:
    git:
      url: git@github.com:openlynk-org/openlynk_flutter.git
      ref: main
```

### 2. Install dependencies

```bash
flutter pub get
```

## Usage

### Basic Setup (with automatic listener and restore)

```dart
import 'package:openlynk_sdk/openlynk_sdk.dart';

// In your State.initState:
openlynkSDK = OpenlynkSDK(
  appId: 'your-app-id',
  apiKey: 'your-api-key',
  config: OpenlynkSDKConfig(
    autoRestoreOnInit: true,
    userEmailProvider: () => getCurrentUserEmail(),
    onRestoredLinks: (restored) { /* navigate from restored links */ },
    onDeepLink: (parsed) { /* navigate from parsed deep link */ },
  ),
);
openlynkSDK.init();
```

Configure your app for **Universal Links** (iOS) and **App Links** (Android) so the OS opens your app for your Openlynk link domain. See your platform docs and the [app_links](https://pub.dev/packages/app_links) package for setup.

### Restore Pending Links

```dart
// For authenticated users
final restoredLinks = await openlynkSDK.restorePendingLinks(
  userEmail: 'user@example.com',
);

// For anonymous users
final restoredLinks = await openlynkSDK.restorePendingLinksForAnonymous();
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

### OpenlynkSDK

#### Constructor
```dart
OpenlynkSDK({
  required String appId,
  required String apiKey,
  String baseURL = 'https://openlynk.io',
  OpenlynkSDKConfig config = const OpenlynkSDKConfig(),
})
```

#### Methods

##### init
```dart
Future<void> init()
```
Call once after creating the SDK. Restores pending links (if `autoRestoreOnInit`), starts the deep link listener, and reports an install heartbeat.

##### restorePendingLinks
```dart
Future<List<RestoredLink>> restorePendingLinks({String? userEmail})
```
Restore pending links after app installation. Uses `userEmail` if provided, otherwise falls back to device fingerprint.

##### restorePendingLinksForAnonymous
```dart
Future<List<RestoredLink>> restorePendingLinksForAnonymous()
```
Shorthand for `restorePendingLinks()` without an email (device fingerprint only).

##### createLink
```dart
Future<CreatedLink> createLink({
  required String destination,
  Map<String, dynamic>? metadata,
})
```
Create a dynamic deep link for sharing. `destination` is the in-app path (e.g., `"/product/123"`).

##### registerPushToken
```dart
Future<void> registerPushToken(String token, {String? userEmail})
```
Register an FCM device token for push notifications.

##### handlePushPayload
```dart
Future<void> handlePushPayload(Map<String, dynamic> data)
```
Handle a push notification payload. Triggers `onDeepLink` and reports the open event.

##### dispose
```dart
void dispose()
```
Stop listening for deep links. Call from `State.dispose`.

### ParsedDeepLink

Returned by the `onDeepLink` callback when a deep link is opened.

#### Properties
- `originalUri`: The raw URI that opened the app
- `destination`: Full destination with parameters (e.g., `"/product/123?utm_source=share"`)
- `destinationPath`: Path only (e.g., `"/product/123"`)
- `parameters`: Extracted parameters as a map
- `metadata`: Full metadata from the link
- `linkId`: Openlynk link ID
- `slug`: URL slug

### CreatedLink

Returned by `createLink()`.

#### Properties
- `id`: Link ID
- `slug`: URL slug
- `url`: Full shareable URL
- `destination`: The destination path
- `metadata`: Link metadata

### RestoredLink

Returned by `restorePendingLinks()`.

#### Properties
- `pendingLinkId`: Unique identifier for the pending link
- `originalUrl`: The original deep link URL that was clicked
- `destinationUrl`: The final destination URL
- `destinationPath`: Path without parameters
- `destination`: Full destination with parameters
- `parameters`: Extracted parameters for easy access
- `metadata`: Map containing UTM parameters and other tracking data
- `linkId`: The ID of the original link

#### UTM Parameter Getters
- `utmSource`: Traffic source (e.g., "google", "facebook")
- `utmMedium`: Marketing medium (e.g., "cpc", "social")
- `utmCampaign`: Campaign name (e.g., "summer-sale")
- `utmTerm`: Paid search keywords
- `utmContent`: Ad content or link text

### Exceptions

- `OpenlynkRateLimitException`: Thrown on HTTP 429 (too many requests)
- `OpenlynkLinkLimitException`: Thrown when `createLink` exceeds your plan's link limit. Includes `currentCount`, `limit`, `plan`, and `upgradeRequired` fields.

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
- `app_links`: For Universal Links / App Links handling

## License

This SDK is provided as part of the Openlynk platform.
