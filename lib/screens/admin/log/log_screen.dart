import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'package:supabase_flutter/supabase_flutter.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class AppColors {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDarkColor = Color(0xFF1E293B);
  static const Color textLightColor = Color(0xFF64748B);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color shadowColor = Color(0x1A000000);
}

class _LogScreenState extends State<LogScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> logs = [];
  List<Map<String, dynamic>> filteredLogs = [];
  bool isLoading = true;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    try {
      setState(() => isLoading = true);

      final response = await supabase
          .from('activity_logs') // Nama tabel di Supabase
          .select('*')
          .order('created_at', ascending: false); // Urutkan berdasarkan waktu

      if (response != null && response is List) {
        setState(() {
          logs = List<Map<String, dynamic>>.from(response);
          filteredLogs =
              List.from(logs); // Inisialisasi filteredLogs dengan semua data
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showError('Tidak ada data log aktivitas');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Error fetching logs: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String formatDate(String? timestamp) {
    if (timestamp == null) return '-';
    final date = DateTime.parse(timestamp);
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        _filterLogsByDateRange();
      });
    }
  }

  void _filterLogsByDateRange() {
    if (startDate == null || endDate == null) return;

    setState(() {
      filteredLogs = logs.where((log) {
        final logDate = DateTime.parse(log['created_at']);
        return logDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
            logDate.isBefore(endDate!.add(const Duration(days: 1)));
      }).toList();
    });
  }

  void _clearDateFilter() {
    setState(() {
      startDate = null;
      endDate = null;
      filteredLogs = List.from(logs); // Reset ke semua data
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(screenSize),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (startDate != null && endDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Menampilkan log dari ${DateFormat('dd MMM yyyy').format(startDate!)} hingga ${DateFormat('dd MMM yyyy').format(endDate!)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLightColor,
                  ),
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLogs.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada log aktivitas',
                            style: TextStyle(
                                fontSize: 16, color: AppColors.textLightColor),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: AppColors.cardColor,
                              shadowColor: AppColors.shadowColor,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.history,
                                          color: AppColors.primaryColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          log['activity_type'] ??
                                              'Tidak ada aktivitas',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.textDarkColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      log['description'] ??
                                          'Deskripsi tidak tersedia',
                                      style: TextStyle(
                                          color: AppColors.textLightColor),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'User ID: ${log['user_id'] ?? '-'}',
                                      style: TextStyle(
                                          color: AppColors.textLightColor),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formatDate(log['created_at']),
                                      style: TextStyle(
                                          color: AppColors.textLightColor),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Size screenSize) {
    final double toolbarHeight = screenSize.height * 0.08;
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Aktivitas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      toolbarHeight: toolbarHeight,
      iconTheme: IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_alt, color: Colors.white),
          onPressed: () => _selectDateRange(context),
        ),
        if (startDate != null || endDate != null)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: _clearDateFilter,
          ),
      ],
    );
  }
}
