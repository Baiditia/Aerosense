import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'database_helper.dart';
import 'models/aqi_history.dart';

const String _bgTaskName = 'aerosense_aqi_fetch';
const String _bgTaskTag = 'aerosense_periodic';
String get _waqiApiKey => dotenv.env['WAQI_API_KEY'] ?? '';
const String _locationsKey = 'bg_monitored_locations';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      debugPrint('[AeroSense BG] Task started: $taskName');
      await dotenv.load(fileName: ".env");

      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList(_locationsKey) ?? [];

      if (locationsJson.isEmpty) {
        debugPrint('[AeroSense BG] No locations to fetch, skipping.');
        return Future.value(true);
      }

      final db = DatabaseHelper();

      for (final json in locationsJson) {
        try {
          final loc = jsonDecode(json) as Map<String, dynamic>;
          final name = loc['name'] as String;
          final lat = (loc['lat'] as num).toDouble();
          final lon = (loc['lon'] as num).toDouble();

          final pm25 = await _fetchPm25(lat, lon);

          if (pm25 > 0) {
            final saved = await db.saveIfNew(
              AqiHistoryRecord(
                location: name,
                pm25: pm25,
                lat: lat,
                lon: lon,
                recordedAt: DateTime.now(),
              ),
            );
            debugPrint(
              '[AeroSense BG] $name → PM2.5=$pm25 ${saved ? "(saved)" : "(skipped, already exists today)"}',
            );
          } else {
            debugPrint('[AeroSense BG] $name → failed to fetch PM2.5');
          }
        } catch (e) {
          debugPrint('[AeroSense BG] Error processing location: $e');
        }
      }

      debugPrint('[AeroSense BG] Task completed successfully.');
      return Future.value(true);
    } catch (e) {
      debugPrint('[AeroSense BG] Task failed: $e');
      return Future.value(false);
    }
  });
}

Future<int> _fetchPm25(double lat, double lon) async {
  try {
    final url = Uri.parse(
      'https://api.waqi.info/feed/geo:$lat;$lon/?token=$_waqiApiKey',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        final aqi = data['data']['iaqi']['pm25']?['v'];
        if (aqi != null) return double.parse(aqi.toString()).round();
      }
    }
  } catch (e) {
    debugPrint('[AeroSense BG] API error: $e');
  }
  return 0;
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);

    await Workmanager().registerPeriodicTask(
      _bgTaskName,
      _bgTaskName,
      tag: _bgTaskTag,
      frequency: const Duration(hours: 6),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 10),
    );

    debugPrint('[AeroSense] Background service initialized (every ~6 hours).');
  }

  static Future<void> saveLocations(List<LocationInfo> locations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = locations
        .map((l) => jsonEncode({'name': l.name, 'lat': l.lat, 'lon': l.lon}))
        .toList();
    await prefs.setStringList(_locationsKey, jsonList);
    debugPrint(
      '[AeroSense] Saved ${jsonList.length} locations for background fetch.',
    );
  }
}

class LocationInfo {
  final String name;
  final double lat;
  final double lon;

  const LocationInfo({
    required this.name,
    required this.lat,
    required this.lon,
  });
}
