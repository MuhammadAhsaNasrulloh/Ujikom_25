import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

class CurrencyFormatUtils {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  // Format number to currency string (returns "Rp10.000")
  static String format(dynamic number) {
    if (number == null) return 'Rp0';

    // Handle string input
    if (number is String) {
      number = double.tryParse(number) ?? 0;
    }

    // Handle int input
    if (number is int) {
      number = number.toDouble();
    }

    return _currencyFormatter.format(number);
  }

  // Format without symbol (returns "10.000")
  static String formatWithoutSymbol(dynamic number) {
    if (number == null) return '0';

    return format(number).replaceAll('Rp', '');
  }

  // Parse currency string to number (handles "Rp10.000" or "10.000")
  static double parse(String currencyString) {
    if (currencyString.isEmpty) return 0;

    // Remove currency symbol and any whitespace
    String cleanString = currencyString
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '');

    return double.tryParse(cleanString) ?? 0;
  }
}

class ThermalPrinterHelper {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  // Check if Bluetooth is turned on
  Future<bool> isBluetoothOn() async {
    try {
      return await bluetooth.isOn ?? false;
    } catch (e) {
      print("Error checking Bluetooth status: $e");
      return false;
    }
  }

  // Check all required Bluetooth permissions
  Future<bool> checkPermissions() async {
    if (await Permission.bluetooth.status.isDenied) {
      final status = await Permission.bluetooth.request();
      if (status.isDenied) {
        return false;
      }
    }
    if (await Permission.bluetoothConnect.status.isDenied) {
      final status = await Permission.bluetoothConnect.request();
      if (status.isDenied) {
        return false;
      }
    }
    if (await Permission.bluetoothScan.status.isDenied) {
      final status = await Permission.bluetoothScan.request();
      if (status.isDenied) {
        return false;
      }
    }
    return true;
  }

  // Get list of paired Bluetooth devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      if (!await checkPermissions()) {
        throw Exception("Bluetooth permissions not granted");
      }
      if (!await isBluetoothOn()) {
        throw Exception("Bluetooth is turned off");
      }
      return await bluetooth.getBondedDevices() ?? [];
    } catch (e) {
      print("Error getting paired devices: $e");
      rethrow;
    }
  }

  // Check printer status - Fixed to use correct methods
  Future<bool> checkPrinterStatus() async {
    try {
      // First check if we're connected
      final isConnected = await bluetooth.isConnected ?? false;
      if (!isConnected) {
        return false;
      }

      // Then check if printer is available
      final isAvailable = await bluetooth.isAvailable ??
          false; // Remove the ?? false since isAvailable() returns bool
      if (!isAvailable) {
        return false;
      }

      // Try to write a test byte to verify printer is ready
      try {
        final initCommand =
            Uint8List.fromList([0x1B, 0x40]); // Convert to Uint8List
        await bluetooth.writeBytes(initCommand);
        return true;
      } catch (e) {
        print("Error testing printer write: $e");
        return false;
      }
    } catch (e) {
      print("Error checking printer status: $e");
      return false;
    }
  }

  // Connect to printer with retry mechanism
  Future<void> connectToDevice(BluetoothDevice device,
      {int retries = 3}) async {
    if (!await checkPermissions()) {
      throw Exception("Bluetooth permissions not granted");
    }

    for (int i = 0; i < retries; i++) {
      try {
        if (!(await bluetooth.isConnected ?? false)) {
          await bluetooth.connect(device);

          // Wait a bit for the connection to stabilize
          await Future.delayed(const Duration(milliseconds: 500));

          // Verify connection
          if (await bluetooth.isConnected ?? false) {
            return;
          }
        } else {
          return;
        }
      } catch (e) {
        if (i == retries - 1) {
          print("Failed to connect after $retries attempts");
          rethrow;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  // Disconnect from printer
  Future<void> disconnect() async {
    try {
      await bluetooth.disconnect();
    } catch (e) {
      print("Error disconnecting: $e");
      rethrow;
    }
  }

  // Print receipt
  Future<void> printReceipt(
      Map<String, dynamic> transaction, List<dynamic> details) async {
    try {
      if (!(await bluetooth.isConnected ?? false)) {
        throw Exception("Printer not connected");
      }

      if (!await checkPrinterStatus()) {
        throw Exception("Printer not ready");
      }

      // Header
      await bluetooth.printNewLine();
      await bluetooth.printCustom("Waixi Laundry", 2, 1);
      await bluetooth.printNewLine();

      // Transaction details
      await bluetooth.printCustom("================================", 1, 1);
      await bluetooth.printCustom("No: ${transaction['kode_unik']}", 1, 0);
      await bluetooth.printCustom(
          "Kasir: ${transaction['profiles']['name'] ?? 'Unknown'}", 1, 0);
      await bluetooth.printCustom(
          "Pelanggan: ${transaction['pelanggans']['nama_pelanggan'] ?? 'Unknown'}",
          1,
          0);
      await bluetooth.printCustom(
          "Tanggal: ${_formatDate(transaction['created_at'])}", 1, 0);
      await bluetooth.printCustom("================================", 1, 1);

      // Services
      final services = details.where((d) => d['layanan_id'] != null).toList();
      if (services.isNotEmpty) {
        await bluetooth.printCustom("LAYANAN:", 1, 0);
        for (var service in services) {
          await bluetooth.printCustom(
              "${service['services']['layanan']}", 1, 0);
          await bluetooth.printCustom(
              "${CurrencyFormatUtils.format(service['harga_layanan'])}", 1, 2);
        }
        await bluetooth.printCustom("--------------------------------", 1, 1);
      }

      // Products
      final products = details.where((d) => d['produk_id'] != null).toList();
      if (products.isNotEmpty) {
        await bluetooth.printCustom("PRODUK:", 1, 0);
        for (var product in products) {
          await bluetooth.printCustom(
              "${product['products']['produk']} x${product['qty']} ${product['units']['unit']}",
              1,
              0);
          await bluetooth.printCustom(
              "${CurrencyFormatUtils.format(product['harga'])}", 1, 2);
        }
        await bluetooth.printCustom("--------------------------------", 1, 1);
      }

      // Payment details
      await bluetooth.printCustom(
          "TOTAL: ${CurrencyFormatUtils.format(transaction['total_harga'])}", 1, 2);
      await bluetooth.printCustom(
          "BAYAR: ${CurrencyFormatUtils.format(transaction['bayar'])}", 1, 2);
      await bluetooth.printCustom(
          "KEMBALI: ${CurrencyFormatUtils.format(transaction['kembalian'])}",
          1,
          2);

      // Footer
      await bluetooth.printNewLine();
      await bluetooth.printCustom("Terima Kasih", 1, 1);
      await bluetooth.printCustom("Atas Kunjungan Anda", 1, 1);

      // Print QR code
      try {
        await bluetooth.printQRcode(transaction['kode_unik'], 200, 200, 1);
      } catch (e) {
        print("QR code printing not supported: $e");
      }

      await bluetooth.printNewLine();
      await bluetooth.printNewLine();

      // Try paper cut, fall back to new lines if not supported
      try {
        await bluetooth.paperCut();
      } catch (e) {
        print("Paper cut not supported: $e");
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
        await bluetooth.printNewLine();
      }
    } catch (e) {
      print("Error printing: $e");
      rethrow;
    }
  }

  // Helper method to format date
  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    return date.toString().split('.')[0];
  }
}
