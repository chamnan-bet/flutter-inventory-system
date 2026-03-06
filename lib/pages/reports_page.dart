// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:math' as math;
import 'package:flutter/material.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // ---- Time ranges ----
  final List<String> _ranges = const [
    'Last 7 Days',
    'Last 30 Days',
    'Last 60 Days',
    'Last 90 Days',
  ];
  int _selectedRange = 0;

  // ---- Demo metrics (could be computed from data) ----
  double get totalRevenue => 125.00;
  double get stockValue => 1478.30;
  double get avgProductValue => 295.66;
  int get transactions => 2;

  // ---- Demo series for line chart (Stock In/Out for 7 points) ----
  // When you change _selectedRange, you can swap in different demo arrays if you want
  final List<double> stockIn = [12, 18, 10, 22, 16, 15, 28];
  final List<double> stockOut = [8, 12, 15, 10, 14, 12, 18];

  // ---- Category pie: label -> value ----
  final Map<String, double> categoryDist = const {
    'Beverages': 35,
    'Snacks': 30,
    'Dairy': 20,
    'Food': 15,
  };

  // ---- Bar chart (sales by category) ----
  final List<_BarItem> salesByCat = const [
    _BarItem('Beverages', 520),
    _BarItem('Snacks', 280),
    _BarItem('Dairy', 140),
    _BarItem('Food', 75),
  ];

  // ---- Best sellers list ----
  final List<_BestSeller> bestSellers = const [
    _BestSeller('Chocolate Bars', 478.80),
    _BestSeller('Pasta', 135.00),
    _BestSeller('Organic Green Tea', 100.00),
    _BestSeller('Milk Powder', 44.95),
  ];

  // ---- Low Stock report ----
  final List<_LowStockItem> lowStock = const [
    _LowStockItem('Organic Green Tea', 'Beverages', 8, 15),
    _LowStockItem('Milk Powder', 'Dairy', 5, 10),
  ];

  void _onExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export (CSV/PDF) coming soon…')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3B47FF);
    final textGrey = const Color(0xFF7A7A7A);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/adminMenu');
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'InventoryPro',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Admin User',
              style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header + actions
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reports & Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Detailed business insights',
                      style: TextStyle(color: textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _onExport,
                icon: const Icon(
                  Icons.file_upload_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  'Export',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Time range filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_ranges.length, (i) {
                final selected = i == _selectedRange;
                return Padding(
                  padding: EdgeInsets.only(
                    right: i == _ranges.length - 1 ? 0 : 8,
                  ),
                  child: ChoiceChip(
                    label: Text(_ranges[i]),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedRange = i),
                    selectedColor: primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    backgroundColor: const Color(0xFFF3F4F6),
                    side: BorderSide(
                      color: selected ? primary : Colors.transparent,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // KPI cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _KpiCard(
                icon: Icons.payments_outlined,
                iconBg: const Color(0xFFE3F2FD),
                title: 'Total Revenue',
                value: '\$${totalRevenue.toStringAsFixed(2)}',
                subtitle: 'vs 24h earlier (placeholder)',
              ),
              _KpiCard(
                icon: Icons.account_balance_wallet_outlined,
                iconBg: const Color(0xFFEDE7F6),
                title: 'Stock Value',
                value: '\$${stockValue.toStringAsFixed(2)}',
                subtitle: 'Inventory value',
              ),
              _KpiCard(
                icon: Icons.attach_money_outlined,
                iconBg: const Color(0xFFE8F5E9),
                title: 'Avg Product Value',
                value: '\$${avgProductValue.toStringAsFixed(2)}',
                subtitle: 'Per product average',
              ),
              _KpiCard(
                icon: Icons.swap_vert_rounded,
                iconBg: const Color(0xFFFFF3E0),
                title: 'Transactions',
                value: '$transactions',
                subtitle: 'Total movements',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stock Movement Trend (line chart)
          _Panel(
            title: 'Stock Movement Trend',
            subtitle: 'Stock In vs Stock Out',
            child: SizedBox(
              height: 200,
              child: _LineChart(
                seriesA: stockIn,
                seriesB: stockOut,
                colorA: const Color(0xFF10B981), // green
                colorB: const Color(0xFFD32F2F), // red
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Pie: Product Distribution by Category
          _Panel(
            title: 'Product Distribution by Category',
            subtitle: 'Categories share',
            child: SizedBox(height: 220, child: _PieChart(data: categoryDist)),
          ),
          const SizedBox(height: 12),

          // Bar chart: Sales by Category
          _Panel(
            title: 'Sales by Category',
            subtitle: 'Total sales (demo)',
            child: SizedBox(height: 220, child: _BarChart(items: salesByCat)),
          ),
          const SizedBox(height: 12),

          // Best Sellers
          _Panel(
            title: 'Best Sellers',
            subtitle: 'Top revenue products',
            child: Column(
              children: bestSellers
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '\$${e.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Low Stock Report
          _Panel(
            title: 'Low Stock Report',
            subtitle: 'Items below minimum',
            child: Column(
              children: lowStock.map((e) {
                final danger = e.current < e.min;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.category,
                              style: const TextStyle(
                                color: Color(0xFF7A7A7A),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${e.current} / ${e.min}',
                        style: TextStyle(
                          color: danger
                              ? const Color(0xFFD32F2F)
                              : Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),

      // Bottom nav: highlight "More"
      bottomNavigationBar: NavigationBar(
        selectedIndex: 4,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/products');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/stock');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/alerts');
              break;
            case 4:
              // Admin/More
              Navigator.pushReplacementNamed(context, '/adminMenu');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert_rounded),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            label: 'Alerts',
          ),
          NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}

/* ====================== Small panels & KPIs ====================== */

class _Panel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Panel({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String value;
  final String subtitle;

  const _KpiCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cardW = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;
    return Container(
      width: cardW,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF7A7A7A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ====================== Charts (CustomPaint) ====================== */

/// Simple dual-series line chart (no axes labels, light grid)
class _LineChart extends StatelessWidget {
  final List<double> seriesA;
  final List<double> seriesB;
  final Color colorA;
  final Color colorB;

  const _LineChart({
    required this.seriesA,
    required this.seriesB,
    required this.colorA,
    required this.colorB,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(seriesA, seriesB, colorA, colorB),
      size: Size.infinite,
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> a;
  final List<double> b;
  final Color ca, cb;

  _LineChartPainter(this.a, this.b, this.ca, this.cb);

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 16.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;

    // background grid
    final grid = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = padding + h * (i / gridLines);
      canvas.drawLine(Offset(padding, y), Offset(padding + w, y), grid);
    }

    // define helpers
    List<double> all = [...a, ...b];
    final minV = 0.0;
    final maxV = (all.isEmpty ? 1.0 : all.reduce(math.max)).clamp(
      1.0,
      double.infinity,
    );
    Offset pt(double xIndex, double value, int len) {
      final dx = padding + (w * (len == 1 ? 0.5 : xIndex / (len - 1)));
      final dy = padding + h - (h * ((value - minV) / (maxV - minV)));
      return Offset(dx, dy);
    }

    void drawSeries(List<double> s, Color c) {
      if (s.isEmpty) return;
      final p = Path();
      for (int i = 0; i < s.length; i++) {
        final o = pt(i.toDouble(), s[i], s.length);
        if (i == 0) {
          p.moveTo(o.dx, o.dy);
        } else {
          p.lineTo(o.dx, o.dy);
        }
      }
      final line = Paint()
        ..color = c
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(p, line);

      // points
      final dot = Paint()..color = c;
      for (int i = 0; i < s.length; i++) {
        final o = pt(i.toDouble(), s[i], s.length);
        canvas.drawCircle(o, 2.5, dot);
      }
    }

    drawSeries(a, ca);
    drawSeries(b, cb);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.a != a || old.b != b || old.ca != ca || old.cb != cb;
}

/// Pie chart with legend percentage text inside slices
class _PieChart extends StatelessWidget {
  final Map<String, double> data;
  const _PieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PiePainter(data), size: Size.infinite);
  }
}

class _PiePainter extends CustomPainter {
  final Map<String, double> data;
  _PiePainter(this.data);

  final List<Color> palette = const [
    Color(0xFF3B47FF), // blue
    Color(0xFF10B981), // green
    Color(0xFFF59E0B), // orange
    Color(0xFFE11D48), // red
    Color(0xFF7C3AED), // violet
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;

    final radius = math.min(size.width, size.height) * 0.35;
    final center = Offset(size.width / 2, size.height / 2 + 10);

    var start = -math.pi / 2;
    int i = 0;
    data.forEach((label, value) {
      final sweep = (value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = palette[i % palette.length]
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);

      // label (%)
      final mid = start + sweep / 2;
      final tx = center.dx + (radius * 0.6) * math.cos(mid);
      final ty = center.dy + (radius * 0.6) * math.sin(mid);
      final percent = (value / total * 100).toStringAsFixed(0) + '%';

      final tp = TextPainter(
        text: TextSpan(
          text: percent,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(tx - tp.width / 2, ty - tp.height / 2));

      start += sweep;
      i++;
    });

    // simple legend (bottom)
    final legendY = center.dy + radius + 16;
    final chunkW = size.width / (data.length);
    i = 0;
    data.forEach((label, _) {
      final color = palette[i % palette.length];
      final tx = i * chunkW + 8;
      final rect = Rect.fromLTWH(tx, legendY, 12, 12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = color,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '  $label',
          style: const TextStyle(color: Colors.black87, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: chunkW - 20);
      tp.paint(canvas, Offset(tx + 14, legendY - 2));
      i++;
    });
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) => old.data != data;
}

/// Simple vertical bar chart
class _BarChart extends StatelessWidget {
  final List<_BarItem> items;
  const _BarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BarPainter(items), size: Size.infinite);
  }
}

class _BarPainter extends CustomPainter {
  final List<_BarItem> items;
  _BarPainter(this.items);

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 28.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;

    // Y grid
    final grid = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padding + h * (i / 4);
      canvas.drawLine(Offset(padding, y), Offset(padding + w, y), grid);
    }

    // bars
    final values = items.map((e) => e.value).toList();
    final maxV = (values.isEmpty ? 1 : values.reduce(math.max))
        .toDouble()
        .clamp(1.0, double.infinity);
    final bw = w / (items.length * 2); // bar width
    final barPaint = Paint()..color = const Color(0xFF3B47FF);

    for (int i = 0; i < items.length; i++) {
      final v = items[i].value;
      final barH = h * (v / maxV);
      final cx = padding + (i * 2 + 0.5) * bw + (i * bw);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx, padding + h - barH, bw, barH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, barPaint);

      // label
      final tp = TextPainter(
        text: TextSpan(
          text: items[i].label,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: bw * 2);
      tp.paint(canvas, Offset(cx - bw * 0.5, padding + h + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.items != items;
}

/* ====================== Small models ====================== */

class _BarItem {
  final String label;
  final double value;
  const _BarItem(this.label, this.value);
}

class _BestSeller {
  final String name;
  final double amount;
  const _BestSeller(this.name, this.amount);
}

class _LowStockItem {
  final String name;
  final String category;
  final int current;
  final int min;
  const _LowStockItem(this.name, this.category, this.current, this.min);
}
