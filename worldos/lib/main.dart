import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/responsive_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WorldOSApp());
}

class WorldOSApp extends StatelessWidget {
  const WorldOSApp({super.key});

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
