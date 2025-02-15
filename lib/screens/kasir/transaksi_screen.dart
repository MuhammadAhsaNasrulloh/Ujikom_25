import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:waixilaundry/helper/thermal_helper.dart';

class CartItem {
  final int productId;
  final String productName;
  final double productPrice;
  final int? unitId; // Change this to int
  final String unitName;
  int quantity;
  SelectedService? selectedService; 

  CartItem({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.unitId, // Change this to int
    required this.unitName,
    this.quantity = 1,
    this.selectedService,
  });

  double get total => productPrice * quantity + (selectedService?.servicePrice ?? 0);
}
class SelectedService {
  final int serviceId;
  final String serviceName;
  final double servicePrice;

  SelectedService({
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
  });
}
class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bayarController = TextEditingController();
  final _kembalianController = TextEditingController();
  final _totalHargaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _namaPelangganController = TextEditingController();
  final _noHpController = TextEditingController(text: '+62 ');

  final _supabase = Supabase.instance.client;
  String _status = 'pending';
  String? _kasirId;
  int? _selectedLayananId;
  double? _selectedServicePrice;
  String? _selectedServiceName;
  List<CartItem> _cartItems = [];
  List<SelectedService> _selectedServices = [];
  int? _selectedPelangganId;
  List<Map<String, dynamic>>? _customerSearchResults;
  bool _isSearching = false;
  final ThermalPrinterHelper _printerHelper = ThermalPrinterHelper();
  BluetoothDevice? _selectedPrinter;
  bool _isPrinterConnected = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchKasirId();
    _noHpController.addListener(() {
      final text = _noHpController.text;
      if (!text.startsWith('+62 ')) {
        _noHpController.text = '+62 ${text.replaceAll('+62 ', '')}';
        _noHpController.selection = TextSelection.fromPosition(
          TextPosition(offset: _noHpController.text.length),
        );
      }
    });
    _initializePrinter();
  }

  @override
  void dispose() {
    _bayarController.dispose();
    _kembalianController.dispose();
    _totalHargaController.dispose();
    _alamatController.dispose();
    _namaPelangganController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  Future<void> _initializePrinter() async {
    try {
      if (await _printerHelper.checkPermissions()) {
        final devices = await _printerHelper.getPairedDevices();
        if (devices.isNotEmpty) {
          setState(() => _selectedPrinter = devices.first);
          await _connectPrinter();
        }
      }
    } catch (e) {
      print('Printer initialization error: $e');
    }
  }
   Future<void> _connectPrinter() async {
    if (_selectedPrinter == null) return;
    
    try {
      await _printerHelper.connectToDevice(_selectedPrinter!);
      setState(() => _isPrinterConnected = true);
    } catch (e) {
      print('Printer connection error: $e');
      setState(() => _isPrinterConnected = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printer connection failed: $e')),
      );
    }
  }

  bool _validateTransaction() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang belanja masih kosong')),
      );
      return false;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu layanan')),
      );
      return false;
    }

    if (_totalHargaController.text.isEmpty || 
        double.tryParse(_totalHargaController.text) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total harga tidak valid')),
      );
      return false;
    }

    if (_bayarController.text.isEmpty || 
        double.tryParse(_bayarController.text) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah pembayaran tidak valid')),
      );
      return false;
    }

    final bayar = double.tryParse(_bayarController.text) ?? 0;
    final total = double.tryParse(_totalHargaController.text) ?? 0;
    if (bayar < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran kurang dari total harga')),
      );
      return false;
    }

    if (_selectedPelangganId == null && 
        (_namaPelangganController.text.isEmpty || 
         _alamatController.text.isEmpty || 
         _noHpController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pelanggan tidak lengkap')),
      );
      return false;
    }

    return true;
  }
  Future<void> _fetchKasirId() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .eq('role', 'kasir')
          .maybeSingle();

      if (response != null) {
        setState(() {
          _kasirId = response['id'];
        });
      } else {
        print('Kasir profile not found');
        // Handle the case where the user is not a kasir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Anda tidak memiliki akses sebagai kasir')),
        );
      }
    } else {
      print('User not logged in');
      setState(() {
        _kasirId = null;
      });
    }
  }

  Future<String> _generateKodeUnik() async {
    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';

    final lastTransaction = await _supabase
        .from('transactions')
        .select('id')
        .order('id', ascending: false)
        .limit(1)
        .maybeSingle();

    int nextTransactionId = 1;
    if (lastTransaction != null) {
      nextTransactionId = lastTransaction['id'] + 1;
    }

    return 'WXL-$formattedDate-$nextTransactionId';
  }
  
  Future<void> _searchCustomers(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _customerSearchResults = null;
          _isSearching = false;
        });
        return;
      }

      setState(() => _isSearching = true);
      
      try {
        final response = await _supabase
            .from('pelanggans')
            .select()
            .or('nama_pelanggan.ilike.%$query%,no_hp.ilike.%$query%')
            .limit(5);

        setState(() {
          _customerSearchResults = List<Map<String, dynamic>>.from(response);
          _isSearching = false;
        });
      } catch (e) {
        print('Error searching customers: $e');
        setState(() => _isSearching = false);
      }
    });
  }
  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('id, produk, harga, unit_id(id, unit)');
      print('Products fetched: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchServices() async {
    try {
      final response =
          await _supabase.from('services').select('id, layanan, harga_layanan');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  Future<void> _printTransactionInvoice(int transactionId) async {
    try {
      // Fetch transaction details
      final transactionData = await _supabase.from('transactions').select('''
            *,
            profiles:kasir_id(name),
            pelanggans:pelanggan_id(nama_pelanggan)
          ''').eq('id', transactionId).single();

      // Fetch transaction details
      final detailTransaksi =
          await _supabase.from('detail_transaction').select('''
            *,
            products:produk_id(produk),
            services:layanan_id(layanan),
            units:unit_id(unit)
          ''').eq('transaksi_id', transactionId);

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                width: 400,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      "Waixi Laundry",
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      width: double.infinity,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                              "Transaction ID: ${transactionData['kode_unik']}",
                              style: pw.TextStyle(fontSize: 12)),
                          pw.Text(
                              "Cashier: ${transactionData['profiles']['name'] ?? 'Unknown'}",
                              style: pw.TextStyle(fontSize: 12)),
                          pw.Text(
                              "Customer: ${transactionData['pelanggans']['nama_pelanggan'] ?? 'Unknown'}",
                              style: pw.TextStyle(fontSize: 12)),

                          pw.Divider(thickness: 1),
                          pw.Text("Items:",
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 10),

                          // Services section
                          ...detailTransaksi
                              .where((detail) => detail['layanan_id'] != null)
                              .map((detail) {
                            return pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Expanded(
                                  child: pw.Text(
                                    "Service: ${detail['services']['layanan']}",
                                    style: pw.TextStyle(fontSize: 12),
                                  ),
                                ),
                                pw.Text(
                                  "Rp${detail['harga_layanan']}",
                                  style: pw.TextStyle(fontSize: 12),
                                ),
                              ],
                            );
                          }).toList(),

                          pw.SizedBox(height: 10),

                          // Products section
                          ...detailTransaksi
                              .where((detail) => detail['produk_id'] != null)
                              .map((detail) {
                            return pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Expanded(
                                  child: pw.Text(
                                    "Product: ${detail['products']['produk']} x ${detail['qty']} ${detail['units']['unit']}",
                                    style: pw.TextStyle(fontSize: 12),
                                  ),
                                ),
                                pw.Text(
                                  "Rp${detail['harga_produk']}",
                                  style: pw.TextStyle(fontSize: 12),
                                ),
                              ],
                            );
                          }).toList(),

                          pw.Divider(thickness: 1),

                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Total:",
                                  style: pw.TextStyle(fontSize: 12)),
                              pw.Text("Rp${transactionData['total_harga']}",
                                  style: pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Paid:",
                                  style: pw.TextStyle(fontSize: 12)),
                              pw.Text("Rp${transactionData['bayar']}",
                                  style: pw.TextStyle(fontSize: 12)),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Change:",
                                  style: pw.TextStyle(fontSize: 12)),
                              pw.Text("Rp${transactionData['kembalian']}",
                                  style: pw.TextStyle(fontSize: 12)),
                            ],
                          ),

                          pw.Divider(thickness: 1),

                          pw.Center(
                            child: pw.Text(
                              "${transactionData['created_at']?.toString().split('.')[0] ?? 'Unknown Date'}",
                              style: pw.TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Waixi Laundry Invoice - ${transactionData['kode_unik']}',
      );
    } catch (e) {
      print('Error printing invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mencetak invoice')),
      );
    }
  }

  void _updateTotalPrices() {
  double total = _cartItems.fold(0, (sum, item) {
    // Hitung total per item (harga produk * quantity + harga service jika ada)
    return sum + (item.productPrice * item.quantity) + (item.selectedService?.servicePrice ?? 0);
  });
  
  _totalHargaController.text = total.toString();
  }

  void _calculateKembalian() {
    if (_bayarController.text.isNotEmpty &&
        _totalHargaController.text.isNotEmpty) {
      try {
        final bayar = double.parse(_bayarController.text);
        final total = double.parse(_totalHargaController.text);
        final kembalian = bayar - total;
        _kembalianController.text = kembalian.toStringAsFixed(2);
      } catch (e) {
        _kembalianController.text = '0';
      }
    }
  }

  void addServiceToProduct(int cartItemIndex, SelectedService service) {
    setState(() {
      _cartItems[cartItemIndex].selectedService = service;
      _updateTotalPrices();
    });
  }

  void removeServiceFromProduct(int cartItemIndex) {
    setState(() {
      _cartItems[cartItemIndex].selectedService = null;
      _updateTotalPrices();
    });
  }
  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final unitId = product['unit_id']?['id'] ?? 0; // Default to 0 if null
      final unitName =
          product['unit_id']?['unit'] ?? 'Unknown'; // Default if null
      final existingItemIndex =
          _cartItems.indexWhere((item) => item.productId == product['id']);

      if (existingItemIndex != -1) {
        _cartItems[existingItemIndex].quantity++;
      } else {
        _cartItems.add(CartItem(
            productId: product['id'],
            productName: product['produk'],
            productPrice: product['harga'],
            unitId: unitId, // Check the unit ID access
            unitName: unitName));
      }
      print("Cart Items: ${_cartItems.map((e) => e.productName).toList()}");
      _updateTotalPrices();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _updateTotalPrices();
      if (_cartItems.isEmpty) {
        _totalHargaController.clear();
      }
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _cartItems[index].quantity = newQuantity;
        _updateTotalPrices();
      });
    }
  }

  // Tambahkan fungsi untuk menampilkan dialog konfirmasi
  Future<void> _showConfirmationDialog() async {
  // Format currency untuk tampilan yang lebih baik
  final formatCurrency = (double value) => 
      'Rp${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Konfirmasi Transaksi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mohon periksa kembali detail transaksi:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              
              // Informasi Pelanggan
              Text('Pelanggan: ${_namaPelangganController.text}'),
              Text('No. HP: ${_noHpController.text}'),
              Text('Alamat: ${_alamatController.text}'),
              const Divider(),
              
              // Detail Items
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.w500)),
              ...(_cartItems.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.productName} (${item.quantity} ${item.unitName})'),
                    if (item.selectedService != null)
                      Text('+ ${item.selectedService!.serviceName}',
                          style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ))),
              const Divider(),
              
              // Informasi Pembayaran
              Text('Total: ${formatCurrency(double.parse(_totalHargaController.text))}'),
              Text('Bayar: ${formatCurrency(double.parse(_bayarController.text))}'),
              Text('Kembalian: ${formatCurrency(double.parse(_kembalianController.text))}'),
              const Divider(),
              
              Text('Status: $_status'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Periksa Kembali'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF005BAC),
            ),
            child: const Text('Konfirmasi & Simpan'),
            onPressed: () {
              Navigator.of(context).pop();
              _processTransaction();
            },
          ),
        ],
      );
    },
  );
}

// Pindahkan logika penyimpanan transaksi ke fungsi terpisah
Future<void> _processTransaction() async {
  try {
    int pelangganId;
    if (_selectedPelangganId == null) {
      final pelangganResponse = await _supabase.from('pelanggans').insert({
        'nama_pelanggan': _namaPelangganController.text,
        'alamat': _alamatController.text,
        'no_hp': _noHpController.text,
      }).select().single();
      pelangganId = pelangganResponse['id'];
    } else {
      pelangganId = _selectedPelangganId!;
    }

    final kodeUnik = await _generateKodeUnik();
    
    final transactionResponse = await _supabase
        .from('transactions')
        .insert({
          'kode_unik': kodeUnik,
          'kasir_id': _kasirId,
          'pelanggan_id': pelangganId,
          'total_harga': double.parse(_totalHargaController.text),
          'bayar': double.parse(_bayarController.text),
          'kembalian': double.parse(_kembalianController.text),
          'is_deleted': false,
        })
        .select()
        .single();

    final int transactionId = transactionResponse['id'];

    // Insert transaction details
    for (var item in _cartItems) {
      await _supabase.from('detail_transaction').insert({
        'transaksi_id': transactionId,
        'status': _status,
        'produk_id': item.productId,
        'harga_produk': item.productPrice * item.quantity,
        'layanan_id': item.selectedService?.serviceId,
        'harga_layanan': item.selectedService?.servicePrice ?? 0,
        'qty': item.quantity,
        'unit_id': item.unitId,
      });
    }

    // Print receipt
    if (_isPrinterConnected) {
      await _printThermalReceipt(transactionResponse, _cartItems);
    } else {
      await _printTransactionInvoice(transactionId);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan!')),
    );

    _resetForm();
  } catch (e) {
    print('Error detail: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

// Modifikasi fungsi _submitForm untuk menampilkan dialog
Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate() || !_validateTransaction()) {
    return;
  }

  await _showConfirmationDialog();
}

  Future<void> _printThermalReceipt(Map<String, dynamic> transaction, List<CartItem> items) async {
    try {
      if (!_isPrinterConnected || _selectedPrinter == null) {
        throw Exception('Printer not connected');
      }

      // Convert cart items to detail format expected by printer
      final details = items.map((item) => {
        'produk_id': item.productId,
        'products': {'produk': item.productName},
        'qty': item.quantity,
        'units': {'unit': item.unitName},
        'harga_produk': item.productPrice * item.quantity,
        'layanan_id': item.selectedService?.serviceId,
        'services': item.selectedService != null 
          ? {'layanan': item.selectedService!.serviceName}
          : null,
        'harga_layanan': item.selectedService?.servicePrice ?? 0,
      }).toList();

      await _printerHelper.printReceipt(transaction, details);
    } catch (e) {
      print('Thermal printing error: $e');
      // Fallback to PDF printing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mencetak ke printer thermal, beralih ke PDF...')),
      );
      await _printTransactionInvoice(transaction['id']);
    }
  }

  // Add printer selection UI in the build method
  Widget _buildPrinterSelection() {
    return FutureBuilder<List<BluetoothDevice>>(
      future: _printerHelper.getPairedDevices(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        return _buildDropdown<BluetoothDevice>(
          label: 'Pilih Printer',
          value: _selectedPrinter,
          items: snapshot.data!.map((device) => DropdownMenuItem(
            value: device,
            child: Text(device.name ?? 'Unknown device'),
          )).toList(),
          onChanged: (device) async {
            if (device != null) {
              setState(() => _selectedPrinter = device);
              await _connectPrinter();
            }
          },
        );
      },
    );
  }

   Widget _buildCustomerSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _namaPelangganController,
          label: 'Cari Pelanggan (Nama/No.HP)',
          onChanged: _searchCustomers,
        ),
        if (_isSearching)
          const Center(child: CircularProgressIndicator())
        else if (_customerSearchResults != null && _customerSearchResults!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _customerSearchResults!.map((customer) {
                return ListTile(
                  title: Text(customer['nama_pelanggan']),
                  subtitle: Text('${customer['no_hp']} - ${customer['alamat']}'),
                  onTap: () {
                    setState(() {
                      _selectedPelangganId = customer['id'];
                      _namaPelangganController.text = customer['nama_pelanggan'];
                      _noHpController.text = customer['no_hp'];
                      _alamatController.text = customer['alamat'];
                      _customerSearchResults = null;
                    });
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _namaPelangganController.clear();
    _alamatController.clear();
    _noHpController.clear();
    _bayarController.clear();
    _kembalianController.clear();
    _totalHargaController.clear();
    setState(() {
      _cartItems.clear();
      _selectedServices.clear();
      _status = 'pending';
    });
  }

  Widget _buildCard({
    required String title,
    required List<Widget> children,
    EdgeInsets? padding,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF005BAC), width: 2),
              ),
              filled: true,
              fillColor: readOnly ? const Color(0xFFF5F5F5) : Colors.white,
            ),
            readOnly: readOnly,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
            style: TextStyle(
              color:
                  readOnly ? const Color(0xFF666666) : const Color(0xFF1A1A1A),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildSelectedServices() {
    return Column(
      children: _selectedServices.map((service) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${service.servicePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _selectedServices.removeWhere(
                      (s) => s.serviceId == service.serviceId
                    );
                    if (_selectedServices.isEmpty) {
                      _selectedLayananId = null;  // Tambahkan ini
                    }
                    _updateTotalPrices();
                  });
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Modify the service selection part in the build method
  Widget _buildServiceSelection() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _fetchServices(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        children: [
          _buildDropdown<int>(
            label: 'Pilih Layanan',
            value: null,
            items: snapshot.data!.map((service) {
              return DropdownMenuItem<int>(
                value: service['id'],
                child: Text(
                  '${service['layanan']} - Rp${service['harga_layanan']}',
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final service = snapshot.data!.firstWhere(
                  (s) => s['id'] == value,
                );
                
                // Check if service is already selected
                if (!_selectedServices.any((s) => s.serviceId == value)) {
                  setState(() {
                    _selectedLayananId = value;  // Tambahkan ini
                    _selectedServices.add(SelectedService(
                      serviceId: value,
                      serviceName: service['layanan'],
                      servicePrice: service['harga_layanan'].toDouble(),
                    ));
                    _updateTotalPrices();
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Layanan ini sudah dipilih'),
                    ),
                  );
                }
              }
            },
            validator: (value) => _selectedServices.isEmpty ? 'Pilih layanan' : null,
          ),
          if (_selectedServices.isNotEmpty) _buildSelectedServices(),
        ],
      );
    },
  );
}

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF005BAC), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.unitName} - Rp ${item.productPrice.toStringAsFixed(2)} x ${item.quantity}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    if (item.selectedService != null)
                      Text(
                        'Service: ${item.selectedService!.serviceName} - Rp ${item.selectedService!.servicePrice}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () => _updateQuantity(index, item.quantity - 1),
                      color: const Color(0xFF666666),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => _updateQuantity(index, item.quantity + 1),
                      color: const Color(0xFF666666),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeFromCart(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Dropdown untuk memilih service
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchServices(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              return DropdownButtonFormField<int>(
                value: item.selectedService?.serviceId,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Pilih Service',
                ),
                items: [
                  // Opsi untuk tidak memilih service
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Tanpa Service'),
                  ),
                  // Daftar service yang tersedia
                  ...snapshot.data!.map((service) {
                    return DropdownMenuItem<int>(
                      value: service['id'],
                      child: Text(
                        '${service['layanan']} - Rp${service['harga_layanan']}',
                      ),
                    );
                  }),
                ],
                onChanged: (serviceId) {
                  if (serviceId == null) {
                    removeServiceFromProduct(index);
                  } else {
                    final service = snapshot.data!.firstWhere(
                      (s) => s['id'] == serviceId,
                    );
                    addServiceToProduct(
                      index,
                      SelectedService(
                        serviceId: serviceId,
                        serviceName: service['layanan'],
                        servicePrice: service['harga_layanan'].toDouble(),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Waixi Laundry',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildCard(
              title: 'Informasi Pelanggan',
              children: [
                _buildCustomerSearch(),
                if (_selectedPelangganId == null) ...[
                  _buildTextField(
                    controller: _alamatController,
                    label: 'Alamat',
                    validator: (value) => value?.isEmpty ?? true ? 'Wajib diisi' : null,
                  ),
                  _buildTextField(
                    controller: _noHpController,
                    label: 'No. HP',
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty ?? true ? 'Wajib diisi' : null,
                  ),
                ],
              ],
            ),
            _buildCard(
              title: 'Layanan Laundry',
              children: [
                _buildServiceSelection(),
              ],
            ),
            _buildCard(
              title: 'Detail Pesanan',
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchProducts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Column(
                      children: [
                        _buildDropdown<int>(
                          label: 'Pilih Produk',
                          value: null,
                          items: snapshot.data!.map((product) {
                            final unit = product['unit_id'];
                            return DropdownMenuItem<int>(
                              value: product['id'],
                              child: Text(
                                '${product['produk']} (${unit['unit']}) - Rp${product['harga']}',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              final product = snapshot.data!.firstWhere(
                                (p) => p['id'] == value,
                              );
                              _addToCart(product);
                            }
                          },
                        ),
                        if (_cartItems.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ..._cartItems.asMap().entries.map(
                                (entry) =>
                                    _buildCartItem(entry.value, entry.key),
                              ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
            _buildCard(
              title: 'Pembayaran',
              children: [
                _buildTextField(
                  controller: _totalHargaController,
                  label: 'Total Harga',
                  readOnly: true,
                ),
                _buildTextField(
                  controller: _bayarController,
                  label: 'Bayar',
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Wajib diisi' : null,
                  onChanged: (_) => _calculateKembalian(),
                ),
                _buildTextField(
                  controller: _kembalianController,
                  label: 'Kembalian',
                  readOnly: true,
                ),
                _buildDropdown<String>(
                  label: 'Status',
                  value: _status,
                  items: ['pending', 'diterima', 'diproses', 'selesai']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
              ],
            ),_buildCard(
              title: 'Printer Settings',
              children: [
                _buildPrinterSelection(),
                if (_isPrinterConnected)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Printer connected',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005BAC),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Simpan Transaksi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
