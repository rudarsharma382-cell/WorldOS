import 'dart:convert';
import 'package:flutter/services.dart';

/// Centralized Environment Configuration for WorldOS.
/// Reads values from compile-time defines (--dart-define / --dart-define-from-file)
/// and optionally hydrates from local assets/.env if bundled.
class EnvConfig {
  static String mapboxToken = const String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: ''),
  );

  static String hfToken = const String.fromEnvironment(
    'HF_TOKEN',
    defaultValue: String.fromEnvironment('HUGGINGFACE_TOKEN', defaultValue: ''),
  );

  static String nasaApiKey = const String.fromEnvironment(
    'NASA_API_KEY',
    defaultValue: 'DEMO_KEY',
  );

  static String unsplashKey = const String.fromEnvironment(
    'UNSPLASH_KEY',
    defaultValue: String.fromEnvironment('UNSPLASH_ACCESS_KEY', defaultValue: ''),
  );

  /// Initializes configuration from bundled assets/.env if available
  static Future<void> init() async {
    try {
      final envData = await rootBundle.loadString('assets/.env');
      final lines = const LineSplitter().convert(envData);
      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final eqIdx = line.indexOf('=');
        if (eqIdx <= 0) continue;

        final key = line.substring(0, eqIdx).trim();
        var val = line.substring(eqIdx + 1).trim();
        // Strip single or double quotes
        if ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'"))) {
          if (val.length >= 2) {
            val = val.substring(1, val.length - 1);
          }
        }

        if (key == 'MAPBOX_ACCESS_TOKEN' || key == 'MAPBOX_TOKEN') {
          if (mapboxToken.isEmpty) mapboxToken = val;
        } else if (key == 'HF_TOKEN' || key == 'HUGGINGFACE_TOKEN') {
          if (hfToken.isEmpty) hfToken = val;
        } else if (key == 'NASA_API_KEY') {
          if (nasaApiKey == 'DEMO_KEY' || nasaApiKey.isEmpty) nasaApiKey = val;
        } else if (key == 'UNSPLASH_ACCESS_KEY' || key == 'UNSPLASH_KEY') {
          if (unsplashKey.isEmpty) unsplashKey = val;
        }
      }
    } catch (_) {
      // Graceful fallback if assets/.env is not bundled or absent
    }
  }
}
