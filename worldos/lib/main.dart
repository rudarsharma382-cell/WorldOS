import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/env_config.dart';
import 'ui/responsive_layout.dart';

@JS('signalAppReady')
external void _signalAppReady();

void notifyBootReady() {
  if (kIsWeb) {
    try {
      _signalAppReady();
    } catch (_) {
      // Graceful no-op on non-web platforms
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.init();
  runApp(const WorldOSApp());
}

class WorldOSApp extends StatefulWidget {
  const WorldOSApp({super.key});

  @override
  State<WorldOSApp> createState() => _WorldOSAppState();
}

class _WorldOSAppState extends State<WorldOSApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyBootReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorldOS — Real-Time Earth Operating System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF04060C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFFF43F5E),
          surface: Color(0xFF0C1017),
        ),
      ),
      home: const ResponsiveWorldOSLayout(),
    );
  }
}
