import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customer_screen.dart';
import 'product_screen.dart';
import 'cashier_screen.dart';
import 'finance_screen.dart';
import 'sales_report_screen.dart';
import 'store_settings_screen.dart';
import 'printer_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _storeName = 'TOKO KASIR PINTAR';

  @override
  void initState() {
    super.initState();
    _loadStoreName();
  }

  Future<void> _loadStoreName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storeName = prefs.getString('store_name') ?? 'TOKO KASIR PINTAR';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _storeName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StoreSettingsScreen()),
              );
              _loadStoreName();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Menu Utama',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            _buildMenuItem(
              icon: Icons.storefront,
              title: 'Pengaturan Identitas & Logo Toko',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StoreSettingsScreen()),
                );
                _loadStoreName();
              },
            ),
            _buildMenuItem(
              icon: Icons.print,
              title: 'Pengaturan Printer Bluetooth',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrinterSettingsScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.layers,
              title: 'Manajemen Produk (Jual & Modal)',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.shopping_cart,
              title: 'Transaksi Penjualan (Kasir)',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CashierScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.account_balance_wallet,
              title: 'Keuangan & Laba Bersih',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FinanceScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.assignment,
              title: 'Laporan Penjualan & Edit Struk',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SalesReportScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.people,
              title: 'Data Pelanggan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00796B)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        onTap: onTap,
      ),
    );
  }
}
