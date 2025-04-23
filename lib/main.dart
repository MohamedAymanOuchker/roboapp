import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';
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
  final initSettings = InitializationSettings(
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
      title: 'RoboCode Kids',
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
        textTheme: TextTheme(
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
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    _sensorCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) {
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No code to run! Create a program first.')));
      return;
    }

    final connectionManager =
        Provider.of<RobotConnectionManager>(context, listen: false);

    if (!connectionManager.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connect to your robot first!')));
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
          await Future.delayed(Duration(milliseconds: 100));
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
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RoboCode Kids'),
        actions: [
          Consumer<RobotConnectionManager>(
            builder: (context, manager, child) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      manager.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: manager.isConnected ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      manager.isConnected ? manager.deviceName : 'Disconnected',
                      style: TextStyle(fontSize: 14),
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
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          tabs: [
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
          HomeScreen(),
          ConnectScreen(),
          CodeScreen(onCodeGenerated: _onCodeGenerated),
          RunScreen(
            generatedCode: _generatedCode,
            isRunning: _isRunning,
            onRun: _runProgram,
          ),
          SensorScreen(),
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to RoboCode Kids!',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 16),
              Text(
                'Program your robot using blocks!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 24),

              // Current level progress
              Row(
                children: [
                  Text(
                    'Level ${levelManager.currentLevel}:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(width: 8),
                  Text(
                    levelManager.getLevelName(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Level description
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      levelManager.getLevelDescription(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Level progress bar
              Text(
                'Your Progress:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: levelManager.currentLevel / levelManager.maxLevels,
                  minHeight: 24,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Level ${levelManager.currentLevel}/${levelManager.maxLevels}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 24),

              // Level selection
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                          boxShadow: [
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
                            SizedBox(height: 8),
                            Text(
                              'Level $level',
                              style: TextStyle(
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
  @override
  _ConnectScreenState createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool _isScanning = false;
  String _ssid = '';
  String _password = '';
  String _ipAddress = '192.168.4.1';
  String _port = '80';

  @override
  Widget build(BuildContext context) {
    return Consumer<RobotConnectionManager>(
      builder: (context, manager, child) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect to Your Robot',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 16),
              if (Platform.isWindows)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(height: 8),
                      Text(
                        'Bluetooth and WebView features are not supported on Windows platform.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please use the Android version of the app for full functionality.',
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ],
                  ),
                )
              else
                // Original connection UI for Android
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
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
                          SizedBox(width: 8),
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
                          Spacer(),
                          if (manager.isConnected)
                            ElevatedButton(
                              onPressed: () => manager.disconnect(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text('Disconnect'),
                            ),
                        ],
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
              padding: EdgeInsets.all(12),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Level ${levelManager.currentLevel}: ${levelManager.getLevelName()}',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
          SizedBox(height: 16),

          // Generated code display
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
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
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 24),

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
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
          ),

          SizedBox(height: 16),
          if (isRunning)
            Center(
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
                Icon(Icons.sensors_off, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Connect to your robot to see sensor data',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.bluetooth),
                  label: Text('Connect'),
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
