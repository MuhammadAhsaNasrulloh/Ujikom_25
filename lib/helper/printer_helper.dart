import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:waixilaundry/helper/thermal_helper.dart';

class BluetoothPrinterSelection extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final List<dynamic> details;

  const BluetoothPrinterSelection({
    Key? key,
    required this.transaction,
    required this.details,
  }) : super(key: key);

  @override
  State<BluetoothPrinterSelection> createState() => _BluetoothPrinterSelectionState();
}

class _BluetoothPrinterSelectionState extends State<BluetoothPrinterSelection> {
  final ThermalPrinterHelper _printerHelper = ThermalPrinterHelper();
  List<BluetoothDevice> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if Bluetooth is on
      if (!await _printerHelper.isBluetoothOn()) {
        setState(() {
          _errorMessage = 'Please turn on Bluetooth';
          _isLoading = false;
        });
        return;
      }

      _devices = await _printerHelper.getPairedDevices();
      
      if (_devices.isEmpty) {
        setState(() {
          _errorMessage = 'No paired devices found';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectAndPrint(BluetoothDevice device) async {
    setState(() => _isLoading = true);
    
    try {
      // Show connecting status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connecting to printer...')),
      );
      
      await _printerHelper.connectToDevice(device);
      
      // Show printing status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printing receipt...')),
      );
      
      await _printerHelper.printReceipt(widget.transaction, widget.details);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Print successful')),
      );

      // Close the printer selection screen
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDevices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(device.name ?? "Unknown Device"),
                      subtitle: Text(device.address ?? ""),
                      onTap: () => _connectAndPrint(device),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _printerHelper.disconnect();
    super.dispose();
  }
}