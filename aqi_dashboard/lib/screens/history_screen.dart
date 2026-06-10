import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../models/aqi_history.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  final _db = DatabaseHelper();
  Map<String, List<AqiHistoryRecord>> _history = {};
  bool _isLoading = false;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
  }

  void reload() => _loadHistory();

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _db.getAllHistory(days: _selectedDays);
      if (!mounted) return;
      setState(() {
        _history = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("History Error: $e");
      if (!mounted) return;
      setState(() {
        _history = {};
        _isLoading = false;
      });
    }
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
                              'Riwayat Udara',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'Pantauan kualitas udara historis',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _loadHistory,
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
                              Icons.refresh_rounded,
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [7, 14, 30, 60].map((days) {
                          final selected = _selectedDays == days;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                if (_selectedDays == days) return;
                                setState(() => _selectedDays = days);
                                _loadHistory();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF6ECFF6)
                                      : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF6ECFF6)
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  days == 7
                                      ? '7 Hari'
                                      : days == 14
                                      ? '2 Minggu'
                                      : days == 30
                                      ? '1 Bulan'
                                      : '2 Bulan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? const Color(0xFF0A0F1E)
                                        : Colors.white60,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6ECFF6),
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_history.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: const Icon(
                            Icons.timeline_rounded,
                            size: 52,
                            color: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Belum ada riwayat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Data akan tersimpan otomatis\nsaat aplikasi dibuka',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white24,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final location = _history.keys.elementAt(index);
                      final records = _history[location]!;
                      return _LocationHistoryCard(
                        location: location,
                        records: records,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationHistoryDetail(
                              location: location,
                              days: _selectedDays,
                            ),
                          ),
                        ).then((_) => _loadHistory()),
                      );
                    }, childCount: _history.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _aqiColor(double pm25) {
  if (pm25 <= 50) return const Color(0xFF6ECFF6);
  if (pm25 <= 100) return const Color(0xFFFFD97D);
  if (pm25 <= 150) return const Color(0xFFFF9A44);
  return const Color(0xFFFF5252);
}

String _aqiStatus(int pm25) {
  if (pm25 <= 50) return 'Baik';
  if (pm25 <= 100) return 'Sedang';
  if (pm25 <= 150) return 'Buruk';
  return 'Berbahaya';
}

class _LocationHistoryCard extends StatelessWidget {
  final String location;
  final List<AqiHistoryRecord> records;
  final VoidCallback onTap;

  const _LocationHistoryCard({
    required this.location,
    required this.records,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final latest = records.first;
    final avg =
        records.map((r) => r.pm25).reduce((a, b) => a + b) / records.length;
    final chartData = records.take(7).toList().reversed.toList();
    final accent = _aqiColor(latest.pm25.toDouble());
    final maxPm25 = records.map((r) => r.pm25).reduce(math.max);
    final minPm25 = records.map((r) => r.pm25).reduce(math.min);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141929),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.12),
                      border: Border.all(
                        color: accent.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        latest.pm25.toString(),
                        style: TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _aqiStatus(latest.pm25),
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${records.length} catatan',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white24,
                    size: 20,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  _StatChip(
                    label: 'Rata-rata',
                    value: avg.toStringAsFixed(0),
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Tertinggi',
                    value: maxPm25.toString(),
                    color: const Color(0xFFFF9A44),
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Terendah',
                    value: minPm25.toString(),
                    color: const Color(0xFF6ECFF6),
                  ),
                ],
              ),
            ),

            if (chartData.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: SizedBox(
                  height: 56,
                  child: _MiniBarChart(records: chartData),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat(
                        'd MMM',
                        'id_ID',
                      ).format(chartData.first.recordedAt),
                      style: TextStyle(fontSize: 10, color: Colors.white24),
                    ),
                    Text(
                      '7 hari terakhir',
                      style: TextStyle(fontSize: 10, color: Colors.white24),
                    ),
                    Text(
                      DateFormat(
                        'd MMM',
                        'id_ID',
                      ).format(chartData.last.recordedAt),
                      style: TextStyle(fontSize: 10, color: Colors.white24),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MiniBarChart extends StatelessWidget {
  final List<AqiHistoryRecord> records;
  const _MiniBarChart({required this.records});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BarChartPainter(records: records),
    child: Container(),
  );
}

class _BarChartPainter extends CustomPainter {
  final List<AqiHistoryRecord> records;
  _BarChartPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;
    final maxVal = records.map((r) => r.pm25).reduce(math.max).toDouble();
    final effectiveMax = math.max(maxVal, 50.0);
    final barW = (size.width / records.length) * 0.55;
    final gap = (size.width / records.length) * 0.45;

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final barH = (r.pm25 / effectiveMax) * size.height;
      final x = i * (barW + gap) + gap / 2;
      final y = size.height - barH;
      final color = _aqiColor(r.pm25.toDouble());

      final bgPaint = Paint()
        ..color = Colors.white.withOpacity(0.04)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barW, size.height),
          const Radius.circular(6),
        ),
        bgPaint,
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withOpacity(0.5)],
        ).createShader(Rect.fromLTWH(x, y, barW, barH))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, barH),
          const Radius.circular(6),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class LocationHistoryDetail extends StatefulWidget {
  final String location;
  final int days;
  const LocationHistoryDetail({
    super.key,
    required this.location,
    required this.days,
  });

  @override
  State<LocationHistoryDetail> createState() => _LocationHistoryDetailState();
}

class _LocationHistoryDetailState extends State<LocationHistoryDetail> {
  final _db = DatabaseHelper();
  List<AqiHistoryRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final records = await _db.getHistoryByLocation(
      widget.location,
      days: widget.days,
    );
    if (mounted)
      setState(() {
        _records = records;
        _isLoading = false;
      });
  }

  Future<void> _confirmDeleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF141929),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.redAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Riwayat?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Semua riwayat untuk lokasi ini akan dihapus permanen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm == true && mounted) {
      await _db.deleteHistoryForLocation(widget.location);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F1E),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6ECFF6),
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_records.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0F1E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Tidak ada data',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    final latest = _records.first;
    final accent = _aqiColor(latest.pm25.toDouble());
    final avg =
        _records.map((r) => r.pm25).reduce((a, b) => a + b) / _records.length;
    final maxPm25 = _records.map((r) => r.pm25).reduce(math.max);
    final minPm25 = _records.map((r) => r.pm25).reduce(math.min);
    final chartData = _records.take(14).toList().reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.3), const Color(0xFF0A0F1E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _confirmDeleteAll,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: accent,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Detail Lokasi',
                                      style: TextStyle(
                                        color: accent.withOpacity(0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.location,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: accent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _aqiStatus(latest.pm25),
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                latest.pm25.toString(),
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  height: 0.9,
                                  letterSpacing: -3,
                                ),
                              ),
                              Text(
                                'PM 2.5',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
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
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _DetailStatCard(
                      label: 'Rata-rata',
                      value: avg.toStringAsFixed(1),
                      unit: 'PM2.5',
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DetailStatCard(
                      label: 'Tertinggi',
                      value: maxPm25.toString(),
                      unit: 'PM2.5',
                      color: const Color(0xFFFF9A44),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DetailStatCard(
                      label: 'Terendah',
                      value: minPm25.toString(),
                      unit: 'PM2.5',
                      color: const Color(0xFF6ECFF6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141929),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tren 14 Hari',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${chartData.length} data',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 100,
                      child: _MiniBarChart(records: chartData),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (chartData.isNotEmpty)
                          Text(
                            DateFormat(
                              'd MMM',
                              'id_ID',
                            ).format(chartData.first.recordedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        if (chartData.isNotEmpty)
                          Text(
                            DateFormat(
                              'd MMM',
                              'id_ID',
                            ).format(chartData.last.recordedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(
                          color: const Color(0xFF6ECFF6),
                          label: '≤50 Baik',
                        ),
                        const SizedBox(width: 16),
                        _LegendDot(
                          color: const Color(0xFFFFD97D),
                          label: '≤100 Sedang',
                        ),
                        const SizedBox(width: 16),
                        _LegendDot(
                          color: const Color(0xFFFF9A44),
                          label: '≤150 Buruk',
                        ),
                        const SizedBox(width: 16),
                        _LegendDot(
                          color: const Color(0xFFFF5252),
                          label: '>150 Bahaya',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 14,
                    color: Color(0xFF6ECFF6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CATATAN HARIAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6ECFF6).withOpacity(0.8),
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_records.length} entri',
                    style: TextStyle(fontSize: 11, color: Colors.white24),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final r = _records[index];
                final rColor = _aqiColor(r.pm25.toDouble());
                final isFirst = index == 0;
                final isLast = index == _records.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141929),
                    borderRadius: BorderRadius.vertical(
                      top: isFirst ? const Radius.circular(20) : Radius.zero,
                      bottom: isLast ? const Radius.circular(20) : Radius.zero,
                    ),
                    border: Border(
                      top: isFirst
                          ? BorderSide(color: Colors.white.withOpacity(0.06))
                          : BorderSide.none,
                      bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
                      left: BorderSide(color: Colors.white.withOpacity(0.06)),
                      right: BorderSide(color: Colors.white.withOpacity(0.06)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Column(
                          children: [
                            Text(
                              DateFormat('dd', 'id_ID').format(r.recordedAt),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'MMM',
                                'id_ID',
                              ).format(r.recordedAt).toUpperCase(),
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.08),
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              DateFormat(
                                    'HH:mm',
                                    'id_ID',
                                  ).format(r.recordedAt) +
                                  ' WIB',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            r.pm25.toString(),
                            style: TextStyle(
                              color: rColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: rColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _aqiStatus(r.pm25),
                              style: TextStyle(
                                color: rColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }, childCount: _records.length),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _DetailStatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF141929),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 9, color: Colors.white38)),
    ],
  );
}
