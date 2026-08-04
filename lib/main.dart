class _KasirPintarAppState extends State<KasirPintarApp> {
StoreInfo storeInfo = StoreInfo(
name: 'TOKO KASIR PINTAR',
address: 'Jl. Merdeka No. 123, Jakarta',
phone: '081234567890',
footer: 'Terima kasih atas kunjungan Anda!',
);
​List<Product> products = [
Product(id: '1', name: 'Kopi Susu', sellingPrice: 15000, modalPrice: 9000, stock: 45),
Product(id: '2', name: 'Roti Bakar', sellingPrice: 12000, modalPrice: 7000, stock: 27),
Product(id: '3', name: 'baso cimol', sellingPrice: 12000, modalPrice: 6000, stock: 192),
];
​List<SalesTransaction> transactions = [];
List<CashEntry> cashEntries = [];
​@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'Toko Kasir Pintar',
theme: ThemeData(
primaryColor: const Color(0xFF00897B),
scaffoldBackgroundColor: Colors.white,
),
home: MainHomeScreen(
storeInfo: storeInfo,
products: products,
transactions: transactions,
cashEntries: cashEntries,
onUpdateStore: (updated) => setState(() => storeInfo = updated),
onUpdateProducts: (updated) => setState(() => products = updated),
onAddTransaction: (trx) => setState(() => transactions.add(trx)),
onUpdateTransactions: (updatedList) => setState(() => transactions = updatedList),
onUpdateCashEntries: (updatedList) => setState(() => cashEntries = updatedList),
),
);
}
}
