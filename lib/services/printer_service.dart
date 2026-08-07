import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/transaction_model.dart';

class PrinterService {
  static final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  static Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await _bluetooth.getBondedDevices();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> isConnected() async {
    return (await _bluetooth.isConnected) ?? false;
  }

  static Future<bool> connect(BluetoothDevice device) async {
    try {
      final connected = await isConnected();
      if (!connected) {
        await _bluetooth.connect(device);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (_) {}
  }

  static String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  static Future<bool> printReceipt(TransactionModel trx, {double paidAmount = 0, double change = 0}) async {
    try {
      bool connected = await isConnected();
      if (!connected) {
        final prefs = await SharedPreferences.getInstance();
        final savedAddress = prefs.getString('printer_address');
        if (savedAddress != null && savedAddress.isNotEmpty) {
          List<BluetoothDevice> devices = await getPairedDevices();
          BluetoothDevice? targetDevice;
          for (var d in devices) {
            if (d.address == savedAddress) {
              targetDevice = d;
              break;
            }
          }
          if (targetDevice != null) {
            bool success = await connect(targetDevice);
            if (!success) return false;
          } else {
            return false;
          }
        } else {
          return false;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      String storeName = prefs.getString('store_name') ?? 'TOKO KASIR PINTAR';
      String storeAddress = prefs.getString('store_address') ?? '';
      String storePhone = prefs.getString('store_phone') ?? '';
      String storeFooter = prefs.getString('store_footer') ?? 'Terima Kasih Atas Kunjungan Anda';
      String? logoPath = prefs.getString('store_logo');

      String dateStr = DateFormat('dd MMM yyyy, HH:mm')
          .format(DateTime.tryParse(trx.transactionDate) ?? DateTime.now());

      // 1. Cetak Logo Toko (Jika Ada & File Terdeteksi)
      if (logoPath != null && logoPath.isNotEmpty && File(logoPath).existsSync()) {
        try {
          await _bluetooth.printImage(logoPath);
          _bluetooth.printNewLine();
        } catch (_) {
          // Jika gambar gagal dimuat/format tidak didukung, proses pencetakan tetap berlanjut
        }
      }

      // 2. Header Struk
      _bluetooth.printCustom(storeName, 2, 1);
      if (storeAddress.isNotEmpty) _bluetooth.printCustom(storeAddress, 1, 1);
      if (storePhone.isNotEmpty) _bluetooth.printCustom("Telp: $storePhone", 1, 1);
      _bluetooth.printCustom("--------------------------------", 1, 1);

      // 3. Info Transaksi
      _bluetooth.printLeftRight("No. Trx:", trx.id, 1);
      _bluetooth.printLeftRight("Tanggal:", dateStr, 1);
      _bluetooth.printLeftRight("Status:", trx.paymentStatus, 1);
      _bluetooth.printCustom("--------------------------------", 1, 1);

      // 4. Detail Barang
      for (var item in trx.items) {
        _bluetooth.printCustom(item.productName, 1, 0);
        _bluetooth.printLeftRight(
          "${item.quantity} x ${_formatRupiah(item.sellPrice)}",
          _formatRupiah(item.subtotal),
          1,
        );
      }

      _bluetooth.printCustom("--------------------------------", 1, 1);
      
      // 5. Total, Bayar, dan Kembalian
      _bluetooth.printLeftRight("TOTAL:", _formatRupiah(trx.totalAmount), 2);
      _bluetooth.printLeftRight("DIBAYAR:", _formatRupiah(paidAmount), 1);
      _bluetooth.printLeftRight("KEMBALIAN:", _formatRupiah(change), 1);
      
      _bluetooth.printCustom("--------------------------------", 1, 1);
      _bluetooth.printCustom(storeFooter, 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();

      return true;
    } catch (e) {
      return false;
    }
  }
}
