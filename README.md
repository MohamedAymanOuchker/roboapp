# RoboCode Kids

A Flutter-based mobile application designed to teach children and beginners how to program robots using a visual, block-based coding interface. The app combines Bluetooth connectivity, a Blockly-based coding environment, and a level-based learning system to create an engaging and educational experience.

## Features

### 1. Blockly Coding Interface
- **Visual Programming**: Drag and drop blocks to create robot programs
- **Custom Blocks**: Predefined blocks for:
  - Robot movements (forward, backward, turn left, turn right)
  - Control structures (wait, repeat, if-then)
  - Sensor interactions (distance sensor)
- **Code Generation**: Automatically converts visual blocks into robot commands

### 2. Bluetooth Connectivity
- **Device Scanning**: Scan for nearby Bluetooth Low Energy (BLE) devices
- **Connection Management**: Connect, disconnect, and send commands to your robot
- **Error Handling**: Graceful handling of connection errors and permission issues

### 3. Level-Based Learning System
- **Progressive Difficulty**: Multiple levels with increasing complexity
- **Level Selection**: Unlock and progress through levels
- **Mission Descriptions**: Clear objectives for each level

### 4. User Interface
- **Tab-Based Navigation**: Easy navigation between screens
- **Real-Time Feedback**: Connection status, code execution, and sensor data
- **Animations and Notifications**: Enhanced user experience with visual feedback

### 5. Platform Support
- **Android and iOS**: Full functionality
- **Windows**: Limited functionality (Bluetooth and WebView features disabled)

## Technical Implementation

### Built With
- **Flutter**: Cross-platform UI toolkit
- **Dart**: Programming language
- **Key Libraries**:
  - flutter_blue_plus: BLE connectivity
  - flutter_inappwebview: Blockly interface
  - provider: State management
  - shared_preferences: Local storage
  - flutter_local_notifications: User notifications
  - lottie: Animations

### Project Structure
- **lib/main.dart**: App entry point and navigation
- **lib/connectivity_manager.dart**: Bluetooth and WiFi handling
- **lib/blockly_workspace.dart**: Blockly interface and code generation
- **lib/level_manager.dart**: Level progression and missions

### Asset Management
- **assets/images/**: App images
- **assets/icons/**: UI icons
- **assets/animations/**: Lottie animation files

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android Studio / Xcode
- A BLE-capable robot

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/roboapp.git
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## How It Works

1. **User Onboarding**
   - Open the app and view available levels
   - Select a level to start a mission

2. **Connecting to the Robot**
   - Navigate to Connect tab
   - Scan for and connect to your robot
   - Handle permissions if needed

3. **Coding with Blockly**
   - Use the Code tab to create programs
   - Drag and drop blocks
   - Generate and test code

4. **Running Programs**
   - Execute programs in the Run tab
   - View real-time feedback
   - Monitor robot actions

5. **Sensor Monitoring**
   - View sensor data in the Sensors tab
   - Monitor battery level
   - Track distance readings

## Educational Value

- **Programming Basics**: Learn sequences, loops, and conditionals
- **Problem-Solving**: Develop logical thinking skills
- **Hands-On Learning**: Connect code to physical actions
- **Progressive Learning**: Build skills through structured levels

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Blockly team for the visual programming interface
- Flutter team for the amazing framework
- All contributors and users of the app
