import 'customer_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOKO KASIR PINTAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner Status Printer
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.print, color: Color(0xFFE65100)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Printer Belum Terhubung (Ketuk untuk hubungkan)',
                      style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Menu Utama',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Daftar Menu
            _buildMenuItem(
              icon: Icons.storefront,
              title: 'Pengaturan Identitas & Logo Toko',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.layers,
              title: 'Manajemen Produk (Jual & Modal)',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.shopping_cart,
              title: 'Transaksi Penjualan (Kasir)',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.account_balance_wallet,
              title: 'Keuangan & Laba Bersih',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.assignment,
              title: 'Laporan Penjualan & Edit Struk',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.people,
              title: 'Data Pelanggan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.settings,
              title: 'Pengaturan Aplikasi',
              onTap: () {},
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
