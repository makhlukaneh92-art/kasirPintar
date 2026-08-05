import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  List<BluetoothInfo> _devices = [];
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getBluetoothDevices();
  }

  // Scan Perangkat Bluetooth yang Terpasang/Paired
  Future<void> _getBluetoothDevices() async {
    setState(() => _isLoading = true);
    bool isConnected = await PrintBluetoothThermal.connectionStatus;
    final List<BluetoothInfo> list = await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      _devices = list;
      _isConnected = isConnected;
      _isLoading = false;
    });
  }

  // Sambungkan ke Printer
  Future<void> _connect(String macAddress) async {
    setState(() => _isLoading = true);
    final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);

    setState(() {
      _isConnected = result;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Berhasil terhubung ke Printer!' : 'Gagal terhubung ke Printer'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // Tes Cetak Struk Singkat
  Future<void> _testPrint() async {
    if (!_isConnected) return;

    bool isConnected = await PrintBluetoothThermal.connectionStatus;
    if (isConnected) {
      List<int> bytes = [];
      bytes += PrintBluetoothThermal.writeBytes(bytes: [27, 64]); // Reset
      bytes += PrintBluetoothThermal.writeBytes(bytes: [27, 97, 1]); // Align Center
      bytes += PrintBluetoothThermal.writeString(text: "TOKO KASIR PINTAR\n\n", fontSize: 2);
      bytes += PrintBluetoothThermal.writeString(text: "--- TES PRINTER BERHASIL ---\n\n", fontSize: 1);
      bytes += PrintBluetoothThermal.writeBytes(bytes: [10, 10, 10]); // Feed Line

      await PrintBluetoothThermal.writeBytes(bytes: bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koneksi Printer Bluetooth'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Banner Status
          Container(
            padding: const EdgeInsets.all(16),
            color: _isConnected ? Colors.green[100] : Colors.orange[100],
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.warning,
                  color: _isConnected ? Colors.green[800] : Colors.orange[800],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isConnected ? 'Status: Terhubung ke Printer' : 'Status: Belum Terhubung',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isConnected ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                ),
                if (_isConnected)
                  ElevatedButton(
                    onPressed: _testPrint,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('TES CETAK'),
                  ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pilih Printer Bluetooth (Sudah Dihubungkan / Paired):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Daftar Perangkat
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _devices.isEmpty
                    ? const Center(child: Text('Tidak ada perangkat Bluetooth ditemukan.\nPastikan Bluetooth HP aktif dan Printer dalam keadaan ON.'))
                    : ListView.builder(
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          return ListTile(
                            leading: const Icon(Icons.print, color: Color(0xFF00796B)),
                            title: Text(device.name.isNotEmpty ? device.name : 'Unknown Device'),
                            subtitle: Text(device.macAdress),
                            trailing: ElevatedButton(
                              onPressed: () => _connect(device.macAdress),
                              child: const Text('Hubungkan'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
