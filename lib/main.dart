// ignore_for_file: unused_field, unused_import, use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:io' show Platform;

// Import our custom components
import 'blockly_workspace.dart';
import 'connectivity_manager.dart';
import 'level_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Run app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RobotConnectionManager()),
        ChangeNotifierProvider(create: (_) => LevelManager()),
      ],
      child: const RobotApp(),
    ),
  );
}

class RobotApp extends StatelessWidget {
  const RobotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoboCode',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
        fontFamily: 'Nunito',
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: Colors.orange,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
        fontFamily: 'Nunito',
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: Colors.orange,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _generatedCode = '';
  bool _isRunning = false;
  Timer? _sensorCheckTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Check sensors periodically
    _sensorCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      // Get connection manager
      final connectionManager =
          Provider.of<RobotConnectionManager>(context, listen: false);
      if (connectionManager.isConnected) {
        connectionManager.checkBatteryLevel(context);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sensorCheckTimer?.cancel();
    super.dispose();
  }

  void _onCodeGenerated(String code) {
    setState(() {
      _generatedCode = code;
    });
  }

  Future<void> _runProgram() async {
    if (_generatedCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No code to run! Create a program first.')));
      return;
    }

    final connectionManager =
        Provider.of<RobotConnectionManager>(context, listen: false);

    if (!connectionManager.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connect to your robot first!')));
      _tabController.animateTo(1); // Navigate to Connect tab
      return;
    }

    setState(() {
      _isRunning = true;
    });

    try {
      // Parse and send commands
      List<String> lines = _generatedCode.split('\n');

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        // Simple regex to extract commands like sendCommand("F1000")
        RegExp cmdRegex = RegExp(r'sendCommand\("([^"]+)"\)');
        RegExp waitRegex = RegExp(r'wait\((\d+(\.\d+)?)\)');

        var cmdMatch = cmdRegex.firstMatch(line);
        var waitMatch = waitRegex.firstMatch(line);

        if (cmdMatch != null) {
          String cmd = cmdMatch.group(1) ?? '';
          await connectionManager.sendCommand(cmd);

          // Add a small delay between commands
          await Future.delayed(const Duration(milliseconds: 100));
        } else if (waitMatch != null) {
          String waitTime = waitMatch.group(1) ?? '0';
          int milliseconds = (double.parse(waitTime) * 1000).round();
          await Future.delayed(Duration(milliseconds: milliseconds));
        }
      }

      // Mark program as completed for level progression
      final levelManager = Provider.of<LevelManager>(context, listen: false);
      levelManager.completeCurrentLevel();

      // Show success animation
      _showSuccessAnimation();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error running program: $e')));
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/success.json',
              width: 200,
              height: 200,
              repeat: false,
            ),
            Text(
              'Great job!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoboCode'),
        actions: [
          Consumer<RobotConnectionManager>(
            builder: (context, manager, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      manager.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: manager.isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      manager.isConnected ? manager.deviceName : 'Disconnected',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Home', icon: Icon(Icons.home)),
            Tab(text: 'Connect', icon: Icon(Icons.bluetooth)),
            Tab(text: 'Code', icon: Icon(Icons.code)),
            Tab(text: 'Run', icon: Icon(Icons.play_arrow)),
            Tab(text: 'Sensors', icon: Icon(Icons.sensors)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const HomeScreen(),
          const ConnectScreen(),
          CodeScreen(onCodeGenerated: _onCodeGenerated),
          RunScreen(
            generatedCode: _generatedCode,
            isRunning: _isRunning,
            onRun: _runProgram,
          ),
          const SensorScreen(),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LevelManager>(
      builder: (context, levelManager, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to RoboCode!',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Program your robot using blocks!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Current level progress
              Row(
                children: [
                  Text(
                    'Level ${levelManager.currentLevel}:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    levelManager.getLevelName(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Level description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mission:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      levelManager.getLevelDescription(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Level progress bar
              const Text(
                'Your Progress:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: levelManager.currentLevel / levelManager.maxLevels,
                  minHeight: 24,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.orange,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Level ${levelManager.currentLevel}/${levelManager.maxLevels}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // Level selection
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: levelManager.maxLevels,
                  itemBuilder: (context, index) {
                    final level = index + 1;
                    final isUnlocked =
                        level <= levelManager.highestUnlockedLevel;
                    final isCompleted = level < levelManager.currentLevel;
                    final isCurrent = level == levelManager.currentLevel;

                    return GestureDetector(
                      onTap: isUnlocked
                          ? () => levelManager.setCurrentLevel(level)
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Colors.blue
                              : isCompleted
                                  ? Colors.green
                                  : isUnlocked
                                      ? Colors.orange
                                      : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : isUnlocked
                                      ? Icons.play_circle_fill
                                      : Icons.lock,
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Level $level',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
        );
      },
    );
  }
}

// Connect Screen to manage Bluetooth and WiFi connections
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  _ConnectScreenState createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _isScanning = false;
  List<BluetoothDevice> _devices = [];
  String _ssid = '';
  String _password = '';
  String _ipAddress = '192.168.4.1';
  String _port = '80';
  String? _errorMessage;

  void _startScanning(BuildContext context) async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final connectionManager =
          Provider.of<RobotConnectionManager>(context, listen: false);
      final deviceStream = await connectionManager.scanForDevices();

      deviceStream.listen((devices) {
        setState(() {
          _devices = devices;
        });
      }, onDone: () {
        setState(() {
          _isScanning = false;
        });
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Error scanning for devices: $e';
      });
    }
  }

  Future<void> _connectToDevice(
      BuildContext context, BluetoothDevice device) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final connectionManager =
          Provider.of<RobotConnectionManager>(context, listen: false);
      final success = await connectionManager.connectBluetooth(device);

      if (!success) {
        setState(() {
          _errorMessage = 'Failed to connect to device';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting to device: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RobotConnectionManager>(
      builder: (context, manager, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect to Your Robot',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              if (Platform.isWindows)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(height: 8),
                      Text(
                        'Bluetooth and WebView features are not supported on Windows platform.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please use the Android version of the app for full functionality.',
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    // Connection status
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: manager.isConnected
                            ? Colors.green[100]
                            : Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            manager.isConnected
                                ? Icons.check_circle
                                : Icons.error,
                            color:
                                manager.isConnected ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            manager.isConnected
                                ? 'Connected to ${manager.deviceName}'
                                : 'Not connected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: manager.isConnected
                                  ? Colors.green[900]
                                  : Colors.red[900],
                            ),
                          ),
                          const Spacer(),
                          if (manager.isConnected)
                            ElevatedButton(
                              onPressed: () => manager.disconnect(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Disconnect'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Scan button
                    if (!manager.isConnected)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isScanning
                              ? null
                              : () => _startScanning(context),
                          icon: Icon(_isScanning
                              ? Icons.hourglass_full
                              : Icons.search),
                          label: Text(
                              _isScanning ? 'Scanning...' : 'Scan for Devices'),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Device list
                    if (!manager.isConnected && _devices.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.bluetooth),
                                title: Text(device.name.isNotEmpty
                                    ? device.name
                                    : 'Unknown Device'),
                                subtitle: Text(device.id.id),
                                trailing: ElevatedButton(
                                  onPressed: () =>
                                      _connectToDevice(context, device),
                                  child: const Text('Connect'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

// Code Screen with Blockly integration
class CodeScreen extends StatelessWidget {
  final Function(String) onCodeGenerated;

  const CodeScreen({Key? key, required this.onCodeGenerated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LevelManager>(
      builder: (context, levelManager, child) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Level ${levelManager.currentLevel}: ${levelManager.getLevelName()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocklyWorkspace(
                onCodeGenerated: onCodeGenerated,
                availableBlocks: levelManager.getAvailableBlocks(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Run Screen to execute and visualize robot commands
class RunScreen extends StatelessWidget {
  final String generatedCode;
  final bool isRunning;
  final VoidCallback onRun;

  const RunScreen({
    Key? key,
    required this.generatedCode,
    required this.isRunning,
    required this.onRun,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Program Commands',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Generated code display
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  generatedCode.isEmpty
                      ? 'Your code will appear here...'
                      : generatedCode,
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Run button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: isRunning ? null : onRun,
              icon: Icon(isRunning ? Icons.hourglass_full : Icons.play_arrow,
                  size: 28),
              label: Text(
                isRunning ? 'Running...' : 'Run Program',
                style: const TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 16),
          if (isRunning)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Executing commands...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Sensor Screen for displaying robot telemetry
class SensorScreen extends StatelessWidget {
  const SensorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RobotConnectionManager>(
      builder: (context, manager, child) {
        if (!manager.isConnected) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sensors_off, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Connect to your robot to see sensor data',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.bluetooth),
                  label: const Text('Connect'),
                ),
              ],
            ),
          );
        }
        return Container(); // Add your sensor data display here
      },
    );
  }
}
