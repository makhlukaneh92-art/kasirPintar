import 'package:flutter/material.dart';

class EditReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> transactionData;

  const EditReceiptScreen({Key? key, required this.transactionData}) : super(key: key);

  @override
  State<EditReceiptScreen> createState() => _EditReceiptScreenState();
}

class _EditReceiptScreenState extends State<EditReceiptScreen> {
  late String statusPembayaran;
  late String namaPelanggan;
  late List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    statusPembayaran = widget.transactionData['status'] ?? 'LUNAS';
    namaPelanggan = widget.transactionData['pelanggan'] ?? 'Umum';
    
    // Salin items dari transaksi
    List originalItems = widget.transactionData['items'] ?? [];
    items = List<Map<String, dynamic>>.from(
      originalItems.map((item) => {
        'nama': item['nama'] ?? '',
        'harga': item['harga'] ?? 0,
        'qty': item['qty'] ?? 1,
        'diskon': item['diskon'] ?? 0,
        'controller': TextEditingController(text: (item['qty'] ?? 1).toString()),
      })
    );
  }

  int hitungSubtotal() {
    int total = 0;
    for (var item in items) {
      total += ((item['harga'] as int) * (item['qty'] as int));
    }
    return total;
  }

  int hitungTotalDiskon() {
    int totalDiskon = 0;
    for (var item in items) {
      totalDiskon += ((item['diskon'] as int) * (item['qty'] as int));
    }
    return totalDiskon;
  }

  int hitungGrandTotal() {
    return hitungSubtotal() - hitungTotalDiskon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit & Preview Struk'),
        backgroundColor: Color(0xFF00695C),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SEKSI EDIT TRANSAKSI ---
            Text('Pengaturan Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 10),
            
            DropdownButtonFormField<String>(
              value: statusPembayaran,
              decoration: InputDecoration(
                labelText: 'Status Pembayaran',
                border: OutlineInputBorder(),
              ),
              items: ['LUNAS', 'BELUM LUNAS'].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => statusPembayaran = val);
              },
            ),
            SizedBox(height: 12),

            TextFormField(
              initialValue: namaPelanggan,
              decoration: InputDecoration(
                labelText: 'Nama Pelanggan',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => namaPelanggan = val),
            ),
            SizedBox(height: 20),

            Text('Daftar Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                var item = items[index];
                TextEditingController qtyController = item['controller'];

                return Card(
                  margin: EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['nama'], style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Rp ${item['harga']}'),
                            ],
                          ),
                        ),
                        
                        // Tombol Kurang (-)
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () {
                            int current = int.tryParse(qtyController.text) ?? 1;
                            if (current > 1) {
                              setState(() {
                                item['qty'] = current - 1;
                                qtyController.text = (current - 1).toString();
                              });
                            }
                          },
                        ),

                        // Input Manual Angka Qty
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              int? newQty = int.tryParse(val);
                              if (newQty != null && newQty >= 0) {
                                setState(() {
                                  item['qty'] = newQty;
                                });
                              }
                            },
                          ),
                        ),

                        // Tombol Tambah (+)
                        IconButton(
                          icon: Icon(Icons.add_circle_outline, color: Colors.green),
                          onPressed: () {
                            int current = int.tryParse(qtyController.text) ?? 0;
                            setState(() {
                              item['qty'] = current + 1;
                              qtyController.text = (current + 1).toString();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 20),
            Divider(thickness: 2),
            SizedBox(height: 10),

            // --- SEKSI LIVE PREVIEW STRUK THERMAL ---
            Center(
              child: Text(
                '--- PREVIEW STRUK THERMAL ---',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 10),

            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Text('NDRA STORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Jl. Toko Utama No. 123', style: TextStyle(fontSize: 12)),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pelanggan: $namaPelanggan', style: TextStyle(fontSize: 12)),
                      Text('Status: $statusPembayaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Divider(),

                  // List Item di Preview Struk
                  Column(
                    children: items.map((item) {
                      int totalPerItem = (item['harga'] as int) * (item['qty'] as int);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item['nama']} x${item['qty']}', style: TextStyle(fontSize: 12)),
                            Text('Rp $totalPerItem', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  Divider(),
                  if (hitungTotalDiskon() > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Diskon', style: TextStyle(fontSize: 12, color: Colors.red)),
                        Text('- Rp ${hitungTotalDiskon()}', style: TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GRAND TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Rp ${hitungGrandTotal()}', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // --- TOMBOL AKSI SIMPAN & CETAK ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.print),
                    label: Text('Cetak Struk'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Mengirim data ke Printer Bluetooth...')),
                      );
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Simpan Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00695C),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context, true); // Kembali & beri sinyal refresh
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
