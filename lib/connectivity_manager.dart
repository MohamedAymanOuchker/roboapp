import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ConnectionType { bluetooth, wifi, none }

class RobotConnectionManager extends ChangeNotifier {
  // Connection state
  ConnectionType _connectionType = ConnectionType.none;
  bool _isConnected = false;
  String _deviceName = "";
  String _deviceAddress = "";

  // BLE specific
  BluetoothDevice? _bleDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  // WiFi specific
  String _ipAddress = "192.168.4.1"; // Default ESP32 AP address
  int _port = 80;

  // Data streams
  final _sensorDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get sensorDataStream =>
      _sensorDataController.stream;

  // Getters
  ConnectionType get connectionType => _connectionType;
  bool get isConnected => _isConnected;
  String get deviceName => _deviceName;
  String get deviceAddress => _deviceAddress;
  String get ipAddress => _ipAddress;
  int get port => _port;

  // Constructor
  RobotConnectionManager() {
    _loadSavedConnections();
  }

  // Load previously connected devices
  Future<void> _loadSavedConnections() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceName = prefs.getString('lastDeviceName') ?? "";
    _deviceAddress = prefs.getString('lastDeviceAddress') ?? "";
    _connectionType =
        ConnectionType.values[prefs.getInt('lastConnectionType') ?? 0];
    _ipAddress = prefs.getString('lastIpAddress') ?? _ipAddress;
    _port = prefs.getInt('lastPort') ?? _port;
  }

  // Save connection settings
  Future<void> _saveConnection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastDeviceName', _deviceName);
    await prefs.setString('lastDeviceAddress', _deviceAddress);
    await prefs.setInt('lastConnectionType', _connectionType.index);
    await prefs.setString('lastIpAddress', _ipAddress);
    await prefs.setInt('lastPort', _port);
  }

  // ----- Bluetooth Functions -----

  // Scan for BLE devices
  Stream<List<BluetoothDevice>> scanForDevices() {
    // Start scanning
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

    // Return results stream
    return FlutterBluePlus.scanResults.map((results) {
      return results.map((result) => result.device).toList();
    });
  }

  // Connect to Bluetooth device
  Future<bool> connectBluetooth(BluetoothDevice device) async {
    try {
      // Stop scanning if still active
      FlutterBluePlus.stopScan();

      // Connect to the device
      await device.connect();

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Look for our service and characteristics
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // Identify write characteristic
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
          }

          // Identify notify characteristic for receiving data
          if (characteristic.properties.notify) {
            _notifyCharacteristic = characteristic;
            await characteristic.setNotifyValue(true);
            characteristic.value.listen(_handleBleData);
          }
        }
      }

      // Check if we found the necessary characteristics
      if (_writeCharacteristic == null) {
        await device.disconnect();
        return false;
      }

      // Update connection state
      _bleDevice = device;
      _connectionType = ConnectionType.bluetooth;
      _isConnected = true;
      _deviceName = device.name;
      _deviceAddress = device.id.id;

      // Save connection info
      await _saveConnection();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error connecting to Bluetooth device: $e');
      return false;
    }
  }

  // Disconnect BLE
  Future<void> disconnectBluetooth() async {
    if (_bleDevice != null) {
      try {
        await _bleDevice!.disconnect();
      } catch (e) {
        print('Error disconnecting: $e');
      }
    }

    _bleDevice = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;

    if (_connectionType == ConnectionType.bluetooth) {
      _isConnected = false;
      _connectionType = ConnectionType.none;
      notifyListeners();
    }
  }

  // ----- WiFi Functions -----

  // Connect to WiFi network (ESP32 AP)
  Future<bool> connectWifi(String ssid, String password) async {
    try {
      // Connect to the robot's WiFi network
      bool connected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
        joinOnce: true,
      );

      if (connected) {
        _deviceName = ssid;
        _connectionType = ConnectionType.wifi;
        _isConnected = true;

        // Get IP of the connected device
        String? ip = await WiFiForIoTPlugin.getIP();
        if (ip != null && ip.isNotEmpty) {
          _deviceAddress = ip;
        }

        await _saveConnection();
        notifyListeners();
      }

      return connected;
    } catch (e) {
      print('Error connecting to WiFi: $e');
      return false;
    }
  }

  // Set WiFi server info (for connecting to existing network where robot is already connected)
  void setWifiServerInfo(String ipAddress, int port) {
    _ipAddress = ipAddress;
    _port = port;
    _saveConnection();
  }

  // Disconnect WiFi
  Future<void> disconnectWifi() async {
    try {
      await WiFiForIoTPlugin.disconnect();
    } catch (e) {
      print('Error disconnecting WiFi: $e');
    }

    if (_connectionType == ConnectionType.wifi) {
      _isConnected = false;
      _connectionType = ConnectionType.none;
      notifyListeners();
    }
  }

  // ----- Common Functions -----

  // Disconnect from current connection
  Future<void> disconnect() async {
    if (_connectionType == ConnectionType.bluetooth) {
      await disconnectBluetooth();
    } else if (_connectionType == ConnectionType.wifi) {
      await disconnectWifi();
    }
  }

  // Send command to robot
  Future<bool> sendCommand(String command) async {
    if (!_isConnected) return false;

    try {
      if (_connectionType == ConnectionType.bluetooth) {
        if (_writeCharacteristic != null) {
          await _writeCharacteristic!.write(utf8.encode(command));
          return true;
        }
      } else if (_connectionType == ConnectionType.wifi) {
        // Basic HTTP request for commanding the robot
        // In a real app, you might want to use web sockets for bidirectional communication

        // Implementation depends on your ESP32 web server setup
        // This is a placeholder for the HTTP implementation
        return true;
      }
    } catch (e) {
      print('Error sending command: $e');
    }

    return false;
  }

  // Process incoming BLE data
  void _handleBleData(List<int> data) {
    // Parse the incoming data - expected to be JSON format
    String dataString = utf8.decode(data);
    try {
      Map<String, dynamic> sensorData = jsonDecode(dataString);
      _sensorDataController.add(sensorData);
    } catch (e) {
      print('Error parsing sensor data: $e');
    }
  }

  // Get latest sensor values
  Future<Map<String, dynamic>> getSensorValues() async {
    // This is a placeholder - in a real app you would request current sensor data
    // if it's not already being streamed regularly
    return {};
  }

  // Check battery level and show alert if low
  void checkBatteryLevel(BuildContext context) async {
    var sensorData = await getSensorValues();
    if (sensorData.containsKey('battery')) {
      int batteryLevel = sensorData['battery'];
      if (batteryLevel < 20) {
        // Show battery alert
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.battery_alert, color: Colors.red),
                SizedBox(width: 10),
                Text('Low battery: $batteryLevel%!'),
              ],
            ),
            backgroundColor: Colors.red[700],
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Clean up resources
  void dispose() {
    _sensorDataController.close();
    disconnect();
    super.dispose();
  }
}
