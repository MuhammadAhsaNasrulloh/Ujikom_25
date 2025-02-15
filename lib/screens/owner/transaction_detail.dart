import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionDetailOwner extends StatefulWidget {
  final Map<String, dynamic> transaksi;
  const TransactionDetailOwner({super.key, required this.transaksi});

  @override
  State<TransactionDetailOwner> createState() => _TransactionDetailOwnerState();
}

class _TransactionDetailOwnerState extends State<TransactionDetailOwner> {
  static const Color primaryColor = Color(0xFF2563EB);
  final _supabase = Supabase.instance.client;
  late Future<List<dynamic>> _futureDetailTransaksi;
  String _currentStatus = 'diterima'; // Default status

  @override
  void initState() {
    super.initState();
    _futureDetailTransaksi = _fetchDetailTransaksi();

    // Extract the status value from the list of maps
    if (widget.transaksi['status'] is List) {
      final statusList = widget.transaksi['status'] as List;
      if (statusList.isNotEmpty) {
        _currentStatus = statusList[0]['status']?.toString() ?? 'diterima';
      } else {
        _currentStatus = 'diterima'; // Default value if the list is empty
      }
    } else {
      _currentStatus = widget.transaksi['status']?.toString() ?? 'diterima';
    }
  }

  Future<List<dynamic>> _fetchDetailTransaksi() async {
    try {
      final response = await _supabase.from('detail_transaction').select('''
            *,
            products:produk_id(id, produk, harga),
            services:layanan_id(id, layanan, harga_layanan, durasi),
            units: unit_id(id, unit)
          ''').eq('transaksi_id', widget.transaksi['id']);

      if (response != null && response is List) {
        return response;
      } else {
        throw Exception('No data found');
      }
    } catch (e) {
      throw Exception('Error fetching transaction details: $e');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: CircularProgressIndicator());
          },
        );
      }

      // Fetch all detail transactions first
      final detailTransaksi = await _supabase
          .from('detail_transaction')
          .select()
          .eq('transaksi_id', widget.transaksi['id']);

      if (detailTransaksi == null || (detailTransaksi as List).isEmpty) {
        throw Exception('No detail transactions found');
      }

      // Update all detail transactions with the new status
      await _supabase.from('detail_transaction').update(
          {'status': newStatus}).eq('transaksi_id', widget.transaksi['id']);

      // Update local state
      setState(() {
        _currentStatus = newStatus;
        // Refresh the detail transaction data
        _futureDetailTransaksi = _fetchDetailTransaksi();
      });

      // Hide loading indicator
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status berhasil diupdate ke $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating status: $e'); // Untuk debugging
      // Hide loading indicator
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupdate status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this new widget for status selection
  Widget _buildStatusSelector() {
  return Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Update Status",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _currentStatus,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'diterima', child: Text('Diterima')),
              DropdownMenuItem(value: 'diproses', child: Text('Diproses')),
              DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
            ],
            onChanged: (String? newValue) {
              if (newValue != null && newValue != _currentStatus) {
                _updateStatus(newValue);
              }
            },
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureDetailTransaksi,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transaction details found.'));
          } else {
            final dataTransaction = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusSelector(), // Add the status selector here
                    const SizedBox(height: 16),
                    _buildTransactionHeader(dataTransaction),
                    const SizedBox(height: 16),
                    _buildServiceDetails(dataTransaction),
                    const SizedBox(height: 16),
                    _buildProductDetails(dataTransaction),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'diterima':
        return Colors.blue;
      case 'diproses':
        return Colors.orange;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'diterima':
        return 'Diterima';
      case 'diproses':
        return 'Diproses';
      case 'selesai':
        return 'Selesai';
      default:
        return 'Unknown';
    }
  }

  Widget _buildTransactionHeader(List<dynamic> dataTransaction) {
    final totalAmount = widget.transaksi['total_harga'] ?? 0;
    String status;
    if (dataTransaction.isNotEmpty) {
      if (dataTransaction[0]['status'] is Map) {
        status = dataTransaction[0]['status']['status']?.toString() ?? 'Unknown';
      } else {
        status = dataTransaction[0]['status']?.toString() ?? 'Unknown';
      }
    } else {
      status = 'Unknown';
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${totalAmount.toString()}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: getStatusColor(
                              status), // status could be 'Unknown', but the function handles that
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getStatusText(
                            status), // status could be 'Unknown', but the function handles that
                        style: TextStyle(
                          color: getStatusColor(status),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            _buildTransactionDetail(
              "Transaction ID",
              widget.transaksi['kode_unik'] ?? 'Unknown',
            ),
            _buildTransactionDetail(
              "Cashier",
              widget.transaksi['profiles']['name'] ?? 'Unknown',
            ),
            _buildTransactionDetail(
              "Customer",
              widget.transaksi['pelanggans']['nama_pelanggan'] ?? 'Unknown',
            ),
            _buildTransactionDetail(
              "No Hp",
              widget.transaksi['pelanggans']?['no_hp'] ?? 'Unknown',
            ),
            _buildTransactionDetail(
              "Payment",
              "${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.transaksi['bayar'])}",
            ),
            _buildTransactionDetail(
              "Change",
              "${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.transaksi['kembalian'])}",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails(List<dynamic> dataTransaction) {
    final serviceDetails = dataTransaction
        .where((detail) => detail['layanan_id'] != null)
        .toList();
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Service Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            serviceDetails.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "No services",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: serviceDetails.length,
                    itemBuilder: (context, index) {
                      final detail = serviceDetails[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Service: ${detail['services']?['layanan'] ?? 'Unknown'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Price: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(detail['harga_layanan'])}",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(List<dynamic> dataTransaction) {
    final productDetails =
        dataTransaction.where((detail) => detail['produk_id'] != null).toList();
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Product Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            productDetails.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "No products",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: productDetails.length,
                    itemBuilder: (context, index) {
                      final detail = productDetails[index];
                      final price = detail['harga_produk'] ?? 0;
                      String formattedPrice;
                      try {
                        formattedPrice = NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(price);
                      } catch (e) {
                        print('Error formatting price: $e'); // Untuk debug
                        formattedPrice = 'Rp ${price.toString()}';
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Product: ${detail['products']?['produk'] ?? 'Unknown'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Price: $formattedPrice",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "Quantity: ${detail['qty']} ${detail['units']['unit']}",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}