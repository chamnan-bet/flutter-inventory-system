import 'package:flutter/material.dart';
import 'package:inventory_system/pages/admin_menu.dart';
import 'package:inventory_system/pages/alert_page.dart';
import 'package:inventory_system/pages/reports_page.dart';
import 'package:inventory_system/pages/sales_orders_page.dart';
import 'package:inventory_system/pages/stock_page.dart';
import 'package:inventory_system/pages/suppliers_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/product_page.dart' show ProductsPage;

class InventoryProApp extends StatelessWidget {
  const InventoryProApp({super.key});

  @override
  Widget build(BuildContext context) {
	return MaterialApp(
  	title: 'InventoryPro',
  	debugShowCheckedModeBanner: false,
  	theme: ThemeData(
    	useMaterial3: true,
    	colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B47FF)),
    	scaffoldBackgroundColor: Colors.white,
  	),
  	initialRoute: '/login',
  	routes: {
    	'/login': (_) => const LoginPage(),
    	'/dashboard': (_) => const DashboardPage(),
      '/products': (_) => const ProductsPage(),
      '/stock': (_) => const StockPage(), 
      '/alerts': (_) => const AlertsPage(),
      '/adminMenu': (_) => const AdminMenuPage(),  	
    	'/reports': (_) => const ReportsPage(),
    	'/suppliers': (_) => const SuppliersPage(),
    	'/orders': (_) => const SalesOrdersPage(),
    	// '/settings': (_) => const SettingsPage(),
    	// '/adminPanel': (_) => const AdminPanelPage(),
  	},
	);
  }
}
