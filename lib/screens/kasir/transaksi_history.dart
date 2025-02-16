import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:waixilaundry/screens/kasir/detail_transaksi.dart';

class TransaksiHistory extends StatefulWidget {
  const TransaksiHistory({super.key});

  @override
  State<TransaksiHistory> createState() => _TransaksiHistoryState();
}

class _TransaksiHistoryState extends State<TransaksiHistory> {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);

  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> dataTransaksi = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDataTransaksi();
  }

  Future<void> fetchDataTransaksi() async {
  try {
    setState(() => isLoading = true);
    final response = await supabase
        .from('transactions')
        .select('''
          id, 
          kode_unik, 
          kasir_id, 
          pelanggan_id, 
          bayar, 
          kembalian, 
          is_deleted, 
          created_at, 
          updated_at, 
          total_harga, 
          status:detail_transaction!inner(status), 
          profiles(name), 
          pelanggans(nama_pelanggan, no_hp)
        ''')
        .eq('is_deleted', false) // Filter untuk hanya mengambil transaksi yang tidak dihapus
        .order('created_at', ascending: false);

    if (response != null && response is List) {
      setState(() {
        dataTransaksi = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } else {
      throw 'No data received from transactions';
    }
    print('Transaction Response: $response');
  } catch (e) {
    setState(() => isLoading = false);
    print('Error fetching transactions: $e');
  }
}


  Color getStatusColor(String status) {
    switch (status) {
      case 'diterima':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'selesai':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(
            color: backgroundColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dataTransaksi.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dataTransaksi.length,
                  itemBuilder: (context, index) {
                    final transaksi = dataTransaksi[index];
                    final kasirName =
                        transaksi['profiles']?['name'] ?? 'Unknown';
                    final pelangganName =
                        transaksi['pelanggans']?['nama_pelanggan'] ?? 'Unknown';
                    final pelangganPhone =
                        transaksi['pelanggans']?['no_hp']?.toString() ??
                            'Unknown';
                    final date = DateTime.parse(transaksi['created_at']);
                    final status = transaksi['status']?.isNotEmpty == true
                        ? transaksi['status'][0]['status']
                        : 'Unknown';

                    return Card(
                      elevation: 0,
                      color: backgroundColor,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailTransaksi(transaksi: transaksi),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaksi['kode_unik'] ??
                                              'Unknown Transaction',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy • HH:mm')
                                              .format(date),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: textLightColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: getStatusColor(status),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            color: getStatusColor(status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              _buildDetailRow('Cashier', kasirName),
                              _buildDetailRow('Customer', pelangganName),
                              _buildDetailRow('Phone', pelangganPhone),
                              _buildDetailRow(
                                'Total',
                                'Rp${NumberFormat('#,###').format(transaksi['total_harga'] ?? 0)}',
                                isTotal: true,
                              ),
                              _buildDetailRow(
                                'Payment',
                                'Rp${NumberFormat('#,###').format(transaksi['bayar'] ?? 0)}',
                              ),
                              _buildDetailRow(
                                'Change',
                                'Rp${NumberFormat('#,###').format(transaksi['kembalian'] ?? 0)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textLightColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
