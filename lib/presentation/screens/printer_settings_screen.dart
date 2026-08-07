import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/printer_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    setState(() => _isLoading = true);
    try {
      List<BluetoothDevice> devices = await PrinterService.getPairedDevices();
      bool connected = await PrinterService.isConnected();

      final prefs = await SharedPreferences.getInstance();
      String? savedAddress = prefs.getString('printer_address');

      BluetoothDevice? current;
      if (savedAddress != null && savedAddress.isNotEmpty) {
        for (var d in devices) {
          if (d.address == savedAddress) {
            current = d;
            break;
          }
        }
      }

      setState(() {
        _devices = devices;
        _selectedDevice = current ?? (devices.isNotEmpty ? devices.first : null);
        _isConnected = connected;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat perangkat Bluetooth: $e')),
        );
      }
    }
  }

  Future<void> _connectPrinter() async {
    if (_selectedDevice == null) return;
    setState(() => _isLoading = true);

    bool success = await PrinterService.connect(_selectedDevice!);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('printer_address', _selectedDevice!.address ?? '');
      await prefs.setString('printer_name', _selectedDevice!.name ?? '');

      setState(() {
        _isConnected = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil terhubung ke ${_selectedDevice!.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal terhubung ke printer. Pastikan Bluetooth & Printer Aktif!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _disconnectPrinter() async {
    setState(() => _isLoading = true);
    await PrinterService.disconnect();
    setState(() {
      _isConnected = false;
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koneksi printer diputuskan')),
      );
    }
  }

  Future<void> _testPrint() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer belum terhubung!'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String storeName = prefs.getString('store_name') ?? 'TOKO KASIR PINTAR';

      BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
      bluetooth.printCustom(storeName, 2, 1);
      bluetooth.printCustom("TEST PRINT STRUK", 1, 1);
      bluetooth.printCustom("Printer Berhasil Terhubung!", 0, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test print terkirim ke printer!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal test print: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer Bluetooth'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: _isConnected ? Colors.green[50] : Colors.red[50],
                    child: ListTile(
                      leading: Icon(
                        _isConnected ? Icons.print : Icons.print_disabled,
                        color: _isConnected ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      title: Text(
                        _isConnected ? 'Status: TERHUBUNG' : 'Status: TERPUTUS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isConnected ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                      subtitle: Text(_selectedDevice?.name ?? 'Belum ada printer dipilih'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pilih Perangkat Printer Bluetooth (Paired):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _devices.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'Tidak ada printer bluetooth ditemukan. Pastikan Anda sudah melakukan "Pairing" Bluetooth Printer di Pengaturan HP Anda terlebih dahulu.',
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<BluetoothDevice>(
                              isExpanded: true,
                              value: _selectedDevice,
                              items: _devices.map((device) {
                                return DropdownMenuItem(
                                  value: device,
                                  child: Text('${device.name} (${device.address})'),
                                );
                              }).toList(),
                              onChanged: (device) {
                                setState(() {
                                  _selectedDevice = device;
                                });
                              },
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isConnected ? _disconnectPrinter : _connectPrinter,
                          icon: Icon(_isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_connected),
                          label: Text(_isConnected ? 'PUTUSKAN' : 'HUBUNGKAN'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isConnected ? Colors.red[700] : const Color(0xFF00796B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _initPrinter,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Perangkat',
                      )
                    ],
                  ),
                  if (_isConnected) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _testPrint,
                        icon: const Icon(Icons.receipt, color: Color(0xFF00796B)),
                        label: const Text('TEST PRINT STRUK', style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00796B)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
