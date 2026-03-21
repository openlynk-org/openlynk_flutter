// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:openlynk_sdk/openlynk_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Openlynk Example',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late OpenlynkSDK openlynkSDK;

  @override
  void initState() {
    super.initState();

    openlynkSDK = OpenlynkSDK(
      appId: 'your-app-id',
      apiKey: 'your-api-key',
      config: OpenlynkSDKConfig(
        autoRestoreOnInit: true,
        userEmailProvider: () => getCurrentUserEmail(),
        onRestoredLinks: (restored) {
          for (final link in restored) {
            _navigateFromRestoredLink(link);
          }
        },
        onDeepLink: (parsed) {
          _navigateFromParsedLink(parsed);
        },
      ),
    );
    openlynkSDK.init();
  }

  @override
  void dispose() {
    openlynkSDK.dispose();
    super.dispose();
  }

  void _navigateFromRestoredLink(RestoredLink link) {
    final destination = link.destination ?? link.destinationUrl;
    final uri = Uri.parse(destination);
    final params = link.parameters ?? link.metadata;
    _navigateToDestination(uri, params);
  }

  void _navigateFromParsedLink(ParsedDeepLink parsed) {
    final uri = Uri.parse(parsed.destination);
    _navigateToDestination(uri, parsed.parameters);
  }

  void _navigateToDestination(Uri uri, Map<String, dynamic> params) {
    if (uri.path.contains('/product/')) {
      final productId = uri.pathSegments.last;
      print('Navigate to product: $productId with params: $params');
    } else {
      print('Navigate to: ${uri.path}');
    }
  }

  Future<String?> getCurrentUserEmail() async => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Openlynk Example')),
      body: Center(child: Text('Welcome!')),
    );
  }
}
