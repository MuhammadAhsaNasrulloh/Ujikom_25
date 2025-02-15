import 'package:flutter/widgets.dart';
import 'package:waixilaundry/screens/admin/category/add_kategori.dart';
import 'package:waixilaundry/screens/admin/log/log_screen.dart';
import 'package:waixilaundry/screens/admin/product/add_product.dart';
import 'package:waixilaundry/screens/admin/product/product_screen.dart';
import 'package:waixilaundry/screens/admin/services/add_services.dart';
import 'package:waixilaundry/screens/admin/services/services_screen.dart';
import 'package:waixilaundry/screens/admin/users/user_screen.dart';
import 'package:waixilaundry/screens/admin/users/add_user.dart';
import 'package:waixilaundry/screens/auth/login_page.dart';
import 'package:waixilaundry/screens/auth/register_page.dart';
import 'package:waixilaundry/screens/dashboard/admin_dashboard.dart';
import 'package:waixilaundry/screens/dashboard/kasir_dashboard.dart';
import 'package:waixilaundry/screens/dashboard/owner_dashboard.dart';
import 'package:waixilaundry/screens/kasir/kasir_product.dart';
import 'package:waixilaundry/screens/kasir/transaksi_history.dart';
import 'package:waixilaundry/screens/kasir/transaksi_screen.dart';
import 'package:waixilaundry/screens/owner/analisis_bisnis.dart';
import 'package:waixilaundry/screens/owner/manage_user.dart';
import 'package:waixilaundry/screens/owner/transaction_report.dart';
import 'package:waixilaundry/screens/owner/transaksi_owner.dart';
import 'package:waixilaundry/screens/profiles_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String adminDashboard = '/admin-dashboard';
  static const String kasirDashboard =
      '/kasir-dashboard'; // Pastikan nama sudah benar
  static const String ownerDashboard = '/owner-dashboard';
  static const String addUser = '/add-user';
  static const String productPage = '/product';
  static const String transactionReport = '/laporan-transaksi';
  static const String activityLog = '/log-activity';
  static const String profilePage = '/profile';
  static const String seeUser = '/see-user';
  static const String addProduct = '/add-product';
  static const String addKategori = '/add-kategori';
  static const String addMenu = '/add-menu';
  static const String seeServices = '/see-services';
  static const String addServices = '/add-services';
  static const String manageUser = '/manage-user';
  static const String transaction = '/transaksi-kasir';
  static const String kasirProduct = '/kasir-product';
  static const String analysis = '/owner-bussines';
  static const String historiTransaksi = '/transaksi-history';
  static const String detailTransaksi = '/detail-transaksi';
  static const String ownerTransaksi = '/owner-transaksi';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => LoginScreen(),
      register: (context) => RegisterScreen(),
      adminDashboard: (context) => AdminDashboard(),
      kasirDashboard: (context) => KasirDashboard(),
      ownerDashboard: (context) => OwnerDashboard(),
      addUser: (context) => AddUser(),
      seeUser: (context) => UserScreen(),
      activityLog: (context) => LogScreen(),
      productPage: (context) => ProductScreen(),
      addProduct: (context) => AddProduct(),
      addKategori: (context) => AddKategori(),
      seeServices: (context) => ServicesScreen(),
      addServices: (context) => AddServices(),
      transaction: (context) => TransaksiScreen(),
      kasirProduct: (context) => KasirProduct(),
      historiTransaksi: (context) => TransaksiHistory(),
      profilePage: (context) => ProfilesScreen(),
      manageUser: (context) => ManageUser(),
      transactionReport: (context) => TransactionReport(),
      analysis: (context) => AnalisisBisnis(),
      ownerTransaksi: (context) => TransaksiOwner(),
    };
  }
}
