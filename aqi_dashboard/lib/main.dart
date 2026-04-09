import 'package:flutter/material.dart';

void main() {
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
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      home: const AqiDashboard(),
    );
  }
}

class AqiData {
  final String location;
  final int pm25;

  AqiData({required this.location, required this.pm25});

  Color getPrimaryColor() {
    if (pm25 <= 50) return const Color(0xFF00C6FF);
    if (pm25 <= 100) return const Color(0xFFF6D365);
    if (pm25 <= 150) return const Color(0xFFFF9A44);
    return const Color(0xFFFF416C);
  }

  Color getSecondaryColor() {
    if (pm25 <= 50) return const Color(0xFF0072FF);
    if (pm25 <= 100) return const Color(0xFFFDA085);
    if (pm25 <= 150) return const Color(0xFFFC6076);
    return const Color(0xFFFF4B2B);
  }

  String getStatus() {
    if (pm25 <= 50) return "Udara Bersih";
    if (pm25 <= 100) return "Kualitas Sedang";
    if (pm25 <= 150) return "Tidak Sehat";
    return "Sangat Berbahaya";
  }

  IconData getIcon() {
    if (pm25 <= 50) return Icons.sentiment_very_satisfied_rounded;
    if (pm25 <= 100) return Icons.sentiment_neutral_rounded;
    if (pm25 <= 150) return Icons.sentiment_dissatisfied_rounded;
    return Icons.coronavirus_rounded;
  }
}

class AqiDashboard extends StatefulWidget {
  const AqiDashboard({super.key});

  @override
  State<AqiDashboard> createState() => _AqiDashboardState();
}

class _AqiDashboardState extends State<AqiDashboard> {
  final AqiData myLocation = AqiData(location: "Surakarta", pm25: 120);

  String get lastUpdated {
    final now = DateTime.now();

    const List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    final day = now.day.toString().padLeft(2, '0');
    final month = monthNames[now.month - 1];
    final year = now.year;
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return "$day $month $year, $hour.$minute WIB";
  }

  List<AqiData> savedCities = [
    AqiData(location: "Kemayoran, Jakarta", pm25: 155),
    AqiData(location: "Surabaya, Jawa Timur", pm25: 125),
  ];

  List<AqiData> availableCities = [
    AqiData(location: "Bandung, Jawa Barat", pm25: 85),
    AqiData(location: "Medan, Sumatera Utara", pm25: 60),
    AqiData(location: "Makassar, Sulawesi Selatan", pm25: 35),
    AqiData(location: "Denpasar, Bali", pm25: 55),
  ];

  void _showAddCityDialog() {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Tambah Lokasi Pantauan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: availableCities.length,
                  itemBuilder: (context, index) {
                    final city = availableCities[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: Colors.blueGrey),
                      ),
                      title: Text(
                        city.location,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "PM2.5: ${city.pm25} — ${city.getStatus()}",
                        style: TextStyle(
                          color: city.getPrimaryColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(Icons.add_circle, color: Colors.blueAccent),
                      onTap: () {
                        setState(() {
                          savedCities.add(city);
                          availableCities.removeAt(index);
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            color: const Color(0xFFF4F6F9),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 80.0,
                  floating: true,
                  backgroundColor: const Color(0xFFF4F6F9),
                  elevation: 0,
                  title: const Text(
                    "AeroSense",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2D3142),
                      letterSpacing: -1,
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: InkWell(
                        onTap: _showAddCityDialog,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: const Icon(Icons.add, color: Color(0xFF2D3142)),
                        ),
                      ),
                    )
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.my_location, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Text(
                              "LOKASI ANDA SAAT INI",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade400,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                myLocation.getPrimaryColor(),
                                myLocation.getSecondaryColor(),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: myLocation.getSecondaryColor().withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                myLocation.location,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.white60, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Diperbarui: $lastUpdated",
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Indeks PM 2.5",
                                        style: TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                      Text(
                                        myLocation.pm25.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 56,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Icon(myLocation.getIcon(), color: Colors.white, size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        myLocation.getStatus(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        Text(
                          "LOKASI PANTAUAN",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade400,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                              size: 60,
                              color: Colors.blueGrey.shade200,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Belum ada lokasi pantauan.\nTambahkan dengan tombol + di atas.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blueGrey.shade300,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final data = savedCities[index];
                      return Dismissible(
                        key: Key(data.location),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 25),
                          child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
                        ),
                        onDismissed: (direction) {
                          setState(() {
                            savedCities.removeAt(index);
                            availableCities.add(data);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${data.location} dihapus"),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [data.getPrimaryColor(), data.getSecondaryColor()],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    data.pm25.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                data.location,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2D3142),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  data.getStatus(),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              trailing: Icon(data.getIcon(), color: data.getPrimaryColor(), size: 30),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: savedCities.length,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}