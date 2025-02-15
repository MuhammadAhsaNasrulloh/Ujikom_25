import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class TransactionReport extends StatefulWidget {
  const TransactionReport({super.key});

  @override
  State<TransactionReport> createState() => _TransactionReportState();
}

class _TransactionReportState extends State<TransactionReport> {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactionData = [];
  DateTime selectedStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime selectedEndDate = DateTime.now();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDataTransaction();
  }

  Future<void> _fetchDataTransaction() async {
    setState(() => isLoading = true);
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            kasir:profiles(id, name),
            pelanggan:pelanggans(id, nama_pelanggan),
            detail_transaction(
              id,
              status,
              qty,
              harga_produk,
              harga_layanan,
              produk:products(produk),
              layanan:services(layanan),
              unit:units(unit)
            )
          ''')
          .gte('created_at', selectedStartDate.toIso8601String())
          .lte('created_at', selectedEndDate.toIso8601String())
          .eq('is_deleted', false);

      if (response != null) {
        setState(() {
          transactionData = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error fetching data transactions: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _calculateTotalRevenue() {
    double total = transactionData.fold(
      0,
      (sum, transaction) => sum + (transaction['total_harga'] ?? 0),
    );
    return total.toStringAsFixed(0);
  }

  int _getCompletedOrdersCount() {
    return transactionData
        .where((transaction) =>
            transaction['detail_transaction'] != null &&
            transaction['detail_transaction'].isNotEmpty &&
            transaction['detail_transaction'][0]['status'] == 'selesai')
        .length;
  }

  int _getPendingOrdersCount() {
    return transactionData
        .where((transaction) =>
            transaction['detail_transaction'] != null &&
            transaction['detail_transaction'].isNotEmpty &&
            transaction['detail_transaction'][0]['status'] == 'pending')
        .length;
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(width * 0.1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.06),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: width * 0.15,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: textDarkColor,
                fontSize: width * 0.15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: textLightColor,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(bool isTablet, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = (availableWidth - (isDesktop ? 48 : 16)) /
            (isDesktop ? 4 : (isTablet ? 3 : 2));
        final cardHeight = cardWidth * 0.8;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              'Total Transaksi',
              '${transactionData.length}',
              Icons.receipt_outlined,
              const Color(0xFFECFDF5),
              const Color(0xFF059669),
              cardWidth,
              cardHeight,
            ),
            _buildStatCard(
              'Total Pendapatan',
              'Rp ${_calculateTotalRevenue()}',
              Icons.account_balance_wallet_outlined,
              const Color(0xFFEFF6FF),
              const Color(0xFF3B82F6),
              cardWidth,
              cardHeight,
            ),
          ],
        );
      },
    );
  }

 Future<void> _generateExcel() async {
  try {
    // Create a new Excel document
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Add headers with styling
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#E5E7EB'), // Light gray background for headers
    );

    final headers = [
      'Tanggal',
      'Kode Transaksi',
      'Kasir',
      'Pelanggan',
      'Produk',
      'Layanan',
      'Unit',
      'Qty',
      'Harga Produk',
      'Harga Layanan',
      'Total Harga',
      'Status',
    ];

    // Add headers with styling
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Check if transactionData is not empty
    if (transactionData.isEmpty) {
      throw Exception('No data available for export');
    }

    // Add transaction data
    var rowIndex = 1;
    for (final transaction in transactionData) {
      // Check if detail_transaction exists and is not empty
      final details = transaction['detail_transaction'];
      if (details == null || (details as List).isEmpty) {
        continue; // Skip this transaction if no details
      }

      // Convert details to List<Map<String, dynamic>>
      final detailsList = List<Map<String, dynamic>>.from(details);

      for (final detail in detailsList) {
        final rowData = [
          // Tanggal
          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaction['created_at'])),
          // Kode Transaksi
          transaction['kode_unik'] ?? 'N/A',
          // Kasir
          transaction['kasir']?['name'] ?? 'Unknown',
          // Pelanggan
          transaction['pelanggan']?['nama_pelanggan'] ?? 'Unknown',
          // Produk
          detail['produk']?['produk'] ?? 'Unknown',
          // Layanan
          detail['layanan']?['layanan'] ?? 'Unknown',
          // Unit
          detail['unit']?['unit'] ?? 'Unknown',
          // Qty
          detail['qty'] ?? 0,
          // Harga Produk
          detail['harga_produk'] ?? 0,
          // Harga Layanan
          detail['harga_layanan'] ?? 0,
          // Total Harga
          transaction['total_harga'] ?? 0,
          // Status
          detail['status'] ?? 'pending',
        ];

        // Add data to sheet
        for (var i = 0; i < rowData.length; i++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: i, rowIndex: rowIndex));
              
          if (i >= 8 && i <= 10) { // Columns with monetary values
            cell.value = DoubleCellValue(double.parse(rowData[i].toString()));
            cell.cellStyle = CellStyle(
              numberFormat: NumFormat.standard_0,
              horizontalAlign: HorizontalAlign.Right,
            );
          } else if (i == 7) { // Qty column
            cell.value = IntCellValue(int.parse(rowData[i].toString()));
            cell.cellStyle = CellStyle(
              horizontalAlign: HorizontalAlign.Right,
            );
          } else { // Text columns
            cell.value = TextCellValue(rowData[i].toString());
          }
        }
        rowIndex++;
      }
    }

    // Auto-size columns
    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20.0);
    }

    // Save the Excel file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'laporan_keuangan_${DateFormat('ddMMyyyy_HHmm').format(DateTime.now())}.xlsx';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    
    // Save and encode the file
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File Excel berhasil dibuat'),
          backgroundColor: Colors.green,
        ),
      );

      // Open the file
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception('Failed to open file: ${result.message}');
      }
    } else {
      throw Exception('Failed to encode Excel file');
    }
  } catch (e) {
    print('Error generating Excel file: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal membuat file Excel: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final screenSize = MediaQuery.of(context).size;
    final amount = transaction['total_harga'] ?? 0.0;
    final kodeUnik = transaction['kode_unik'] ?? 'Unknown';
    final kasirName = transaction['kasir']?['name'] ?? 'Unknown';
    final pelangganNama =
        transaction['pelanggan']?['nama_pelanggan'] ?? 'Unknown';
    final details = List<Map<String, dynamic>>.from(
        transaction['detail_transaction'] ?? []);
    final status = details.isNotEmpty ? details[0]['status'] : 'pending';

    return Column(
      children: [
        const SizedBox(
          height: 8,
        ),
        ExpansionTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          title: Container(
            padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.01),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenSize.width * 0.025),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_outlined,
                    color: primaryColor,
                    size: screenSize.width * 0.05,
                  ),
                ),
                SizedBox(width: screenSize.width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order $kodeUnik',
                        style: TextStyle(
                          color: textDarkColor,
                          fontWeight: FontWeight.w600,
                          fontSize: screenSize.width * 0.035,
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.005),
                      Text(
                        'Kasir: $kasirName',
                        style: TextStyle(
                          color: textLightColor,
                          fontSize: screenSize.width * 0.03,
                        ),
                      ),
                      Text(
                        'Pelanggan: $pelangganNama',
                        style: TextStyle(
                          color: textLightColor,
                          fontSize: screenSize.width * 0.03,
                        ),
                      ),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          color: status == 'selesai'
                              ? Colors.green
                              : Colors.orange,
                          fontSize: screenSize.width * 0.03,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rp ${NumberFormat('#,###').format(amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: screenSize.width * 0.035,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: EdgeInsets.all(screenSize.width * 0.04),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Transaksi',
                    style: TextStyle(
                      color: textDarkColor,
                      fontWeight: FontWeight.w600,
                      fontSize: screenSize.width * 0.035,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  ...details.map((detail) {
                    final produk = detail['produk']?['produk'] ?? 'Unknown';
                    final layanan = detail['layanan']?['layanan'] ?? 'Unknown';
                    final unit = detail['unit']?['unit'] ?? 'Unknown';
                    final qty = detail['qty'] ?? 0;
                    final hargaProduk = detail['harga_produk'] ?? 0;
                    final hargaLayanan = detail['harga_layanan'] ?? 0;
                    final totalHarga = transaction['total_harga'] ?? 0;

                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                produk,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: screenSize.width * 0.032,
                                ),
                              ),
                              Text(
                                'Rp ${NumberFormat('#,###').format(totalHarga)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                  fontSize: screenSize.width * 0.032,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Layanan: $layanan',
                            style: TextStyle(
                              color: textLightColor,
                              fontSize: screenSize.width * 0.028,
                            ),
                          ),
                          Text(
                            'Unit: $unit',
                            style: TextStyle(
                              color: textLightColor,
                              fontSize: screenSize.width * 0.028,
                            ),
                          ),
                          Text(
                            'Quantity: $qty',
                            style: TextStyle(
                              color: textLightColor,
                              fontSize: screenSize.width * 0.028,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Harga Produk: Rp ${NumberFormat('#,###').format(hargaProduk)}',
                                style: TextStyle(
                                  color: textLightColor,
                                  fontSize: screenSize.width * 0.028,
                                ),
                              ),
                              Text(
                                'Harga Layanan: Rp ${NumberFormat('#,###').format(hargaLayanan)}',
                                style: TextStyle(
                                  color: textLightColor,
                                  fontSize: screenSize.width * 0.028,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isTablet = screenSize.width >= 600;
    final isDesktop = screenSize.width >= 1024;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Laporan Keuangan',
          style: TextStyle(
            color: backgroundColor,
            fontSize: 20,
            fontWeight: FontWeight.w700
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: backgroundColor),
            onPressed: _generateExcel, // Change this to _generateExcel
          ),
        ],
        iconTheme: IconThemeData(color: backgroundColor),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.04,
          vertical: screenSize.height * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildStatisticsGrid(isTablet, isDesktop),
              const SizedBox(height: 24),
              Text(
                'Daftar Transaksi',
                style: TextStyle(
                  color: textDarkColor,
                  fontSize: screenSize.width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDateFilter(),
              const SizedBox(height: 16),
              ...transactionData.map(_buildTransactionItem).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    final dateTextStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Colors.grey[800],
    );

    final labelStyle = TextStyle(
      fontSize: 14,
      color: Colors.grey[600],
      fontWeight: FontWeight.w500,
    );

    InputDecoration _buildInputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, color: Colors.blue),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
    }

    Future<void> _selectDate(
        DateTime initialDate, Function(DateTime) onDateSelected) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.grey[800]!,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        onDateSelected(picked);
        _fetchDataTransaction();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Periode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  style: dateTextStyle,
                  decoration: _buildInputDecoration(
                      'Tanggal Mulai', Icons.calendar_today),
                  readOnly: true,
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy').format(selectedStartDate),
                  ),
                  onTap: () => _selectDate(selectedStartDate, (date) {
                    setState(() => selectedStartDate = date);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  style: dateTextStyle,
                  decoration: _buildInputDecoration(
                      'Tanggal Akhir', Icons.calendar_today),
                  readOnly: true,
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy').format(selectedEndDate),
                  ),
                  onTap: () => _selectDate(selectedEndDate, (date) {
                    setState(() => selectedEndDate = date);
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
