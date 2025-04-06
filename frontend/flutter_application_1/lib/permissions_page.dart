import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this line
import 'package:overlay_support/overlay_support.dart';
import 'app_permission_item.dart';
import 'floating_alert_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  _PermissionsPageState createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> with WidgetsBindingObserver{
  bool isComplete = false;
  bool isMonitoring = false;
  List<String> selectedApps = [];
  OverlaySupportEntry? _overlayEntry;

  // Inside _PermissionsPageState class (at the top, with other variables)
  final MethodChannel _channel = MethodChannel('com.yourproject/overlay');

  final List<Map<String, dynamic>> socialMediaApps = [
    {
      'name': 'Facebook',
      'package': 'com.facebook.katana',
      'icon':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/2021_Facebook_icon.svg/800px-2021_Facebook_icon.svg.png',
      'description': 'Access to monitor messages and posts for misinformation.',
      'color': Colors.blue,
      'selected': false,
    },
    {
      'name': 'Instagram',
      'package': 'com.instagram.android',
      'icon':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Instagram_logo_2016.svg/768px-Instagram_logo_2016.svg.png',
      'description':
          'Access to monitor direct messages and comments for misinformation.',
      'color': Colors.purple,
      'selected': false,
    },
    {
      'name': 'X',
      'package': 'com.twitter.android',
      'icon':
          "https://abs.twimg.com/responsive-web/client-web/icon-ios.b1fc727a.png",
      'description':
          'Access to monitor tweets and direct messages for misinformation.',
      'color': Colors.black,
      'selected': false,
    },
    {
      'name': 'WhatsApp',
      'package': 'com.whatsapp',
      'icon':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/512px-WhatsApp.svg.png',
      'description': 'Access to monitor messages for dangerous misinformation.',
      'color': Colors.green,
      'selected': false,
    },
  ];

  Future<void> _saveToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('user_settings')
          .doc(user.uid)
          .set({
        'selected_apps': selectedApps,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firebase save error: $e');
    }
  }

  Future<void> _loadFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('user_settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final savedApps = List<String>.from(doc.data()?['selected_apps'] ?? []);
        setState(() {
          for (var app in socialMediaApps) {
            app['selected'] = savedApps.contains(app['name']);
          }
        });
      }
    } catch (e) {
      debugPrint('Firebase load error: $e');
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      socialMediaApps[index]['selected'] = !socialMediaApps[index]['selected'];
    });
  }

  // Add these methods in the same class
  Future<bool> checkOverlayPermission() async {
    return await _channel.invokeMethod('checkOverlayPermission');
  }

  Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFromFirebase(); // Add this line
  }

  Future<void> _saveSelection() async {
    selectedApps = socialMediaApps
        .where((app) => app['selected'])
        .map((app) => app['name'].toString())
        .toList();

    if (selectedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one app to monitor.')),
      );
      return;
    }

    try {
      if (!await checkOverlayPermission()) {
        await requestOverlayPermission();
        // Wait a moment for permission to be granted
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (await checkOverlayPermission()) {
        await _saveToFirebase();
        setState(() {
          isComplete = true;
          isMonitoring = true;
        });
        _showFloatingButton();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Overlay permission is required')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // void _startMonitoring() {
  //   if (isMonitoring) {
  //     _showFloatingButton(); // Use the dedicated method instead
  //   }
  // }

  void _showFloatingButton() {
    _overlayEntry = showOverlay(
      (context, progress) => Positioned(
        bottom: 100,
        right: 20,
        child: FloatingAlertButton(
          text: 'Scan',
          onPressed: () async {
            showSimpleNotification(
              const Text("Scanning content..."),
              background: Colors.blue,
            );

            await Future.delayed(const Duration(seconds: 2));

            // Replace this with actual scanning logic:
            final fakeContent = "Sample post with potential misinformation";
            final isFake = fakeContent.contains("misinformation");

            showSimpleNotification(
              Text(isFake
                  ? "Potential Misinformation Detected!"
                  : "Content appears factual"),
              background: isFake ? Colors.red : Colors.green,
              duration: const Duration(seconds: 5),
            );
          },
        ),
      ),
      key: const ValueKey('scan_button'), // Unique key for the overlay
      duration: null, // Makes it persistent
    );
    // if (defaultTargetPlatform == TargetPlatform.android) {
    //    await SystemChannels.platform.invokeMethod('SystemNavigator.enableSystemUIOverlays');
    // }
  }

  void _hideFloatingButton() {
    _overlayEntry?.dismiss();
    _overlayEntry = null;
  }

  // void _scanContent() {
  //   showSimpleNotification(
  //     const Text("Scanning content..."),
  //     background: Colors.blue,
  //   );
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlayEntry?.dismiss(); // Properly remove overlay
    _overlayEntry = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isMonitoring) {
      _showFloatingButton();
    } else if (state == AppLifecycleState.paused) {
      _hideFloatingButton();
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Social Media Platforms"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: isComplete
              ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isMonitoring ? Icons.security : Icons.check_circle,
                          size: 48,
                          color: isMonitoring ? Colors.blue : Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isMonitoring
                              ? 'Monitoring Active'
                              : 'Setup Complete!',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isMonitoring
                              ? 'CyberGuard is now monitoring your selected apps. Look for the floating button to scan content.'
                              : 'CyberGuard is ready to monitor your social media accounts for misinformation.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (isMonitoring) ...[
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isMonitoring = false;
                                _hideFloatingButton();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Stop Monitoring'),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/');
                          },
                          child: const Text('Go to Dashboard'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    const Icon(Icons.security, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'App Permissions',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Grant access to analyze content across your social media accounts to detect misinformation.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: socialMediaApps.length,
                        itemBuilder: (context, index) {
                          final app = socialMediaApps[index];
                          return AppPermissionItem(
                            icon: app['icon'],
                            name: app['name'],
                            description: app['description'],
                            color: app['color'],
                            isSelected: app['selected'],
                            onToggle: () => _toggleSelection(index),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveSelection,
                      child: const Text('Start Monitoring'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: You need to grant "Display over other apps" permission',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
