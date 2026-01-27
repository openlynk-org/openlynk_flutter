/**
 * Whyleloop Deferred Deep Linking SDK for Flutter
 * 
 * This SDK provides Flutter integration for deferred deep linking.
 * It handles storing and restoring pending links when users install your app
 * after clicking a deep link.
 */

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class WhyleloopSDK {
  static const String _tag = 'WhyleloopSDK';
  static const String _prefsKey = 'whyleloop_device_fingerprint';
  
  final String baseURL;
  final String appId;
  
  /// Initialize the Whyleloop SDK
  /// 
  /// [appId] - Your app ID from Whyleloop dashboard
  /// [baseURL] - Base URL (default: https://whyleloop.app)
  WhyleloopSDK({
    required this.appId,
    this.baseURL = 'https://whyleloop.app',
  });
  
  /// Restore pending links for a user after app installation
  /// 
  /// Call this method on app launch to retrieve any pending deep links
  /// that were clicked before the app was installed.
  /// 
  /// [userEmail] - User email for identification (optional)
  /// Returns a list of restored links
  Future<List<RestoredLink>> restorePendingLinks({
    String? userEmail,
  }) async {
    try {
      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'appId': appId,
      };
      
      if (userEmail != null) {
        requestBody['userEmail'] = userEmail;
      } else {
        requestBody['deviceFingerprint'] = await _getDeviceFingerprint();
      }
      
      // Make API request
      final response = await http.post(
        Uri.parse('$baseURL/api/deferred-deep-linking/restore'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> linksData = responseData['restoredLinks'];
          return linksData.map((linkData) => RestoredLink.fromJson(linkData)).toList();
        } else {
          throw Exception('API returned error: ${responseData['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('$_tag: Error restoring pending links: $e');
      rethrow;
    }
  }
  
  /// Restore pending links for anonymous users using device fingerprint
  /// 
  /// Returns a list of restored links
  Future<List<RestoredLink>> restorePendingLinksForAnonymous() async {
    return restorePendingLinks();
  }
  
  /// Create a dynamic link for the current page
  /// 
  /// Generates a shareable link that deep links to the page where the user is currently viewing.
  /// When any user clicks this link, they will be navigated to the specified destination.
  /// 
  /// Example usage:
  /// - User is on a product page: `/product/123`
  /// - User clicks share button
  /// - App calls: `sdk.createLink(destination: '/product/123')`
  /// - Generated link, when clicked, navigates to `/product/123`
  /// 
  /// [destination] - The current page path/route in your app (e.g., "/product/123")
  ///                 This should be the path where the user is when creating the link.
  /// [metadata] - Optional metadata (UTM parameters, custom data, etc.)
  /// Returns a CreatedLink with the generated link URL
  Future<CreatedLink> createLink({
    required String destination,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'appId': appId,
        'destination': destination,
      };
      
      if (metadata != null && metadata.isNotEmpty) {
        requestBody['metadata'] = metadata;
      }
      
      // Make API request
      final response = await http.post(
        Uri.parse('$baseURL/api/links/create-sdk'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          return CreatedLink.fromJson(responseData['link']);
        } else {
          throw Exception('API returned error: ${responseData['error'] ?? 'Unknown error'}');
        }
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('$_tag: Error creating link: $e');
      rethrow;
    }
  }
  
  /// Get link details by slug
  /// 
  /// When your app receives a deep link URL, extract the slug and call this method
  /// to get the link details including destination and parameters.
  /// 
  /// [slug] - The slug from the deep link URL (e.g., "1734567890-abc123")
  /// [hostname] - Optional hostname from the URL (for custom domain support)
  /// Returns a LinkDetails with destination and parameters
  Future<LinkDetails> getLinkBySlug({
    required String slug,
    String? hostname,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'slug': slug,
        'appId': appId,
      };
      if (hostname != null) {
        queryParams['hostname'] = hostname;
      }
      
      final uri = Uri.parse('$baseURL/api/links/get-by-slug')
          .replace(queryParameters: queryParams);
      
      // Make API request
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          return LinkDetails.fromJson(responseData['link']);
        } else {
          throw Exception('API returned error: ${responseData['error'] ?? 'Unknown error'}');
        }
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('$_tag: Error getting link by slug: $e');
      rethrow;
    }
  }
  
  /// Get device fingerprint for anonymous user identification
  Future<String> _getDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    String? fingerprint = prefs.getString(_prefsKey);
    
    if (fingerprint == null) {
      fingerprint = await _generateDeviceFingerprint();
      await prefs.setString(_prefsKey, fingerprint);
    }
    
    return fingerprint;
  }
  
  /// Generate a unique device fingerprint
  Future<String> _generateDeviceFingerprint() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceInfoString = '';
      
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceInfoString = '${androidInfo.id}_${androidInfo.model}_${androidInfo.manufacturer}_${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceInfoString = '${iosInfo.identifierForVendor}_${iosInfo.model}_${iosInfo.systemName}_${iosInfo.systemVersion}';
      } else {
        // Fallback for other platforms
        deviceInfoString = DateTime.now().millisecondsSinceEpoch.toString();
      }
      
      // Create a simple hash (in production, use proper hashing)
      return deviceInfoString.hashCode.toString();
    } catch (e) {
      print('$_tag: Error generating device fingerprint: $e');
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
}

/// Data class for created link
class CreatedLink {
  final String id;
  final String slug;
  final String url;
  final String destination;
  final Map<String, dynamic> metadata;
  
  CreatedLink({
    required this.id,
    required this.slug,
    required this.url,
    required this.destination,
    required this.metadata,
  });
  
  /// Create CreatedLink from JSON
  factory CreatedLink.fromJson(Map<String, dynamic> json) {
    return CreatedLink(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      url: json['url'] ?? '',
      destination: json['destination'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'url': url,
      'destination': destination,
      'metadata': metadata,
    };
  }
  
  @override
  String toString() {
    return 'CreatedLink(id: $id, url: $url, destination: $destination)';
  }
}

/// Data class for restored link
class RestoredLink {
  final String pendingLinkId;
  final String originalUrl;
  final String destinationUrl;
  final String? destinationPath; // Path without parameters (e.g., "/product/123")
  final String? destination; // Full destination with parameters (e.g., "/product/123?utm_source=share")
  final Map<String, dynamic>? parameters; // Extracted parameters for easy access
  final Map<String, dynamic> metadata;
  final String linkId;
  
  RestoredLink({
    required this.pendingLinkId,
    required this.originalUrl,
    required this.destinationUrl,
    this.destinationPath,
    this.destination,
    this.parameters,
    required this.metadata,
    required this.linkId,
  });
  
  /// Create RestoredLink from JSON
  factory RestoredLink.fromJson(Map<String, dynamic> json) {
    return RestoredLink(
      pendingLinkId: json['pending_link_id'] ?? '',
      originalUrl: json['original_url'] ?? '',
      destinationUrl: json['destination_url'] ?? '',
      destinationPath: json['destination_path'] as String?,
      destination: json['destination'] as String?,
      parameters: json['parameters'] != null 
        ? Map<String, dynamic>.from(json['parameters'] as Map)
        : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      linkId: json['link_id'] ?? '',
    );
  }
  
  /// Get UTM source from metadata
  String? get utmSource => metadata['utm_source']?.toString();
  
  /// Get UTM campaign from metadata
  String? get utmCampaign => metadata['utm_campaign']?.toString();
  
  /// Get UTM medium from metadata
  String? get utmMedium => metadata['utm_medium']?.toString();
  
  /// Get UTM term from metadata
  String? get utmTerm => metadata['utm_term']?.toString();
  
  /// Get UTM content from metadata
  String? get utmContent => metadata['utm_content']?.toString();
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'pending_link_id': pendingLinkId,
      'original_url': originalUrl,
      'destination_url': destinationUrl,
      'metadata': metadata,
      'link_id': linkId,
    };
  }
  
  @override
  String toString() {
    return 'RestoredLink(pendingLinkId: $pendingLinkId, originalUrl: $originalUrl, destinationUrl: $destinationUrl, linkId: $linkId)';
  }
}

/// Data class for link details
class LinkDetails {
  final String id;
  final String slug;
  final String destinationWebUrl;
  final String destinationPath; // Path without parameters
  final String destination; // Full destination with parameters
  final Map<String, dynamic> parameters; // Extracted parameters
  final Map<String, dynamic> metadata;
  
  LinkDetails({
    required this.id,
    required this.slug,
    required this.destinationWebUrl,
    required this.destinationPath,
    required this.destination,
    required this.parameters,
    required this.metadata,
  });
  
  /// Create LinkDetails from JSON
  factory LinkDetails.fromJson(Map<String, dynamic> json) {
    return LinkDetails(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      destinationWebUrl: json['destination_web_url'] ?? '',
      destinationPath: json['destination_path'] ?? '',
      destination: json['destination'] ?? '',
      parameters: json['parameters'] != null
        ? Map<String, dynamic>.from(json['parameters'] as Map)
        : {},
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  
  @override
  String toString() {
    return 'LinkDetails(id: $id, destination: $destination)';
  }
}

/// Callback function type for restore operations
typedef RestoreCallback = void Function(List<RestoredLink> restoredLinks, Exception? error);

/// Extension to provide callback-based API for easier integration
extension WhyleloopSDKExtension on WhyleloopSDK {
  /// Restore pending links with callback
  /// 
  /// [userEmail] - User email for identification (optional)
  /// [callback] - Callback function to handle results
  Future<void> restorePendingLinksWithCallback({
    String? userEmail,
    required RestoreCallback callback,
  }) async {
    try {
      final restoredLinks = await restorePendingLinks(userEmail: userEmail);
      callback(restoredLinks, null);
    } catch (e) {
      callback([], e is Exception ? e : Exception(e.toString()));
    }
  }
  
  /// Restore pending links for anonymous users with callback
  /// 
  /// [callback] - Callback function to handle results
  Future<void> restorePendingLinksForAnonymousWithCallback({
    required RestoreCallback callback,
  }) async {
    try {
      final restoredLinks = await restorePendingLinksForAnonymous();
      callback(restoredLinks, null);
    } catch (e) {
      callback([], e is Exception ? e : Exception(e.toString()));
    }
  }
  
  /// Create a dynamic link with callback
  /// 
  /// [destination] - The current page path/route where the user is when creating the link
  ///                 When the link is clicked, users will navigate to this destination.
  /// [metadata] - Optional metadata (UTM parameters, etc.)
  /// [callback] - Callback function to handle results
  Future<void> createLinkWithCallback({
    required String destination,
    Map<String, dynamic>? metadata,
    required CreateLinkCallback callback,
  }) async {
    try {
      final createdLink = await createLink(
        destination: destination,
        metadata: metadata,
      );
      callback(createdLink, null);
    } catch (e) {
      callback(CreatedLink(
        id: '',
        slug: '',
        url: '',
        destination: destination,
        metadata: metadata ?? {},
      ), e is Exception ? e : Exception(e.toString()));
    }
  }
}

/// Callback function type for create link operations
typedef CreateLinkCallback = void Function(CreatedLink link, Exception? error);

/*
// Usage Example in your main.dart or app initialization:

import 'package:whyleloop_sdk/whyleloop_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WhyleloopSDK whyleloopSDK;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the SDK
    whyleloopSDK = WhyleloopSDK(appId: 'your-app-id');
    
    // Restore pending links on app launch
    _restorePendingLinks();
  }
  
  Future<void> _restorePendingLinks() async {
    try {
      // Get user email (implement your own method)
      String? userEmail = await getCurrentUserEmail();
      
      List<RestoredLink> restoredLinks;
      if (userEmail != null) {
        // Restore for authenticated users
        restoredLinks = await whyleloopSDK.restorePendingLinks(userEmail: userEmail);
      } else {
        // Restore for anonymous users
        restoredLinks = await whyleloopSDK.restorePendingLinksForAnonymous();
      }
      
      if (restoredLinks.isNotEmpty) {
        print('WhyleloopSDK: Restored ${restoredLinks.length} pending links');
        
        // Handle each restored link
        for (RestoredLink link in restoredLinks) {
          _handleRestoredLink(link);
        }
      }
    } catch (e) {
      print('WhyleloopSDK: Failed to restore pending links: $e');
    }
  }
  
  void _handleRestoredLink(RestoredLink link) {
    // Parse the destination URL and navigate accordingly
    try {
      final uri = Uri.parse(link.destinationUrl);
      
      // Extract UTM parameters
      final utmSource = link.utmSource;
      final utmCampaign = link.utmCampaign;
      
      // Navigate to the appropriate screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToDestination(uri, utmSource, utmCampaign);
      });
      
    } catch (e) {
      print('WhyleloopSDK: Error handling restored link: $e');
    }
  }
  
  void _navigateToDestination(Uri uri, String? utmSource, String? utmCampaign) {
    // Implement your navigation logic here
    // Example: Navigate to specific product, category, or screen
    print('WhyleloopSDK: Navigating to: ${uri.toString()}');
    print('WhyleloopSDK: UTM Source: ${utmSource ?? "none"}');
    print('WhyleloopSDK: UTM Campaign: ${utmCampaign ?? "none"}');
    
    // Example navigation logic:
    if (uri.path.contains('/product/')) {
      final productId = uri.pathSegments.last;
      // Navigate to product screen
      // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductScreen(productId: productId)));
    } else if (uri.path.contains('/category/')) {
      final categoryId = uri.pathSegments.last;
      // Navigate to category screen
      // Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryScreen(categoryId: categoryId)));
    } else {
      // Default navigation
      // Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }
  
  // Implement your own method to get current user email
  Future<String?> getCurrentUserEmail() async {
    // Return user email if authenticated, null otherwise
    return null; // Replace with your implementation
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
      ),
      body: Center(
        child: Text('Welcome to My App!'),
      ),
    );
  }
}

// Alternative usage with callbacks:

void _restorePendingLinksWithCallback() {
  whyleloopSDK.restorePendingLinksWithCallback(
    userEmail: getCurrentUserEmail(),
    callback: (restoredLinks, error) {
      if (error != null) {
        print('WhyleloopSDK: Error: $error');
      } else {
        print('WhyleloopSDK: Restored ${restoredLinks.length} pending links');
        for (RestoredLink link in restoredLinks) {
          _handleRestoredLink(link);
        }
      }
    },
  );
}
*/
