import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Mengaktifkan orientasi Portrait dan Landscape (HP & Tablet)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const KasirApp());
}

class KasirApp extends StatefulWidget {
  const KasirApp({Key? key}) : super(key: key);

  @override
  State<KasirApp> createState() => _KasirAppState();
}

class _KasirAppState extends State<KasirApp> {
  // Data Identitas Toko Utama
  StoreInfo storeInfo = StoreInfo(
    name: 'NDRA STORE',
    address: 'Jl. Merdeka No. 123, Jakarta',
    phone: '081234567890',
    footer: 'Terima kasih atas kunjungan Anda!',
  );

  // Sample Data Produk Awal
  List<Product> products = [
    Product(id: '1', name: 'Baso Cimol', costPrice: 8000, sellPrice: 12000, stock: 100),
    Product(id: '2', name: 'Roti Bakar', costPrice: 7000, sellPrice: 12000, stock: 50),
    Product(id: '3', name: 'Kopi Susu', costPrice: 9000, sellPrice: 15000, stock: 80),
  ];

  // Riwayat Transaksi & Kas
  List<SalesTransaction> transactions = [];
  List<CashEntry> cashEntries = [];

  void _updateStore(StoreInfo newStore) {
    setState(() {
      storeInfo = newStore;
    });
  }

  void _updateProducts(List<Product> newProducts) {
    setState(() {
      products = newProducts;
    });
  }

  void _addTransaction(SalesTransaction tx) {
    setState(() {
      transactions.insert(0, tx);
      // Kurangi stok produk otomatis
      for (var item in tx.items) {
        final idx = products.indexWhere((p) => p.id == item.product.id);
        if (idx != -1) {
          products[idx].stock -= item.quantity;
        }
      }
    });
  }

  void _updateTransactions(List<SalesTransaction> newTxs) {
    setState(() {
      transactions = newTxs;
    });
  }

  void _updateCashEntries(List<CashEntry> newEntries) {
    setState(() {
      cashEntries = newEntries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasir Pintar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: false,
      ),
      home: MainHomeScreen(
        storeInfo: storeInfo,
        products: products,
        transactions: transactions,
        cashEntries: cashEntries,
        onUpdateStore: _updateStore,
        onUpdateProducts: _updateProducts,
        onAddTransaction: _addTransaction,
        onUpdateTransactions: _updateTransactions,
        onUpdateCashEntries: _updateCashEntries,
      ),
    );
  }
}
