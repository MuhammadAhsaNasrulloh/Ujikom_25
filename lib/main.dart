import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waixilaundry/config/route.dart';
import 'package:waixilaundry/screens/auth/login_page.dart';
import 'package:waixilaundry/screens/auth/register_page.dart';
import 'package:waixilaundry/screens/kasir/detail_transaksi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2cndxaHV6anR0a3RscWVycnVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgyMzI2MzksImV4cCI6MjA1MzgwODYzOX0.ufilf-O0WBq3Ms_NK39h8HvCCbdyjA16fMPt2y65Hnc',
      url: 'https://uvrwqhuzjttktlqerruc.supabase.co');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waixi Laundry',
      theme: ThemeData(
        fontFamily: 'PlusJakartaSans',
      ),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.detailTransaksi) {
          final transaksi = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => DetailTransaksi(transaksi: transaksi),
          );
        }
        return MaterialPageRoute(
          builder: (context) => AppRoutes.getRoutes()[settings.name]!(context),
        );
      },
      routes: AppRoutes.getRoutes(),
      home: LoginScreen(),
    );
  }
}
