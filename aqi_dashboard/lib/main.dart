import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'database_helper.dart';
import 'models/aqi_history.dart';
import 'screens/history_screen.dart';
import 'background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('id_ID', null);

  if (!kIsWeb) {
    await BackgroundService.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AeroSense',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0A0F1E),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6ECFF6),
          surface: const Color(0xFF141929),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;

  final GlobalKey<HistoryScreenState> _historyKey =
      GlobalKey<HistoryScreenState>();

  late final List<Widget> _screens = [
    const AqiDashboard(),
    HistoryScreen(key: _historyKey),
  ];

  void _changeTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) _historyKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _AeroBottomBar(
        currentIndex: _currentIndex,
        onTap: _changeTab,
      ),
    );
  }
}

class _AeroBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _AeroBottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1220),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BarItem(
                icon: Icons.air_rounded,
                label: 'Beranda',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _BarItem(
                icon: Icons.timeline_rounded,
                label: 'Riwayat',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6ECFF6).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF6ECFF6) : Colors.white38,
              size: 22,
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6ECFF6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AqiData {
  final String location;
  final int pm25;
  final double? lat;
  final double? lon;

  AqiData({required this.location, required this.pm25, this.lat, this.lon});

  AqiData copyWith({String? location, int? pm25, double? lat, double? lon}) =>
      AqiData(
        location: location ?? this.location,
        pm25: pm25 ?? this.pm25,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
      );

  List<Color> getSkyGradient() {
    if (pm25 <= 50)
      return [
        const Color(0xFF1B6CA8),
        const Color(0xFF24B5C4),
        const Color(0xFF70E8D4),
      ];
    if (pm25 <= 100)
      return [
        const Color(0xFF7B5E00),
        const Color(0xFFD4A017),
        const Color(0xFFFFD97D),
      ];
    if (pm25 <= 150)
      return [
        const Color(0xFF8B3A00),
        const Color(0xFFD4601A),
        const Color(0xFFFF9A44),
      ];
    return [
      const Color(0xFF6B0000),
      const Color(0xFFCC1A1A),
      const Color(0xFFFF5252),
    ];
  }

  Color getAccentColor() {
    if (pm25 <= 50) return const Color(0xFF6ECFF6);
    if (pm25 <= 100) return const Color(0xFFFFD97D);
    if (pm25 <= 150) return const Color(0xFFFF9A44);
    return const Color(0xFFFF5252);
  }

  String getStatus() {
    if (pm25 <= 50) return 'Udara Bersih';
    if (pm25 <= 100) return 'Kualitas Sedang';
    if (pm25 <= 150) return 'Tidak Sehat';
    return 'Sangat Berbahaya';
  }

  Icon getStatusIcon() {
    if (pm25 <= 50)
      return const Icon(Icons.eco, color: Colors.green, size: 44.0);
    if (pm25 <= 100)
      return const Icon(
        Icons.sentiment_neutral,
        color: Colors.amber,
        size: 44.0,
      );
    if (pm25 <= 150)
      return const Icon(Icons.masks, color: Colors.orange, size: 44.0);
    return const Icon(Icons.dangerous, color: Colors.red, size: 44.0);
  }

  String getAdvice() {
    if (pm25 <= 50) return 'Aktivitas luar ruangan aman';
    if (pm25 <= 100) return 'Kelompok sensitif harap berhati-hati';
    if (pm25 <= 150) return 'Gunakan masker saat keluar';
    return 'Hindari aktivitas luar ruangan';
  }

  IconData getIcon() {
    if (pm25 <= 50) return Icons.sentiment_very_satisfied_rounded;
    if (pm25 <= 100) return Icons.sentiment_neutral_rounded;
    if (pm25 <= 150) return Icons.sentiment_dissatisfied_rounded;
    return Icons.coronavirus_rounded;
  }

  String getAqiCategory() {
    if (pm25 <= 50) return 'BAIK';
    if (pm25 <= 100) return 'SEDANG';
    if (pm25 <= 150) return 'BURUK';
    return 'BERBAHAYA';
  }
}

class AqiDashboard extends StatefulWidget {
  const AqiDashboard({super.key});

  @override
  State<AqiDashboard> createState() => _AqiDashboardState();
}

class _AqiDashboardState extends State<AqiDashboard>
    with SingleTickerProviderStateMixin {
  static String get _waqiApiKey => dotenv.env['WAQI_API_KEY'] ?? '';
  static const _savedCitiesKey = 'saved_city_names';

  final _db = DatabaseHelper();
  AqiData myLocation = AqiData(location: 'Mencari lokasi...', pm25: 0);
  StreamSubscription<Position>? _positionStream;
  bool _isLoading = true;
  late AnimationController _shimmerCtrl;

  static final List<AqiData> _allCities = [
    AqiData(
      location: 'Kemayoran, Jakarta',
      pm25: 0,
      lat: -6.1610,
      lon: 106.8450,
    ),
    AqiData(
      location: 'Surabaya, Jawa Timur',
      pm25: 0,
      lat: -7.2592,
      lon: 112.6778,
    ),
    AqiData(
      location: 'Bandung, Jawa Barat',
      pm25: 0,
      lat: -6.9175,
      lon: 107.6191,
    ),
    AqiData(
      location: 'Medan, Sumatera Utara',
      pm25: 0,
      lat: 3.5952,
      lon: 98.6722,
    ),
    AqiData(
      location: 'Makassar, Sulawesi Selatan',
      pm25: 0,
      lat: -5.1476,
      lon: 119.4327,
    ),
    AqiData(location: 'Denpasar, Bali', pm25: 0, lat: -8.6705, lon: 115.2126),
    AqiData(
      location: 'Malang, Jawa Timur',
      pm25: 0,
      lat: -8.0023,
      lon: 112.6309,
    ),
    AqiData(
      location: 'Palembang, Sumatera Selatan',
      pm25: 0,
      lat: -3.4344,
      lon: 104.2305,
    ),
    AqiData(
      location: 'Samarinda, Kalimantan Timur',
      pm25: 0,
      lat: -0.4930,
      lon: 117.1490,
    ),
    AqiData(location: 'Aceh Besar, Aceh', pm25: 0, lat: 5.3833, lon: 95.5166),
    AqiData(location: 'Nabire, Papua', pm25: 0, lat: 2.5916, lon: 140.6690),
  ];

  static const _defaultSavedCityNames = [
    'Kemayoran, Jakarta',
    'Surabaya, Jawa Timur',
  ];

  List<AqiData> savedCities = [];
  List<AqiData> availableCities = [];

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _db.deleteOldRecords(keepDays: 60);
    _initLocationService();
    _loadSavedCities().then((_) => _refreshAllCitiesData());
  }

  Future<void> _loadSavedCities() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> names;

    if (prefs.containsKey(_savedCitiesKey)) {
      names = prefs.getStringList(_savedCitiesKey) ?? _defaultSavedCityNames;
    } else {
      names = List<String>.from(_defaultSavedCityNames);
    }

    final nameSet = names.toSet();
    final saved = <AqiData>[];
    final available = <AqiData>[];

    for (final name in names) {
      final city = _allCities.firstWhere(
        (c) => c.location == name,
        orElse: () => AqiData(location: name, pm25: 0),
      );
      saved.add(city);
    }

    for (final city in _allCities) {
      if (!nameSet.contains(city.location)) {
        available.add(city);
      }
    }

    if (mounted) {
      setState(() {
        savedCities = saved;
        availableCities = available;
      });
    }
  }

  Future<void> _persistSavedCities() async {
    final prefs = await SharedPreferences.getInstance();
    final names = savedCities.map((c) => c.location).toList();
    await prefs.setStringList(_savedCitiesKey, names);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<int> _fetchAqiFromApi(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.waqi.info/feed/geo:$lat;$lon/?token=$_waqiApiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          final aqi = data['data']['iaqi']['pm25']?['v'];
          if (aqi != null) return double.parse(aqi.toString()).round();
        }
      }
    } catch (e) {
      debugPrint('AQICN error: $e');
    }
    return 0;
  }

  Future<int> _fetchAndSave({
    required double lat,
    required double lon,
    required String locationName,
  }) async {
    final pm25 = await _fetchAqiFromApi(lat, lon);
    if (pm25 > 0) {
      await _db.saveIfNew(
        AqiHistoryRecord(
          location: locationName,
          pm25: pm25,
          lat: lat,
          lon: lon,
          recordedAt: DateTime.now(),
        ),
      );
    }
    return pm25;
  }

  Future<void> _refreshAllCitiesData() async {
    for (int i = 0; i < savedCities.length; i++) {
      final city = savedCities[i];
      final aqi = await _fetchAndSave(
        lat: city.lat!,
        lon: city.lon!,
        locationName: city.location,
      );
      if (mounted)
        setState(() {
          savedCities[i] = city.copyWith(pm25: aqi);
        });
    }
    for (int i = 0; i < availableCities.length; i++) {
      final city = availableCities[i];
      final aqi = await _fetchAqiFromApi(city.lat!, city.lon!);
      if (mounted)
        setState(() {
          availableCities[i] = city.copyWith(pm25: aqi);
        });
    }

    _saveLocationsForBackground();
  }

  void _saveLocationsForBackground() {
    if (kIsWeb) return;
    final locations = <LocationInfo>[];

    if (myLocation.lat != null &&
        myLocation.lon != null &&
        myLocation.pm25 > 0) {
      locations.add(
        LocationInfo(
          name: myLocation.location,
          lat: myLocation.lat!,
          lon: myLocation.lon!,
        ),
      );
    }

    for (final city in savedCities) {
      if (city.lat != null && city.lon != null) {
        locations.add(
          LocationInfo(name: city.location, lat: city.lat!, lon: city.lon!),
        );
      }
    }

    BackgroundService.saveLocations(locations);
  }

  Future<void> _initLocationService() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        myLocation = AqiData(location: 'GPS tidak aktif', pm25: 0);
        _isLoading = false;
      });
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        myLocation = AqiData(location: 'Izin lokasi ditolak', pm25: 0);
        _isLoading = false;
      });
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition();
      await _updateLocation(position);
    } catch (e) {
      debugPrint('Error: $e');
    }
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_updateLocation);
  }

  Future<void> _updateLocation(Position position) async {
    final lat = position.latitude;
    final lon = position.longitude;
    String cityName =
        'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
    if (kIsWeb) {
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
        );
        final response = await http
            .get(
              url,
              headers: {
                'Accept-Language': 'id',
                'User-Agent': 'AeroSenseApp/1.0',
              },
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['address'];
          final parts = [
            data['suburb'],
            data['city'] ?? data['town'] ?? data['village'],
            data['state'],
          ].where((s) => s != null && s.toString().trim().isNotEmpty).toList();
          if (parts.isNotEmpty) cityName = parts.join(', ');
        }
      } catch (_) {}
    } else {
      try {
        final placemarks = await placemarkFromCoordinates(
          lat,
          lon,
        ).timeout(const Duration(seconds: 10));
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s!.trim().isNotEmpty).toList();
          if (parts.isNotEmpty) cityName = parts.join(', ');
        }
      } catch (_) {}
    }
    final pm25 = await _fetchAndSave(
      lat: lat,
      lon: lon,
      locationName: cityName,
    );
    if (mounted) {
      setState(() {
        myLocation = AqiData(
          location: cityName,
          pm25: pm25,
          lat: lat,
          lon: lon,
        );
        _isLoading = false;
      });
      _saveLocationsForBackground();
    }
  }

  String get lastUpdated {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}, ${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')} WIB';
  }

  void _showAddCityDialog() {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddCitySheet(
        availableCities: availableCities,
        onAdd: (city, index) {
          setState(() {
            savedCities.add(city);
            availableCities.removeAt(index);
          });
          _persistSavedCities();
          Navigator.pop(context);
          if (city.lat != null && city.lon != null) {
            _fetchAndSave(
              lat: city.lat!,
              lon: city.lon!,
              locationName: city.location,
            );
          }
          _saveLocationsForBackground();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AeroSense',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'Kualitas Udara Real-time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showAddCityDialog,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: GestureDetector(
                    onTap: () {
                      if (myLocation.location != 'Mencari lokasi...' &&
                          myLocation.pm25 > 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationHistoryDetail(
                              location: myLocation.location,
                              days: 60,
                            ),
                          ),
                        );
                      }
                    },
                    child: _HeroWeatherCard(
                      data: myLocation,
                      isLoading: _isLoading,
                      lastUpdated: lastUpdated,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bookmark_rounded,
                        size: 14,
                        color: Color(0xFF6ECFF6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LOKASI PANTAUAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6ECFF6).withOpacity(0.8),
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (savedCities.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_location_alt_outlined,
                            size: 56,
                            color: Colors.white12,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada lokasi pantauan',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + untuk menambahkan',
                            style: TextStyle(
                              color: Colors.white12,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final data = savedCities[index];
                    return Dismissible(
                      key: Key(data.location),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                      onDismissed: (_) {
                        setState(() {
                          savedCities.removeAt(index);
                          availableCities.add(data);
                        });
                        _persistSavedCities();
                        _saveLocationsForBackground();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF1A2035),
                            content: Text(
                              '${data.location} dihapus',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationHistoryDetail(
                              location: data.location,
                              days: 60,
                            ),
                          ),
                        ),
                        child: _CityCard(data: data),
                      ),
                    );
                  }, childCount: savedCities.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroWeatherCard extends StatelessWidget {
  final AqiData data;
  final bool isLoading;
  final String lastUpdated;

  const _HeroWeatherCard({
    required this.data,
    required this.isLoading,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = data.getSkyGradient();
    final accent = data.getAccentColor();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: isLoading
                            ? _shimmerText(120, 13)
                            : Text(
                                data.location,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isLoading)
                              _shimmerText(80, 72)
                            else
                              Text(
                                data.pm25.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 80,
                                  fontWeight: FontWeight.w900,
                                  height: 0.9,
                                  letterSpacing: -4,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              'PM 2.5 µg/m³',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          data.getStatusIcon(),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data.getAqiCategory(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(data.getIcon(), color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.getStatus(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                data.getAdvice(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white38,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white38,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Diperbarui: $lastUpdated',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerText(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class _CityCard extends StatelessWidget {
  final AqiData data;
  const _CityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = data.getAccentColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.12),
              border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
            ),
            child: Center(
              child: Text(
                data.pm25.toString(),
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.location,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        data.getStatus(),
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}

class _AddCitySheet extends StatelessWidget {
  final List<AqiData> availableCities;
  final void Function(AqiData city, int index) onAdd;
  const _AddCitySheet({required this.availableCities, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF141929),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Tambah Lokasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Swipe kiri pada kartu untuk menghapus lokasi',
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: availableCities.length,
              itemBuilder: (context, index) {
                final city = availableCities[index];
                final accent = city.getAccentColor();
                return GestureDetector(
                  onTap: () => onAdd(city, index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: accent.withOpacity(0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            city.location,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (city.pm25 > 0)
                          Text(
                            city.pm25.toString(),
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.add_circle_rounded,
                          color: const Color(0xFF6ECFF6).withOpacity(0.6),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
