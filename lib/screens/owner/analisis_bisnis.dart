import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalisisBisnis extends StatefulWidget {
  const AnalisisBisnis({super.key});

  @override
  State<AnalisisBisnis> createState() => _AnalisisBisnisState();
}

class _AnalisisBisnisState extends State<AnalisisBisnis> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> analysisTransaction = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDataTransaksi();
  }

  Future<void> fetchDataTransaksi() async {
    try {
      final response = await _supabase.from('detail_transaction').select('*');
      if (response != null) {
        analysisTransaction = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('Error analysis data $e');
    }
  }

  Future<void> fetchDataProduk() async {
    try {
      final response = await _supabase.from('products').select('*');
      if (response != null) {
        analysisTransaction = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('Error analysis data $e');
    }
  }

  Future<void> fetchDataLayanan() async {
    try {
      final response = await _supabase.from('services').select('*');
      if (response != null) {
        analysisTransaction = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('Error analysis data $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
