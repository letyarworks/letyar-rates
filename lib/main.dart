import 'package:flutter/material.dart';

import 'services/rate_service.dart';

void main() {
  runApp(const LetyarRatesApp());
}

class LetyarRatesApp extends StatelessWidget {
  const LetyarRatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Letyar Rates',

      // Default = Dark
      themeMode: ThemeMode.dark,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B8D9),
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B8D9),
          brightness: Brightness.dark,
        ),
      ),

      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RateService _rateService = RateService();

  UsdRate? _usdRate;
GoldRate? _goldRate;

  bool _loading = true;
  bool _refreshing = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }
String _formatNumber(double value) {
  return value
      .round()
      .toString()
      .replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
}
Future<void> _loadRates() async {
  if (mounted) {
    setState(() {
      _loading = true;
      _error = null;
    });
  }

  try {
    final rates = await _rateService.fetchRates();

    if (!mounted) return;

    setState(() {
      _usdRate = rates.usd;
      _goldRate = rates.gold;
      _loading = false;
      _refreshing = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _error = 'Unable to load rates';
      _loading = false;
      _refreshing = false;
    });
  }
}
  Future<void> _refreshRates() async {
    if (_refreshing) return;

    setState(() {
      _refreshing = true;
    });

    await _loadRates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Letyar Rates',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        // Theme toggle မပါပါ
        actions: const [
          SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshRates,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            32,
          ),

          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 8),

                const Text(
                  'Market rates',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(),

                const Text(
                  'MMK',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // USD
            RateCard(
              title: 'USD / MMK',
              subtitle: 'US Dollar',
              icon: Icons.currency_exchange_rounded,
              accent: const Color(0xFF00B8D9),

              value: _loading
                  ? 'Loading...'
                  : _usdRate != null
                      ? '${_usdRate!.buy.toStringAsFixed(0)} MMK'
                      : '— MMK',

              secondaryValue: _usdRate != null
                  ? 'Sell ${_usdRate!.sell.toStringAsFixed(0)} MMK'
                  : null,
            ),

            const SizedBox(height: 14),
// Gold
RateCard(
  title: 'Gold',
  subtitle: 'Gold • 1 Kyattha',
  value: _goldRate == null
      ? '—'
      : 'Buy ${_formatNumber(_goldRate!.buy * 16.329325)} MMK',
  secondaryValue: _goldRate == null
      ? null
      : 'Sell ${_formatNumber(_goldRate!.sell * 16.329325)} MMK',
  icon: Icons.workspace_premium_rounded,
  accent: const Color(0xFFE0A72E),
),

            const SizedBox(height: 24),

            const Text(
              'Price History',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),

         const SizedBox(height: 12),

HistoryCard(),

const SizedBox(height: 24),

            // Refresh button
            OutlinedButton.icon(
              onPressed: _refreshing
                  ? null
                  : _refreshRates,

              icon: _refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                    ),

              label: Text(
                _refreshing
                    ? 'Updating...'
                    : 'Refresh Rates',
              ),

              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Last Updated - Yellow
            Center(
              child: Text(
                _error != null
                    ? _error!
                    : _usdRate?.updatedAt != null
                        ? 'Last updated: ${_usdRate!.updatedAt}'
                        : 'Last updated: —',

                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE0A72E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String value;
  final String? secondaryValue;

  const RateCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.value = '— MMK',
    this.secondaryValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF111827),
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,

                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: Icon(
                    icon,
                    color: accent,
                  ),
                ),

                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 22),

            Text(
              value,
              style: const TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),

            if (secondaryValue != null) ...[
              const SizedBox(height: 6),

              // SELL = Yellow
              Text(
                secondaryValue!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE0A72E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF111827),
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      child: SizedBox(
        height: 220,

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'USD / MMK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: CustomPaint(
                  painter: HistoryPainter(
                    lineColor: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),

                  child: const SizedBox.expand(),
                ),
              ),

              const Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [
                  Text('7d'),
                  Text('5d'),
                  Text('3d'),
                  Text('Today'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryPainter extends CustomPainter {
  final Color lineColor;

  HistoryPainter({
    required this.lineColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    final points = [
      Offset(
        0,
        size.height * 0.72,
      ),
      Offset(
        size.width * 0.16,
        size.height * 0.62,
      ),
      Offset(
        size.width * 0.32,
        size.height * 0.67,
      ),
      Offset(
        size.width * 0.48,
        size.height * 0.42,
      ),
      Offset(
        size.width * 0.65,
        size.height * 0.50,
      ),
      Offset(
        size.width * 0.82,
        size.height * 0.30,
      ),
      Offset(
        size.width,
        size.height * 0.36,
      ),
    ];

    path.moveTo(
      points.first.dx,
      points.first.dy,
    );

    for (var i = 1; i < points.length; i++) {
      path.lineTo(
        points[i].dx,
        points[i].dy,
      );
    }

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant HistoryPainter oldDelegate,
  ) {
    return oldDelegate.lineColor != lineColor;
  }
}