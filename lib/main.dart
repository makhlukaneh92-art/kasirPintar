import 'package02/flutter/material.dart';

void main() {
  runApp(const KasirApp());
}

class KasirApp extends StatelessWidget {
  const KasirApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kasir Pintar',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const DashboardKasir(),
    );
  }
}

class DashboardKasir extends StatelessWidget {
  const DashboardKasir({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Profil
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Kepada, Toko/tn...',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Owner',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.swap_horiz, size: 28),
                ],
              ),
              const SizedBox(height: 20),

              // Backoffice Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.language, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Backoffice Kasir Pintar',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Spacer(),
                    Icon(Icons.chevron_right, color: Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Misi Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Colors.greenAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('Misi dapat hadiah',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Baru!',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu List
              const Text('Toko Online Saya',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              _buildMenuItem(Icons.layers, 'Manajemen'),
              _buildMenuItem(Icons.shopping_cart, 'Transaksi Penjualan'),
              _buildMenuItem(Icons.inventory, 'Pembelian dari Supplier'),
              _buildMenuItem(Icons.account_balance_wallet, 'Keuangan'),
              _buildMenuItem(Icons.bolt, 'PPOB'),
              _buildMenuItem(Icons.description, 'Laporan'),
              _buildMenuItem(Icons.access_time, 'Absensi'),
              _buildMenuItem(Icons.event_note, 'Shift'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 28),
          const SizedBox(width: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
