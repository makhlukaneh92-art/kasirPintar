import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../models.dart';
import 'product_screen.dart';
import 'cashier_screen.dart';
import 'finance_screen.dart';
import 'report_screen.dart';
class MainHomeScreen extends StatefulWidget {
final StoreInfo storeInfo;
final List<Product> products;
final List<SalesTransaction> transactions;
final List<CashEntry> cashEntries;
final Function(StoreInfo) onUpdateStore;
final Function(List<Product>) onUpdateProducts;
final Function(SalesTransaction) onAddTransaction;
final Function(List<SalesTransaction>) onUpdateTransactions;
final Function(List<CashEntry>) onUpdateCashEntries;
  const MainHomeScreen({
Key? key,
required this.storeInfo,
required this.products,
required this.transactions,
required this.cashEntries,
required this.onUpdateStore,
required this.onUpdateProducts,
required this.onAddTransaction,
required this.onUpdateTransactions,
required this.onUpdateCashEntries,
}) : super(key: key);
@override
State<MainHomeScreen> createState() => _MainHomeScreenState();
}
class _MainHomeScreenState extends State<MainHomeScreen> {
BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
List<BluetoothDevice> _devices = [];
BluetoothDevice? _selectedDevice;
bool _isConnected = false;
  @override
void initState() {
super.initState();
_initBluetooth();
}
  void _initBluetooth() async {
try {
bool? isConnected = await bluetooth.isConnected;
List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
setState(() {
_devices = devices;
_isConnected = isConnected ?? false;
});
} catch (e) {
debugPrint("Bluetooth error: $e");
}
}
  void _showPrinterDialog() {
showDialog(
context: context,
builder: (ctx) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
title: const Text('Pilih Printer Bluetooth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
content: SizedBox(
width: double.maxFinite,
child: _devices.isEmpty
? const Padding(
padding: EdgeInsets.symmetric(vertical: 8.0),
child: Text('Tidak ada perangkat Bluetooth terpasang.', style: TextStyle(color: Colors.grey)),
)
: ListView.builder(
shrinkWrap: true,
itemCount: _devices.length,
itemBuilder: (context, index) {
final device = _devices[index];
return ListTile(
title: Text(device.name ?? 'Unknown Device'),
subtitle: Text(device.address ?? ''),
trailing: _selectedDevice?.address == device.address && _isConnected
? const Icon(Icons.check_circle, color: Colors.green)
: null,
onTap: () async {
try {
await bluetooth.connect(device);
setState(() {
_selectedDevice = device;
_isConnected = true;
});
Navigator.pop(ctx);
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Gagal menghubungkan printer!')),
);
}
},
);
},
),
),
actions: [
if (_isConnected)
TextButton(
onPressed: () async {
await bluetooth.disconnect();
setState(() {
_isConnected = false;
_selectedDevice = null;
});
Navigator.pop(ctx);
},
child: const Text('Putuskan', style: TextStyle(color: Colors.red)),
),
TextButton(
onPressed: () => Navigator.pop(ctx),
child: const Text('Tutup', style: TextStyle(color: Colors.purple)),
),
],
),
);
}
  void _showStoreSettingsDialog() {
final nameCtrl = TextEditingController(text: widget.storeInfo.name);
final addressCtrl = TextEditingController(text: widget.storeInfo.address);
final phoneCtrl = TextEditingController(text: widget.storeInfo.phone);
final footerCtrl = TextEditingController(text: widget.storeInfo.footer);
File? tempImage = widget.storeInfo.logoFile;
    showDialog(
context: context,
builder: (ctx) => StatefulBuilder(
builder: (context, setDialogState) {
return AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('Pengaturan Identitas Toko', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
content: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
height: 80,
width: 80,
decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
child: tempImage != null
? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(tempImage!, fit: BoxFit.cover))
: const Icon(Icons.storefront, size: 40, color: Colors.grey),
),
const SizedBox(height: 8),
OutlinedButton.icon(
onPressed: () async {
final picker = ImagePicker();
final picked = await picker.pickImage(source: ImageSource.gallery);
if (picked != null) {
setDialogState(() => tempImage = File(picked.path));
}
},
icon: const Icon(Icons.image, size: 18, color: Colors.purple),
label: const Text('Pilih Logo Toko', style: TextStyle(color: Colors.purple)),
),
const SizedBox(height: 12),
TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Toko / Usaha')),
TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Alamat Toko')),
TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Nomor Telepon / WA')),
TextField(controller: footerCtrl, decoration: const InputDecoration(labelText: 'Pesan Kaki Struk (Footer)')),
],
),
),
actions: [
TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.purple))),
ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
onPressed: () {
widget.onUpdateStore(StoreInfo(
name: nameCtrl.text,
address: addressCtrl.text,
phone: phoneCtrl.text,
footer: footerCtrl.text,
logoFile: tempImage,
));
Navigator.pop(ctx);
},
child: const Text('Simpan'),
),
],
);
},
),
);
}
  @override
  Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
backgroundColor: const Color(0xFF00897B),
title: Text(
widget.storeInfo.name.toUpperCase(),
style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
),
actions: [
IconButton(icon: const Icon(Icons.storefront, color: Colors.white), onPressed: _showStoreSettingsDialog),
IconButton(
icon: Icon(Icons.print, color: _isConnected ? Colors.lightGreenAccent : Colors.white),
onPressed: _showPrinterDialog,
),
],
),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
GestureDetector(
onTap: _showPrinterDialog,
child: Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
borderRadius: BorderRadius.circular(12),
border: Border.all(color: _isConnected ? Colors.green.shade300 : Colors.orange.shade200),
),
child: Row(
children: [
Icon(Icons.print, color: _isConnected ? Colors.green : Colors.orange),
const SizedBox(width: 12),
Expanded(
child: Text(
_isConnected
? 'Printer Terhubung: ${_selectedDevice?.name}'
: 'Printer Belum Terhubung (Ketuk ikon printer di atas)',
style: TextStyle(
color: _isConnected ? Colors.green.shade800 : Colors.orange.shade900,
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
),
],
),
),
),
const SizedBox(height: 20),
const Text('Menu Utama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
const SizedBox(height: 12),
_buildMenuItem(context, Icons.storefront, 'Pengaturan Identitas & Logo Toko', _showStoreSettingsDialog),
_buildMenuItem(context, Icons.layers, 'Manajemen Produk (Jual & Modal)', () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ProductManagementScreen(products: widget.products, onUpdateProducts: widget.onUpdateProducts),
),
);
}),
_buildMenuItem(context, Icons.shopping_cart, 'Transaksi Penjualan (Kasir)', () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => CashierScreen(
products: widget.products,
storeInfo: widget.storeInfo,
bluetooth: bluetooth,
isConnected: _isConnected,
onAddTransaction: widget.onAddTransaction,
),
),
);
}),
_buildMenuItem(context, Icons.account_balance_wallet, 'Keuangan & Laba Bersih', () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => FinanceScreen(
transactions: widget.transactions,
cashEntries: widget.cashEntries,
onUpdateCashEntries: widget.onUpdateCashEntries,
),
),
);
}),
_buildMenuItem(context, Icons.assignment, 'Laporan Penjualan & Edit Struk', () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ReportScreen(
transactions: widget.transactions,
products: widget.products,
bluetooth: bluetooth,
isConnected: _isConnected,
onUpdateTransactions: widget.onUpdateTransactions,
onUpdateProducts: widget.onUpdateProducts,
),
),
);
}),
],
),
),
);
}
  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
return ListTile(
onTap: onTap,
leading: Icon(icon, color: const Color(0xFF00897B), size: 28),
title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
contentPadding: const EdgeInsets.symmetric(vertical: 4),
);
}
}
