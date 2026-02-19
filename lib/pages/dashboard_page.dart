import 'package:flutter/material.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    // const primaryBlue = Color(0xFF3B47FF);

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          const SizedBox(height: 4),
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Overview of your inventory',
            style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Summary metrics grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              MetricCard(
                icon: Icons.all_inbox_rounded,
                iconBg: Color(0xFFE9EEFF),
                value: '5',
                label: 'Total Products',
              ),
              MetricCard(
                icon: Icons.attach_money_rounded,
                iconBg: Color(0xFFE9EEFF),
                value: '\$1478',
                label: 'Stock Value',
              ),
              MetricCard(
                icon: Icons.warning_amber_rounded,
                iconBg: Color(0xFFFFF3E0),
                value: '2',
                label: 'Low Stock',
                valueColor: Color(0xFFFF6D00),
              ),
              MetricCard(
                icon: Icons.access_time_rounded,
                iconBg: Color(0xFFFFEBEE),
                value: '3',
                label: 'Expiring Soon',
                valueColor: Color(0xFFD32F2F),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Attention Required
          SectionCard(
            borderColor: const Color(0xFFFFC48B),
            bgColor: const Color(0xFFFFF3E6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SectionTitleWithIcon(
                  icon: Icons.warning_amber_rounded,
                  title: 'Attention Required',
                  iconColor: Color(0xFFFF6D00),
                ),
                SizedBox(height: 8),
                _Bullet(text: '2 product(s) running low on stock'),
                _Bullet(text: '3 product(s) expiring within 2 months'),
                SizedBox(height: 8),
                Text(
                  'View Details',
                  style: TextStyle(
                    color: Color(0xFF3B47FF),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Low Stock Alert
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitleWithIcon(
                  icon: Icons.trending_down_rounded,
                  title: 'Low Stock Alert',
                  iconColor: Colors.black87,
                ),
                const SizedBox(height: 12),
                _lowStockRow(
                  name: 'Organic Green Tea',
                  sku: 'TEA-002',
                  units: 8,
                  min: 15,
                ),
                const Divider(height: 20),
                _lowStockRow(
                  name: 'Milk Powder',
                  sku: 'MLK-004',
                  units: 5,
                  min: 10,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // =========================
          // NEW: Recent Transactions
          // =========================
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitleWithIcon(
                  icon: Icons.receipt_long_rounded,
                  title: 'Recent Transactions',
                  iconColor: Colors.black87,
                ),
                const SizedBox(height: 12),

                // Item 1 (positive)
                _TransactionRow(
                  title: 'Premium Coffee Beans',
                  subtitle: 'New shipment from supplier',
                  date: '2026-02-15',
                  qtyText: '+50',
                  qtyColor: const Color(0xFF2E7D32), // green
                  chipBg: const Color(0xFFE8F5E9),
                ),
                const Divider(height: 20),

                // Item 2 (negative)
                _TransactionRow(
                  title: 'Organic Green Tea',
                  subtitle: 'Sold to customer',
                  date: '2026-02-14',
                  qtyText: '-10',
                  qtyColor: const Color(0xFFC62828), // red
                  chipBg: const Color(0xFFFFEBEE),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex, // keep your local tab index for highlight
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          switch (i) {
            case 0: // Home
              // already on dashboard
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
              Navigator.pushReplacementNamed(context, '/adminMenu');
              break;

            case 5: // Admin/More
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More coming soon…')),
              );
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
            icon: Icon(Icons.warehouse_outlined),
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

  Widget _lowStockRow({
    required String name,
    required String sku,
    required int units,
    required int min,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                'SKU: $sku',
                style: const TextStyle(color: Color(0xFF7A7A7A)),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$units units',
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text('Min: $min', style: const TextStyle(color: Color(0xFF7A7A7A))),
          ],
        ),
      ],
    );
  }
}

/// Title row with an icon; used by multiple sections
class _SectionTitleWithIcon extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;

  const _SectionTitleWithIcon({
    required this.icon,
    required this.title,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('• ', style: TextStyle(fontSize: 16)),
        Expanded(child: Text(text)),
      ],
    );
  }
}

/// NEW: A single transaction row with a colored qty chip and date
class _TransactionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String qtyText;
  final Color qtyColor;
  final Color chipBg;

  const _TransactionRow({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.qtyText,
    required this.qtyColor,
    required this.chipBg,
  });

  @override
  Widget build(BuildContext context) {
    final textGrey = const Color(0xFF7A7A7A);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: textGrey, fontSize: 13)),
            ],
          ),
        ),

        // Right: qty chip + date (aligned to top)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                qtyText,
                style: TextStyle(
                  color: qtyColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(date, style: TextStyle(color: textGrey, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
